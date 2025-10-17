# R Backend Process Management

This document describes the comprehensive process management system for the R backend server, including startup, monitoring, health checks, and graceful shutdown capabilities.

## Overview

The R backend process management system provides:

- **Automated startup and shutdown** with proper port configuration
- **Health monitoring** with automatic restart capabilities
- **Process monitoring** with metrics collection
- **Development environment** integration with FastAPI
- **Configuration management** with flexible settings
- **Logging and alerting** for operational visibility

## Components

### Core Scripts

1. **`start-server.sh` / `start-server.bat`** - Server startup with configuration
2. **`stop-server.sh` / `stop-server.bat`** - Graceful server shutdown
3. **`health-monitor.sh`** - Continuous health monitoring with auto-restart
4. **`server-status.sh` / `server-status.bat`** - Server status and diagnostics
5. **`dev-with-fastapi.sh` / `dev-with-fastapi.bat`** - Development environment
6. **`process-manager.sh` / `process-manager.bat`** - Unified process management

### Configuration Files

- **`server.conf`** - Main configuration file (created from template)
- **`server.conf.template`** - Configuration template with all options
- **`r-server.pid`** - Process ID file
- **`r-server.pid.info`** - Extended process information

### Log Files

- **`r-server.log`** - Main server log
- **`health-monitor.log`** - Health monitoring log
- **`process-manager.log`** - Process manager log
- **`server-metrics.log`** - Performance metrics log

## Quick Start

### 1. Basic Server Operations

```bash
# Start server with defaults (port 8001, localhost)
./process-manager.sh start

# Start server with custom port and host
./process-manager.sh start 8002 0.0.0.0

# Check server status
./process-manager.sh status

# Stop server
./process-manager.sh stop

# Restart server
./process-manager.sh restart
```

### 2. Development Environment

```bash
# Start both FastAPI and R backend for development
./process-manager.sh dev

# Or use the dedicated script
./dev-with-fastapi.sh
```

### 3. Health Monitoring

```bash
# Start health monitoring (with auto-restart)
./process-manager.sh monitor

# Or use the dedicated script
./health-monitor.sh
```

## Configuration

### Creating Configuration File

```bash
# Copy template and customize
cp server.conf.template server.conf
# Edit server.conf with your preferred settings
```

### Key Configuration Options

```bash
# Server settings
DEFAULT_PORT=8001
DEFAULT_HOST="127.0.0.1"

# Process management
STARTUP_TIMEOUT=60
SHUTDOWN_TIMEOUT=30

# Health monitoring
CHECK_INTERVAL=30
MAX_FAILURES=3
AUTO_RESTART=true

# Performance
R_MAX_MEMORY="2G"
R_THREADS=4

# Logging
R_LOG_LEVEL="INFO"
LOG_FILE="r-server.log"
```

## Process Management Features

### 1. Startup Management

- **Port validation** - Ensures port is available and in valid range
- **Dependency checking** - Verifies R installation and required packages
- **Configuration loading** - Loads settings from server.conf
- **Process information** - Saves detailed process metadata
- **Health verification** - Waits for server to respond before confirming startup

### 2. Graceful Shutdown

- **Signal handling** - Responds to SIGTERM for graceful shutdown
- **Timeout management** - Configurable shutdown timeout
- **Force termination** - SIGKILL as fallback if graceful shutdown fails
- **Cleanup** - Removes PID files and temporary resources

### 3. Health Monitoring

- **HTTP health checks** - Regular endpoint monitoring
- **Process monitoring** - Verifies process is still running
- **Metrics collection** - CPU, memory, and response time tracking
- **Auto-restart** - Automatic recovery from failures
- **Alert system** - Email and webhook notifications

### 4. Development Integration

- **Multi-service startup** - Starts both FastAPI and R backend
- **Port management** - Ensures no port conflicts
- **Log aggregation** - Centralized logging for both services
- **Health monitoring** - Monitors both services simultaneously

## Advanced Usage

### Custom Startup Options

```bash
# Start with custom memory limit
R_MAX_MEMORY="4G" ./start-server.sh

# Start with debug logging
R_LOG_LEVEL="DEBUG" ./start-server.sh

# Start with custom log file
R_LOG_FILE="custom.log" ./start-server.sh
```

### Health Monitoring with Alerts

```bash
# Configure email alerts
echo 'ALERT_EMAIL="admin@example.com"' >> server.conf

# Configure webhook alerts
echo 'WEBHOOK_URL="https://hooks.slack.com/..."' >> server.conf

# Start monitoring
./health-monitor.sh
```

### Performance Monitoring

