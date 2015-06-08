-- print aggregations from ash for 11.2 
-- Luca March 2012
--
-- usage @ash_top <n#_sec>
--

set verify off

break on sql_id

with b as (
 select count(distinct sample_id) samples, max(sample_time)-min(sample_time) deltaT_interval,
        extract( hour from (max(sample_time)-min(sample_time)) )*60*60+extract( minute from (max(sample_time)-min(sample_time)) )*60+extract( second from (max(sample_time)-min(sample_time)) ) DeltaT
 from v$active_session_history
 where sample_time>systimestamp-numtodsinterval(&1,'second')
 )
select sql_id,decode(session_state,'WAITING',event,'CPU') event,
       round(100*sum(TM_DELTA_DB_TIME/TM_DELTA_TIME)/b.samples) "DB_TIME%",
       round(100*sum(TM_DELTA_CPU_TIME/TM_DELTA_TIME)/b.samples) "CPU_TIME%",
       round(sum(DELTA_READ_IO_REQUESTS)/b.deltaT) R_IOPs,
       round(sum(DELTA_READ_IO_BYTES)/b.deltaT/1000000,1) R_MBPs,
       round(sum(DELTA_WRITE_IO_REQUESTS)/b.deltaT) W_IOPs,
       round(sum(DELTA_WRITE_IO_BYTES)/b.deltaT/1000000,1) W_MBPs,
       round(max(PGA_ALLOCATED)/1000000,1) PGA_MB, round(max(TEMP_SPACE_ALLOCATED)/1000000,1) TEMP_MB
from v$active_session_history,b
where sample_time>systimestamp-numtodsinterval(&1,'second')
group by sql_id,event,b.samples,b.deltaT,session_state
--having round(100*sum(TM_DELTA_DB_TIME/TM_DELTA_TIME)/b.samples) >=1
order by 1,2,3 desc nulls last;

clear breaks
break on username

with b as (
 select count(distinct sample_id) samples, max(sample_time)-min(sample_time) deltaT_interval,
        extract( hour from (max(sample_time)-min(sample_time)) )*60*60+extract( minute from (max(sample_time)-min(sample_time)) )*60+extract( second from (max(sample_time)-min(sample_time)) ) DeltaT
 from v$active_session_history
 where sample_time>systimestamp-numtodsinterval(&1,'second')
 )
select (select us.name from sys.user$ us where us.user#=user_id)||case when regexp_substr(program,' \(...') <> ' (TNS' then regexp_substr(program,' \(.+') end username,
       sql_id,
       round(100*sum(TM_DELTA_DB_TIME/TM_DELTA_TIME)/b.samples) "DB_TIME%",
       round(100*sum(TM_DELTA_CPU_TIME/TM_DELTA_TIME)/b.samples) "CPU_TIME%",
       round(sum(DELTA_READ_IO_REQUESTS)/b.deltaT) R_IOPs,
       round(sum(DELTA_READ_IO_BYTES)/b.deltaT/1000000,1) R_MBPs,
       round(sum(DELTA_WRITE_IO_REQUESTS)/b.deltaT) W_IOPs,
       round(sum(DELTA_WRITE_IO_BYTES)/b.deltaT/1000000,1) W_MBPs,
       round(max(PGA_ALLOCATED)/1000000,1) PGA_MB, round(max(TEMP_SPACE_ALLOCATED)/1000000,1) TEMP_MB
from v$active_session_history,b
where sample_time>systimestamp-numtodsinterval(&1,'second')
group by user_id,program,sql_id,b.samples,b.deltaT
having round(100*sum(TM_DELTA_DB_TIME/TM_DELTA_TIME)/b.samples) >=2
order by 3 desc nulls last;

clear breaks
break on session_id

with b as (
 select count(distinct sample_id) samples, max(sample_time)-min(sample_time) deltaT_interval,
        extract( hour from (max(sample_time)-min(sample_time)) )*60*60+extract( minute from (max(sample_time)-min(sample_time)) )*60+extract( second from (max(sample_time)-min(sample_time)) ) DeltaT
 from v$active_session_history
 where sample_time>systimestamp-numtodsinterval(&1,'second')
 )
select session_id,
       sql_id,
       round(100*sum(TM_DELTA_DB_TIME/TM_DELTA_TIME)/b.samples) "DB_TIME%",
       round(100*sum(TM_DELTA_CPU_TIME/TM_DELTA_TIME)/b.samples) "CPU_TIME%",
       round(sum(DELTA_READ_IO_REQUESTS)/b.deltaT) R_IOPs,
       round(sum(DELTA_READ_IO_BYTES)/b.deltaT/1000000,1) R_MBPs,
       round(sum(DELTA_WRITE_IO_REQUESTS)/b.deltaT) W_IOPs,
       round(sum(DELTA_WRITE_IO_BYTES)/b.deltaT/1000000,1) W_MBPs,
       round(max(PGA_ALLOCATED)/1000000,1) PGA_MB, round(max(TEMP_SPACE_ALLOCATED)/1000000,1) TEMP_MB
from v$active_session_history,b
where sample_time>systimestamp-numtodsinterval(&1,'second')
group by session_id,sql_id,b.samples,b.deltaT
having round(100*sum(TM_DELTA_DB_TIME/TM_DELTA_TIME)/b.samples) >=2
order by 3 desc nulls last;

clear breaks