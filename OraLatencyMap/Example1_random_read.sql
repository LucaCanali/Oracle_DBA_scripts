--
-- This is an example launcher script for OraLatencyMap 
-- The sqlplus script reads from gv$event_histogram data the latency drilldown for the db file sequential read wait event
-- and displays data as two heatmaps: a Frequency heatmap and an Intensity heatMap
-- This script is intended to be used to measure the latency drilldown for IOPS of single-block random read in Oracle
--

@@OraLatencyMap_advanced 3 "db file sequential read" 11 90 ""
