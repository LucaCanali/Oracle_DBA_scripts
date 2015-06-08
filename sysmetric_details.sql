/* 
   sysmetric_details.sql - sqlplus script - displays significant system metrics detailed per RAC instance
   By Luca Nov 2007 
*/

col "Time+Delta" for a14
col "Metric" for a40
col "Total" for a10
col metric_name for a25

set linesize 140
set pagesize 1000

set wrap off 
REM truncates the metric field to max length

 select to_char(min(begin_time),'hh24:mi:ss')||' /'||round(avg(intsize_csec/100),0)||'s' "Time+Delta",
       metric_name||' - '||metric_unit "Metric", 
       sum(value_inst1) inst1, sum(value_inst2) inst2, sum(value_inst3) inst3, sum(value_inst4) inst4,
       sum(value_inst5) inst5, sum(value_inst6) inst6
 from
  ( select begin_time,intsize_csec,metric_name,metric_unit,metric_id,group_id,
       case inst_id when 1 then round(value,1) end value_inst1,
       case inst_id when 2 then round(value,1) end value_inst2,
       case inst_id when 3 then round(value,1) end value_inst3,
       case inst_id when 4 then round(value,1) end value_inst4,
       case inst_id when 5 then round(value,1) end value_inst5,
       case inst_id when 6 then round(value,1) end value_inst6
  from gv$sysmetric
  where metric_name in ('Host CPU Utilization (%)','Current OS Load', 'Physical Write Total IO Requests Per Sec',
        'Physical Write Total Bytes Per Sec', 'Physical Write IO Requests Per Sec', 'Physical Write Bytes Per Sec',
         'I/O Requests per Second', 'I/O Megabytes per Second',
        'Physical Read Total Bytes Per Sec', 'Physical Read Total IO Requests Per Sec', 'Physical Read IO Requests Per Sec',
        'CPU Usage Per Sec','Network Traffic Volume Per Sec','Logons Per Sec','Redo Generated Per Sec',
        'User Transaction Per Sec','Average Active Sessions','Average Synchronous Single-Block Read Latency',
        'Logical Reads Per Sec','DB Block Changes Per Sec')
  )
 group by metric_id,group_id,metric_name,metric_unit
 order by metric_name;

set wrap on 