#!/bin/bash

# R Backend Process Manager
# Comprehensive process management for R backend with monitoring and auto-recovery

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="r-server.pid"
LOG_FILE="r-server.log"
MONITOR_LOG="process-manager.log"
CONFIG_FILE="server.conf"
DEFAULT_PORT=8001
DEFAULT_HOST="127.0.0.1"

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

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
        log "Configuration loaded from $CONFIG_FILE"
    else
        log "No configuration file found, using defaults"
    fi
}

# Function to show usage
show_usage() {
    echo "R Backend Process Manager"
    echo "========================"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start [port] [host] [daemon]  - Start the R backend server"
    echo "  stop                          - Stop the R backend server"
    echo "  restart [port] [host]         - Restart the R backend server"
    echo "  status                        - Show server status"
    echo "  monitor                       - Start health monitoring"
    echo "  logs [lines]                  - Show server logs"
    echo "  dev                           - Start development environment"
    echo "  config                        - Show current configuration"
    echo "  cleanup                       - Clean up old logs and PID files"
    echo ""
    echo "Examples:"
    echo "  $0 start                      - Start server with defaults"
    echo "  $0 start 8002 0.0.0.0 true   - Start on port 8002, all interfaces, daemon mode"
    echo "  $0 monitor                    - Start health monitoring"
    echo "  $0 logs 50                    - Show last 50 log lines"
}

# Function to check if server is running
is_running() {
    if [ ! -f "$PID_FILE" ]; then
        return 1
    fi
    
    local pid=$(cat "$PID_FILE")
    kill -0 "$pid" 2>/dev/null
}

# Function to get server info
get_server_info() {
    if [ -f "${PID_FILE}.info" ]; then
        source "${PID_FILE}.info"
        echo "PID: $PID, Port: $PORT, Host: $HOST, Started: $START_TIME"
    else
        echo "Server info not available"
    fi
}

# Function to start server
start_server() {
    local port=${1:-$DEFAULT_PORT}
    local host=${2:-$DEFAULT_HOST}
    local daemon=${3:-true}
    
    if is_running; then
        warning "Server is already running"
        get_server_info
        return 1
    fi
    
    log "Starting R backend server..."
    if ./start-server.sh "$port" "$host" "$daemon"; then
        success "Server started successfully"
        return 0
    else
        error "Failed to start server"
        return 1
    fi
}

# Function to stop server
stop_server() {
    if ! is_running; then
        warning "Server is not running"
        return 1
    fi
    
    log "Stopping R backend server..."
    if ./stop-server.sh; then
        success "Server stopped successfully"
        return 0
    else
        error "Failed to stop server"
        return 1
    fi
}

# Function to restart server
restart_server() {
    local port=${1:-$DEFAULT_PORT}
    local host=${2:-$DEFAULT_HOST}
    
    log "Restarting R backend server..."
    
    if is_running; then
        stop_server
        sleep 2
    fi
    
    start_server "$port" "$host" true
}

# Function to show status
show_status() {
    echo "R Backend Server Status"
    echo "======================"
    
    if is_running; then
        success "Server is running"
        get_server_info
        
        # Run detailed status check
        ./server-status.sh
    else
        error "Server is not running"
        
        # Check for stale files
        if [ -f "$PID_FILE" ]; then
            warning "Stale PID file found: $PID_FILE"
        fi
        
        if [ -f "${PID_FILE}.info" ]; then
            warning "Stale info file found: ${PID_FILE}.info"
        fi
    fi
}

# Function to start monitoring
start_monitoring() {
    if ! is_running; then
        error "Server is not running. Start the server first."
        return 1
    fi
    
    log "Starting health monitoring..."
    ./health-monitor.sh
}

# Function to show logs
show_logs() {
    local lines=${1:-20}
    
    if [ -f "$LOG_FILE" ]; then
        echo "Last $lines lines from $LOG_FILE:"
        echo "================================="
        tail -n "$lines" "$LOG_FILE"
    else
        warning "Log file not found: $LOG_FILE"
    fi
    
    if [ -f "$MONITOR_LOG" ]; then
        echo ""
        echo "Last $lines lines from $MONITOR_LOG:"
        echo "===================================="
        tail -n "$lines" "$MONITOR_LOG"
    fi
}

# Function to start development environment
start_dev() {
    log "Starting development environment..."
    ./dev-with-fastapi.sh
}

# Function to show configuration
show_config() {
    echo "Current Configuration"
    echo "===================="
    
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo "No configuration file found"
        echo "Default values:"
        echo "DEFAULT_PORT=8001"
        echo "DEFAULT_HOST=127.0.0.1"
    fi
}

# Function to cleanup old files
cleanup() {
    log "Cleaning up old files..."
    
    # Remove stale PID files
    if [ -f "$PID_FILE" ] && ! is_running; then
        rm -f "$PID_FILE"
        log "Removed stale PID file"
    fi
    
    if [ -f "${PID_FILE}.info" ] && ! is_running; then
        rm -f "${PID_FILE}.info"
        log "Removed stale info file"
    fi
    
    # Rotate logs if they're too large
    for logfile in "$LOG_FILE" "$MONITOR_LOG" "health-monitor.log" "server-metrics.log"; do
        if [ -f "$logfile" ] && [ $(wc -c < "$logfile") -gt 10485760 ]; then  # 10MB
            mv "$logfile" "${logfile}.old"
            touch "$logfile"
            log "Rotated large log file: $logfile"
        fi
    done
    
    success "Cleanup completed"
}

# Main script logic
main() {
    cd "$SCRIPT_DIR"
    load_config
    
    case "${1:-}" in
        start)
            start_server "$2" "$3" "$4"
            ;;
        stop)
            stop_server
            ;;
        restart)
            restart_server "$2" "$3"
            ;;
        status)
            show_status
            ;;
        monitor)
            start_monitoring
            ;;
        logs)
            show_logs "$2"
            ;;
        dev)
            start_dev
            ;;
        config)
            show_config
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            error "Unknown command: ${1:-}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"