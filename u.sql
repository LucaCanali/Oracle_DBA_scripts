set verify off
set feedback off
set linesize 250

col username for a30
col account_status for a25
col lock_date for a20
col expiry_date for a20
col profile for a20
col temporary_tablespace for a20
col default_tablespace for a30
col last_login for a20

select username, account_status, lock_date, expiry_date, default_tablespace, temporary_tablespace, profile, last_login
from dba_users where username like upper('%&&1%')
order by 1;

set hea off
select chr(13) from dual;
set hea on
set feedback on
set verify on

