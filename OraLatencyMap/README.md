# OraLatencyMap — Oracle Wait and I/O Latency Heatmaps

**This is a copy from the official repository for OraLatencyMap: https://github.com/LucaCanali/OraLatencyMap/**
  
**OraLatencyMap** is an Oracle RDBMS performance troubleshooting tool.
It helps DBAs and performance engineers drill into wait-event and I/O latencies.
It captures wait-event histograms from the database and renders them as **heat maps** directly in
your terminal. Runs from CLI with SQL\*Plus, 

---

## ✨ Why latency histograms and why two heat maps?

Oracle instrumentation provides **detailed latency histograms** for wait events, sampled at the microsecond level.
This is precious when using just wait averages makes it hard to understand a multi-modal distribution (e.g., a mix of fast and slow I/Os).
Heat maps are a great way to visualize histograms over time.
OraLatencyMap does just that. It runs from Oracle CLI, SQL*PLus, and samples Oracle’s **wait histograms** and renders two views:

1) **Frequency heat map** — *How often* waits occur in each latency bucket (Hz).
2) **Intensity heat map** — *How much time* those waits consume (ms/sec).

These two views answer different questions:

- **“Are many calls slow?”** → Frequency map
- **“Are a few slow calls dominating total time?”** → Intensity map

A common pattern: 90% of reads are served from storage cache with latency < 1 ms (bright band in the *frequency* map),
but a small tail around 10 ms (I/O served by slow spindles) paints the *intensity* map hot—meaning that tail dominates
user-visible delay. 
You need **both** maps to see the full picture

---

## 🚀 Quick Start

    -- Connect to Oracle via SQL*Plus
    $ sqlplus system/password@service

    -- Basic wrapper with sensible defaults
    SQL> @OraLatencyMap

    -- @OraLatencyMap [seconds] ["wait event"]
    SQL> @OraLatencyMap 3 "db file sequential read"

    -- Commit latency example
    SQL> @OraLatencyMap 5 "log file sync"

---

## 🔧 Advanced Mode

Use the advanced mode when you want full control over sampling period, canvas geometry, or optional filters:

    -- Usage:
    -- @OraLatencyMap_advanced <refresh_sec> "<event_name>" <num_bins> <num_cols> "<extra_where>"

    -- Examples:
    SQL> @OraLatencyMap_advanced 5 "db file sequential read" 11 90  "and inst_id=1"
    SQL> @OraLatencyMap_advanced 5 "log file sync"           13 110 "and inst_id in (1,2)"

**Arguments**

| Arg | Meaning | Tips |
|---|---|---|
| `<refresh_sec>` | Seconds between samples/frames | 3–10s is a good start. Higher reduces overhead and jitter. |
| `"<event_name>"` | Exact non-idle wait event (case-insensitive) | e.g., `db file sequential read`, `log file sync`, `db file scattered read` |
| `<num_bins>` | Heat map **rows** (latency buckets) | More rows = finer latency detail; 11–15 is typical |
| `<num_cols>` | Heat map **columns** (time window width) | 80–120 columns balance detail and readability |
| `"<extra_where>"` | Extra predicate appended to `GV$` filters | Use for RAC: `and inst_id=1` or `and inst_id in (1,2)`; or targeted tests |

**When to use Advanced Mode**
- You want a wider/narrower time window or more latency granularity.
- You need to focus on a subset of instances in RAC.
- You’re presenting data on a larger terminal (more columns/rows).

> Note: The simple wrapper fixes geometry and proxies to advanced mode.  
> For custom bins/cols or filters, call **`@OraLatencyMap_advanced`** directly.

---

## 📦 Requirements

- Run from **SQL\*Plus** in a terminal that supports **ANSI escape codes** (xterm, PuTTY, most modern terminals).
- Privileges:
  - `SELECT` on `GV$EVENT_HISTOGRAM_MICRO` (or `V$...` in single instance)
  - `EXECUTE` on `DBMS_LOCK` (used for sleep)
- Oracle versions: tested on **19c, 23ai**
  - For Oracle 11g, use version 1.2
 
---

## 🧭 Reading the Heat Maps

- **Axes**:
  - Y = latency buckets (ms; sub-ms appear as decimals; the lowest is `<0.128`)
  - X = time, newest at the **right** (scrolling right→left)

- **Frequency map** (top): “how many waits?”  
  Watch for skew: stripes/bands indicate stable distributions; sudden vertical streaks indicate bursts.

- **Intensity map** (bottom): “how much time is lost?”  
  A small hot band at higher ms means a tail that’s killing throughput, even if rare.

**Common patterns**
- **Bimodal I/O**: two horizontal bands (e.g., SSD vs. spinning disk) → verify storage tiers.
- **Commit stalls** (`log file sync`) spiking into 5–20 ms → check redo I/O latency, log buffer pressure, or contention.
- **Sustained drift upward** → storage contention or throttling; correlate with system metrics.

