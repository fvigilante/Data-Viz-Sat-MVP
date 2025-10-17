@echo off
REM Test script for R Backend Process Management (Windows)
REM This script tests the startup, monitoring, and shutdown capabilities

setlocal enabledelayedexpansion

REM Configuration
set TEST_PORT=8099
set TEST_HOST=127.0.0.1
set TEST_LOG=test-process-management.log

echo [%date% %time%] Starting R Backend Process Management Tests
echo ==========================================================

REM Function to cleanup test environment
:cleanup_test
echo [%date% %time%] TEST: Cleaning up test environment...

REM Stop any running test server
if exist "r-server.pid" (
    set /p TEST_PID=<"r-server.pid"
    tasklist /FI "PID eq !TEST_PID!" 2>nul | find /I "!TEST_PID!" >nul
    if !errorlevel! equ 0 (
        echo [%date% %time%] TEST: Stopping test server (PID: !TEST_PID!)...
        taskkill /PID !TEST_PID! /T /F >nul 2>&1
    )
    del "r-server.pid" >nul 2>&1
    del "r-server.pid.info" >nul 2>&1
)

REM Clean up test files
del "r-server.log" >nul 2>&1
del "server-shutdown.info" >nul 2>&1
del "server-metrics.log" >nul 2>&1

echo [%date% %time%] TEST: Test cleanup completed
goto :eof

REM Function to test server startup
:test_startup
echo [%date% %time%] TEST: Testing server startup...

call start-server.bat %TEST_PORT% %TEST_HOST% true
if %errorlevel% equ 0 (
    echo [SUCCESS] Server startup test passed
    
    REM Wait for server to initialize
    timeout /t 3 /nobreak >nul
    
    REM Test health check
    powershell -Command "try { Invoke-WebRequest -Uri 'http://%TEST_HOST%:%TEST_PORT%/health' -TimeoutSec 5 -UseBasicParsing | Out-Null; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Server health check test passed
        set STARTUP_SUCCESS=1
    ) else (
        echo [ERROR] Server health check test failed
        set STARTUP_SUCCESS=0
    )
) else (
    echo [ERROR] Server startup test failed
    set STARTUP_SUCCESS=0
)
goto :eof

REM Function to test server status
:test_status
echo [%date% %time%] TEST: Testing server status...

call server-status.bat %TEST_PORT% %TEST_HOST% >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Server status test passed
    set STATUS_SUCCESS=1
) else (
    echo [ERROR] Server status test failed
    set STATUS_SUCCESS=0
)
goto :eof

REM Function to test process manager
:test_process_manager
echo [%date% %time%] TEST: Testing process manager...

call process-manager.bat status >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Process manager status test passed
    
    call process-manager.bat logs 5 >nul 2>&1
    if !errorlevel! equ 0 (
        echo [SUCCESS] Process manager logs test passed
        set MANAGER_SUCCESS=1
    ) else (
        echo [ERROR] Process manager logs test failed
        set MANAGER_SUCCESS=0
    )
) else (
    echo [ERROR] Process manager status test failed
    set MANAGER_SUCCESS=0
)
goto :eof

REM Function to test graceful shutdown
:test_shutdown
echo [%date% %time%] TEST: Testing graceful shutdown...

call stop-server.bat
if %errorlevel% equ 0 (
    echo [SUCCESS] Server shutdown test passed
    
    if exist "server-shutdown.info" (
        echo [SUCCESS] Shutdown info file created successfully
        echo [%date% %time%] TEST: Shutdown info contents: >> "%TEST_LOG%"
        type "server-shutdown.info" >> "%TEST_LOG%"
    ) else (
        echo [WARNING] Shutdown info file not created
    )
    
    set SHUTDOWN_SUCCESS=1
) else (
    echo [ERROR] Server shutdown test failed
    set SHUTDOWN_SUCCESS=0
)
goto :eof

REM Function to test configuration
:test_configuration
echo [%date% %time%] TEST: Testing configuration management...

REM Create test configuration
(
    echo # Test configuration
    echo DEFAULT_PORT=%TEST_PORT%
    echo DEFAULT_HOST=%TEST_HOST%
    echo STARTUP_TIMEOUT=30
    echo R_LOG_LEVEL=DEBUG
) > "server.conf"

echo [SUCCESS] Test configuration created

call process-manager.bat config >nul 2>&1
if %errorlevel% equ 0 (
    echo [SUCCESS] Configuration loading test passed
    set CONFIG_SUCCESS=1
) else (
    echo [ERROR] Configuration loading test failed
    set CONFIG_SUCCESS=0
)
goto :eof

REM Main test execution
if "%1"=="cleanup" (
    call :cleanup_test
    goto :eof
)

REM Initialize test counters
set TESTS_PASSED=0
set TESTS_FAILED=0

REM Cleanup before starting
call :cleanup_test

REM Test 1: Configuration
echo [%date% %time%] TEST: Test 1: Configuration Management
call :test_configuration
if !CONFIG_SUCCESS! equ 1 (
    set /a TESTS_PASSED+=1
) else (
    set /a TESTS_FAILED+=1
)

REM Test 2: Startup
echo [%date% %time%] TEST: Test 2: Server Startup
call :test_startup
if !STARTUP_SUCCESS! equ 1 (
    set /a TESTS_PASSED+=1
) else (
    set /a TESTS_FAILED+=1
    call :cleanup_test
    goto test_summary
)

REM Test 3: Status
echo [%date% %time%] TEST: Test 3: Server Status
call :test_status
if !STATUS_SUCCESS! equ 1 (
    set /a TESTS_PASSED+=1
) else (
    set /a TESTS_FAILED+=1
)

REM Test 4: Process Manager
echo [%date% %time%] TEST: Test 4: Process Manager
call :test_process_manager
if !MANAGER_SUCCESS! equ 1 (
    set /a TESTS_PASSED+=1
) else (
    set /a TESTS_FAILED+=1
)

REM Test 5: Shutdown
echo [%date% %time%] TEST: Test 5: Graceful Shutdown
call :test_shutdown
if !SHUTDOWN_SUCCESS! equ 1 (
    set /a TESTS_PASSED+=1
) else (
    set /a TESTS_FAILED+=1
)

REM Cleanup after tests
call :cleanup_test

:test_summary
REM Summary
echo [%date% %time%] TEST: Test Results Summary
echo [%date% %time%] TEST: ===================
echo [%date% %time%] TEST: Tests passed: !TESTS_PASSED!
echo [%date% %time%] TEST: Tests failed: !TESTS_FAILED!

if !TESTS_FAILED! equ 0 (
    echo [SUCCESS] All tests passed!
    exit /b 0
) else (
    echo [ERROR] Some tests failed. Check %TEST_LOG% for details.
    exit /b 1
)