-- Top.sql: prints details of active sessions 
-- Usage: @top, run a few times on to see dynamics of active sessions
-- Luca Canali 2002, last updated and customized for 10g Feb 2011

col username for a21
col service for a19
col "User@Term" for a10
col program for a22
col inst_sid_serial# for a12
col seq for a5
col module for a15
col tr for a2
col event for a25
col sql_id for a13
col elaps for 9999999
col w_tim for 9999
col state for a7
set linesize 150
set pagesize 1000
col "Event details" for a37
col obj# for 99999999
col module for a16

set lines 180

select 	inst_id||'_'||sid||' '||serial# inst_sid_serial#,nvl(username,'PRG: '||program) username, service_name service, substr(module,0,15) module, decode(taddr,null,null,'NN') tr,
	sql_id, decode(state,'WAITING',null,state||':')||event event, row_wait_obj# obj#,
        p1text||'='||p1||'; '||p2text||'='||p2||'; '||p3text||'='||p3 "Event details",
	case state when 'WAITING' then seconds_in_wait else wait_time end w_tim, last_call_et elaps
from gv$session
where status='ACTIVE'
      and not (username is null and wait_class='Idle')
      and not (username in ('SYS','DBSNMP') and wait_class='Idle')
      and audsid !=sys_context('USERENV','SESSIONID')
order by inst_id
/