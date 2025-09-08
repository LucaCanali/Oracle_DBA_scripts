/* 
   Find sessid from OS pid
   Luca 03
*/

col username for a10
col "Server User@terminal" for a20
col program for a12
col terminal for a10
col sid for 9999
col seq for 9999999
col module for a10
set linesize 150
set pagesize 1000

select 	sid,username,osuser||'@'||terminal "Server User@terminal",program,taddr, status,
	module, sql_hash_value hash, fixed_table_sequence seq, last_call_et elaps 
from v$session 
where paddr=(select addr from v$process where spid=&1);
