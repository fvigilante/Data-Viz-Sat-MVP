#!/bin/bash

# R Backend Server Startup Script with Process Management
# This script starts the R Plumber API server for volcano plot processing

set -e  # Exit on any error

# Configuration
DEFAULT_PORT=8001
DEFAULT_HOST="127.0.0.1"
PID_FILE="r-server.pid"
LOG_FILE="r-server.log"
HEALTH_CHECK_TIMEOUT=30
STARTUP_TIMEOUT=60
CONFIG_FILE="server.conf"

# Load configuration from file if it exists
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

# Parse command line arguments with enhanced validation
PORT=${1:-$DEFAULT_PORT}
HOST=${2:-$DEFAULT_HOST}
DAEMON_MODE=${3:-false}

# Validate port range
if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1024 ] || [ "$PORT" -gt 65535 ]; then
    error "Invalid port: $PORT. Must be a number between 1024 and 65535"
    exit 1
fi

# Validate host format (basic check)
if [[ ! "$HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && [[ "$HOST" != "localhost" ]] && [[ ! "$HOST" =~ ^[a-zA-Z0-9.-]+$ ]]; then
    error "Invalid host format: $HOST"
    exit 1
fi

log "Starting R Volcano Plot API Server..."
log "Configuration: Host=$HOST, Port=$PORT, Daemon=$DAEMON_MODE"

# Create configuration file if it doesn't exist
create_config

# Check if port is available
if command -v lsof &> /dev/null; then
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        error "Port $PORT is already in use"
        log "Use 'lsof -Pi :$PORT -sTCP:LISTEN' to see what's using the port"
        exit 1
    fi
elif command -v netstat &> /dev/null; then
    if netstat -ln | grep ":$PORT " >/dev/null 2>&1; then
        error "Port $PORT is already in use"
        log "Use 'netstat -ln | grep :$PORT' to see what's using the port"
        exit 1
    fi
fi

# Check if R is installed
if ! command -v Rscript &> /dev/null; then
    error "R is not installed or not in PATH"
    error "Please install R from https://www.r-project.org/"
    exit 1
fi

# Check R version and capabilities
R_VERSION=$(Rscript --version 2>&1 | head -n1)
log "R Version: $R_VERSION"

# Check available memory
if command -v free &> /dev/null; then
    AVAILABLE_MEMORY=$(free -h | awk '/^Mem:/ {print $7}')
    log "Available memory: $AVAILABLE_MEMORY"
elif command -v vm_stat &> /dev/null; then
    # macOS
    FREE_PAGES=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    if [ -n "$FREE_PAGES" ]; then
        AVAILABLE_MEMORY=$(echo "$FREE_PAGES * 4096 / 1024 / 1024" | bc 2>/dev/null || echo "Unknown")
        log "Available memory: ${AVAILABLE_MEMORY}MB (approx)"
    fi
fi

# Check if server is already running
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        warning "Server is already running with PID $OLD_PID"
        log "Use './stop-server.sh' to stop the existing server first"
        exit 1
    else
        warning "Stale PID file found, removing..."
        rm -f "$PID_FILE"
    fi
fi

# Install/check required packages
log "Installing/checking required packages..."
if ! Rscript install-packages.R; then
    error "Failed to install R packages"
    exit 1
fi

# Set environment variables for R server
export R_LOG_LEVEL=${R_LOG_LEVEL:-INFO}
export R_LOG_FILE=${R_LOG_FILE:-$LOG_FILE}

# Function to check server health
check_health() {
    local url="http://$HOST:$PORT/health"
    local timeout=${1:-5}
    
    if command -v curl &> /dev/null; then
        curl -s --max-time "$timeout" "$url" > /dev/null 2>&1
    elif command -v wget &> /dev/null; then
        wget -q --timeout="$timeout" -O /dev/null "$url" > /dev/null 2>&1
    else
        # Fallback using nc if available
        if command -v nc &> /dev/null; then
            echo -e "GET /health HTTP/1.0\r\n\r\n" | nc -w "$timeout" "$HOST" "$PORT" > /dev/null 2>&1
        else
            return 1
        fi
    fi
}

# Function to wait for server startup
wait_for_startup() {
    local elapsed=0
    log "Waiting for server to start (timeout: ${STARTUP_TIMEOUT}s)..."
    
    while [ $elapsed -lt $STARTUP_TIMEOUT ]; do
        if check_health 2; then
            success "Server is responding to health checks"
            return 0
        fi
        
        sleep 2
        elapsed=$((elapsed + 2))
        echo -n "."
    done
    
    echo ""
    error "Server failed to start within ${STARTUP_TIMEOUT} seconds"
    return 1
}

# Function to create default configuration file
create_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "Creating default configuration file: $CONFIG_FILE"
        cat > "$CONFIG_FILE" << EOF
# R Backend Server Configuration
# This file is sourced by start-server.sh

# Server settings
DEFAULT_PORT=8001
DEFAULT_HOST="127.0.0.1"

# Process management
STARTUP_TIMEOUT=60
HEALTH_CHECK_TIMEOUT=30
SHUTDOWN_TIMEOUT=30

# Logging
LOG_FILE="r-server.log"
R_LOG_LEVEL="INFO"

# Performance tuning
R_MAX_MEMORY="2G"
R_THREADS=4

# Development mode settings
DEV_MODE=false
AUTO_RELOAD=false
EOF
        success "Configuration file created: $CONFIG_FILE"
    fi
}

# Function to save process information
save_process_info() {
    local pid=$1
    local port=$2
    local host=$3
    
    cat > "${PID_FILE}.info" << EOF
PID=$pid
PORT=$port
HOST=$host
START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE=$LOG_FILE
CONFIG_FILE=$CONFIG_FILE
EOF
}

# Function to handle graceful shutdown
cleanup() {
    log "Received shutdown signal, stopping server..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            log "Sending SIGTERM to process $PID..."
            kill -TERM "$PID"
            
            # Wait for graceful shutdown with configurable timeout
            local count=0
            local timeout=${SHUTDOWN_TIMEOUT:-30}
            while kill -0 "$PID" 2>/dev/null && [ $count -lt $timeout ]; do
                sleep 1
                count=$((count + 1))
                if [ $((count % 5)) -eq 0 ]; then
                    log "Waiting for graceful shutdown... ($count/${timeout}s)"
                fi
            done
            
            # Force kill if still running
            if kill -0 "$PID" 2>/dev/null; then
                warning "Process did not terminate gracefully within ${timeout}s, forcing shutdown..."
                kill -KILL "$PID"
                sleep 2
                
                if kill -0 "$PID" 2>/dev/null; then
                    error "Failed to terminate process $PID even with SIGKILL"
                else
                    warning "Process forcefully terminated"
                fi
            else
                success "Process terminated gracefully"
            fi
        fi
        rm -f "$PID_FILE" "${PID_FILE}.info"
    fi
    exit 0
}

# Set up signal handlers for graceful shutdown
trap cleanup SIGINT SIGTERM

# Start the server
log "Starting Plumber API server..."
log "Server will be available at: http://$HOST:$PORT"
log "Health check endpoint: http://$HOST:$PORT/health"
log "Log file: $LOG_FILE"

# Set R environment variables for better performance
export R_MAX_VSIZE=${R_MAX_MEMORY:-"2G"}
export R_NSIZE=${R_THREADS:-4}
export R_LOG_LEVEL=${R_LOG_LEVEL:-"INFO"}
export R_LOG_FILE="$LOG_FILE"

if [ "$DAEMON_MODE" = "true" ]; then
    # Start in daemon mode
    log "Starting server in daemon mode..."
    nohup Rscript plumber-api.R "$PORT" "$HOST" > "$LOG_FILE" 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    # Save detailed process information
    save_process_info "$SERVER_PID" "$PORT" "$HOST"
    
    # Wait for startup and verify
    if wait_for_startup; then
        success "Server started successfully in daemon mode (PID: $SERVER_PID)"
        log "Server information saved to: ${PID_FILE}.info"
        log "Use './stop-server.sh' to stop the server"
        log "Use './server-status.sh' to check server status"
        log "Use 'tail -f $LOG_FILE' to monitor logs"
        
        # Show process details
        if command -v ps &> /dev/null; then
            PROCESS_INFO=$(ps -p "$SERVER_PID" -o pid,ppid,cmd,etime --no-headers 2>/dev/null || echo "Process info unavailable")
            log "Process details: $PROCESS_INFO"
        fi
    else
        error "Failed to start server in daemon mode"
        rm -f "$PID_FILE" "${PID_FILE}.info"
        exit 1
    fi
else
    # Start in foreground mode
    log "Starting server in foreground mode (Ctrl+C to stop)..."
    Rscript plumber-api.R "$PORT" "$HOST" &
    SERVER_PID=$!
    echo $SERVER_PID > "$PID_FILE"
    
    # Save detailed process information
    save_process_info "$SERVER_PID" "$PORT" "$HOST"
    
    # Wait for startup
    if wait_for_startup; then
        success "Server started successfully (PID: $SERVER_PID)"
        log "Server information saved to: ${PID_FILE}.info"
        log "Press Ctrl+C to stop the server"
        
        # Show process details
        if command -v ps &> /dev/null; then
            PROCESS_INFO=$(ps -p "$SERVER_PID" -o pid,ppid,cmd,etime --no-headers 2>/dev/null || echo "Process info unavailable")
            log "Process details: $PROCESS_INFO"
        fi
        
        # Wait for the R process to finish
        wait $SERVER_PID
        
        # Cleanup on normal exit
        rm -f "$PID_FILE" "${PID_FILE}.info"
    else
        error "Failed to start server"
        rm -f "$PID_FILE" "${PID_FILE}.info"
        exit 1
    fi
fi