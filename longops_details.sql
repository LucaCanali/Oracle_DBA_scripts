-- Session longops
-- By L. Canali
-- Oct 04

col remaining for 999999
col elapsed for 999999
col hash for 9999999999
col inst_sid_ser for a13
col username for a25
col message for a100
col exec_plan for a25


prompt longops last day with daration > 60 sec

select inst_id||'_'||sid||' '||serial# inst_sid_ser,username,start_time,elapsed_seconds elapsed, sql_id,
       message
from gv$session_longops
where time_remaining=0 
      and elapsed_seconds>60
      and start_time >sysdate-1 order by start_time desc;
