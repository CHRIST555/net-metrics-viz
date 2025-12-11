# ===============================================
#  stop-monitoring.ps1
#  Stops monitoring containers safely
# ===============================================

Write-Host "=== Stopping Synology Monitoring Containers ===" -ForegroundColor Yellow

# -----------------------------------------------
# List of containers to stop
# -----------------------------------------------
$containers = @(
    "grafana",
    "prometheus",
    "alertmanager",
    "snmp-exporter"
)

# -----------------------------------------------
# Stop each container gracefully
# -----------------------------------------------
foreach ($c in $containers) {
    if ((docker ps -a -q -f name="^$c$") -ne $null) {
        Write-Host "Stopping $c..." -ForegroundColor Cyan
        docker stop $c 2>$null | Out-Null
        
        # Verify it stopped
        $status = docker ps -q -f name="^$c$"
        if ($status -eq $null) {
            Write-Host "$c stopped successfully." -ForegroundColor Green
        } else {
            Write-Host "$c may still be running - checking..." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            docker stop $c --time 10 2>$null | Out-Null
        }
    } else {
        Write-Host "$c is not running." -ForegroundColor DarkYellow
    }
}

# -----------------------------------------------
# Optional: Clean up stopped containers
# -----------------------------------------------
Write-Host ""
Write-Host "=== Cleaning up stopped containers ===" -ForegroundColor Cyan
foreach ($c in $containers) {
    if ((docker ps -a -q -f name="^$c$" -f status=exited) -ne $null) {
        Write-Host "Removing stopped container: $c" -ForegroundColor Gray
        docker rm $c 2>$null | Out-Null
    }
}

# -----------------------------------------------
# Show final status
# -----------------------------------------------
Write-Host ""
Write-Host "=== Final Container Status ===" -ForegroundColor Cyan
$runningContainers = docker ps --filter "network=monitoring-net" --format "{{.Names}}"
if ($runningContainers) {
    Write-Host "Still running on monitoring network:" -ForegroundColor Yellow
    $runningContainers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
} else {
    Write-Host "No containers running on monitoring network." -ForegroundColor Green
}

# -----------------------------------------------
# Optional: Network cleanup
# -----------------------------------------------
Write-Host ""
Write-Host "=== Network Cleanup (Optional) ===" -ForegroundColor Cyan
Write-Host "To remove the monitoring network, run:" -ForegroundColor Gray
Write-Host "  docker network rm monitoring-net" -ForegroundColor White
Write-Host ""
Write-Host "To remove volumes, run:" -ForegroundColor Gray
Write-Host "  docker volume rm prometheus-data grafana-storage" -ForegroundColor White

# -----------------------------------------------
# Done
# -----------------------------------------------
Write-Host ""
Write-Host "===============================================" -ForegroundColor Green
Write-Host " Synology monitoring stack has been stopped." -ForegroundColor Green
Write-Host "===============================================" -ForegroundColor Green
Write-Host ""
Write-Host "Services that were running:" -ForegroundColor White
Write-Host "  • Prometheus (metrics collection)" -ForegroundColor Gray
Write-Host "  • SNMP Exporter (Synology NAS monitoring)" -ForegroundColor Gray
Write-Host "  • Grafana (visualization)" -ForegroundColor Gray
Write-Host "  • Alertmanager (notifications)" -ForegroundColor Gray
Write-Host ""
Write-Host "To restart, run: .\start-monitoring.ps1" -ForegroundColor Cyan

