-- locks.sql locks and enqueue blocks for 11g
-- Luca Jan 2012


set feedback off
col oracle_username for a15
col owner for a15
col object_name for a15
col inst_sid_s# for a13
col username for a14
col obj_lck for a18
col blk_info for a14
col f_blk_info for a14
col event for a30
col s_wt for 9999
col chain_signature for a65
col Wsecs for 999

/*

prompt DML locks from current instance (dba_dml_locks)

select session_id sid, owner,name,mode_held,mode_requested from dba_dml_locks;

prompt
prompt sessions with lockwait from gv$session

select inst_id||' '||sid||','||serial# inst_sid_s#, username, row_wait_obj#||','||row_wait_block#||','||row_wait_row# obj_lck, 
       blocking_session_Status||' '||blocking_instance||','||blocking_session blk_info,        
       final_blocking_session_Status||' '||final_blocking_instance||','||final_blocking_session f_blk_info, 
       event, seconds_in_wait s_wt
from gv$session 
where lockwait is not null
order by inst_id;

prompt
prompt waitchains (all events)

select instance||' '||sid||','||sess_serial# inst_sid_s#, chain_signature,num_waiters wrs#,in_wait_secs Wsecs,row_wait_obj#||','||row_wait_block# obj_lck,
       blocker_is_valid||' '||blocker_instance||','||blocker_sid blk_info
from v$wait_chains
where in_wait='TRUE' and blocker_is_valid='TRUE'
order by instance,chain_signature;

*/

prompt
prompt final blockers from gv$session_blockers


select * from GV$SESSION_BLOCKERS;


prompt
prompt final blockers from gv$session (all events)

select final_blocking_instance f_blk_inst, final_blocking_session f_blk_sess, event, sql_id, row_wait_obj#||','||row_wait_block# obj_lck, count(*) num_blocked, round(max(wait_time_micro)/1000000,2) max_wait_sec
from gv$session 
where final_blocking_session_Status='VALID'
group by final_blocking_instance, final_blocking_session, event, sql_id, row_wait_obj#||','||row_wait_block#
order by 1;


/*

prompt global blocked locks

select * from  GV$GLOBAL_BLOCKED_LOCKS    ;

prompt TX locks

select * from gv$transaction_enqueue;

prompt waiting sessions

select inst_id,sid,process,username,row_wait_obj#,LOCKWAIT,blocking_instance blk_inst, blocking_session blk_sid
from gv$session 
where lockwait is not null;

prompt blocking sessions

select sid,username,row_wait_obj#,row_wait_block#,row_wait_row#,blocking_session  from gv$session a where row_wait_obj#<>0 and blocking_Session is not null order by 2,1;

prompt blockers from gv$Lock

select inst_id,sid,type,ctime LOCK_TIME,id1,id2
from gv$lock
where block =1;


*/

set feedback on
