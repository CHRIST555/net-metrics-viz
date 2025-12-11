@echo off
title Network Metrics Visualizer (NMV)
color 0A

:menu
cls
echo ===========================================
echo        Network Metrics Visualizer (NMV)
echo ===========================================
echo.
echo       Synology NAS Monitoring Edition
echo       Disk MIB Integration Enabled
echo ===========================================
echo.
echo 1. Start Monitoring
echo 2. Stop Monitoring  
echo 3. View Service URLs
echo 4. Check NAS Status
echo 5. View Container Logs
echo 6. Restart Monitoring
echo 7. Clean Everything
echo 8. Exit
echo.
set /p choice=Enter your choice [1-8]: 

if "%choice%"=="1" goto start
if "%choice%"=="2" goto stop
if "%choice%"=="3" goto urls
if "%choice%"=="4" goto status
if "%choice%"=="5" goto logs
if "%choice%"=="6" goto restart
if "%choice%"=="7" goto clean
if "%choice%"=="8" goto end

echo.
echo Invalid choice. Please try again.
pause
goto menu

:start
cls
echo ===========================================
echo    Starting NMV Monitoring Stack...
echo ===========================================
echo.
echo Synology NAS Monitoring Features:
echo  * Disk Status Monitoring (MIB .1.3.6.1.4.1.6574.2)
echo  * Temperature Monitoring
echo  * System Health Checks
echo  * Network Interface Monitoring
echo  * Storage I/O Performance
echo  * Fan Status Monitoring
echo.
echo Starting services, please wait...
echo.

REM Check if Docker is running
docker version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker is not running or not installed!
    echo Please start Docker Desktop and try again.
    pause
    goto menu
)

REM Start PowerShell script to start monitoring
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-monitoring.ps1"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo NMV monitoring stack started successfully!
    echo ========================================
    echo.
    echo Quick Access:
    echo  - Grafana: https://localhost:3000
    echo  - Prometheus: http://localhost:9090
    echo.
) else (
    echo.
    echo ERROR: Failed to start monitoring stack!
    echo Check the logs above for details.
)
echo Press Enter to return to menu...
pause
goto menu

:stop
cls
echo ===========================================
echo       Stopping NMV Stack...
echo ===========================================
echo.

REM Start PowerShell script to stop monitoring
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-monitoring.ps1"

echo.
echo NMV monitoring stack stopped.
echo Press Enter to return to menu...
pause
goto menu

:urls
cls
echo ===========================================
echo        NMV Service Access URLs
echo ===========================================
echo.
echo Monitoring Services:
echo  * Grafana Dashboard:  https://localhost:3000
echo    Username: admin / Password: admin
echo    (Default dashboard includes Synology metrics)
echo.
echo  * Prometheus:         http://localhost:9090
echo    (Raw metrics and query interface)
echo.
echo  * Alertmanager:       http://localhost:9093
echo    (Alert management and notifications)
echo.
echo  * SNMP Exporter:      http://localhost:9116
echo    (SNMP metrics collection service)
echo.
echo Direct SNMP Queries:
echo  * Synology NAS:       http://localhost:9116/snmp?module=synology^&target=192.168.12.248
echo  * Network Interfaces: http://localhost:9116/snmp?module=if_mib^&target=192.168.12.248
echo.
echo Monitored Metrics:
echo  * Disk Status: Real-time disk health monitoring
echo  * Temperature: System and disk temperature tracking  
echo  * Network: Interface status and throughput
echo  * Storage I/O: Read/write performance metrics
echo  * System Health: Overall NAS status monitoring
echo  * Hardware: Fan status and system alerts
echo.
echo Press Enter to return to menu...
pause
goto menu

:status
cls
echo ===========================================
echo       NMV Status Check...
echo ===========================================
echo.

REM Check Docker status
echo [1/4] Checking Docker status...
docker version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Docker is not running!
    goto status_end
)
echo Docker: RUNNING

echo.
echo [2/4] Checking NMV Docker containers...
docker ps --filter "network=monitoring-net" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo No containers found on monitoring network.
)

echo.
echo [3/4] Testing SNMP Exporter connectivity...
powershell -Command "try { $result = Invoke-WebRequest -Uri 'http://localhost:9116/' -TimeoutSec 5 -UseBasicParsing; if($result.StatusCode -eq 200) { Write-Host 'SNMP Exporter: ACCESSIBLE' -ForegroundColor Green } else { Write-Host 'SNMP Exporter: FAILED' -ForegroundColor Red } } catch { Write-Host 'SNMP Exporter: NOT RUNNING' -ForegroundColor Red }"

