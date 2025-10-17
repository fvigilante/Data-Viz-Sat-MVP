@echo off
REM R Backend Server Startup Script with Process Management for Windows
REM This script starts the R Plumber API server for volcano plot processing

setlocal enabledelayedexpansion

REM Configuration
set DEFAULT_PORT=8001
set DEFAULT_HOST=127.0.0.1
set PID_FILE=r-server.pid
set LOG_FILE=r-server.log
set HEALTH_CHECK_TIMEOUT=30
set STARTUP_TIMEOUT=60
set CONFIG_FILE=server.conf
set SHUTDOWN_TIMEOUT=30

REM Load configuration from file if it exists (Windows style)
if exist "%CONFIG_FILE%" (
    echo [%date% %time%] Loading configuration from %CONFIG_FILE%
    REM Note: Windows batch doesn't have source, so we'll use a simple approach
    for /f "tokens=1,2 delims==" %%a in ('type "%CONFIG_FILE%" ^| findstr /v "^#" ^| findstr "="') do (
        set "%%a=%%b"
    )
)

REM Parse command line arguments with validation
set PORT=%1
if "%PORT%"=="" set PORT=%DEFAULT_PORT%

set HOST=%2
if "%HOST%"=="" set HOST=%DEFAULT_HOST%

set DAEMON_MODE=%3
if "%DAEMON_MODE%"=="" set DAEMON_MODE=false

REM Validate port range
if %PORT% LSS 1024 (
    echo [ERROR] Invalid port: %PORT%. Must be between 1024 and 65535
    exit /b 1
)
if %PORT% GTR 65535 (
    echo [ERROR] Invalid port: %PORT%. Must be between 1024 and 65535
    exit /b 1
)

REM Create configuration file if it doesn't exist
if not exist "%CONFIG_FILE%" (
    echo [%date% %time%] Creating default configuration file: %CONFIG_FILE%
    (
        echo # R Backend Server Configuration
        echo # This file is loaded by start-server.bat
        echo.
        echo DEFAULT_PORT=8001
        echo DEFAULT_HOST=127.0.0.1
        echo STARTUP_TIMEOUT=60
        echo HEALTH_CHECK_TIMEOUT=30
        echo SHUTDOWN_TIMEOUT=30
        echo LOG_FILE=r-server.log
        echo R_LOG_LEVEL=INFO
        echo R_MAX_MEMORY=2G
        echo R_THREADS=4
    ) > "%CONFIG_FILE%"
    echo [SUCCESS] Configuration file created: %CONFIG_FILE%
)

echo [%date% %time%] Starting R Volcano Plot API Server...
echo [%date% %time%] Configuration: Host=%HOST%, Port=%PORT%, Daemon=%DAEMON_MODE%

REM Check if R is installed
Rscript --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] R is not installed or not in PATH
    echo [ERROR] Please install R from https://www.r-project.org/
    exit /b 1
)

REM Check R version
for /f "tokens=*" %%i in ('Rscript --version 2^>^&1') do set R_VERSION=%%i
echo [%date% %time%] R Version: %R_VERSION%

REM Check if server is already running
if exist "%PID_FILE%" (
    set /p OLD_PID=<"%PID_FILE%"
    tasklist /FI "PID eq !OLD_PID!" 2>nul | find /I "!OLD_PID!" >nul
    if !errorlevel! equ 0 (
        echo [WARNING] Server is already running with PID !OLD_PID!
        echo [WARNING] Use 'stop-server.bat' to stop the existing server first
        exit /b 1
    ) else (
        echo [WARNING] Stale PID file found, removing...
        del "%PID_FILE%" >nul 2>&1
    )
)

REM Install/check required packages
echo [%date% %time%] Installing/checking required packages...
Rscript install-packages.R

if %errorlevel% neq 0 (
    echo [ERROR] Failed to install R packages
    exit /b 1
)

REM Set environment variables for R server
if "%R_LOG_LEVEL%"=="" set R_LOG_LEVEL=INFO
if "%R_LOG_FILE%"=="" set R_LOG_FILE=%LOG_FILE%

