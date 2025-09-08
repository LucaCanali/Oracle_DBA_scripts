--
-- This is an example launcher script for OraLatencyMap 
-- The sqlplus script reads from gv$event_histogram data the latency drilldown for the cell single block physical read wait event
-- This is a wait event for Exadata storage.
-- and displays data as two heatmaps: a Frequency heatmap and an Intensity heatMap
-- This script is intended to be used to measure the latency drilldown for single-block random read latency and iops for Exadata 
--

@@OraLatencyMap_advanced 3 "cell single block physical read" 11 90 ""
