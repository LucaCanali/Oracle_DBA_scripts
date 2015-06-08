--
-- Generates and prints sql_monitor report for a given sql_id
-- Luca Jan 2014
-- Usage: @monitor_report sql_id

set long 1000000000
set longc 2000
set pages 0
set lines 1500
set verify off
set heading off
set termout off

host del reports\scratch_report_sql_monitor.html
spool reports\scratch_report_sql_monitor.html
SELECT  DBMS_SQLTUNE.REPORT_SQL_MONITOR(SQL_ID=>'&1', report_level=>'ALL', type => 'HTML') as report FROM dual;
spool off
set heading on
set termout on
set pages 1000

host reports\scratch_report_sql_monitor.html


