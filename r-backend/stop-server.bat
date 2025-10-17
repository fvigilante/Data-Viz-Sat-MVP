@echo off
REM R Backend Server Stop Script for Windows
REM This script gracefully stops the R Plumber API server

setlocal enabledelayedexpansion

REM Configuration
set PID_FILE=r-server.pid
set LOG_FILE=r-server.log
set SHUTDOWN_TIMEOUT=30

echo [%date% %time%] Stopping R Volcano Plot API Server...

REM Check if PID file exists
if not exist "%PID_FILE%" (
    echo [WARNING] PID file not found. Server may not be running.
    exit /b 0
)

REM Read PID from file
set /p PID=<"%PID_FILE%"

REM Check if process is actually running
tasklist /FI "PID eq %PID%" 2>nul | find /I "%PID%" >nul
if %errorlevel% neq 0 (
    echo [WARNING] Process with PID %PID% is not running
    del "%PID_FILE%" >nul 2>&1
    echo [SUCCESS] Cleaned up stale PID file
    exit /b 0
)

echo [%date% %time%] Found running server process (PID: %PID%)

REM Send termination signal (Windows doesn't have SIGTERM, so we use taskkill)
echo [%date% %time%] Sending termination signal for graceful shutdown...
taskkill /PID %PID% /T >nul 2>&1

REM Wait for graceful shutdown
echo [%date% %time%] Waiting for process to terminate (timeout: %SHUTDOWN_TIMEOUT%s)...
set /a elapsed=0

:wait_loop
if !elapsed! geq %SHUTDOWN_TIMEOUT% (
    echo [WARNING] Process did not terminate gracefully within %SHUTDOWN_TIMEOUT% seconds
    echo [%date% %time%] Forcing termination...
    taskkill /F /PID %PID% /T >nul 2>&1
    
    REM Wait a bit more
    timeout /t 2 /nobreak >nul
    
    tasklist /FI "PID eq %PID%" 2>nul | find /I "%PID%" >nul
    if !errorlevel! equ 0 (
        echo [ERROR] Failed to terminate process %PID%
        exit /b 1
    ) else (
        echo [WARNING] Process forcefully terminated
    )
    goto cleanup
)

REM Check if process is still running
tasklist /FI "PID eq %PID%" 2>nul | find /I "%PID%" >nul
if !errorlevel! neq 0 (
    echo [SUCCESS] Server stopped gracefully
    goto cleanup
)

timeout /t 1 /nobreak >nul
set /a elapsed+=1
goto wait_loop

:cleanup
REM Clean up PID file
del "%PID_FILE%" >nul 2>&1
echo [SUCCESS] PID file cleaned up

REM Show final status
echo [%date% %time%] Server shutdown complete
if exist "%LOG_FILE%" (
    echo [%date% %time%] Log file preserved at: %LOG_FILE%
)