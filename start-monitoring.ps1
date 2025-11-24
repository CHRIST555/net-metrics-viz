# ===============================================
#  start-monitoring.ps1
#  PowerShell script to build and run monitoring stack
#  Updated: hyperlinks removed for stability
# ===============================================

Write-Host "=== Building test-monitor-ubuntu Docker image ===" -ForegroundColor Cyan
docker build -t test-monitor-ubuntu:latest -f Dockerfile-test-monitor-ubuntu .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Exiting..." -ForegroundColor Red
    exit 1
}

Write-Host "=== Stopping old containers (if any) ===" -ForegroundColor Cyan
$containers = @(
    "test-monitor-ubuntu", 
    "grafana", 
    "prometheus", 
    "snmp-exporter", 
    "snmp-generator",
    "alertmanager"
)

foreach ($c in $containers) {
    docker stop $c 2>$null
    docker rm $c 2>$null
}

Write-Host "=== Creating Docker volumes (if missing) ===" -ForegroundColor Cyan
docker volume create prometheus-data | Out-Null
docker volume create grafana-storage | Out-Null
docker volume create snmp-volume | Out-Null

Write-Host "=== Creating monitoring network ===" -ForegroundColor Cyan
docker network create monitoring-net 2>$null | Out-Null

# ----------------------
# SNMP Generator
# ----------------------
Write-Host "=== Generating snmp.yml inside Docker volume ===" -ForegroundColor Cyan
docker run --rm `
    -v snmp-volume:/app `
    -w /app `
    golang:1.24-alpine `
    sh -c "cp -r /app-template/* /app && go run generator.go generate -m ./mibs -g ./generator.yml -o ./snmp.yml"
Write-Host "snmp.yml generated successfully inside volume." -ForegroundColor Green

# ----------------------
# SNMP Exporter
# ----------------------
Write-Host "=== Starting SNMP Exporter (port 9116) ===" -ForegroundColor Green
docker run -d `
    --name snmp-exporter `
    --network monitoring-net `
    -p 9116:9116 `
    -v snmp-volume:/etc/snmp_exporter:ro `
    prom/snmp-exporter:latest `
    --config.file=/etc/snmp_exporter/snmp.yml

# ----------------------
# Prometheus
# ----------------------
Write-Host "=== Starting Prometheus (port 9090) ===" -ForegroundColor Green
docker run -d `
    --name prometheus `
    --network monitoring-net `
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
    --network monitoring-net `
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
    --network monitoring-net `
    -p 3000:3000 `
    -v grafana-storage:/var/lib/grafana `
    -v "${PWD}/grafana/provisioning:/etc/grafana/provisioning:ro" `
    grafana/grafana:latest

# ----------------------
# Test Ubuntu SNMP monitor container
# ----------------------
Write-Host "=== Starting Test Ubuntu SNMP container ===" -ForegroundColor Green
docker run -d `
    --name test-monitor-ubuntu `
    --network monitoring-net `
    --cap-add=NET_RAW `
    --cap-add=NET_ADMIN `
    test-monitor-ubuntu:latest

# ----------------------
# Summary
# ----------------------
Write-Host ""
Write-Host "==============================================="
Write-Host " Monitoring Stack Started Successfully!"
Write-Host ""
Write-Host " Access your services at:"
Write-Host "   Grafana:      http://localhost:3000"
Write-Host "   Prometheus:   http://localhost:9090"
Write-Host "   Alertmanager: http://localhost:9093"
Write-Host "   SNMP Exporter:http://localhost:9116/snmp?module=system&target=<IP>"
Write-Host ""
Write-Host " To access Test Ubuntu SNMP container:"
Write-Host "    docker exec -it test-monitor-ubuntu bash"
Write-Host "==============================================="
