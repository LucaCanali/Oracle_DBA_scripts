-- Title: event histogram metric micro, an Oracle monitoring script RAC version (data source are gv$ views).
-- Requires 12.1.0.2 or higher (use ehm.sql if on previous versions).
-- This script collects and displays latency histograms for Oracle wait events
-- It works by computing deltas between two snapshots of gv$event_histogram_micro and gv$system_event 
-- Privileges needed: execute on sys.DBMS_LOCK and select on gv$event_histogram_micro and gv$system_event 
--
-- Author: Luca.Canali@cern.ch
-- Version 1.1, June 2015
-- Based on ehm.sql version 1.0, April 2012
--
-- Usage: @ehm_micro <delta time> <event>
-- Tips: for random I/O studies measure "db file sequential read". For commit time latency: "log file sync"
-- Examples:
--    @ehm_micro 10 "db file sequential read"
--    @ehm_micro 10 "log file sync"
--

set serverout on
set verify off

-- set parameters default when not provided, this sqlplus trick technique is described in orafaq
COLUMN p1 NEW_VALUE 1
COLUMN p2 NEW_VALUE 2
set termout off	
SELECT null p1, null p2 FROM dual WHERE 1=2;
-- NOTE: the default values for <delay> and <event> parameters are hard coded here
SELECT nvl('&1','5') p1, nvl('&2','db file sequential read') p2 from dual;  
set termout on

prompt
prompt Latency histograms for Oracle wait events, RAC 12c version.
prompt Usage: @ehm_micro <delta time> <event>
prompt Please wait for &1 sec (DeltaT = &1 sec) for snapshot N.2 and script output.

DECLARE
  v_sleep_time                 number;
  v_event_name                 varchar2(50) := '&2';
  v_delta_waits                number;
  v_delta_waits_per_sec        number;
  v_delta_time_waited_estimate number;
  v_delta_time_waited_micro    number; 
  v_avg_wait_time_micro        number;
  v_latencybin                 varchar2(100);

  CURSOR c1 IS
    SELECT event, wait_time_micro, sum(wait_count) wait_count, max(last_update_time) last_update_time
    FROM gv$event_histogram_micro
    WHERE event = v_event_name
	GROUP BY event, wait_time_micro
	ORDER BY event, wait_time_micro;
	
  CURSOR c2 IS
    SELECT event, sum(time_waited_micro) time_waited_micro, sum(total_waits) total_waits
    FROM gv$system_event
    WHERE event = v_event_name
	GROUP BY event
	ORDER BY event;


  TYPE EventHisto IS TABLE OF c1%ROWTYPE;
  TYPE SysEvent   IS TABLE OF c2%ROWTYPE;

  t0_histval  EventHisto;  -- nested table of records for t0 snapshot
  t1_histval  EventHisto;  -- nested table of records for t1 snapshot
  t0_eventval SysEvent;    -- nested table of records for t0 snapshot
  t1_eventval SysEvent;    -- nested table of records for t1 snapshot

