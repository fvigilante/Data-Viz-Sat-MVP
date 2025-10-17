#!/bin/bash

# R Backend Health Monitor Script
# This script continuously monitors the R server health and can restart it if needed

set -e

# Configuration
PID_FILE="r-server.pid"
LOG_FILE="r-server.log"
MONITOR_LOG="health-monitor.log"
DEFAULT_PORT=8001
DEFAULT_HOST="127.0.0.1"
CHECK_INTERVAL=30
MAX_FAILURES=3
RESTART_DELAY=10
ALERT_EMAIL=""
WEBHOOK_URL=""
METRICS_FILE="server-metrics.log"

# Load configuration if available
CONFIG_FILE="server.conf"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo -e "${BLUE}$message${NC}"
    echo "$message" >> "$MONITOR_LOG"
}

error() {
    local message="[ERROR] $1"
    echo -e "${RED}$message${NC}" >&2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$MONITOR_LOG"
}

success() {
    local message="[SUCCESS] $1"
    echo -e "${GREEN}$message${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$MONITOR_LOG"
}

warning() {
    local message="[WARNING] $1"
    echo -e "${YELLOW}$message${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$MONITOR_LOG"
}

# Parse command line arguments
PORT=${1:-$DEFAULT_PORT}
HOST=${2:-$DEFAULT_HOST}
AUTO_RESTART=${3:-true}

# Function to collect server metrics
collect_metrics() {
    local pid=$1
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        # Get process stats
        if command -v ps &> /dev/null; then
            local cpu_mem=$(ps -p "$pid" -o pcpu,pmem --no-headers 2>/dev/null | tr -s ' ')
            local cpu=$(echo "$cpu_mem" | awk '{print $1}')
            local mem=$(echo "$cpu_mem" | awk '{print $2}')
            
            # Log metrics
            echo "$timestamp,CPU:${cpu}%,MEM:${mem}%,PID:$pid" >> "$METRICS_FILE"
        fi
    fi
}

# Function to send alert (email or webhook)
send_alert() {
    local message="$1"
    local severity="$2"
    
    # Email alert
    if [ -n "$ALERT_EMAIL" ] && command -v mail &> /dev/null; then
        echo "$message" | mail -s "R Backend Alert [$severity]" "$ALERT_EMAIL"
    fi
    
    # Webhook alert
    if [ -n "$WEBHOOK_URL" ] && command -v curl &> /dev/null; then
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"message\":\"$message\",\"severity\":\"$severity\",\"timestamp\":\"$(date -Iseconds)\"}" \
            > /dev/null 2>&1
    fi
}

# Function to check server health with detailed response
check_health() {
    local url="http://$HOST:$PORT/health"
    local response_time_start=$(date +%s.%N)
    local health_status=1
    local response_body=""
    
    if command -v curl &> /dev/null; then
        response_body=$(curl -s --max-time 5 "$url" 2>/dev/null)
        health_status=$?
    elif command -v wget &> /dev/null; then
        response_body=$(wget -q --timeout=5 -O - "$url" 2>/dev/null)
        health_status=$?
    else
        # Fallback using nc if available
        if command -v nc &> /dev/null; then
            response_body=$(echo -e "GET /health HTTP/1.0\r\n\r\n" | nc -w 5 "$HOST" "$PORT" 2>/dev/null)
            if [ $? -eq 0 ] && echo "$response_body" | grep -q "200 OK"; then
                health_status=0
            fi
        fi
    fi
    
    local response_time_end=$(date +%s.%N)
    local response_time=$(echo "$response_time_end - $response_time_start" | bc 2>/dev/null || echo "0")
    
    # Log response time if health check succeeded
    if [ $health_status -eq 0 ]; then
        echo "$(date '+%Y-%m-%d %H:%M:%S'),HEALTH_CHECK,SUCCESS,${response_time}s" >> "$METRICS_FILE"
    else
        echo "$(date '+%Y-%m-%d %H:%M:%S'),HEALTH_CHECK,FAILED,${response_time}s" >> "$METRICS_FILE"
    fi
    
    return $health_status
}

