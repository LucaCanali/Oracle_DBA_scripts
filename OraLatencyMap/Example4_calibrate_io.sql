--
-- This is an example launcher script for OraLatencyMap 
-- The sqlplus script reads from gv$event_histogram data the latency drilldown for the Disk file I/O Calibration read  wait event
-- and displays data as two heatmaps: a Frequency heatmap and an Intensity heatMap
-- This script is intended to be used to measure the latency drilldown for calibrate_io workload 
--
-- The example here below is added for convenience. It shows how to run calibrate_io workload from sqlplus
-- 
/* 
SET SERVEROUTPUT ON
DECLARE
  l_latency PLS_INTEGER;
  l_iops PLS_INTEGER;
  l_mbps PLS_INTEGER;
BEGIN
  DBMS_RESOURCE_MANAGER.calibrate_io (num_physical_disks => 4,
    max_latency => 10,
    max_iops => l_iops,
    max_mbps => l_mbps,
    actual_latency => l_latency);
  DBMS_OUTPUT.put_line('Max IOPS = ' || l_iops);
  DBMS_OUTPUT.put_line('Max MBPS = ' || l_mbps);
  DBMS_OUTPUT.put_line('Latency = ' || l_latency);
END;
/
*/

@@OraLatencyMap_advanced 3 "Disk file I/O Calibration" 11 90 ""
