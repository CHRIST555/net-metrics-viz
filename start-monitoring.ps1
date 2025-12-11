# ===============================================
#  start-monitoring.ps1
#  PowerShell script to build and run monitoring stack
#  UPDATED: New Synology NAS IP address + Grafana HTTPS support
# ===============================================

# Try to find the correct project directory
$possiblePaths = @(
    "C:\Program Files\Docker\net-metrics-viz-v3",
    "$PSScriptRoot",
    $PWD
)

$projectPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path "$path\prometheus.yml") {
        $projectPath = $path
        break
    }
}

if ($projectPath -eq $null) {
    Write-Host "ERROR: Cannot find project directory with prometheus.yml" -ForegroundColor Red
    Write-Host "Please ensure you're in the correct directory or update the path in the script" -ForegroundColor Yellow
    Write-Host "Looking for prometheus.yml in these locations:" -ForegroundColor Gray
    foreach ($path in $possiblePaths) {
        Write-Host "  - $path" -ForegroundColor Gray
    }
    exit 1
}

Set-Location $projectPath
$configPath = $projectPath

# Set the Synology NAS IP address here
$synologyIP = "192.168.1.160"  # Updated IP address

# Path to Grafana certificates
$certPath = "$configPath\grafana\certs"

Write-Host "=== Validating configuration files ===" -ForegroundColor Cyan
Write-Host "Using project path: $configPath" -ForegroundColor Green
Write-Host "Synology NAS IP: $synologyIP" -ForegroundColor Green

# Check for required configuration files
$requiredFiles = @("prometheus.yml", "snmp.yml", "alertmanager.yml")
$optionalFiles = @("rules.yml")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (Test-Path "$configPath\$file") {
        Write-Host "  [OK] Found: $file" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] $file" -ForegroundColor Red
        $missingFiles += $file
    }
}

# Check optional files
foreach ($file in $optionalFiles) {
    if (Test-Path "$configPath\$file") {
        Write-Host "  [OK] Found: $file (optional)" -ForegroundColor Green
    } else {
        Write-Host "  [INFO] Optional file not found: $file" -ForegroundColor Yellow
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "ERROR: Missing required configuration files!" -ForegroundColor Red
    Write-Host "Please ensure these files exist in your project directory:" -ForegroundColor Yellow
    foreach ($file in $missingFiles) {
        Write-Host "  - $file" -ForegroundColor Yellow
    }
    exit 1
}

# Validate Prometheus configuration
if (Test-Path "$configPath/prometheus.yml") {
    $promConfig = Get-Content "$configPath/prometheus.yml" -Raw
    if ($promConfig -match "synology") {
        Write-Host "  [OK] Prometheus config: Contains Synology job" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Prometheus config: Missing Synology job" -ForegroundColor Yellow
    }
    
    if ($promConfig -match $synologyIP) {
        Write-Host "  [OK] Prometheus config: Contains correct IP ($synologyIP)" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] Prometheus config: May need IP address update" -ForegroundColor Yellow
        Write-Host "    Please update prometheus.yml to use IP: $synologyIP" -ForegroundColor Gray
    }
}

# Validate SNMP configuration
if (Test-Path "$configPath/snmp.yml") {
    $snmpConfig = Get-Content "$configPath/snmp.yml" -Raw
    if ($snmpConfig -match "synology") {
        Write-Host "  [OK] SNMP config: Contains Synology module" -ForegroundColor Green
    } else {
        Write-Host "  [WARNING] SNMP config: Missing Synology module" -ForegroundColor Yellow
    }
}

# Validate rules.yml configuration (if it exists)
$useRulesFile = $false
if (Test-Path "$configPath/rules.yml") {
    $rulesConfig = Get-Content "$configPath/rules.yml" -Raw
    if ($rulesConfig -match "groups:") {
        Write-Host "  [OK] Rules config: Contains alert groups" -ForegroundColor Green
        $useRulesFile = $true
    } else {
        Write-Host "  [WARNING] Rules config: Invalid format (skipping)" -ForegroundColor Yellow
    }
}

Write-Host "=== Stopping old containers (if any) ===" -ForegroundColor Cyan
$containersToStop = @("grafana", "prometheus", "snmp-exporter", "alertmanager")
foreach ($container in $containersToStop) {
    Write-Host "  Stopping $container..." -ForegroundColor Gray
    docker stop $container 2>$null | Out-Null
    docker rm $container 2>$null | Out-Null
}

Write-Host "=== Creating Docker volumes (if missing) ===" -ForegroundColor Cyan
docker volume create prometheus-data 2>$null | Out-Null
docker volume create grafana-storage 2>$null | Out-Null
Write-Host "  [OK] Docker volumes ready" -ForegroundColor Green

