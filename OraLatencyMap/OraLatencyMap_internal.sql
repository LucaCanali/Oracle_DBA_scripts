--
-- OraLatencyMap_internal - This is the internal part of OraLatencyMap, a tool to visualize Oracle wait events latency with heatmaps
--                        - do not run this directly, use a launcher script instead: OraLatencyMap or OraLatencyMap_advanced
--
-- Luca.Canali@cern.ch, v1.3, September 2025. Original version, August 2013.
--
-- v1.3 changes:
--   * Switch source to GV$EVENT_HISTOGRAM_MICRO (µs bins).
--   * First (lowest) bucket aggregates all waits <= 128 µs -> label "<.128".
--   * Subsequent buckets are powers-of-two thresholds in µs, shown in ms:
--       .128, .256, .512, 1, 2, 4, 8, ... (ms)
-- More info: see README
--

declare
  -- Main datatypes for data collections (1D and 2D arrays implemented with pl/sql associative arrays)
  type t_numberarray  is table of number       index by pls_integer;
  type t_integerarray is table of pls_integer  index by pls_integer;
  type t_integertable is table of t_integerarray index by pls_integer;

  gc_num_bins pls_integer := &num_bins;   -- number of latency buckets on the Y axis (plus 1 catch-all highest bucket)
  gc_num_rows pls_integer := &num_rows;   -- X axis width: number of time samples kept

  -- State
  g_previous_wait_count  t_numberarray;
  g_latest_wait_count    t_numberarray;
  g_previous_time_waited t_numberarray;   -- milliseconds
  g_latest_time_waited   t_numberarray;   -- milliseconds
  g_previous_time_sec    number;
  g_latest_time_sec      number;
  g_delta_time           number;
  g_latest_iops          pls_integer;
  g_latest_wait          pls_integer;
  g_total_iops           pls_integer;
  g_total_wait           pls_integer;

  g_screen               clob;             -- screen output stored in a clob

  g_table_wait_count  t_integertable;      -- 2D array, wait count data for blue heat map
  g_table_time_waited t_integertable;      -- 2D array, time waited data (ms/sec) for yellow-red heat map

  ---------------------------------------------------------------------------
  -- Helpers for µs→ms bucket labeling and formatting
  ---------------------------------------------------------------------------
  -- format a threshold in microseconds as a millisecond bucket label:
  --   <1ms: ".128", ".256", ".512"
  --   >=1ms: "1", "2", "4", ...
  function format_ms_label(p_us number) return varchar2 is
    v_ms number;
    v_txt varchar2(32);
  begin
    v_ms := p_us/1000;
    if v_ms < 1 then
      v_txt := to_char(v_ms, 'FM0D000', 'NLS_NUMERIC_CHARACTERS=''.,''');
      -- strip leading 0 -> ".128"
      return '.'||substr(v_txt, 3);
    else
      -- round to nearest integer (1.024->1, 2.048->2, etc.)
      return to_char(round(v_ms));
    end if;
  end;

  -- Return the label for a given bucket index (0..gc_num_bins)
  -- index 0 is the special aggregated bucket "<.128"
  function bucket_label(p_idx pls_integer) return varchar2 is
    v_us number;
  begin
    if p_idx = 0 then
      return '<.128';
    else
      -- p_idx = 1 -> 256 µs, p_idx = 2 -> 512 µs, p_idx = 3 -> 1024 µs, ...
      v_us := power(2, 7 + p_idx); -- since 2^7 = 128 µs is the aggregated floor
      return format_ms_label(v_us);
    end if;
  end;

  ---------------------------------------------------------------------------
  -- Collect latest data points from GV$EVENT_HISTOGRAM_MICRO
  ---------------------------------------------------------------------------
  procedure collect_latest_data_points is
    cursor c1_histogram_data is
      select wait_time_micro, wait_count,
             -- estimate time waited per bin in milliseconds (same heuristic as v1.2)
             wait_count * (wait_time_micro/1000) * .75 as estimated_wait_time_ms
      from   gv$event_histogram_micro
      where  event='&wait_event' &instance_filter_clause;

    v_bin pls_integer;
    v_exp number;
  begin
    -- zero latest arrays
    for y in 0..gc_num_bins loop
      g_latest_wait_count(y) := 0;
      g_latest_time_waited(y):= 0;   -- ms
    end loop;

    -- seconds in current hour (with decimals)
    g_latest_time_sec := extract(second from systimestamp) + 60*extract(minute from systimestamp);

    -- map µs bins to our ms-oriented buckets:
    --   <=128 µs -> bucket 0 ("<.128")
    --   256 µs   -> bucket 1
    --   512 µs   -> bucket 2
    --   1024 µs  -> bucket 3 (~1 ms)
    --   ...
    for c in c1_histogram_data loop
      if c.wait_time_micro <= 128 then
        v_bin := 0;
      else
        v_exp := log(2, c.wait_time_micro);        -- exact exponents: 8 for 256, 9 for 512, 10 for 1024, ...
        v_bin := greatest(1, trunc(v_exp) - 7);    -- shift so 256µs->1, 512µs->2, 1024µs->3, ...
      end if;

      if v_bin < gc_num_bins then
        g_latest_wait_count(v_bin)  := g_latest_wait_count(v_bin)  + c.wait_count;
        g_latest_time_waited(v_bin) := g_latest_time_waited(v_bin) + c.estimated_wait_time_ms;
      else
        -- highest bin is catch-all (>= last explicit threshold)
        g_latest_wait_count(gc_num_bins)  := g_latest_wait_count(gc_num_bins)  + c.wait_count;
        g_latest_time_waited(gc_num_bins) := g_latest_time_waited(gc_num_bins) + c.estimated_wait_time_ms;
      end if;
    end loop;
  end collect_latest_data_points;

  ---------------------------------------------------------------------------
  -- Compute new state (append deltas as latest column)
  ---------------------------------------------------------------------------
  procedure compute_new_state is
    v_delta_time number;
  begin
    if (:var_number_iterations = 0) then
      g_delta_time := 0;
      return;
    end if;

    dbms_lock.sleep (&sleep_interval);

    if g_previous_time_sec <= g_latest_time_sec then
      v_delta_time := g_latest_time_sec - g_previous_time_sec;
    else
      v_delta_time := 3600 + g_latest_time_sec - g_previous_time_sec;  -- wrap at hour boundary
    end if;

    g_delta_time := round(v_delta_time,1);

    for y in 0..gc_num_bins loop
      g_table_wait_count(gc_num_rows)(y)  := ceil ((g_latest_wait_count(y)  - g_previous_wait_count(y)) / v_delta_time);
      g_table_time_waited(gc_num_rows)(y) := round ((g_latest_time_waited(y) - g_previous_time_waited(y))/ v_delta_time); -- ms/sec
    end loop;
  end compute_new_state;

  ---------------------------------------------------------------------------
  -- Save state in sqlplus variables
  ---------------------------------------------------------------------------
  procedure save_state is
    v_dump_wait_count         clob :='';
    v_dump_time_waited        clob :='';
    v_dump_latest_wait_count  varchar2(1000) :='';
    v_dump_latest_time_waited varchar2(1000) :='';
  begin
    for x in 1..gc_num_rows loop
      for y in 0..gc_num_bins loop
        v_dump_wait_count  := v_dump_wait_count||to_char(g_table_wait_count(x)(y))||',';
        v_dump_time_waited := v_dump_time_waited||to_char(g_table_time_waited(x)(y))||',';
      end loop;
    end loop;

    for y in 0..gc_num_bins loop
      v_dump_latest_wait_count  := v_dump_latest_wait_count  ||to_char(g_latest_wait_count(y))||',';
      v_dump_latest_time_waited := v_dump_latest_time_waited ||to_char(g_latest_time_waited(y))||','; -- ms
    end loop;

    :var_dump_wait_count        := v_dump_wait_count;
    :var_dump_time_waited       := v_dump_time_waited;
    :var_dump_latest_wait_count := v_dump_latest_wait_count;
    :var_dump_latest_time_waited:= v_dump_latest_time_waited;
    :var_dump_latest_time_sec   := g_latest_time_sec;
    :var_number_iterations      := :var_number_iterations + 1;
  end save_state;

  ---------------------------------------------------------------------------
  -- Load state from sqlplus variables
  ---------------------------------------------------------------------------
  procedure load_state is
    v_dumpstring clob;
    v_pos1 pls_integer;
    v_pos2 pls_integer;
  begin
    if (:var_number_iterations = 0) then
      for x in 0..gc_num_rows loop
        for y in 0..gc_num_bins loop
          g_table_wait_count(x)(y)  := 0;
          g_table_time_waited(x)(y) := 0;
        end loop;
      end loop;
      return;
    end if;

    -- wait count table
    v_dumpstring  := :var_dump_wait_count;
    v_pos1 := 1;
    for x in 0..gc_num_rows-1 loop
      for y in 0..gc_num_bins loop
        v_pos2 := instr(v_dumpstring,',',v_pos1,1);
        g_table_wait_count(x)(y) := to_number(substr(v_dumpstring,v_pos1,v_pos2-v_pos1));
        v_pos1 := v_pos2+1;
      end loop;
    end loop;

    -- time waited table (ms/sec)
    v_dumpstring  := :var_dump_time_waited;
    v_pos1 := 1;
    for x in 0..gc_num_rows-1 loop
      for y in 0..gc_num_bins loop
        v_pos2 := instr(v_dumpstring,',',v_pos1,1);
        g_table_time_waited(x)(y) := to_number(substr(v_dumpstring,v_pos1,v_pos2-v_pos1));
        v_pos1 := v_pos2+1;
      end loop;
    end loop;

    -- previous latest arrays
    v_dumpstring  := :var_dump_latest_wait_count;
    v_pos1 := 1;
    for y in 0..gc_num_bins loop
      v_pos2 := instr(v_dumpstring,',',v_pos1,1);
      g_previous_wait_count(y) := to_number(substr(v_dumpstring,v_pos1,v_pos2-v_pos1));
      v_pos1 := v_pos2+1;
    end loop;

    v_dumpstring  := :var_dump_latest_time_waited;
    v_pos1 := 1;
    for y in 0..gc_num_bins loop
      v_pos2 := instr(v_dumpstring,',',v_pos1,1);
      g_previous_time_waited(y) := to_number(substr(v_dumpstring,v_pos1,v_pos2-v_pos1)); -- ms
      v_pos1 := v_pos2+1;
    end loop;

    g_previous_time_sec := :var_dump_latest_time_sec;
  end load_state;

  ---------------------------------------------------------------------------
  -- Screen helpers
  ---------------------------------------------------------------------------
  procedure print_to_screen (p_string varchar2) is
  begin
     g_screen := g_screen || p_string || chr(10);
  end;

  procedure print_header is
     v_line  varchar2(1000);
  begin
     g_screen :='';
     v_line := chr(27)||'[0m'||chr(27)||'[2J'||chr(27)||'[H';     -- clear and home
     v_line := v_line||'OraLatencyMap v1.3 - https://github.com/LucaCanali/OraLatencyMap';
     print_to_screen(v_line);
     print_to_screen('');

     v_line := 'Heatmap representation of &wait_event wait event latency from gv$event_histogram_micro';
     v_line := chr(27)||'[1m'||lpad(' ',(gc_num_rows+11-length(v_line))/2,' ')||v_line||chr(27)||'[0m';
     print_to_screen(v_line);
  end;

  ---------------------------------------------------------------------------
  -- Heatmap printer (Y labels via bucket_label)
  ---------------------------------------------------------------------------
  procedure print_heat_map(
      p_table t_integertable,
      p_rows  pls_integer,
      p_cols  pls_integer,
      p_palette_type varchar2,
      p_graph_header varchar2,
      p_graph_unit   varchar2,
      p_color_desc   varchar2,
      p_total_sum OUT NOCOPY pls_integer,
      p_latestcol_sum OUT NOCOPY pls_integer)
  is
     type t_scanline is table of varchar2(4000) index by pls_integer;
     v_graph_lines t_scanline;
     v_line varchar2(4000);
     v_color   pls_integer;
     v_max_val pls_integer;
     v_col_sum pls_integer;
     v_max_col_sum pls_integer;

    function asciiescape_backtonormal return varchar2 is
    begin return chr(27)||'[0m'; end;

    function asciiescape_color (p_token pls_integer, p_palette_type varchar2) return varchar2 is
      type t_palette is varray(7) of pls_integer;
      v_palette_blue t_palette := t_palette(15,51,45,39,33,27,21);      -- white -> dark blue
      v_palette_red  t_palette := t_palette(15,226,220,214,208,202,196);-- white -> red
      v_colornum pls_integer;
    begin
      if p_token < 0 or p_token > 6 then
        raise_application_error(-20001,'Palette has 7 colors, 0..6, got:'||to_char(p_token));
      end if;
      v_colornum := case p_palette_type when 'blue' then v_palette_blue(p_token+1)
                                        else v_palette_red(p_token+1) end;
      return chr(27)||'[48;5;'||to_char(v_colornum)||'m';
    end;
  begin
     -- maxima and sums
     v_max_val := 0; v_max_col_sum := 0; p_total_sum := 0;
     for x in 0..p_rows loop
       v_col_sum := 0;
       for y in 0..p_cols loop
         if (p_table(x)(y)) > v_max_val then v_max_val := p_table(x)(y); end if;
         v_col_sum     := v_col_sum + p_table(x)(y);
         p_total_sum   := p_total_sum + p_table(x)(y);
       end loop;
       if v_col_sum > v_max_col_sum then v_max_col_sum := v_col_sum; end if;
     end loop;
     p_latestcol_sum := v_col_sum;

     -- raster lines
     for y in 0..p_cols loop
       v_graph_lines(y):='';
       for x in 0..p_rows loop
         if (p_table(x)(y) <= 0) then
           v_color := 0;
         elsif (p_table(x)(y) >= v_max_val) then
           v_color := 6;
         else
           v_color := ceil((p_table(x)(y)*6)/v_max_val);
         end if;
         v_graph_lines(y) := v_graph_lines(y) || asciiescape_color(v_color, p_palette_type) || ' ';
       end loop;
       v_graph_lines(y) := v_graph_lines(y) || asciiescape_backtonormal();
     end loop;

     -- header
     print_to_screen('');
     v_line := 'Latency bucket';
     v_line := v_line||lpad(' ',(p_rows-length(p_graph_header)-6)/2,' ')||p_graph_header;
     v_line := v_line||lpad(' ',(p_rows-length(v_line)),' ')||'Latest values';
     v_line := v_line||'    Legend';
     print_to_screen(v_line);
     v_line := asciiescape_backtonormal()||'(millisec)';  -- keep ms unit on Y axis
     v_line := v_line||lpad(' ',p_rows-1-length(p_graph_unit),' ')||p_graph_unit;
     print_to_screen(v_line);

     -- body
     for y in 0..p_cols loop
       v_line := asciiescape_backtonormal();
       if (y = 0) then
         -- catch-all “greater than last explicit threshold”
         v_line := v_line||'>'||lpad(bucket_label(p_cols-1),4,' ');
       else
         v_line := v_line||lpad(bucket_label(p_cols-y),5,' ');
       end if;
       v_line := v_line||' '||v_graph_lines(p_cols-y)|| lpad(to_char(p_table(p_rows)(p_cols-y)),6,'.');

       if (y <= 6) then
         v_line:=v_line||asciiescape_backtonormal()||' '||asciiescape_backtonormal()||' ';
         v_line:=v_line||asciiescape_backtonormal()||' '||asciiescape_backtonormal()||' ';
         v_line:=v_line||asciiescape_color(y, p_palette_type) || ' ';
         v_line:=v_line||asciiescape_backtonormal()||' ';
         if (y = 0) then
           v_line:=v_line||to_char(ceil(v_max_val*y/6));
         else
           v_line:=v_line||'>'||to_char(ceil(v_max_val*(y-1)/6));
         end if;
       end if;

       if (y = 7) then
         v_line:=v_line||asciiescape_backtonormal()||' '||asciiescape_backtonormal()||' ';
         v_line:=v_line||asciiescape_backtonormal()||' '||asciiescape_backtonormal()||' ';
         v_line:=v_line||'Max: '||to_char(v_max_val);
       end if;

       if (y = p_cols) then
         v_line:=v_line||asciiescape_backtonormal()||' '||asciiescape_backtonormal()||' ';
         v_line:=v_line||asciiescape_backtonormal()||' '||asciiescape_backtonormal()||' ';
         v_line:=v_line||'Max(Sum):';
       end if;

       print_to_screen(v_line);
     end loop;

     -- footer line under graph
     v_line := '      x=time, y=latency bucket (ms), '||p_color_desc;
     v_line := v_line||lpad(' ',p_rows-length(v_line)+2,' ')||'Sum:'||lpad(to_char(v_col_sum),7,'.');
     v_line := v_line||'    '||to_char(v_max_col_sum);
     print_to_screen(v_line);
  end print_heat_map;

  ---------------------------------------------------------------------------
  -- Footer
  ---------------------------------------------------------------------------
  procedure print_footer is
    v_line varchar2(1000);
    v_iops pls_integer;
  begin
    print_to_screen('');
    if (g_total_iops > 0) then
      v_iops := round(g_total_wait/g_total_iops,0);   -- ms average
    else
      v_iops := 0;
    end if;
    v_line := 'Average latency: '||to_char(v_iops)||' millisec. ';
    if (g_latest_iops > 0) then
      v_iops := round(g_latest_wait/g_latest_iops,0);
    else
      v_iops := 0;
    end if;
    v_line := v_line||'Latest value of average latency: '||to_char(v_iops)||' millisec.';
    print_to_screen(v_line);
    v_line := 'Sample num: '||to_char(:var_number_iterations)||', latest sampling interval: '||to_char(g_delta_time)||' sec.';
    v_line := v_line ||' Date: '|| to_char(sysdate, 'DD-MON-YYYY hh24:mi:ss');
    print_to_screen(v_line);
    v_line := 'Wait event: &wait_event';
    if ('&wait_event' = 'db file sequential read') then
      v_line := v_line || ' (e.g. analyze random read latency).';
    elsif ('&wait_event' = 'log file sync') then
      v_line := v_line || ' (e.g. analyze commit response time).';
    end if;
    print_to_screen(v_line);
  end print_footer;

begin
  -- load previous state
  load_state;

  -- collect from gv$event_histogram_micro
  collect_latest_data_points;

  -- append computed deltas
  compute_new_state;

  -- save state
  save_state;

  -- header
  print_header;

  -- frequency heatmap (events/sec)
  print_heat_map (g_table_wait_count,gc_num_rows,gc_num_bins,'blue',
                  'Frequency Heatmap: events per sec','(N#/sec)',
                  'color=wait frequency (IOPS)', g_total_iops, g_latest_iops);

  -- intensity heatmap (ms/sec)
  print_heat_map (g_table_time_waited,gc_num_rows,gc_num_bins,'red',
                  'Intensity Heatmap: time waited per sec','(millisec/sec)',
                  'color=time waited', g_total_wait, g_latest_wait);

  -- footer
  print_footer;

  -- emit
  :var_screen := g_screen;
end;
/
print var_screen
