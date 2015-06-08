/* 
   lock.sql locks and enqueue blocks for 10g
   By Luca Canali 2006
*/

set feedback off
col oracle_username for a15
col owner for a15
col object_name for a15
 

prompt DML locks from current instance

select session_id sid, owner,name,mode_held,mode_requested from dba_dml_locks;

prompt blockers from gv$Lock

select inst_id,sid,type,ctime LOCK_TIME,id1,id2 
from gv$lock
where block =1;


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

*/

--in 11g can use select .. from v$wait_chains 

set feedback on