---
## Example Output
![Latency reads heatmap](https://raw.githubusercontent.com/LucaCanali/OraLatencyMap/master/Latency_reads_heatmap.png)

This example shows the latency heatmap for the `db file sequential read` event.  
The system is experiencing a **bimodal latency distribution**, indicating two distinct latency patterns:

- Reads from **fast storage (SSD)** with latency < 1 ms (visible in the *Frequency Heatmap*, blue area).
- Reads from **slower storage (spinning disks)** with latency ≈ 10 ms (visible in the *Intensity Heatmap*, yellow-red areas).

Although most requests are served in under 1 ms, the slower I/Os with latency around 10 ms contribute a significant share
of the **total wait time**.

Note you can use [ehm_micro.sql](https://github.com/LucaCanali/Oracle_DBA_scripts/blob/master/ehm_micro.sql) to further analyze the latency distribution:

```
@ehm_micro 10 "db file sequential read"

Latency histograms for Oracle wait events, RAC 12c version.
Usage: @ehm_micro <delta time> <event>
Please wait for 10 sec (DeltaT = 10 sec) for snapshot N.2 and script output.

Latency histogram for event "db file sequential read" from GV$EVENT_HISTOGRAM_MICRO:

Latency Bucket       Num Waits/DeltaT  Wait Time/DeltaT    Event Name                 Last Update Time
(microsec)           (Hz)              (microsec/sec)
-------------------  ----------------  ------------------  -------------------------  -----------------------------------
0 -> 1                              0                   0   db file sequential read
1 -> 2                              0                   0   db file sequential read
2 -> 4                              0                   0   db file sequential read
4 -> 8                              0                   0   db file sequential read
8 -> 16                             0                   0   db file sequential read
16 -> 32                            0                   0   db file sequential read
32 -> 64                            0                   0   db file sequential read
64 -> 128                           0                   0   db file sequential read  29-AUG-25 06.47.47.201065 AM +02:00
128 -> 256                         .1                19.2   db file sequential read  01-SEP-25 04.55.21.313881 PM +02:00
256 -> 512                       47.8             18355.2   db file sequential read  01-SEP-25 04.55.27.417436 PM +02:00
512 -> 1024                       4.4              3379.2   db file sequential read  01-SEP-25 04.55.26.965961 PM +02:00
1024 -> 2048                       .4               614.4   db file sequential read  01-SEP-25 04.55.25.375314 PM +02:00
2048 -> 4096                      1.2              3686.4   db file sequential read  01-SEP-25 04.55.26.001333 PM +02:00
4096 -> 8192                      6.6             40550.4   db file sequential read  01-SEP-25 04.55.27.223077 PM +02:00
8192 -> 16384                    27.5              337920   db file sequential read  01-SEP-25 04.55.27.288955 PM +02:00
16384 -> 32768                   15.6            383385.6   db file sequential read  01-SEP-25 04.55.27.414934 PM +02:00
32768 -> 65536                    1.6             78643.2   db file sequential read  01-SEP-25 04.55.23.754890 PM +02:00
65536 -> 131072                    .1              9830.4   db file sequential read  01-SEP-25 04.55.18.028308 PM +02:00
131072 -> 262144                    0                   0   db file sequential read  01-SEP-25 04.55.15.986906 PM +02:00
262144 -> 524288                    0                   0   db file sequential read  01-SEP-25 12.45.57.034086 PM +02:00
524288 -> 1048576                   0                   0   db file sequential read  01-SEP-25 12.46.04.063835 PM +02:00
1048576 -> 2097152                  0                   0   db file sequential read  30-AUG-25 12.46.04.572741 PM +02:00
2097152 -> 4194304                  0                   0   db file sequential read  29-AUG-25 12.45.39.832565 PM +02:00
4194304 -> 8388608                  0                   0   db file sequential read  25-MAY-25 12.46.20.207090 PM +02:00
8388608 -> 16777216                 0                   0   db file sequential read  22-APR-25 05.25.45.492752 PM +02:00
16777216 -> 3355443                 0                   0   db file sequential read  22-APR-25 05.25.45.535937 PM +02:00

Average values from GV$SYSTEM_EVENT:

Mean Wait Time       Num Waits/DeltaT  Wait Time/DeltaT    Event Name
(microsec)           (Hz)              (microsec/sec)
-------------------  ----------------  ------------------  -------------------------
7774.3                          105.3            818634.8  db file sequential read
```

---
## 🧪 Practical Workflows

- **Single-block reads (OLTP)**  
  `@OraLatencyMap 3 "db file sequential read"`  
  If the *intensity* map is hot around ~8–12 ms, a minority of slow reads is likely the bottleneck.

- **Commit latency**  
  `@OraLatencyMap 5 "log file sync"`  
  Spikes here are user-facing. Investigate `redo write` latency, log file size/placement, IOPS saturation.

- **RAC focus**  
  `@OraLatencyMap_advanced 5 "db file sequential read" 11 90 "and inst_id=1"`  
  Compare nodes side by side in separate sessions.

- **Deeper drill-down**  
  Pair with script [ehm_micro.sql](https://github.com/LucaCanali/Oracle_DBA_scripts/blob/master/ehm_micro.sql)
  to print the numeric histogram and last-update timestamps.

---
## 🐳 Testing using Oracle-free container image

You can try **OraLatencyMap** without access to a production Oracle database by using the
[Oracle Free container image](https://hub.docker.com/r/gvenzl/oracle-free).  
This image includes **Oracle Database**, **SQL\*Plus**, and is ideal for functional testing or demos.

**Setup**

```bash
# Start Oracle Free 23c container
docker run -d --name mydb1 -e ORACLE_PASSWORD=oracle -p 1521:1521 gvenzl/oracle-free:23.9-slim

# Open a shell inside the container
docker exec -it mydb1 /bin/bash

# Connect as SYSDBA
sqlplus / as sysdba
```

From SQL\*Plus you can, for example, run `DBMS_RESOURCE_MANAGER.CALIBRATE_IO` to generate I/O activity:

```sql
DECLARE
  l_latency PLS_INTEGER;
  l_iops    PLS_INTEGER;
  l_mbps    PLS_INTEGER;
BEGIN
  DBMS_RESOURCE_MANAGER.calibrate_io (
    num_physical_disks => 4,
    max_latency        => 10,
    max_iops           => l_iops,
    max_mbps           => l_mbps,
    actual_latency     => l_latency
  );
  DBMS_OUTPUT.put_line('Max IOPS = ' || l_iops);
  DBMS_OUTPUT.put_line('Max MBPS = ' || l_mbps);
  DBMS_OUTPUT.put_line('Latency  = ' || l_latency);
END;
/
```

**Measure with OraLatencyMap**

```bash
# Clone OraLatencyMap locally and copy into the container
git clone https://github.com/LucaCanali/OraLatencyMap
docker cp OraLatencyMap mydb1:/opt/oracle

# Back inside the container
docker exec -it mydb1 /bin/bash
sqlplus / as sysdba

-- Run the example, it will sample I/O waits "Disk file I/O Calibration" every 3 seconds
@OraLatencyMap/Example4_calibrate_io.sql
```

This workflow lets you quickly validate the scripts and visualize latency heat maps in a safe, self-contained environment.

---

## 🧯 Troubleshooting

- **No color/garbled output**: use a terminal with ANSI support; avoid character translation.
- **ORA-01031 / missing view**: grant `SELECT` on `GV$EVENT_HISTOGRAM_MICRO`; grant `EXECUTE` on `DBMS_LOCK`.
- **Blank maps**: the event may be idle, mistyped, or inactive; try a busier event or longer sampling.
- **RAC totals look odd**: filter by `inst_id` to isolate nodes; tails can differ across instances.

---

## 📂 Files

- `OraLatencyMap.sql` — simple wrapper (defaults; hardcoded geometry → bins/cols)
- `OraLatencyMap_advanced.sql` — advanced driver (sampling period, geometry, RAC filters)
- `OraLatencyMap_internal.sql` — core compute + rendering engine
- `OraLatencyMap_internal_loop.sql` — orchestrates repeated sampling
- `Examples*.sql` — ready-to-run scripts

---
## 👤 Author and Contact

**Luca Canali** — CERN
📧 [Luca.Canali@cern.ch](mailto:Luca.Canali@cern.ch)  
🌐 [cern.ch/canali](https://cern.ch/canali)

## 📌 Versions

- **v1.3** (September 2025) — uses microsecond event histograms (`gv$event_histogram_micro`) and includes minor refactoring
- **v1.2** (March 2014) — improvements and stability updates
- **v1.0** (August 2013) — initial release

---
## 📖 References

- Blog: [Troubleshoot I/O & Wait Latency with OraLatencyMap and PyLatencyMap](https://db-blog.web.cern.ch/node/199)
- Blog: [Recent updates of OraLatencyMap](https://externaltable.blogspot.com/2014/03/recent-updates-of-oralatencymap-and.html)
- Blog: [Latency Heat Map in SQL\*Plus](https://externaltable.blogspot.com/2013/05/latency-heat-map-in-sqlplus-with.html)
- Heatmaps in Python [PyLatencyMap](https://github.com/LucaCanali/PyLatencyMap) 
- Oracle DBA scripts: [Oracle_DBA_scripts](https://github.com/LucaCanali/Oracle_DBA_scripts) → see `ehm_micro.sql`

---
## Acknowledgements
- **Brendan Gregg** – *Visualizing System Latency*, CACM (July 2010)
- **Tanel Poder** – Snapper, MOATS, SQL*Plus & color hacks
- **Marcin Przepiorowski** – TopasS
