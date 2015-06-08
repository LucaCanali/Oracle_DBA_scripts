-- generates and prints AWR report for current instance
-- Luca Apr 2012
-- Usage: @awr_report snap_begin snap_end
-- use @awr_snapshots or select max(snap_id) from DBA_HIST_SNAPSHOT ; to find latest snapshot

set pages 0
set lines 1500
set verify off
set heading off
set termout off

host del reports\scratch_awr.html
spool reports\scratch_awr.html
select * from table(DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML((select dbid from v$database),(select instance_number from v$instance),&1,&2));
spool off
set heading on
set termout on
set pages 1000

host reports\scratch_awr.html

