#!/bin/bash

# Development Script for Running R Backend alongside FastAPI
# This script starts both the FastAPI server and R backend for development

set -e

# Configuration
FASTAPI_PORT=8000
R_PORT=8001
FASTAPI_HOST="127.0.0.1"
R_HOST="127.0.0.1"
FASTAPI_DIR="../api"
R_PID_FILE="r-server.pid"
FASTAPI_PID_FILE="fastapi-server.pid"
DEV_LOG="dev-environment.log"
MONITOR_INTERVAL=5
HEALTH_CHECK_INTERVAL=30

# Load configuration if available
CONFIG_FILE="server.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    log "Loaded configuration from $CONFIG_FILE"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if port is in use
check_port() {
    local port=$1
    local service=$2
    
    if command -v lsof &> /dev/null; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
            warning "$service port $port is already in use"
            return 1
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -ln | grep ":$port " >/dev/null 2>&1; then
            warning "$service port $port is already in use"
            return 1
        fi
    fi
    return 0
}

# Function to wait for service startup
wait_for_service() {
    local host=$1
    local port=$2
    local service=$3
    local timeout=${4:-30}
    local endpoint=${5:-""}
    
    local url="http://$host:$port$endpoint"
    local elapsed=0
    
    log "Waiting for $service to start at $url (timeout: ${timeout}s)..."
    
    while [ $elapsed -lt $timeout ]; do
        if command -v curl &> /dev/null; then
            if curl -s --max-time 2 "$url" > /dev/null 2>&1; then
                success "$service is responding"
                return 0
            fi
        elif command -v wget &> /dev/null; then
            if wget -q --timeout=2 -O /dev/null "$url" > /dev/null 2>&1; then
                success "$service is responding"
                return 0
            fi
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
        echo -n "."
    done
    
    echo ""
    error "$service failed to start within ${timeout} seconds"
    return 1
}

