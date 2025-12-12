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
- [Milestones](#Milestones)

## About

  The Network Metrics Visualizer monitors network devices in real time using SNMP Exporter and a Windows Exporter Agent, storing metrics in a time-series database and displaying them on a Grafana dashboard. 
  It detects issues like device downtime, throughput drops, and high latency, sending push notifications for alerts.
  All components run as Docker containers on a single VM, making deployment simple, portable, and easy to manage. 

## Objectives

  - Collect real-time network metrics from devices via SNMP.
  - Store time-series data in a TSDB (e.g., Prometheus or InfluxDB) and visualize it.
  - Detect events (throughput drop, latency increase, device offline) and trigger push notifications.
  - Run all components on a single VM, each as a Docker container.
     
## Design 

 - One-click startup using a PowerShell script.
 - Automatically build all required images and containers in a single VM.
   - Docker Desktop creates a Linux VM (using Hyper-V/WSL2 on Windows) to host the Docker Engine.
 - Enable SNMP (v2c or v3) on target devices; note IPs, communities/creds.
 - Windows devices use windows_exporter-0.31.3 Agent for metrics 
     - https://github.com/prometheus-community/windows_exporter/releases 
 - Containerize a polling stack: SNMP exporter/collector → TSDB (e.g., Prometheus + snmp_exporter).
 - Ingest key OIDs: interface octets/pps, uptime, CPU/mem, reachability.
 - Add latency/availability probes (e.g., blackbox-exporter ICMP/TCP) to the same TSDB.
 - Create alert rules for:
   - Device down/unreachable (no scrape / failed probe).
   - Throughput drop vs baseline or absolute threshold.
   - Latency above threshold.
  - Implement push notifications (e.g., ntfy/webhook/Alertmanager receiver).
  - Build Grafana dashboard for interfaces, device health, and alert status.
  - Persist configs/data with Docker volumes; expose only needed ports.

## Requirements 
  ### Functional Requirements 
  
  - **Data Collection**
    - Collect real-time metrics (throughput, latency, CPU, memory, uptime) via SNMP v2c/v3.
    - Allow adding/removing monitored devices and configuring polling intervals.
    
  - **Data Storage**
    - Store collected metrics in a Time-Series Database (Prometheus or InfluxDB).
    - Retain historical data for trend and performance analysis.
   
  - **Visualization**
    - Display real-time and historical graphs in a Grafana dashboard.
    - Include panels for device health, interface stats, and alert status.
  
  - **Event Detection & Alerts**
    - Detect device downtime, throughput drops, and high latency.
    - Trigger push notifications through Alertmanager, webhooks, or ntfy.

  - **Containerization & Deployment**
    - Run all services (SNMP exporter, TSDB, alert system, dashboard) in separate Docker containers.
    - Deploy on a single VM using Docker Compose with persistent storage volumes.
      
  ### Non-Functional Requirements 
  
  - **Performance:** Support at least 10–20 monitored devices concurrently.
  - **Reliability:** Retry failed SNMP polls automatically.
  - **Security:** Use SNMPv3 for authentication/encryption and HTTPS for dashboards.
  - **Usability:** Provide a clean, responsive, and intuitive web interface.
  - **Maintainability:** Configurable thresholds and polling intervals.
  - **Portability:** Must be easily deployable:
    - Linux VM via Docker Compose.
    - Windows computer via Docker Desktop.

  ### System Requirements 
  
  - **OS:** Windows 11 or Linux distribution.
  - **Hardware:** 2 vCPUs, 4 GB RAM, 20–40 GB storage minimum.
  - **Software:** Docker, Docker Compose, Prometheus, Grafana, SNMP exporter, Blackbox exporter, Alertmanager.
  - **Network:** SNMP access (UDP 161) to all monitored devices; internet access for notifications.
  
## Structure

netmetrics-app/
- start-netmetrics.bat      <- Menu interface calling start/stop/status     
- start-monitoring.ps1      <- Powershell script to start containers
- stop-monitoring.ps1       <- Powershell script to stop containers
- docker-compose.yml        <- Stack definitions
- prometheus.yml            <- Prometheus configuration
- rules.yml                 <- Prometheus alert rules (optional)
- alertmanager.yml          <- Alertmanager configuration
- scripts
     - snmp-dashboard       <- Dashboard JSON file
- grafana/                  <- Grafana dashboards/datasources & SSL certificates for HTTPS
     - provisioning/
       - datasources/
         - prometheus.yaml
       - certs/               
         - grafana.crt
         - grafana.key

## Installation

- Prerequisites:
  - Windows 11
  - Docker Desktop (latest version)
  - Verify installation by running:
    - docker --version  

  <img width="1112" height="728" alt="image" src="https://github.com/user-attachments/assets/8a2986c8-0747-406c-bcaf-0124c2ca7616" />

- **Setup Steps:** Follow the steps below to install and launch the NetMetrics monitoring stack.

1. Download the Project
   - Download the ZIP version of this repository and extract it.
   - Example location:
     - path\netmetrics-app

2. Run "start-netmetrics" batch file as an administrator.
   
   <img width="979" height="518" alt="image" src="https://github.com/user-attachments/assets/4ed8b8b6-6431-4800-9ed4-db2026ce58ab" />

3. Start the Monitoring Stack
   - Enter 1 to start monitoring.
   - Once the script finishes:
     - All images and containers will be built and started automatically.

<img width="1362" height="718" alt="image" src="https://github.com/user-attachments/assets/5a29ee90-8e63-452e-972a-c98313afd2ef" />

  - The script will output the URLs for:
    - Grafana
    - Prometheus
    - SNMP Exporter
    - Any additional services (if configured)
    - The monitoring stack outputs a screen for troubleshooting purposes:
  
<img width="984" height="521" alt="image" src="https://github.com/user-attachments/assets/44f5a113-4724-4ead-806c-d56d7140f6bb" />

4. Access your services
   - Open any local web browser and copy each URL from the monitoring stack into the browser to access the monitoring services.
   - Import the JSON file (snmp-dashboard) into the Grafana console to see the "Network Metrics Visualizer (NMV) Dashboard"

<img width="1901" height="1022" alt="image" src="https://github.com/user-attachments/assets/6c62bc21-4d1f-4d10-8656-a654f0b95f8e" />

## Usage

- Collect real-time network metrics via SNMP.
- Store time-series data using Prometheus.
- Visualize performance with Grafana dashboards.

## Milestones

- Deliverables
  -  All components run in Docker
  -  Store time-series data in a TSDB
  -  **Ingest key OIDs:** Synology-specific MIBs (complete OID tree)
      - 1.3.6.1.4.1.6574.1  # System info (status, temperature, fans)
      - 1.3.6.1.4.1.6574.2  # Disk info (complete disk table)
      - 1.3.6.1.4.1.6574.3  # RAID info
      - 1.3.6.1.4.1.6574.4  # UPS info (if connected)
      - 1.3.6.1.4.1.6574.5  # Smart disk info
      - 1.3.6.1.4.1.6574.6  # Service status
      - 1.3.6.1.4.1.6574.101 # Storage IO
      - 1.3.6.1.4.1.6574.102 # Space IO
      - 1.3.6.1.4.1.6574.104 # iSCSI LUN info
  -  HTTPS Grafana Dashboard
  -  GitHub repository
  -  Configure notifications via Alertmanager → Grafana

- Outstanding Deliverables
  - Add latency/availability probes (e.g., blackbox-exporter ICMP/TCP) to the same TSDB.
  - Detect events (throughput drop, latency increase, device offline) and trigger push notifications.

  

  [@CHRIST555](https://github.com/CHRIST555).


  