Write-Host "=== Creating monitoring network ===" -ForegroundColor Cyan
docker network create monitoring-net 2>$null | Out-Null
Write-Host "  [OK] Monitoring network ready" -ForegroundColor Green

Write-Host "=== Starting SNMP Exporter (port 9116) ===" -ForegroundColor Green
$snmpConfigPath = "$configPath\snmp.yml"
docker run -d --name snmp-exporter --network monitoring-net -p 9116:9116 -v "${snmpConfigPath}:/etc/snmp_exporter/snmp.yml:ro" prom/snmp-exporter:latest --config.file=/etc/snmp_exporter/snmp.yml
Start-Sleep -Seconds 5

Write-Host "=== Starting Prometheus (port 9090) ===" -ForegroundColor Green
if ($useRulesFile) {
    Write-Host "  Including rules.yml for alerting" -ForegroundColor Cyan
    docker run -d --name prometheus --network monitoring-net -p 9090:9090 `
        -v "${configPath}\prometheus.yml:/etc/prometheus/prometheus.yml:ro" `
        -v "${configPath}\rules.yml:/etc/prometheus/rules.yml:ro" `
        -v prometheus-data:/prometheus `
        prom/prometheus:latest --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.enable-lifecycle
} else {
    Write-Host "  Starting without rules file" -ForegroundColor Yellow
    docker run -d --name prometheus --network monitoring-net -p 9090:9090 `
        -v "${configPath}\prometheus.yml:/etc/prometheus/prometheus.yml:ro" `
        -v prometheus-data:/prometheus `
        prom/prometheus:latest --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/prometheus --web.enable-lifecycle
}

Write-Host "=== Starting Alertmanager (port 9093) ===" -ForegroundColor Green
docker run -d --name alertmanager --network monitoring-net -p 9093:9093 `
    -v "${configPath}\alertmanager.yml:/etc/alertmanager/alertmanager.yml:ro" `
    prom/alertmanager:latest --config.file=/etc/alertmanager/alertmanager.yml

Write-Host "=== Starting Grafana (HTTPS port 3000) ===" -ForegroundColor Green
if (Test-Path "${configPath}\grafana\provisioning") {
    Write-Host "  Using Grafana provisioning configuration" -ForegroundColor Cyan
    docker run -d --name grafana --network monitoring-net -p 3000:3000 `
        -e GF_INSTALL_PLUGINS=grafana-piechart-panel `
        -e GF_SERVER_PROTOCOL=https `
        -e GF_SERVER_CERT_FILE=/etc/grafana/grafana.crt `
        -e GF_SERVER_CERT_KEY=/etc/grafana/grafana.key `
        -v grafana-storage:/var/lib/grafana `
        -v "${configPath}\grafana\provisioning:/etc/grafana/provisioning:ro" `
        -v "$certPath\grafana.crt:/etc/grafana/grafana.crt:ro" `
        -v "$certPath\grafana.key:/etc/grafana/grafana.key:ro" `
        grafana/grafana:latest
} else {
    Write-Host "  Starting with default Grafana config" -ForegroundColor Yellow
    docker run -d --name grafana --network monitoring-net -p 3000:3000 `
        -e GF_INSTALL_PLUGINS=grafana-piechart-panel `
        -e GF_SERVER_PROTOCOL=https `
        -e GF_SERVER_CERT_FILE=/etc/grafana/grafana.crt `
        -e GF_SERVER_CERT_KEY=/etc/grafana/grafana.key `
        -v grafana-storage:/var/lib/grafana `
        -v "$certPath\grafana.crt:/etc/grafana/grafana.crt:ro" `
        -v "$certPath\grafana.key:/etc/grafana/grafana.key:ro" `
        grafana/grafana:latest
}

# --- Rest of the script remains unchanged, except final access URLs ---
Write-Host ""
Write-Host " Access your services at:" -ForegroundColor White
Write-Host "   Grafana Dashboard: https://localhost:3000 (admin/admin)" -ForegroundColor Yellow
Write-Host "   Prometheus:        http://localhost:9090" -ForegroundColor Yellow
Write-Host "   Alertmanager:      http://localhost:9093" -ForegroundColor Yellow
Write-Host "   SNMP Exporter:     http://localhost:9116" -ForegroundColor Yellow
Write-Host ""
Write-Host " Direct Monitoring URLs:" -ForegroundColor White
Write-Host "   Synology Metrics:  http://localhost:9116/snmp?module=synology&target=$synologyIP" -ForegroundColor Cyan
Write-Host "   Interface Metrics: http://localhost:9116/snmp?module=if_mib&target=$synologyIP" -ForegroundColor Cyan
