-- query to iofuncmetric view in 11g
-- Luca Jan 2012


select inst_id,begin_time,function_name,
       round(small_read_iops) RD_IOPS_sm, round(large_read_iops) RD_IOPS_lg, 
       round(small_read_mbps) RD_MBPS_sm, round(large_read_mbps) RD_MBPS_lg, 
       round(small_write_iops) WT_IOPS_sm, round(large_write_iops) WT_IOPS_lg, 
       round(small_write_mbps) WT_MBPS_sm, round(large_write_mbps) WT_MBPS_lg 
from GV$IOFUNCMETRIC
--where function_name in ('Buffer Cache Reads','LGWR','DBWR','Direct Reads','Direct Writes','RMAN') 
--where round(small_read_iops+large_read_iops+small_write_iops+large_write_iops) >0
order by function_name,inst_id;

select min(begin_time) b_time, min(end_time) e_time, round(sum(small_read_iops+large_read_iops)) read_TOT_iops, round(sum(large_read_mbps+small_read_mbps)) read_TOT_mbps, round(sum(small_write_iops+large_write_iops)) write_TOT_iops, round(sum(large_write_mbps+small_write_mbps)) write_TOT_mbps from GV$IOFUNCMETRIC;

