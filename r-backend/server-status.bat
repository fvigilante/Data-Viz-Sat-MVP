@echo off
REM R Backend Server Status Script for Windows
REM This script checks the status of the R Plumber API server

setlocal enabledelayedexpansion

REM Configuration
set PID_FILE=r-server.pid
set LOG_FILE=r-server.log
set DEFAULT_PORT=8001
set DEFAULT_HOST=127.0.0.1

REM Parse command line arguments
set PORT=%1
if "%PORT%"=="" set PORT=%DEFAULT_PORT%

set HOST=%2
if "%HOST%"=="" set HOST=%DEFAULT_HOST%

echo R Volcano Plot API Server Status Check
echo ======================================

REM Check if PID file exists
if not exist "%PID_FILE%" (
    echo [ERROR] PID file not found - server appears to be stopped
    exit /b 1
)

REM Read PID from file
set /p PID=<"%PID_FILE%"
echo [INFO] PID file found with process ID: %PID%

REM Check if process is running
tasklist /FI "PID eq %PID%" 2>nul | find /I "%PID%" >nul
if %errorlevel% neq 0 (
    echo [ERROR] Process with PID %PID% is not running
    echo [WARNING] Stale PID file detected - server may have crashed
    exit /b 1
)

echo [SUCCESS] Server process is running (PID: %PID%)

REM Get process information
for /f "tokens=1,2,3,4,5" %%a in ('tasklist /FI "PID eq %PID%" /FO CSV /NH 2^>nul') do (
    set PROCESS_NAME=%%a
    set PROCESS_PID=%%b
    set PROCESS_SESSION=%%c
    set PROCESS_SESSION_NUM=%%d
    set PROCESS_MEMORY=%%e
)

if defined PROCESS_NAME (
    echo [INFO] Process details: Name=%PROCESS_NAME%, Memory=%PROCESS_MEMORY%
)

REM Check server health via HTTP
set HEALTH_URL=http://%HOST%:%PORT%/health
echo [INFO] Checking server health at: %HEALTH_URL%

REM Use PowerShell to check HTTP health
powershell -Command "try { $response = Invoke-WebRequest -Uri '%HEALTH_URL%' -TimeoutSec 5 -UseBasicParsing; Write-Host '[SUCCESS] Server is responding to health checks'; Write-Host '[INFO] Health response:' $response.Content; exit 0 } catch { Write-Host '[ERROR] Server is not responding to health checks'; Write-Host '[WARNING] Process is running but HTTP endpoint is not accessible'; exit 1 }"

set HEALTH_STATUS=%errorlevel%

REM Check log file
if exist "%LOG_FILE%" (
    for %%F in ("%LOG_FILE%") do set LOG_SIZE=%%~zF
    for /f %%C in ('find /c /v "" ^< "%LOG_FILE%" 2^>nul') do set LOG_LINES=%%C
    echo [INFO] Log file: %LOG_FILE% (!LOG_SIZE! bytes, !LOG_LINES! lines)
    
    REM Show last few log entries
    if !LOG_LINES! gtr 0 (
        echo.
        echo Recent log entries:
        echo ===================
        powershell -Command "Get-Content '%LOG_FILE%' | Select-Object -Last 5"
    )
) else (
    echo [WARNING] Log file not found: %LOG_FILE%
)

REM Show server endpoints
echo.
echo Server Endpoints:
echo =================
echo Health Check:    http://%HOST%:%PORT%/health
echo Cache Status:    http://%HOST%:%PORT%/api/cache-status
echo Volcano Data:    http://%HOST%:%PORT%/api/volcano-data
echo Warm Cache:      http://%HOST%:%PORT%/api/warm-cache (POST)
echo Clear Cache:     http://%HOST%:%PORT%/api/clear-cache (POST)

REM Overall status
echo.
if %HEALTH_STATUS% equ 0 (
    echo [SUCCESS] Server is running and healthy
    exit /b 0
) else (
    echo [ERROR] Server has issues - check logs for details
    exit /b 1
)