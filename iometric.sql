-- iometric values in 11g
-- Luca Jan 2012

select min(begin_time) b_time, min(end_time) e_time, function_name,
       round(sum(small_read_iops+large_read_iops)) read_TOT_iops, round(sum(small_write_iops+large_write_iops)) write_TOT_iops, round(sum(large_read_mbps+small_read_mbps)) read_TOT_mbps, round(sum(large_write_mbps+small_write_mbps)) write_TOT_mbps
       from GV$IOFUNCMETRIC
       group by rollup(function_name)
       having round(sum(small_read_iops+large_read_iops)) + round(sum(large_read_mbps+small_read_mbps)) + round(sum(small_write_iops+large_write_iops)) + round(sum(large_write_mbps+small_write_mbps))  >0
       order by function_name;
