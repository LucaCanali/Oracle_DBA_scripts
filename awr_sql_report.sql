-- generates and prints awr sql report for current instance
-- Luca Apr 2012
-- Usage: @awr_sql_report snap_begin snap_end sql_id
-- example: @awr_sql_report 3843 3844 "'9dhn1b8d88dpf'"

set pages 0
set lines 1500
set verify off
set heading off
set termout off

host del reports\scratch_sql_awr.html
spool reports\scratch_sql_awr.html
select * from table(DBMS_WORKLOAD_REPOSITORY.AWR_SQL_REPORT_HTML((select dbid from v$database),(select instance_number from v$instance),&1,&2,&3));
spool off
set heading on
set termout on
set pages 1000

host reports\scratch_sql_awr.html

