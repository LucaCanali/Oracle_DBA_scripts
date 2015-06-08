-- generates and prints ASH report for current instance
-- Luca Apr 2012
-- Usage: @awr_report begin_time end_time
-- example: @ash_report sysdate-1/24 sysdate 

-- can add more parameters: http://docs.oracle.com/cd/E11882_01/appdev.112/e25788/d_workload_repos.htm#autoId10


set pages 0
set lines 1500
set verify off
set heading off
set termout off

host del reports\scratch_ash.html
spool reports\scratch_ash.html
select * from table(DBMS_WORKLOAD_REPOSITORY.Ash_REPORT_HTML((select dbid from v$database),(select instance_number from v$instance),&1,&2));
spool off
set heading on
set termout on
set pages 1000

host reports\scratch_ash.html