echo.
echo [4/4] Testing Synology NAS connectivity (192.168.12.248)...
powershell -Command "try { $result = Invoke-WebRequest -Uri 'http://localhost:9116/snmp?module=synology&target=192.168.12.248' -TimeoutSec 5 -UseBasicParsing; if($result.StatusCode -eq 200) { Write-Host 'Synology NAS: ACCESSIBLE' -ForegroundColor Green } else { Write-Host 'Synology NAS: FAILED' -ForegroundColor Red } } catch { Write-Host 'Synology NAS: UNREACHABLE' -ForegroundColor Red }"

:status_end
echo.
echo Status check complete.
echo Press Enter to return to menu...
pause
goto menu

:logs
cls
echo ===========================================
echo       Container Logs Viewer
echo ===========================================
echo.
echo Select container to view logs:
echo 1. Prometheus
echo 2. SNMP Exporter  
echo 3. Grafana
echo 4. Alertmanager
echo 5. All containers (brief)
echo 6. Return to main menu
echo.
set /p logchoice=Enter your choice [1-6]: 

if "%logchoice%"=="1" (
    echo.
    echo === Prometheus Logs ===
    docker logs prometheus --tail 20
)
if "%logchoice%"=="2" (
    echo.
    echo === SNMP Exporter Logs ===
    docker logs snmp-exporter --tail 20
)
if "%logchoice%"=="3" (
    echo.
    echo === Grafana Logs ===
    docker logs grafana --tail 20
)
if "%logchoice%"=="4" (
    echo.
    echo === Alertmanager Logs ===
    docker logs alertmanager --tail 20
)
if "%logchoice%"=="5" (
    echo.
    echo === All Container Status ===
    docker ps --filter "network=monitoring-net" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
    echo.
    echo Recent errors from all containers:
    docker logs prometheus --tail 5 2>&1 | findstr -i "error\|warn\|fail" 
    docker logs snmp-exporter --tail 5 2>&1 | findstr -i "error\|warn\|fail"
    docker logs grafana --tail 5 2>&1 | findstr -i "error\|warn\|fail"
    docker logs alertmanager --tail 5 2>&1 | findstr -i "error\|warn\|fail"
)
if "%logchoice%"=="6" goto menu

echo.
echo Press Enter to return to logs menu...
pause
goto logs

:restart
cls
echo ===========================================
echo       Restarting NMV Stack...
echo ===========================================
echo.
echo This will stop and restart all monitoring services.
echo.
set /p confirm=Continue? (Y/N): 
if /i not "%confirm%"=="Y" goto menu

echo.
echo Step 1: Stopping services...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-monitoring.ps1"

echo.
echo Step 2: Waiting for cleanup...
timeout /t 5 >nul

echo.
echo Step 3: Starting services...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-monitoring.ps1"

echo.
echo Restart complete!
echo Press Enter to return to menu...
pause
goto menu

:clean
cls
echo ===========================================
echo       Clean Everything
echo ===========================================
echo.
echo WARNING: This will remove:
echo  * All monitoring containers
echo  * All monitoring volumes (data loss!)
echo  * Monitoring network
echo  * Generated configuration files
echo.
set /p confirm=Are you sure? This cannot be undone! (Y/N): 
if /i not "%confirm%"=="Y" goto menu

echo.
echo Stopping and removing containers...
docker stop grafana prometheus snmp-exporter alertmanager 2>nul
docker rm grafana prometheus snmp-exporter alertmanager 2>nul

echo Removing volumes...
docker volume rm prometheus-data grafana-storage 2>nul

echo Removing network...
docker network rm monitoring-net 2>nul

echo Removing generated files...
if exist "%~dp0snmp.yml" del "%~dp0snmp.yml"

echo.
echo Clean complete! All monitoring components removed.
echo Press Enter to return to menu...
pause
goto menu

:end
cls
echo ===========================================
echo        Network Metrics Visualizer (NMV)
echo ===========================================
echo.
echo Thank you for using NMV!
echo.
echo Your Synology NAS monitoring capabilities:
echo  + Disk Health Monitoring (MIB .1.3.6.1.4.1.6574.2)
echo  + Temperature Tracking  
echo  + System Status Alerts
echo  + Network Performance Analysis
echo  + Storage I/O Metrics
echo  + Hardware Health Monitoring
echo.
echo For support or issues:
echo  - Check container logs via option 5
echo  - Visit https://localhost:3000 for Grafana dashboard
echo  - Use option 4 to verify NAS connectivity
echo.
echo                Goodbye!
echo ===========================================
pause
exit