# Function to cleanup processes on exit
cleanup() {
    log "Shutting down services..."
    
    # Stop R backend
    if [ -f "$R_PID_FILE" ]; then
        R_PID=$(cat "$R_PID_FILE")
        if kill -0 "$R_PID" 2>/dev/null; then
            log "Stopping R backend (PID: $R_PID)..."
            kill -TERM "$R_PID" 2>/dev/null || true
            sleep 2
            kill -0 "$R_PID" 2>/dev/null && kill -KILL "$R_PID" 2>/dev/null || true
        fi
        rm -f "$R_PID_FILE"
    fi
    
    # Stop FastAPI
    if [ -f "$FASTAPI_PID_FILE" ]; then
        FASTAPI_PID=$(cat "$FASTAPI_PID_FILE")
        if kill -0 "$FASTAPI_PID" 2>/dev/null; then
            log "Stopping FastAPI (PID: $FASTAPI_PID)..."
            kill -TERM "$FASTAPI_PID" 2>/dev/null || true
            sleep 2
            kill -0 "$FASTAPI_PID" 2>/dev/null && kill -KILL "$FASTAPI_PID" 2>/dev/null || true
        fi
        rm -f "$FASTAPI_PID_FILE"
    fi
    
    success "Development environment stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

log "Starting Development Environment with FastAPI + R Backend"
log "========================================================"

# Check if required directories exist
if [ ! -d "$FASTAPI_DIR" ]; then
    error "FastAPI directory not found: $FASTAPI_DIR"
    exit 1
fi

# Check if ports are available
check_port $FASTAPI_PORT "FastAPI" || exit 1
check_port $R_PORT "R Backend" || exit 1

# Check if Python/FastAPI is available
if [ ! -f "$FASTAPI_DIR/main.py" ]; then
    error "FastAPI main.py not found in $FASTAPI_DIR"
    exit 1
fi

# Check if R is available
if ! command -v Rscript &> /dev/null; then
    error "R is not installed or not in PATH"
    exit 1
fi

# Install R packages if needed
log "Checking R packages..."
if ! Rscript install-packages.R; then
    error "Failed to install R packages"
    exit 1
fi

# Start FastAPI server
log "Starting FastAPI server on port $FASTAPI_PORT..."
cd "$FASTAPI_DIR"

# Check if we should use uvicorn or python directly
if command -v uvicorn &> /dev/null; then
    uvicorn main:app --host $FASTAPI_HOST --port $FASTAPI_PORT --reload > ../r-backend/fastapi-server.log 2>&1 &
elif python3 -c "import uvicorn" 2>/dev/null; then
    python3 -m uvicorn main:app --host $FASTAPI_HOST --port $FASTAPI_PORT --reload > ../r-backend/fastapi-server.log 2>&1 &
else
    python3 main.py > ../r-backend/fastapi-server.log 2>&1 &
fi

FASTAPI_PID=$!
echo $FASTAPI_PID > "../r-backend/$FASTAPI_PID_FILE"
cd - > /dev/null

# Wait for FastAPI to start
if ! wait_for_service $FASTAPI_HOST $FASTAPI_PORT "FastAPI" 30 "/docs"; then
    error "Failed to start FastAPI server"
    cleanup
    exit 1
fi

# Start R backend
log "Starting R backend on port $R_PORT..."
Rscript plumber-api.R $R_PORT $R_HOST > r-server.log 2>&1 &
R_PID=$!
echo $R_PID > "$R_PID_FILE"

# Wait for R backend to start
if ! wait_for_service $R_HOST $R_PORT "R Backend" 30 "/health"; then
    error "Failed to start R backend"
    cleanup
    exit 1
fi

# Show status
success "Development environment is ready!"
echo ""
echo "Services Running:"
echo "================="
echo "FastAPI Server:  http://$FASTAPI_HOST:$FASTAPI_PORT"
echo "FastAPI Docs:    http://$FASTAPI_HOST:$FASTAPI_PORT/docs"
echo "R Backend:       http://$R_HOST:$R_PORT"
echo "R Health Check:  http://$R_HOST:$R_PORT/health"
echo ""
echo "Log Files:"
echo "=========="
echo "FastAPI:         fastapi-server.log"
echo "R Backend:       r-server.log"
echo ""
echo "Press Ctrl+C to stop all services"

# Enhanced process monitoring with health checks
monitor_count=0
last_health_check=0

while true; do
    current_time=$(date +%s)
    
    # Check if FastAPI is still running
    if ! kill -0 "$FASTAPI_PID" 2>/dev/null; then
        error "FastAPI server has stopped unexpectedly"
        log "FastAPI log tail:"
        tail -n 10 "fastapi-server.log" 2>/dev/null || echo "No log available"
        cleanup
        exit 1
    fi
    
    # Check if R backend is still running
    if ! kill -0 "$R_PID" 2>/dev/null; then
        error "R backend has stopped unexpectedly"
        log "R backend log tail:"
        tail -n 10 "r-server.log" 2>/dev/null || echo "No log available"
        cleanup
        exit 1
    fi
    
    # Perform health checks periodically
    if [ $((current_time - last_health_check)) -ge $HEALTH_CHECK_INTERVAL ]; then
        log "Performing health checks..."
        
        # Check FastAPI health
        if command -v curl &> /dev/null; then
            if curl -s --max-time 3 "http://$FASTAPI_HOST:$FASTAPI_PORT/docs" > /dev/null 2>&1; then
                log "FastAPI health: OK"
            else
                warning "FastAPI health check failed"
            fi
            
            # Check R backend health
            if curl -s --max-time 3 "http://$R_HOST:$R_PORT/health" > /dev/null 2>&1; then
                log "R Backend health: OK"
            else
                warning "R Backend health check failed"
            fi
        fi
        
        last_health_check=$current_time
    fi
    
    # Log periodic status
    monitor_count=$((monitor_count + 1))
    if [ $((monitor_count % 12)) -eq 0 ]; then  # Every minute (5s * 12)
        log "Development environment running (FastAPI PID: $FASTAPI_PID, R PID: $R_PID)"
        
        # Log process stats if available
        if command -v ps &> /dev/null; then
            FASTAPI_STATS=$(ps -p "$FASTAPI_PID" -o pcpu,pmem --no-headers 2>/dev/null | tr -s ' ')
            R_STATS=$(ps -p "$R_PID" -o pcpu,pmem --no-headers 2>/dev/null | tr -s ' ')
            
            if [ -n "$FASTAPI_STATS" ]; then
                log "FastAPI stats: CPU/MEM $FASTAPI_STATS"
            fi
            if [ -n "$R_STATS" ]; then
                log "R Backend stats: CPU/MEM $R_STATS"
            fi
        fi
    fi
    
    sleep $MONITOR_INTERVAL
done