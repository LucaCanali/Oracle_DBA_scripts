-- ======================================================================
-- OraLatencyMap_advanced.sql
-- A tool to visualize Oracle wait-event latency as terminal heat maps
--
-- Author   : Luca.Canali@cern.ch
-- https://github.com/LucaCanali/OraLatencyMap
-- Version  : v1.3  (September 2025)
-- Purpose  : Sample latency micro-histograms for a chosen wait event and
--            render two live heat maps in SQL*Plus using ANSI escapes.
--
-- ──────────────────────────────────────────────────────────────────────
-- USAGE (run from SQL*Plus)
--   @OraLatencyMap_advanced <refresh_sec> "<event_name>" <num_bins> <num_cols> "<extra_where>"
--
-- PARAMETERS
--   <refresh_sec>   : Sampling period (in seconds) between consecutive frames.
--   "<event_name>"  : Exact wait event name (case-insensitive). Examples:
--                     "db file sequential read", "log file sync", etc.
--   <num_bins>      : Number of latency buckets (heat map rows).
--   <num_cols>      : Number of time slices retained on screen (heat map columns).
--   "<extra_where>" : Optional SQL predicate appended to the GV$* filters,
--                     e.g. "and inst_id=1" or "and inst_id in (1,2)" in RAC.
--
-- EXAMPLES
--   @OraLatencyMap_advanced 5 "db file sequential read" 11 90 "and inst_id=1"
--   @OraLatencyMap_advanced 5 "log file sync"           13 110 "and inst_id in (1,2)"
--
-- WHAT YOU’LL SEE
--   • Two synchronized heat maps for the target event:
--       1) Frequency map  → waits per second per latency bucket
--       2) Intensity map  → estimated time waited per second per bucket
--   • Y-axis = latency buckets (micro-histogram bins)
--   • X-axis = time (scrolling right-to-left)
--
-- DATA SOURCE / ASSUMPTIONS
--   • Reads latency distributions from GV$EVENT_HISTOGRAM_MICRO (non-idle).
--   • Requires privileges to read GV$ views (or V$ in single instance).
--   • This “advanced” driver orchestrates the loop and terminal output; the
--     sampling + rendering logic lives in:  @@OraLatencyMap_internal_loop
--
-- TERMINAL REQUIREMENTS
--   • Your client must support ANSI escape codes (e.g., xterm, PuTTY, modern terminals).
--   • If colors or positioning look wrong, try a different terminal or disable “translation.”
--
-- TIPS
--   • Stop the live view with Ctrl-C.
--   • Increase <num_bins> for finer latency detail; increase <num_cols> for a wider time window.
--   • Use "<extra_where>" to focus on specific INST_IDs in RAC or to test subsets.
--
-- ======================================================================

-- SQL*Plus environment (non-invasive and friendly defaults)
set lines 2000
set pages 100
set feedback off
set verify off
set heading off
set tab off
set long 100000
set longchunksize 100000

-- Working variables (frame buffers for the two heat maps and the screen)
var var_dump_wait_count        clob
var var_dump_time_waited       clob
var var_screen                 clob

-- Latest frame (rightmost column) used for incremental updates
var var_dump_latest_wait_count   varchar2(1000)
var var_dump_latest_time_waited  varchar2(1000)
var var_dump_latest_time_sec     number

-- Loop control
var var_number_iterations number

begin
  :var_number_iterations      := 0;
  :var_dump_wait_count        := '';
  :var_dump_time_waited       := '';
end;
/

-- Parameters from the caller
define sleep_interval=&1
define wait_event='&2'
define num_bins=&3
define num_rows=&4
define instance_filter_clause='&5'

-- Friendly banner so users see what’s about to run
prompt
prompt ======================================================================
prompt OraLatencyMap starting up
prompt   refresh_sec : &sleep_interval
prompt   wait_event  : &wait_event
prompt   num_bins    : &num_bins       (heat map rows / latency buckets)
prompt   num_cols    : &num_rows       (heat map columns / time slices)
prompt   extra_where : &instance_filter_clause
prompt ----------------------------------------------------------------------
prompt Collecting initial datapoints… this may take a moment.
prompt NOTES: This tool requires a terminal with ANSI escape support (xterm, PuTTY).
prompt        Need privileges to read GV$EVENT_HISTOGRAM_MICRO and to execute DBMS_LOCK.SLEEP.
prompt        Stop with Ctrl-C. For help/README, see the project documentation.
prompt ======================================================================
prompt

-- The main logic (sampling + rendering) is implemented in OraLatencyMap_internal:
--  • Gathers deltas from GV$EVENT_HISTOGRAM_MICRO at each interval
--  • Converts to waits/s (frequency) and ms/s (intensity)
--  • Maintains rolling windows (num_cols) and renders both heat maps
--  • Uses ANSI escapes to draw/refresh the screen
-- A basic for of looping is done by OraLatencyMap_internal_loop

@@OraLatencyMap_internal_loop
