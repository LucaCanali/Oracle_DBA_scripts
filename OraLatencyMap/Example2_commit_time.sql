--
-- This is an example launcher script for OraLatencyMap 
-- The sqlplus script reads from gv$event_histogram data the latency drilldown for the log file sync wait event
-- and displays data as two heatmaps: a Frequency heatmap and an Intensity heatMap
-- This script is intended to be used to measure the latency drilldown for commit time wait in Oracle
--

@@OraLatencyMap_advanced 3 "log file sync" 11 90 ""
