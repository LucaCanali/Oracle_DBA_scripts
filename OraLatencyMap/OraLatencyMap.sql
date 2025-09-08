-- =======================================================================
-- OraLatencyMap.sql
-- A tool to visualize Oracle wait-event latency as terminal heat maps
-- This is a thin wrapper over OraLatencyMap_advanced
--
-- Author   : Luca.Canali@cern.ch
-- https://github.com/LucaCanali/OraLatencyMap
-- Version  : v1.3  (September 2025)

-- Usage:
--   @OraLatencyMap [seconds] ["wait event"]
--
-- Defaults (when args are omitted):
--   seconds     : 3
--   wait event  : "db file sequential read"
--
-- Quick example (commit latency with wrapper defaults):
--   @OraLatencyMap
--   @OraLatencyMap 5 "db file sequential read"
--   @OraLatencyMap 3 "log file sync"
--
-- https://github.com/LucaCanali/OraLatencyMap
-- =======================================================================

SET VERIFY OFF FEEDBACK OFF TERMOUT ON HEADING OFF

-- Heatmap geometry
def NUM_BINS=11   -- number of latency buckets (heatmap rows)
def NUM_ROWS=90   -- number of time slices (heatmap columns)

-- Seed &1 / &2 with defaults via the classic SQL*Plus trick
COLUMN p1 NEW_VALUE 1
COLUMN p2 NEW_VALUE 2

SET TERMOUT OFF
SELECT NULL p1, NULL p2 FROM dual WHERE 1=2;
SELECT NVL('&&1','3') p1,
       NVL('&&2','db file sequential read') p2
FROM dual;
SET TERMOUT ON

-- Hand-off to the existing advanced script (exact call signature)
@@OraLatencyMap_advanced '&1' '&2' &NUM_BINS &NUM_ROWS ""

-- Cleanup
UNDEFINE 1 2
SET FEEDBACK ON HEADING ON
