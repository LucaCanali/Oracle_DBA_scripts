/* 
   filematric.sql - displays files with significant IO activity
   Luca Feb-2008
*/

col name for a60
col sec for 999
col file# for 99999

select sum(physical_block_writes) Phys_BLK_W, sum(physical_block_reads) Phys_BLK_R, round(avg(average_read_time)*10,1) AVG_read_ms,
       file_id file#, (select tablespace_name from dba_data_files ddf where ddf.file_id=fh.file_id) TBS_Name, 
       to_char(max(begin_time),'hh24:mi') time, round(max(intsize_csec)/100,0) sec
from gv$filemetric_history fh
where begin_time >sysdate-1/24/3
group by inst_id,file_id
having sum(physical_block_writes) + sum(physical_block_writes) > 100
order by 1 desc;
