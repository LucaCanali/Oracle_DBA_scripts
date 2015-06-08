-- Session longops
-- By L. Canali
-- Oct 04, updated for 11g Mar 2012

col remaining for 999999
col elapsed for 999999
col hash for 9999999999
col inst_sid_ser for a13
col username for a20
col message for a80
col exec_plan for a25


select inst_id||'_'||sid||' '||serial# inst_sid_ser,username,time_remaining remaining,elapsed_seconds elapsed, sql_id, 
       sql_plan_operation||'-'||sql_plan_options||', '||sql_plan_line_id exec_plan,
       message
from gv$session_longops
where time_remaining>0;
