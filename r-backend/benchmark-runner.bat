@echo off
REM Windows batch script for running performance benchmarks

setlocal enabledelayedexpansion

echo R vs Python Volcano Plot Benchmark Runner
echo ==========================================

REM Set default environment variables if not already set
if not defined FASTAPI_URL set FASTAPI_URL=http://localhost:8000
if not defined R_API_URL set R_API_URL=http://localhost:8001

echo FastAPI URL: %FASTAPI_URL%
echo R API URL: %R_API_URL%
echo.

REM Check if R is available
where Rscript >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Rscript not found in PATH
    echo Please install R and ensure Rscript is available
    pause
    exit /b 1
)

REM Parse command line arguments
set COMMAND=%1
if "%COMMAND%"=="" set COMMAND=quick

if "%COMMAND%"=="quick" (
    echo Running quick benchmark...
    Rscript quick-benchmark.R
) else if "%COMMAND%"=="full" (
    echo Running comprehensive benchmark...
    set OUTPUT_FILE=benchmark_results_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%.rds
    set OUTPUT_FILE=!OUTPUT_FILE: =0!
    Rscript benchmark-framework.R run !OUTPUT_FILE!
) else if "%COMMAND%"=="health" (
    echo Checking API health...
    Rscript quick-benchmark.R health
) else if "%COMMAND%"=="report" (
    if "%2"=="" (
        echo Error: Please specify results file for report generation
        echo Usage: benchmark-runner.bat report results_file.rds
        pause
        exit /b 1
    )
    echo Generating report from %2...
    Rscript benchmark-framework.R report %2
) else (
    echo Usage: benchmark-runner.bat [quick^|full^|health^|report]
    echo.
    echo Commands:
    echo   quick  - Run quick benchmark ^(default^)
    echo   full   - Run comprehensive benchmark suite
    echo   health - Check API health status
    echo   report - Generate report from existing results
    echo.
    echo Examples:
    echo   benchmark-runner.bat quick
    echo   benchmark-runner.bat full
    echo   benchmark-runner.bat report benchmark_results.rds
    pause
    exit /b 1
)

if %errorlevel% neq 0 (
    echo.
    echo Benchmark failed with error code %errorlevel%
    pause
    exit /b %errorlevel%
)

echo.
echo Benchmark completed successfully!
pause