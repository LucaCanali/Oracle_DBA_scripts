-- read from sql_monitor
-- Luca March 2012

-- used by monitor.sql script
-- usage @monitor_details "<filter condition>"

col key for 9999999999999
col inst_sid_ser for a13
col username for a24
col mod_action for a32
col R_MB for 9999999
col W_MB for 9999
col px for 99

select key, inst_id||'_'||sid||' '||session_serial# inst_sid_ser,
       username||case when regexp_substr(program,' \(.+') <> ' (TNS V1-V3)' then regexp_substr(program,' \(.+') end username,
       regexp_substr(module,'.+@.+cern')||' '||ACTION mod_action,
       sql_id, round(elapsed_time/1000000,1) elaps_s, round(cpu_time/1000000,1) cpu_s,
       round(user_io_wait_time/1000000,1) iowait_s,round((cluster_wait_time+application_wait_time+plsql_exec_time+java_exec_time)/1000000,1) other_s,
       physical_read_requests R_IOPS,round(physical_read_bytes/1000000,1) R_MB,round(physical_write_bytes/1000000,1) W_MB, PX_SERVERS_ALLOCATED PX
from gv$sql_monitor where &1
order by SQL_EXEC_START desc;