# Function to check if process is running
check_process() {
    if [ ! -f "$PID_FILE" ]; then
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    kill -0 "$pid" 2>/dev/null
}

# Function to restart server
restart_server() {
    log "Attempting to restart R server..."
    
    # Stop existing server if running
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log "Stopping existing server (PID: $pid)..."
            kill -TERM "$pid" 2>/dev/null || true
            sleep 5
            kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
    fi
    
    # Wait before restart
    log "Waiting ${RESTART_DELAY} seconds before restart..."
    sleep $RESTART_DELAY
    
    # Start server
    log "Starting R server..."
    if ./start-server.sh "$PORT" "$HOST" true; then
        success "Server restarted successfully"
        return 0
    else
        error "Failed to restart server"
        return 1
    fi
}

# Function to handle cleanup on exit
cleanup() {
    log "Health monitor stopping..."
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

log "Starting R Backend Health Monitor"
log "Configuration: Host=$HOST, Port=$PORT, Auto-restart=$AUTO_RESTART"
log "Check interval: ${CHECK_INTERVAL}s, Max failures: $MAX_FAILURES"

# Initialize failure counter
failure_count=0
last_status="unknown"

# Main monitoring loop
while true; do
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Get current PID if available
    current_pid=""
    if [ -f "$PID_FILE" ]; then
        current_pid=$(cat "$PID_FILE")
    fi
    
    # Check if process is running
    if ! check_process; then
        if [ "$last_status" != "process_down" ]; then
            error "Server process is not running"
            send_alert "R Backend server process is not running" "CRITICAL"
            last_status="process_down"
        fi
        failure_count=$((failure_count + 1))
    else
        # Collect metrics for running process
        collect_metrics "$current_pid"
        
        # Check HTTP health
        if check_health; then
            if [ "$last_status" != "healthy" ]; then
                success "Server is healthy"
                if [ "$last_status" = "unhealthy" ] || [ "$last_status" = "process_down" ]; then
                    send_alert "R Backend server is now healthy" "INFO"
                fi
                last_status="healthy"
                failure_count=0
            fi
        else
            if [ "$last_status" != "unhealthy" ]; then
                warning "Server process is running but not responding to health checks"
                send_alert "R Backend server is not responding to health checks" "WARNING"
                last_status="unhealthy"
            fi
            failure_count=$((failure_count + 1))
        fi
    fi
    
    # Check if we need to restart
    if [ $failure_count -ge $MAX_FAILURES ]; then
        error "Server has failed $failure_count consecutive health checks"
        send_alert "R Backend server has failed $failure_count consecutive health checks" "CRITICAL"
        
        if [ "$AUTO_RESTART" = "true" ]; then
            log "Attempting automatic restart..."
            if restart_server; then
                success "Server restarted successfully"
                send_alert "R Backend server automatically restarted" "INFO"
                failure_count=0
                last_status="restarted"
            else
                error "Failed to restart server, will try again in next cycle"
                send_alert "Failed to automatically restart R Backend server" "CRITICAL"
            fi
        else
            error "Auto-restart is disabled, manual intervention required"
            log "Use './start-server.sh $PORT $HOST true' to restart manually"
            send_alert "R Backend server requires manual restart (auto-restart disabled)" "CRITICAL"
        fi
    fi
    
    # Log periodic status and cleanup old metrics
    if [ $(($(date +%s) % 300)) -eq 0 ]; then
        if [ "$last_status" = "healthy" ]; then
            log "Periodic status: Server is healthy (uptime check)"
        fi
        
        # Cleanup old metrics (keep last 1000 lines)
        if [ -f "$METRICS_FILE" ] && [ $(wc -l < "$METRICS_FILE") -gt 1000 ]; then
            tail -n 1000 "$METRICS_FILE" > "${METRICS_FILE}.tmp" && mv "${METRICS_FILE}.tmp" "$METRICS_FILE"
        fi
    fi
    
    sleep $CHECK_INTERVAL
done