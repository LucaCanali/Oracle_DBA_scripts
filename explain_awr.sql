-- explain.sql
-- prints execution plan for a give sql_id 
-- detailed execution plan, taken from AWR
-- Usage @explain <sql_id>
-- by Luca

--select * from table(dbms_xplan.display_cursor('&1'));
--select * from table(dbms_xplan.display_cursor('&1',0,'ALLSTATS LAST'));
--select * from table(dbms_xplan.display_cursor('&1',0,'TYPICAL OUTLINE'));
--select * from table(dbms_xplan.display_cursor('&1',null,'ADVANCED OUTLINE ALLSTATS LAST +PEEKED_BINDS'));
select * from table(dbms_xplan.display_awr('&1',null,null,'ADVANCED OUTLINE ALLSTATS LAST +PEEKED_BINDS'));