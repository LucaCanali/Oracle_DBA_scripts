-- Session longops
-- By Luca Canali
-- Oct 04

col remaining for 999999
col elapsed for 999999
col hash for 9999999999
col sid for 9999
col username for a10
col opname for a15
col message for a45


select inst_id,sid,username,time_remaining remaining, elapsed_seconds elapsed, sql_id, opname,message
from gv$session_longops
where time_remaining>0;
