# ===============================================
#  start-monitoring.ps1
#  PowerShell script to build and run monitoring stack
# ===============================================

Write-Host "=== Building monitor-ubuntu Docker image ===" -ForegroundColor Cyan
docker build -t monitor-ubuntu:latest .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host "=== Stopping old containers (if any) ===" -ForegroundColor Cyan
$containers = @("monitor-ubuntu", "grafana", "prometheus", "snmp-exporter", "alertmanager")
foreach ($c in $containers) {
    docker stop $c 2>$null
    docker rm $c 2>$null
}

Write-Host "=== Creating Docker volumes (if missing) ===" -ForegroundColor Cyan
docker volume create prometheus-data | Out-Null
docker volume create grafana-storage | Out-Null

# ----------------------
# SNMP Exporter
# ----------------------
Write-Host "=== Starting SNMP Exporter (port 9116) ===" -ForegroundColor Green
docker run -d `
    --name snmp-exporter `
    -p 9116:9116 `
    -v "${PWD}/snmp.yml:/etc/snmp_exporter/snmp.yml:ro" `
    prom/snmp-exporter:latest `
    --config.file=/etc/snmp_exporter/snmp.yml

# ----------------------
# Prometheus
# ----------------------
Write-Host "=== Starting Prometheus (port 9090) ===" -ForegroundColor Green
docker run -d `
    --name prometheus `
    -p 9090:9090 `
    -v "${PWD}/prometheus.yml:/etc/prometheus/prometheus.yml:ro" `
    -v "${PWD}/rules.yml:/etc/prometheus/rules.yml:ro" `
    -v prometheus-data:/prometheus `
    prom/prometheus:latest `
    --config.file=/etc/prometheus/prometheus.yml `
    --storage.tsdb.path=/prometheus `
    --web.enable-lifecycle

# ----------------------
# Alertmanager
# ----------------------
Write-Host "=== Starting Alertmanager (port 9093) ===" -ForegroundColor Green
docker run -d `
    --name alertmanager `
    -p 9093:9093 `
    -v "${PWD}/alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro" `
    prom/alertmanager:latest `
    --config.file=/etc/alertmanager/alertmanager.yml

# ----------------------
# Grafana
# ----------------------
Write-Host "=== Starting Grafana (port 3000) ===" -ForegroundColor Green
docker run -d `
    --name grafana `
    -p 3000:3000 `
    -v grafana-storage:/var/lib/grafana `
    -v "${PWD}/grafana/provisioning:/etc/grafana/provisioning:ro" `
    grafana/grafana:latest

# ----------------------
# Ubuntu monitor container
# ----------------------
Write-Host "=== Starting Ubuntu monitoring container ===" -ForegroundColor Green
docker run -d `
    --name monitor-ubuntu `
    --cap-add=NET_RAW `
    --cap-add=NET_ADMIN `
    monitor-ubuntu:latest `
    tail -f /dev/null

# ----------------------
# Summary
# ----------------------
Write-Host ""
Write-Host "==============================================="
Write-Host " Monitoring Stack Started Successfully!"
Write-Host ""
Write-Host " Grafana:      http://localhost:3000"
Write-Host " Prometheus:   http://localhost:9090"
Write-Host " Alertmanager: http://localhost:9093"
Write-Host " SNMP Exporter:http://localhost:9116/metrics"
Write-Host ""
Write-Host " To access Ubuntu monitor container:"
Write-Host "    docker exec -it monitor-ubuntu bash"
Write-Host "==============================================="

