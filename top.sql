-- Top.sql: prints details of active sessions 
-- Usage: @top, run a few times on to see dynamics of active sessions
-- Luca Canali 2002, last updated and customized for 11g, Apr 2012

set lines 180
col inst_sid_ser for a13
col username for a23
col serv_mod_action for a48
col tr for a2
col event for a32
col sql_id for a13
col sql_dT for 999999
col call_dT for 9999999
col W_dT for 9999
col obj# for 99999999


select 	inst_id||'_'||sid||' '||serial# inst_sid_ser,
	username||case when regexp_substr(program,' \(...') <> ' (TNS' then regexp_substr(program,' \(.+') end username,
	sql_id sql_id, 
	round((sysdate-sql_exec_start)*24*3600,1) sql_dT,
        last_call_et call_dT,
	case state when 'WAITING' then round(wait_time_micro/1000000,2) else round(time_since_last_wait_micro/1000000,2) end W_dT,
        decode(state,'WAITING',event,'CPU') event, 
	service_name||' '||substr(module,1,20)||' '||ACTION serv_mod_action,  
          nullif(row_wait_obj#,-1) obj#,decode(taddr,null,null,'NN') tr
from gv$session
where ((state='WAITING' and wait_class<>'Idle') or (state<>'WAITING' and status='ACTIVE'))
      --and audsid != to_number(sys_context('USERENV','SESSIONID')) -- this is clean but does not work on ADG so replaced by following line
      and (machine,port) <> (select machine,port from v$session where sid=sys_context('USERENV','SID')) --workaround for ADG
order by inst_id,sql_id
/


