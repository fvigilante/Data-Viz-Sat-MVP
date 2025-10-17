#!/bin/bash

# Unix shell script for running performance benchmarks

set -e

echo "R vs Python Volcano Plot Benchmark Runner"
echo "=========================================="

# Set default environment variables if not already set
export FASTAPI_URL=${FASTAPI_URL:-"http://localhost:8000"}
export R_API_URL=${R_API_URL:-"http://localhost:8001"}

echo "FastAPI URL: $FASTAPI_URL"
echo "R API URL: $R_API_URL"
echo

# Check if R is available
if ! command -v Rscript &> /dev/null; then
    echo "Error: Rscript not found in PATH"
    echo "Please install R and ensure Rscript is available"
    exit 1
fi

# Parse command line arguments
COMMAND=${1:-quick}

case $COMMAND in
    "quick")
        echo "Running quick benchmark..."
        Rscript quick-benchmark.R
        ;;
    "full")
        echo "Running comprehensive benchmark..."
        OUTPUT_FILE="benchmark_results_$(date +%Y%m%d_%H%M%S).rds"
        Rscript benchmark-framework.R run "$OUTPUT_FILE"
        ;;
    "health")
        echo "Checking API health..."
        Rscript quick-benchmark.R health
        ;;
    "report")
        if [ -z "$2" ]; then
            echo "Error: Please specify results file for report generation"
            echo "Usage: $0 report results_file.rds"
            exit 1
        fi
        echo "Generating report from $2..."
        Rscript benchmark-framework.R report "$2"
        ;;
    *)
        echo "Usage: $0 [quick|full|health|report]"
        echo
        echo "Commands:"
        echo "  quick  - Run quick benchmark (default)"
        echo "  full   - Run comprehensive benchmark suite"
        echo "  health - Check API health status"
        echo "  report - Generate report from existing results"
        echo
        echo "Examples:"
        echo "  $0 quick"
        echo "  $0 full"
        echo "  $0 report benchmark_results.rds"
        exit 1
        ;;
esac

echo
echo "Benchmark completed successfully!"