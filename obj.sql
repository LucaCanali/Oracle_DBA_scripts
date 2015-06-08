-- object details from data_object_id
-- Luca Feb 2011

-- note for advanced troubleshooting
-- RBS segments use obj_id = 4294950912 + SEG_ID (as seen in dba_rollback_segs)
-- fixed objects had object ID in SYS.X$KQFTA (which are also numbers above 4294950912 )


col owner for a10
col object_name for a20
col subobject_name for a20
col object_type for a10

select owner,object_name,SUBOBJECT_NAME,object_type,object_id,data_object_id,created,last_ddl_time from dba_objects where data_object_id=&1 or object_id=&1;

