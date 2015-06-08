-- explain.sql
-- prints execution plan for a give sql_id 
-- detailed execution plan, taken from memory/library cache 
-- Usage @explain <sql_id>
-- by Luca

--select * from table(dbms_xplan.display_cursor('&1'));
--select * from table(dbms_xplan.display_cursor('&1',0,'ALLSTATS LAST'));
--select * from table(dbms_xplan.display_cursor('&1',0,'TYPICAL OUTLINE'));
--for explain plan use:
--select * from table(dbms_xplan.display('PLAN_TABLE',null,'ADVANCED OUTLINE ALLSTATS LAST +PEEKED_BINDS',null));
select * from table(dbms_xplan.display_cursor('&1',null,'ADVANCED OUTLINE ALLSTATS LAST +PEEKED_BINDS'));