BEGIN
  -- input validation
  BEGIN
     v_sleep_time := TO_NUMBER('&1');
	 IF (v_sleep_time <= 0) THEN
        raise value_error;
	 END IF;
  EXCEPTION	 
       WHEN value_error THEN
	     RAISE_APPLICATION_ERROR(-20001,'Wait time must be numeric and >0. Example use wait time = 10');
  END;

  -- collect t0 data
  OPEN c1;
  OPEN c2;
  FETCH c1 BULK COLLECT INTO t0_histval;
  FETCH c2 BULK COLLECT INTO t0_eventval; 
  CLOSE c1;
  CLOSE c2;

  IF t0_eventval.COUNT <=0 THEN
      RAISE_APPLICATION_ERROR(-20001,'Not enough data. Probably wrong event name. Tip, try event = "db file sequential read".');
  END IF;

  IF t0_eventval.COUNT >= 100 THEN
    RAISE_APPLICATION_ERROR(-20002,'Too many values, soft limit set to 100');
  END IF;

  -- put wait time here note user needs exec privilege on dbms_lock  
  sys.DBMS_LOCK.SLEEP (v_sleep_time);

  -- collect t1 data
  OPEN c1;
  OPEN c2;
  FETCH c1 BULK COLLECT INTO t1_histval;
  FETCH c2 BULK COLLECT INTO t1_eventval; 
  CLOSE c1;
  CLOSE c2;

  -- check and report error if number of points is different between the two snapshots
  -- (rare, but can happen if a new histogram bin has been created)
  IF t0_histval.COUNT <> t1_histval.COUNT THEN
     RAISE_APPLICATION_ERROR(-20003,'Number of histogram bins changed during collection. Cannot handle it.');
  END IF;

  -- print out results
  -- compute delta values and print. 
  -- format with rpad to keep column width constant

  -- Latency histogram from gv$event_histogram_micro
  DBMS_OUTPUT.PUT_LINE(chr(13));
  DBMS_OUTPUT.PUT_LINE('Latency histogram for event "&2" from GV$EVENT_HISTOGRAM_MICRO:');
  DBMS_OUTPUT.PUT_LINE(chr(13));
  DBMS_OUTPUT.PUT_LINE ('Latency Bucket       Num Waits/DeltaT  Wait Time/DeltaT    Event Name                 Last Update Time');
  DBMS_OUTPUT.PUT_LINE ('(microsec)           (Hz)              (microsec/sec)                                                 ');
  DBMS_OUTPUT.PUT_LINE ('-------------------  ----------------  ------------------  -------------------------  -----------------------------------');

  FOR i IN t1_histval.FIRST .. t1_histval.LAST LOOP
    v_delta_waits := t1_histval(i).wait_count - t0_histval(i).wait_count;
    v_delta_waits_per_sec := round(v_delta_waits / v_sleep_time,1);
	v_delta_time_waited_estimate := round(0.75 * t1_histval(i).wait_time_micro * v_delta_waits_per_sec,1);  -- estimated value
	IF (t1_histval(i).wait_time_micro <> 1) THEN
		v_latencybin := to_char(t1_histval(i).wait_time_micro/2) ||' -> ' || to_char(t1_histval(i).wait_time_micro);
    ELSE
		v_latencybin := '0 -> 1';
	END IF;
    DBMS_OUTPUT.PUT_LINE (
        rpad(v_latencybin,19,' ')||'  '||
        lpad(to_char(v_delta_waits_per_sec),16,' ')||'  '||
        lpad(to_char(v_delta_time_waited_estimate),18,' ')||'   '||
        rpad(t1_histval(i).event,24,' ') ||' '||
        t1_histval(i).last_update_time 
      );
    END LOOP;

  -- This is the summary from gv$system_event
  DBMS_OUTPUT.PUT_LINE(chr(13));
  DBMS_OUTPUT.PUT_LINE('Average values from GV$SYSTEM_EVENT:');
  DBMS_OUTPUT.PUT_LINE(chr(13));
  DBMS_OUTPUT.PUT_LINE ('Mean Wait Time       Num Waits/DeltaT  Wait Time/DeltaT    Event Name               ');
  DBMS_OUTPUT.PUT_LINE ('(microsec)           (Hz)              (microsec/sec)                               ');
  DBMS_OUTPUT.PUT_LINE ('-------------------  ----------------  ------------------  -------------------------');

  FOR i IN t1_eventval.FIRST .. t1_eventval.LAST LOOP
    v_delta_time_waited_micro :=  t1_eventval(i).time_waited_micro - t0_eventval(i).time_waited_micro;
    v_delta_waits := t1_eventval(i).total_waits - t0_eventval(i).total_waits;
    v_delta_waits_per_sec := round(v_delta_waits / v_sleep_time, 1);
   IF v_delta_waits <> 0 then
       v_avg_wait_time_micro := round(v_delta_time_waited_micro/v_delta_waits,1);
    ELSE
       v_avg_wait_time_micro := 0;
    END IF;
    DBMS_OUTPUT.PUT_LINE(
        rpad(to_char(v_avg_wait_time_micro),19,' ')||'  '||
        lpad(to_char(v_delta_waits_per_sec),16,' ')||'  '||
        lpad(to_char(round(v_delta_time_waited_micro/v_sleep_time,1)),18,' ')||'  '||
        rpad(t1_histval(i).event,24,' ')
      );
  END LOOP;
  DBMS_OUTPUT.PUT_LINE(chr(13));
  
END;
/
