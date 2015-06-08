-- lists transactions open and in crash recovery
-- Luca Feb2011

select inst_id,addr,start_time,used_ublk,xid from gv$transaction;

select inst_id,state,undoblocksdone,undoblockstotal,xid from gv$fast_start_transactions;

SELECT sess.sid, sess.status, sess.username, machine, sql_id, prev_sql_id, trans.USED_UBLK, trans.start_date
from gv$session sess, gv$transaction trans
WHERE sess.taddr=trans.addr and sess.inst_id=trans.inst_id;
