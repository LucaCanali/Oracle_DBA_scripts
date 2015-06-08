-- kill a given oracle session
-- usage @kill <sid> <serial#>

alter system kill session '&1,&2' immediate;
