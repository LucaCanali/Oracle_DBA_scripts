-- bind values captured on DB
-- for more need to do oradebug dump errorstack 3
-- Luca Mar 2012 updated for oracle 11g


select * from gV$SQL_BIND_CAPTURE where sql_id='&1';

select BINDS_XML from gv$sql_monitor where sql_id='&1';