REM Function to check server health (using PowerShell)
set HEALTH_CHECK_CMD=powershell -Command "try { $response = Invoke-WebRequest -Uri 'http://%HOST%:%PORT%/health' -TimeoutSec 5 -UseBasicParsing; exit 0 } catch { exit 1 }"

echo [%date% %time%] Starting Plumber API server...
echo [%date% %time%] Server will be available at: http://%HOST%:%PORT%
echo [%date% %time%] Health check endpoint: http://%HOST%:%PORT%/health
echo [%date% %time%] Log file: %LOG_FILE%

if "%DAEMON_MODE%"=="true" (
    REM Start in daemon mode (background)
    echo [%date% %time%] Starting server in daemon mode...
    start /B Rscript plumber-api.R %PORT% %HOST% > %LOG_FILE% 2>&1
    
    REM Get the PID (this is tricky in Windows batch, using PowerShell)
    for /f %%i in ('powershell -Command "Get-Process | Where-Object {$_.ProcessName -eq 'Rscript' -and $_.CommandLine -like '*plumber-api.R*'} | Select-Object -First 1 -ExpandProperty Id"') do set SERVER_PID=%%i
    echo !SERVER_PID! > "%PID_FILE%"
    
    REM Wait for startup
    echo [%date% %time%] Waiting for server to start (timeout: %STARTUP_TIMEOUT%s)...
    set /a elapsed=0
    :wait_loop
    if !elapsed! geq %STARTUP_TIMEOUT% (
        echo [ERROR] Server failed to start within %STARTUP_TIMEOUT% seconds
        del "%PID_FILE%" >nul 2>&1
        exit /b 1
    )
    
    %HEALTH_CHECK_CMD% >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Server started successfully in daemon mode (PID: !SERVER_PID!)
        echo [%date% %time%] Use 'stop-server.bat' to stop the server
        echo [%date% %time%] Use 'type %LOG_FILE%' to view logs
        goto :eof
    )
    
    timeout /t 2 /nobreak >nul
    set /a elapsed+=2
    goto wait_loop
    
) else (
    REM Start in foreground mode
    echo [%date% %time%] Starting server in foreground mode (Ctrl+C to stop)...
    
    REM Create a temporary batch file to capture PID
    echo @echo off > temp_start.bat
    echo Rscript plumber-api.R %PORT% %HOST% >> temp_start.bat
    
    start /B temp_start.bat
    
    REM Get PID and clean up temp file
    for /f %%i in ('powershell -Command "Get-Process | Where-Object {$_.ProcessName -eq 'Rscript' -and $_.CommandLine -like '*plumber-api.R*'} | Select-Object -First 1 -ExpandProperty Id"') do set SERVER_PID=%%i
    echo !SERVER_PID! > "%PID_FILE%"
    del temp_start.bat >nul 2>&1
    
    REM Wait for startup
    echo [%date% %time%] Waiting for server to start...
    set /a elapsed=0
    :wait_loop_fg
    if !elapsed! geq %STARTUP_TIMEOUT% (
        echo [ERROR] Server failed to start within %STARTUP_TIMEOUT% seconds
        del "%PID_FILE%" >nul 2>&1
        exit /b 1
    )
    
    %HEALTH_CHECK_CMD% >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Server started successfully (PID: !SERVER_PID!)
        echo [%date% %time%] Press Ctrl+C to stop the server
        goto wait_for_process
    )
    
    timeout /t 2 /nobreak >nul
    set /a elapsed+=2
    goto wait_loop_fg
    
    :wait_for_process
    REM Wait for the process to finish
    :process_wait
    tasklist /FI "PID eq !SERVER_PID!" 2>nul | find /I "!SERVER_PID!" >nul
    if !errorlevel! equ 0 (
        timeout /t 1 /nobreak >nul
        goto process_wait
    )
    
    echo [%date% %time%] Server process has stopped
    del "%PID_FILE%" >nul 2>&1
)