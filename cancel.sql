-- cancel SQL for a given oracle session
-- usage @cancel <sid> <serial#>

alter system cancel sql '&1,&2';
