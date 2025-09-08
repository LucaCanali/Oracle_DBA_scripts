-- ddl.sql - extract object DDL, modified from Tanel's ddl.sql script
-- 
-- Luca, Nov 2022
--
-- Usage:       @ddl [schema.]<object_name_pattern>
--              @ddl mytable
--              @ddl system.table
--              @ddl sys%.%tab%

-- unclutter the storage options
EXEC DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);

exec dbms_metadata.set_transform_param( dbms_metadata.session_transform,'SQLTERMINATOR', TRUE);

-- use from select
-- example
-- select DBMS_METADATA.GET_DDL('TABLE','AMI_DS_STATE','ATLAS_AMI_DATA22_01') from dual;
--
-- using sqlplus variables
-- var a varchar2(4000)
-- exec :a := DBMS_METADATA.GET_DDL('TABLE','AMI_DS_STATE','ATLAS_AMI_DATA22_01')
-- print :a



select
        dbms_metadata.get_ddl( object_type, object_name, owner )
from
        all_objects
where
    object_type NOT LIKE '%PARTITION' AND object_type NOT LIKE '%BODY'
AND     upper(object_name) LIKE
                                upper(CASE
                                        WHEN INSTR('&1','.') > 0 THEN
                                            SUBSTR('&1',INSTR('&1','.')+1)
                                        ELSE
                                            '&1'
                                        END
                                     )
AND     owner LIKE
                CASE WHEN INSTR('&1','.') > 0 THEN
                        UPPER(SUBSTR('&1',1,INSTR('&1','.')-1))
                ELSE
                        user
                END
/





