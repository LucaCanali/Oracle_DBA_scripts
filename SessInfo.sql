/* 
   sessinfo.sql, find session info from v$sessino and @process
   example: @sessinfo sid=392
            @sessinfo "s.username='myuser'"
   By Luca 2012
*/

col username for a10
col "Server User@terminal" for a15
col program for a14
col terminal for a15
col inst for 999
col sid for 9999
col serial# for 99999
col seq for 9999999
col module for a15
col taddr for a8
col OS_PID for 99999
col elaps for 999999
col service_name for a14
col tracefile for a40
 

select s.inst_id,s.sid,s.serial#,s.username,s.osuser||'@'||s.terminal "Server User@terminal",s.program,s.taddr,s.sql_id, s.sql_exec_start,
       s.status,s.module, s.service_name, s.event, s.last_call_et elaps, s.logon_time, p.spid OS_PID, p.tracefile
from gv$session s, gv$process p
where p.addr=s.paddr and p.inst_id=s.inst_id
      and &1;


