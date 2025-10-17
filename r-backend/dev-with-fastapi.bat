@echo off
REM Development Script for Running R Backend alongside FastAPI for Windows
REM This script starts both the FastAPI server and R backend for development

setlocal enabledelayedexpansion

REM Configuration
set FASTAPI_PORT=8000
set R_PORT=8001
set FASTAPI_HOST=127.0.0.1
set R_HOST=127.0.0.1
set FASTAPI_DIR=..\api
set R_PID_FILE=r-server.pid
set FASTAPI_PID_FILE=fastapi-server.pid

echo [%date% %time%] Starting Development Environment with FastAPI + R Backend
echo ========================================================================

REM Check if required directories exist
if not exist "%FASTAPI_DIR%" (
    echo [ERROR] FastAPI directory not found: %FASTAPI_DIR%
    exit /b 1
)

REM Check if FastAPI main.py exists
if not exist "%FASTAPI_DIR%\main.py" (
    echo [ERROR] FastAPI main.py not found in %FASTAPI_DIR%
    exit /b 1
)

REM Check if R is available
Rscript --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] R is not installed or not in PATH
    exit /b 1
)

REM Function to check if port is in use (using netstat)
echo [%date% %time%] Checking if ports are available...
netstat -an | find ":%FASTAPI_PORT% " | find "LISTENING" >nul
if %errorlevel% equ 0 (
    echo [WARNING] FastAPI port %FASTAPI_PORT% is already in use
    exit /b 1
)

netstat -an | find ":%R_PORT% " | find "LISTENING" >nul
if %errorlevel% equ 0 (
    echo [WARNING] R Backend port %R_PORT% is already in use
    exit /b 1
)

REM Install R packages if needed
echo [%date% %time%] Checking R packages...
Rscript install-packages.R
if %errorlevel% neq 0 (
    echo [ERROR] Failed to install R packages
    exit /b 1
)

REM Start FastAPI server
echo [%date% %time%] Starting FastAPI server on port %FASTAPI_PORT%...
cd /d "%FASTAPI_DIR%"

REM Try different ways to start FastAPI
python -c "import uvicorn" >nul 2>&1
if %errorlevel% equ 0 (
    start /B python -m uvicorn main:app --host %FASTAPI_HOST% --port %FASTAPI_PORT% --reload > ..\r-backend\fastapi-server.log 2>&1
) else (
    start /B python main.py > ..\r-backend\fastapi-server.log 2>&1
)

REM Get FastAPI PID (this is complex in Windows batch, using PowerShell)
timeout /t 3 /nobreak >nul
for /f %%i in ('powershell -Command "Get-Process | Where-Object {$_.ProcessName -eq 'python' -and $_.CommandLine -like '*uvicorn*' -or $_.CommandLine -like '*main.py*'} | Select-Object -First 1 -ExpandProperty Id"') do set FASTAPI_PID=%%i

if defined FASTAPI_PID (
    echo !FASTAPI_PID! > "..\r-backend\%FASTAPI_PID_FILE%"
    echo [%date% %time%] FastAPI started with PID: !FASTAPI_PID!
) else (
    echo [ERROR] Failed to get FastAPI PID
)

cd /d "..\r-backend"

REM Wait for FastAPI to start
echo [%date% %time%] Waiting for FastAPI to start...
set /a elapsed=0
:wait_fastapi
if !elapsed! geq 30 (
    echo [ERROR] FastAPI failed to start within 30 seconds
    goto cleanup
)

powershell -Command "try { Invoke-WebRequest -Uri 'http://%FASTAPI_HOST%:%FASTAPI_PORT%/docs' -TimeoutSec 2 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] FastAPI is responding
    goto start_r
)

timeout /t 2 /nobreak >nul
set /a elapsed+=2
goto wait_fastapi

:start_r
REM Start R backend
echo [%date% %time%] Starting R backend on port %R_PORT%...
start /B Rscript plumber-api.R %R_PORT% %R_HOST% > r-server.log 2>&1

REM Get R PID
timeout /t 3 /nobreak >nul
for /f %%i in ('powershell -Command "Get-Process | Where-Object {$_.ProcessName -eq 'Rscript' -and $_.CommandLine -like '*plumber-api.R*'} | Select-Object -First 1 -ExpandProperty Id"') do set R_PID=%%i

if defined R_PID (
    echo !R_PID! > "%R_PID_FILE%"
    echo [%date% %time%] R Backend started with PID: !R_PID!
) else (
    echo [ERROR] Failed to get R Backend PID
)

REM Wait for R backend to start
echo [%date% %time%] Waiting for R backend to start...
set /a elapsed=0
:wait_r
if !elapsed! geq 30 (
    echo [ERROR] R Backend failed to start within 30 seconds
    goto cleanup
)

powershell -Command "try { Invoke-WebRequest -Uri 'http://%R_HOST%:%R_PORT%/health' -TimeoutSec 2 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] R Backend is responding
    goto show_status
)

timeout /t 2 /nobreak >nul
set /a elapsed+=2
goto wait_r

:show_status
REM Show status
echo [SUCCESS] Development environment is ready!
echo.
echo Services Running:
echo =================
echo FastAPI Server:  http://%FASTAPI_HOST%:%FASTAPI_PORT%
echo FastAPI Docs:    http://%FASTAPI_HOST%:%FASTAPI_PORT%/docs
echo R Backend:       http://%R_HOST%:%R_PORT%
echo R Health Check:  http://%R_HOST%:%R_PORT%/health
echo.
echo Log Files:
echo ==========
echo FastAPI:         fastapi-server.log
echo R Backend:       r-server.log
echo.
echo Press Ctrl+C to stop all services

REM Monitor processes
:monitor
timeout /t 5 /nobreak >nul

REM Check if FastAPI is still running
if defined FASTAPI_PID (
    tasklist /FI "PID eq !FASTAPI_PID!" 2>nul | find /I "!FASTAPI_PID!" >nul
    if !errorlevel! neq 0 (
        echo [ERROR] FastAPI server has stopped unexpectedly
        goto cleanup
    )
)

REM Check if R backend is still running
if defined R_PID (
    tasklist /FI "PID eq !R_PID!" 2>nul | find /I "!R_PID!" >nul
    if !errorlevel! neq 0 (
        echo [ERROR] R backend has stopped unexpectedly
        goto cleanup
    )
)

goto monitor

:cleanup
echo [%date% %time%] Shutting down services...

REM Stop R backend
if exist "%R_PID_FILE%" (
    set /p R_PID=<"%R_PID_FILE%"
    if defined R_PID (
        echo [%date% %time%] Stopping R backend (PID: !R_PID!)...
        taskkill /PID !R_PID! /T /F >nul 2>&1
    )
    del "%R_PID_FILE%" >nul 2>&1
)

REM Stop FastAPI
if exist "%FASTAPI_PID_FILE%" (
    set /p FASTAPI_PID=<"%FASTAPI_PID_FILE%"
    if defined FASTAPI_PID (
        echo [%date% %time%] Stopping FastAPI (PID: !FASTAPI_PID!)...
        taskkill /PID !FASTAPI_PID! /T /F >nul 2>&1
    )
    del "%FASTAPI_PID_FILE%" >nul 2>&1
)

echo [SUCCESS] Development environment stopped