-- select from v$sql_monitor_plan by key
-- Luca, March 2012

-- Usage: @monitor_plan <key>

set verify off
col operation for a70
col part for a12

select status,sql_exec_start,last_refresh_time,sid,process_name,sql_id,sql_plan_hash_value,sql_child_address
from gv$sql_plan_monitor where key=&1 and rownum=1;


select lpad(' ',plan_depth)||plan_operation||' '||plan_options||nullif(' - '||plan_object_owner||'.'||plan_object_name||' ('||plan_object_type||')',' - . ()') operation,
        plan_cost p_cost,plan_cardinality p_card,output_rows outp_rows,starts,physical_read_requests R_iops, 
        round(physical_read_bytes/1000000,1) R_MB,round(physical_write_bytes/1000000,1) W_MB, 
        round(workarea_mem/1000000,1) pga_MB,round(workarea_tempseg/1000000,1) temp_mb, 
        nullif(plan_partition_start||'-'||plan_partition_stop,'-') part
from gv$sql_plan_monitor where key=&1 
order by plan_line_id;