```bash
# View real-time metrics
tail -f server-metrics.log

# View server statistics
./process-manager.sh status

# View recent logs
./process-manager.sh logs 50
```

## Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   # Check what's using the port
   lsof -Pi :8001 -sTCP:LISTEN  # Linux/macOS
   netstat -an | find ":8001"   # Windows
   ```

2. **Server won't start**
   ```bash
   # Check R installation
   Rscript --version
   
   # Check required packages
   Rscript install-packages.R
   
   # Check logs
   ./process-manager.sh logs
   ```

3. **Health checks failing**
   ```bash
   # Manual health check
   curl http://localhost:8001/health
   
   # Check server status
   ./process-manager.sh status
   ```

### Log Analysis

```bash
# View startup logs
grep "STARTUP" r-server.log

# View error logs
grep "ERROR" r-server.log

# View health check logs
grep "HEALTH_CHECK" server-metrics.log
```

### Process Recovery

```bash
# Clean up stale processes
./process-manager.sh cleanup

# Force restart
./process-manager.sh stop
./process-manager.sh start

# Reset all logs
rm -f *.log *.pid*
```

## Production Deployment

### Systemd Service (Linux)

Create `/etc/systemd/system/r-backend.service`:

```ini
[Unit]
Description=R Backend Volcano Plot API
After=network.target

[Service]
Type=forking
User=r-backend
WorkingDirectory=/path/to/r-backend
ExecStart=/path/to/r-backend/start-server.sh 8001 127.0.0.1 true
ExecStop=/path/to/r-backend/stop-server.sh
PIDFile=/path/to/r-backend/r-server.pid
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Windows Service

Use `nssm` (Non-Sucking Service Manager):

```cmd
nssm install "R Backend" "C:\path\to\r-backend\start-server.bat"
nssm set "R Backend" AppParameters "8001 127.0.0.1 true"
nssm set "R Backend" AppDirectory "C:\path\to\r-backend"
nssm start "R Backend"
```

### Docker Integration

```dockerfile
# Add to existing Dockerfile
COPY r-backend/ /app/r-backend/
WORKDIR /app/r-backend
RUN chmod +x *.sh
EXPOSE 8001
CMD ["./start-server.sh", "8001", "0.0.0.0", "true"]
```

## Security Considerations

1. **Port binding** - Bind to localhost in development, specific interfaces in production
2. **Process isolation** - Run as dedicated user with minimal privileges
3. **Log rotation** - Implement log rotation to prevent disk space issues
4. **Resource limits** - Set appropriate memory and CPU limits
5. **Network security** - Use firewall rules to restrict access

## Performance Tuning

### Memory Management

```bash
# Increase R memory limit
R_MAX_MEMORY="4G" ./start-server.sh

# Monitor memory usage
grep "MEM:" server-metrics.log
```

### CPU Optimization

```bash
# Set thread count
R_THREADS=8 ./start-server.sh

# Monitor CPU usage
grep "CPU:" server-metrics.log
```

### Cache Optimization

```bash
# Configure cache limits in server.conf
CACHE_SIZE_LIMIT=2000000
CACHE_TTL=7200
```

## Monitoring and Alerting

### Metrics Collection

The system automatically collects:
- CPU usage percentage
- Memory usage percentage
- HTTP response times
- Health check success/failure rates
- Process uptime

### Alert Configuration

```bash
# Email alerts (requires mail command)
ALERT_EMAIL="ops@example.com"

# Webhook alerts (Slack, Discord, etc.)
WEBHOOK_URL="https://hooks.slack.com/services/..."

# Alert thresholds
MAX_FAILURES=3
CHECK_INTERVAL=30
```

### Dashboard Integration

Metrics are logged in CSV format for easy integration with monitoring tools:

```bash
# Example metrics format
2024-01-15 10:30:00,CPU:15.2%,MEM:8.5%,PID:12345
2024-01-15 10:30:30,HEALTH_CHECK,SUCCESS,0.125s
```

## API Reference

### Process Manager Commands

- `start [port] [host] [daemon]` - Start server
- `stop` - Stop server
- `restart [port] [host]` - Restart server
- `status` - Show detailed status
- `monitor` - Start health monitoring
- `logs [lines]` - Show recent logs
- `dev` - Start development environment
- `config` - Show configuration
- `cleanup` - Clean up old files

### Environment Variables

- `R_LOG_LEVEL` - Logging level (DEBUG, INFO, WARN, ERROR)
- `R_LOG_FILE` - Log file path
- `R_MAX_MEMORY` - Maximum memory limit
- `R_THREADS` - Number of threads

### Exit Codes

- `0` - Success
- `1` - General error
- `2` - Configuration error
- `3` - Network error
- `4` - Process error