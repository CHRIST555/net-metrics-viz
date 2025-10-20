# net-metrics-viz
## Network Metrics Visualizer (NMV)

## Table of Contents
- [About](#About)
- [Objectives](#Objectives)
- [Design](#Design)
- [Requirements](#Requirements)
- [Installation](#Installation)
- [Usage](#Usage)
- [Maintainer](#Maintainer)

## About

## Objectives

  - Collect real-time network metrics from devices via SNMP.
  - Store time-series data in a TSDB (e.g., Prometheus or InfluxDB) and visualize it.
  - Detect events (throughput drop, latency increase, device offline) and trigger push notifications.
  - Run all components on a single VM, each as a Docker container.
     
## Design 

 - Enable SNMP (v2c or v3) on target devices; note IPs, communities/creds.
 - Containerize a polling stack: SNMP exporter/collector → TSDB (e.g., Prometheus + snmp_exporter).
     Ingest key OIDs: interface octets/pps, uptime, CPU/mem, reachability.
 - Add latency/availability probes (e.g., blackbox-exporter ICMP/TCP) to the same TSDB.
 - Create alert rules for:
            - Device down/unreachable (no scrape / failed probe).
            - Throughput drop vs baseline or absolute threshold.
            - Latency above threshold.
  - Implement push notifications (e.g., ntfy/webhook/Alertmanager receiver).
  - Build Grafana dashboards for interfaces, device health, and alert status.
  - Persist configs/data with Docker volumes; expose only needed ports.

## Requirements 
  ### Functional Requirements 
  
  - Data Collection
      Collect real-time metrics (throughput, latency, CPU, memory, uptime) via SNMP v2c/v3.
      Allow adding/removing monitored devices and configuring polling intervals.
    
  - Data Storage
      Store collected metrics in a Time-Series Database (Prometheus or InfluxDB).
      Retain historical data for trend and performance analysis.
   
  - Visualization
      Display real-time and historical graphs in a Grafana dashboard.
      Include panels for device health, interface stats, and alert status.
      Event Detection & Alerts
      Detect device downtime, throughput drops, and high latency.
      Trigger push notifications through Alertmanager, webhooks, or ntfy.

  - Containerization & Deployment
      Run all services (SNMP exporter, TSDB, alert system, dashboard) in separate Docker containers.
      Deploy on a single VM using Docker Compose with persistent storage volumes.
      
  ### Non-Functional Requirements 
  
  - Performance: Support at least 10–20 monitored devices concurrently.
  - Reliability: Retry failed SNMP polls automatically.
  - Security: Use SNMPv3 for authentication/encryption and HTTPS for dashboards.
  - Usability: Provide a clean, responsive, and intuitive web interface.
  - Maintainability: Configurable thresholds and polling intervals.
  - Portability: Must be easily deployable on any Linux VM via Docker Compose.

  ### System Requirements 
  
  - OS: Ubuntu 22.04 or equivalent Linux distribution.
  - Hardware: 2 vCPUs, 4 GB RAM, 20–40 GB storage minimum.
  - Software: Docker, Docker Compose, Prometheus/InfluxDB, Grafana, SNMP exporter, Blackbox exporter, Alertmanager.
  - Network: SNMP access (UDP 161) to all monitored devices; internet access for notifications.
  
## Installation

## Usage



## Maintainer

  [@CHRIST555](https://github.com/CHRIST555).


