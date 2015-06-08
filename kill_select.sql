REM creates selects statements for session kill
REM Luca, Feb 2008

col SQL for a80

select 'alter system kill session '''||sid||','||serial#||''' immediate;' SQL
from v$session where &1;
