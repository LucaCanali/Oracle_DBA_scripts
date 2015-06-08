/* 
   sesmetric.sql  
   displays resource utilization per session
   By Luca Canali 2005
*/


select * from (
  select inst_id, session_id sid, to_char(begin_time,'hh24:mi:ss') begTime, round(intsize_csec/100,0) D_sec,  cpu,          
         physical_reads PhyReads, logical_reads LogicalReads, pga_memory, hard_parses, soft_parses 
  from gv$sessmetric
  order by cpu+physical_reads desc
)
where rownum<20
/
