/* sql.sql script to display sql instructions for a give sql_id
   By Luca Canali 2005
*/

set verify off
set long 4000
col sql_fulltext for a400

--select inst_id,sql_text from gv$sqltext where sql_id='&1' order by inst_id,piece;
select inst_id,sql_fulltext from gv$sqlstats where sql_id='&1' order by inst_id;
