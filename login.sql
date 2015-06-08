-- sqlplus startup scripts, sets up prompt, etc
-- Luca 2005, last updated from 11g Mar 2012

set termout off
set long 5000

set pagesize 9999
set linesize 180
set longchunksize 180
set arraysize 100

set num 10

define gname=idle
column global_name new_value gname
--select lower(user) || '@' || sys_context('USERENV','INSTANCE_NAME') global_name from dual;
select lower(sys_context('USERENV','DATABASE_ROLE'))||':'||lower(user) || '@' || sys_context('USERENV','INSTANCE_NAME') global_name from dual;
select lower(sys_context('USERENV','DATABASE_ROLE'))||':'||lower(user) || '@' || sys_context('USERENV','DB_UNIQUE_NAME') || '-' ||sys_context('USERENV','INSTANCE_NAME') global_name from dual;


set sqlprompt '&gname> '

host title sqlplus connected to &gname
alter session set nls_date_format='dd-mm-yy hh24:mi';

set tab off
set termout on

