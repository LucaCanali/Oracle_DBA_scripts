-- generates and prints AWR global report
-- Luca Apr 2012
-- Usage: @awr_global_report snap_begin snap_end

set pages 0
set lines 1500
set verify off
set heading off
set termout off

host del reports\scratch_awr_global.html
spool reports\scratch_awr_global.html
select * from table(DBMS_WORKLOAD_REPOSITORY.AWR_GLOBAL_REPORT_HTML((select dbid from v$database),'',&1,&2));
spool off
set heading on
set termout on
set pages 1000

host reports\scratch_awr_global.html

