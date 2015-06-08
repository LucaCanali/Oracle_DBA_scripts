--
-- adg.sql - shows the status of the ADG recovery
-- 

select inst_id, max(timestamp) from gv$recovery_progress group by inst_id;
