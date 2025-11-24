# ===============================================
#  stop-monitoring.ps1
#  Stops monitoring containers safely
# ===============================================

Write-Host "=== Stopping Monitoring Containers ===" -ForegroundColor Yellow

# -----------------------------------------------
# List of containers to stop
# -----------------------------------------------
$containers = @(
    "grafana",
    "prometheus",
    "alertmanager",
    "snmp-exporter",
    "test-monitor-ubuntu"
)

# -----------------------------------------------
# Stop each container
# -----------------------------------------------
foreach ($c in $containers) {
    if ((docker ps -a -q -f name="^$c$") -ne $null) {
        Write-Host "Stopping $c..." -ForegroundColor Cyan
        docker stop $c 2>$null | Out-Null
        Write-Host "$c stopped successfully." -ForegroundColor Green
    } else {
        Write-Host "$c is not running." -ForegroundColor DarkYellow
    }
}

# -----------------------------------------------
# Done
# -----------------------------------------------
Write-Host ""
Write-Host "==============================================="
Write-Host " All monitoring containers have been stopped."
Write-Host "===============================================" -ForegroundColor Green
