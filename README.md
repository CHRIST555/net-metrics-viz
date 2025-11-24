# net-metrics-viz
## Network Metrics Visualizer (NMV)

## Table of Contents
- [About](#About)
- [Objectives](#Objectives)
- [Design](#Design)
- [Requirements](#Requirements)
- [Structure](#Structure)
- [Installation](#Installation)
- [Usage](#Usage)
- [Maintainer](#Maintainer)

## About

  The Network Metrics Visualizer monitors network devices in real time using SNMP, storing metrics in a time-series database and displaying them on a Grafana dashboard. 
  It detects issues like device downtime, throughput drops, and high latency, sending push notifications for alerts.
  All components run as Docker containers on a single VM, making deployment simple, portable, and easy to manage. 

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
  
## Structure

- netmetrics-app/
    - docker-compose.yml
    - Dockerfile-test-monitor-ubuntu
    - start-monitoring.ps1
    - README.md
    - grafana/
        - provisioning/
            - datasources/
                - prometheus.yaml
                - (other datasource configuration files)
    - scripts/
        - net-metrics-viz-dashboard.json
        - (other helper scripts)
    - alertmanager.yml
    - prometheus.yml
    - rules.yml
    - snmp.yml
    - snmpd.conf

## Installation

Prerequisites:
Windows 11
Docker Desktop (latest version)
Verify installation by running:
docker --version

Setup Steps:
Follow the steps below to install and launch the NetMetrics monitoring stack.

1. Download the Project
Download the ZIP version of this repository and extract it.
Example location:
.\netmetrics-app

2. Open PowerShell as Administrator
Right-click Start
Select Windows PowerShell (Admin)

3. Navigate to the Project Folder 
e.g cd ".\netmetrics-app"

4. Start the Monitoring Stack

Run  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Type A
Run the startup script:
.\start-monitoring.ps1

After Startup:
Once the script finishes:
All images and containers will be built and started automatically.
The script will output the URLs for:
- Grafana
- Prometheus
- SNMP Exporter
- Any additional services (if configured)

Open any local web browser and copy each URL into the browser to access the monitoring interfaces.

## Usage

- Collect real-time network metrics via SNMP
- Store time-series data using Prometheus
- Visualize performance with Grafana dashboards
- One-click startup using a PowerShell script
- Automatically builds all required images and containers

## Maintainer

  Notes: Windows SNMP service does NOT support MSFT-MIB by default.
         Microsoft removed SNMP support in Windows 10/11 unless manually installed (and even then, many Microsoft MIBs are NOT implemented).

  [@CHRIST555](https://github.com/CHRIST555).


