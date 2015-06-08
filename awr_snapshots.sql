-- lists latest 24 snapshots
-- Luca Apr 2012

select * from (
 select snap_id,min(begin_interval_time), min(end_interval_time) from dba_hist_snapshot group by snap_id order by snap_id desc
) where rownum<=24;
