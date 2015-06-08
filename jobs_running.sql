-- Display nfo on running jobs
-- Luca Sep 2011


col elapsed_time for a20
col cpu_used for a20
col inst_sid for a7

--dbms_schedule_jobs
select running_instance||'_'||session_id inst_sid,owner,job_name,elapsed_time,cpu_used from dba_SCHEDULER_RUNNING_JOBS;


--old fashioned jobs
select * from dba_jobs_running;