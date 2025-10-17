@echo off
REM R Backend Process Manager for Windows
REM Comprehensive process management for R backend with monitoring and auto-recovery

setlocal enabledelayedexpansion

REM Configuration
set SCRIPT_DIR=%~dp0
set PID_FILE=r-server.pid
set LOG_FILE=r-server.log
set MONITOR_LOG=process-manager.log
set CONFIG_FILE=server.conf
set DEFAULT_PORT=8001
set DEFAULT_HOST=127.0.0.1

REM Load configuration if available
if exist "%CONFIG_FILE%" (
    echo [%date% %time%] Loading configuration from %CONFIG_FILE%
    for /f "tokens=1,2 delims==" %%a in ('type "%CONFIG_FILE%" ^| findstr /v "^#" ^| findstr "="') do (
        set "%%a=%%b"
    )
)

REM Function to show usage
if "%1"=="" goto show_usage
if "%1"=="help" goto show_usage
if "%1"=="--help" goto show_usage
if "%1"=="-h" goto show_usage

REM Main command processing
if "%1"=="start" goto start_server
if "%1"=="stop" goto stop_server
if "%1"=="restart" goto restart_server
if "%1"=="status" goto show_status
if "%1"=="logs" goto show_logs
if "%1"=="dev" goto start_dev
if "%1"=="config" goto show_config
if "%1"=="cleanup" goto cleanup
goto unknown_command

:show_usage
echo R Backend Process Manager for Windows
echo =====================================
echo.
echo Usage: %0 ^<command^> [options]
echo.
echo Commands:
echo   start [port] [host] [daemon]  - Start the R backend server
echo   stop                          - Stop the R backend server
echo   restart [port] [host]         - Restart the R backend server
echo   status                        - Show server status
echo   logs [lines]                  - Show server logs
echo   dev                           - Start development environment
echo   config                        - Show current configuration
echo   cleanup                       - Clean up old logs and PID files
echo.
echo Examples:
echo   %0 start                      - Start server with defaults
echo   %0 start 8002 0.0.0.0 true    - Start on port 8002, all interfaces, daemon mode
echo   %0 logs 50                    - Show last 50 log lines
goto :eof

:is_running
if not exist "%PID_FILE%" (
    set IS_RUNNING=false
    goto :eof
)

set /p SERVER_PID=<"%PID_FILE%"
tasklist /FI "PID eq %SERVER_PID%" 2>nul | find /I "%SERVER_PID%" >nul
if %errorlevel% equ 0 (
    set IS_RUNNING=true
) else (
    set IS_RUNNING=false
)
goto :eof

:start_server
call :is_running
if "%IS_RUNNING%"=="true" (
    echo [WARNING] Server is already running
    call :get_server_info
    exit /b 1
)

set START_PORT=%2
if "%START_PORT%"=="" set START_PORT=%DEFAULT_PORT%

set START_HOST=%3
if "%START_HOST%"=="" set START_HOST=%DEFAULT_HOST%

set START_DAEMON=%4
if "%START_DAEMON%"=="" set START_DAEMON=true

echo [%date% %time%] Starting R backend server...
call start-server.bat %START_PORT% %START_HOST% %START_DAEMON%
if %errorlevel% equ 0 (
    echo [SUCCESS] Server started successfully
) else (
    echo [ERROR] Failed to start server
    exit /b 1
)
goto :eof

:stop_server
call :is_running
if "%IS_RUNNING%"=="false" (
    echo [WARNING] Server is not running
    exit /b 1
)

echo [%date% %time%] Stopping R backend server...
call stop-server.bat
if %errorlevel% equ 0 (
    echo [SUCCESS] Server stopped successfully
) else (
    echo [ERROR] Failed to stop server
    exit /b 1
)
goto :eof

:restart_server
set RESTART_PORT=%2
if "%RESTART_PORT%"=="" set RESTART_PORT=%DEFAULT_PORT%

set RESTART_HOST=%3
if "%RESTART_HOST%"=="" set RESTART_HOST=%DEFAULT_HOST%

echo [%date% %time%] Restarting R backend server...

call :is_running
if "%IS_RUNNING%"=="true" (
    call :stop_server
    timeout /t 2 /nobreak >nul
)

call :start_server "" %RESTART_PORT% %RESTART_HOST% true
goto :eof

:get_server_info
if exist "%PID_FILE%.info" (
    for /f "tokens=1,2 delims==" %%a in ('type "%PID_FILE%.info"') do (
        if "%%a"=="PID" set INFO_PID=%%b
        if "%%a"=="PORT" set INFO_PORT=%%b
        if "%%a"=="HOST" set INFO_HOST=%%b
        if "%%a"=="START_TIME" set INFO_START_TIME=%%b
    )
    echo Server Info: PID=%INFO_PID%, Port=%INFO_PORT%, Host=%INFO_HOST%, Started=%INFO_START_TIME%
) else (
    echo Server info not available
)
goto :eof

:show_status
echo R Backend Server Status
echo =======================

call :is_running
if "%IS_RUNNING%"=="true" (
    echo [SUCCESS] Server is running
    call :get_server_info
    echo.
    call server-status.bat
) else (
    echo [ERROR] Server is not running
    
    if exist "%PID_FILE%" (
        echo [WARNING] Stale PID file found: %PID_FILE%
    )
    
    if exist "%PID_FILE%.info" (
        echo [WARNING] Stale info file found: %PID_FILE%.info
    )
)
goto :eof

:show_logs
set LOG_LINES=%2
if "%LOG_LINES%"=="" set LOG_LINES=20

if exist "%LOG_FILE%" (
    echo Last %LOG_LINES% lines from %LOG_FILE%:
    echo =================================
    powershell -Command "Get-Content '%LOG_FILE%' | Select-Object -Last %LOG_LINES%"
) else (
    echo [WARNING] Log file not found: %LOG_FILE%
)

if exist "%MONITOR_LOG%" (
    echo.
    echo Last %LOG_LINES% lines from %MONITOR_LOG%:
    echo ====================================
    powershell -Command "Get-Content '%MONITOR_LOG%' | Select-Object -Last %LOG_LINES%"
)
goto :eof

:start_dev
echo [%date% %time%] Starting development environment...
call dev-with-fastapi.bat
goto :eof

:show_config
echo Current Configuration
echo ====================

if exist "%CONFIG_FILE%" (
    type "%CONFIG_FILE%"
) else (
    echo No configuration file found
    echo Default values:
    echo DEFAULT_PORT=8001
    echo DEFAULT_HOST=127.0.0.1
)
goto :eof

:cleanup
echo [%date% %time%] Cleaning up old files...

REM Remove stale PID files
call :is_running
if "%IS_RUNNING%"=="false" (
    if exist "%PID_FILE%" (
        del "%PID_FILE%" >nul 2>&1
        echo [%date% %time%] Removed stale PID file
    )
    
    if exist "%PID_FILE%.info" (
        del "%PID_FILE%.info" >nul 2>&1
        echo [%date% %time%] Removed stale info file
    )
)

REM Rotate logs if they're too large (>10MB)
for %%f in ("%LOG_FILE%" "%MONITOR_LOG%" "health-monitor.log" "server-metrics.log") do (
    if exist "%%f" (
        for %%s in ("%%f") do (
            if %%~zs gtr 10485760 (
                move "%%f" "%%f.old" >nul 2>&1
                echo. > "%%f"
                echo [%date% %time%] Rotated large log file: %%f
            )
        )
    )
)

echo [SUCCESS] Cleanup completed
goto :eof

:unknown_command
echo [ERROR] Unknown command: %1
echo.
goto show_usage

:eof