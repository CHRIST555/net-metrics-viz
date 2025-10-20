# net-metrics-viz
### Network Metrics Visualizer (NMV)

## Table of Contents
- [Objectives](#Objectives)
- [Design](#Design)
- [Requirements](#Requirements)
- [Installation](#Installation)
- [Usage](#Usage)
- [Maintainer](#Maintainer)

## Objectives

  1. Collect real-time network metrics from devices via SNMP.
  2. Store time-series data in a TSDB (e.g., Prometheus or InfluxDB) and visualize it.
  3. Detect events (throughput drop, latency increase, device offline) and trigger push notifications.
  4. Run all components on a single VM, each as a Docker container.
     
## Design 

  1. Enable SNMP (v2c or v3) on target devices; note IPs, communities/creds.
  2. Containerize a polling stack: SNMP exporter/collector → TSDB (e.g., Prometheus + snmp_exporter).
     Ingest key OIDs: interface octets/pps, uptime, CPU/mem, reachability.
  3. Add latency/availability probes (e.g., blackbox-exporter ICMP/TCP) to the same TSDB.
  4. Create alert rules for:
            - Device down/unreachable (no scrape / failed probe).
            - Throughput drop vs baseline or absolute threshold.
            - Latency above threshold.
  5. Implement push notifications (e.g., ntfy/webhook/Alertmanager receiver).
  6. Build Grafana dashboards for interfaces, device health, and alert status.
  7. Persist configs/data with Docker volumes; expose only needed ports.

## Requirements 


## Installation

## Usage



## Maintainer

  @CHRIST555.

