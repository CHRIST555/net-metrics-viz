@echo off
title Network Metrics Visualizer (NMV)
color 0A

:menu
cls
echo ===========================================
echo        Network Metrics Visualizer (NMV)
echo ===========================================
echo.
echo 1. Start Monitoring
echo 2. Stop Monitoring
echo 3. Exit
echo.
set /p choice=Enter your choice [1-3]: 

if "%choice%"=="1" goto start
if "%choice%"=="2" goto stop
if "%choice%"=="3" goto end

echo.
echo Invalid choice. Please try again.
pause
goto menu

:start
cls
echo ===========================================
echo       Starting Monitoring Stack...
echo ===========================================
echo.

REM Start PowerShell script to start monitoring
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-monitoring.ps1"

echo.
echo Monitoring stack started. Press Enter to return to menu...
pause
goto menu

:stop
cls
echo ===========================================
echo       Stopping Monitoring Stack...
echo ===========================================
echo.

REM Start PowerShell script to stop monitoring
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0stop-monitoring.ps1"

echo.
echo Monitoring stack stopped. Press Enter to return to menu...
pause
goto menu

:end
cls
echo ===========================================
echo                  Goodbye!
echo ===========================================
pause
exit
