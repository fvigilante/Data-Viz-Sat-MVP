# R Backend Troubleshooting Guide

This comprehensive guide covers common issues, solutions, and debugging procedures for the R volcano plot backend integration.

## Quick Diagnostics

### Health Check Procedure

1. **Verify R Installation**
   ```bash
   Rscript --version
   ```
   Expected: `R scripting front-end version 4.x.x`

2. **Check Required Packages**
   ```bash
   cd r-backend
   Rscript validate-setup.R
   ```

3. **Test Server Startup**
   ```bash
   # Windows
   start-server.bat
   
   # macOS/Linux
   ./start-server.sh
   ```

4. **Verify Server Health**
   ```bash
   curl http://localhost:8001/health
   ```

## Installation Issues

### R Not Found

**Symptoms:**
- `'Rscript' is not recognized as an internal or external command`
- `bash: Rscript: command not found`

**Solutions:**

**Windows:**
1. Download R from [CRAN](https://cran.r-project.org/bin/windows/base/)
2. Install with default settings
3. Add R to PATH:
   - Open System Properties → Environment Variables
   - Add `C:\Program Files\R\R-4.x.x\bin` to PATH
   - Restart terminal/IDE

**macOS:**
```bash
# Using Homebrew (recommended)
brew install r

# Or download from CRAN
# https://cran.r-project.org/bin/macosx/
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install r-base r-base-dev

# For CentOS/RHEL
sudo yum install R
```

**Verification:**
```bash
Rscript --version
R --version
which Rscript  # Unix systems
where Rscript  # Windows
```

### Package Installation Failures

**Symptoms:**
- `Error: package 'plumber' is not available`
- `installation of package 'data.table' had non-zero exit status`

**Solutions:**

**Basic Package Installation:**
```bash
cd r-backend
Rscript install-packages.R
```

**Manual Installation:**
```r
# Start R interactive session
R

# Install packages manually
install.packages(c("plumber", "data.table", "jsonlite"))

# Check installation
library(plumber)
library(data.table)
library(jsonlite)
```

**Linux Compilation Issues:**
```bash
# Install development packages
sudo apt install r-base-dev build-essential

# For specific packages that need compilation
sudo apt install libcurl4-openssl-dev libssl-dev libxml2-dev
```

**Network/Proxy Issues:**
```r
# Configure CRAN mirror
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# For corporate networks with proxy
Sys.setenv(http_proxy = "http://proxy.company.com:8080")
Sys.setenv(https_proxy = "https://proxy.company.com:8080")
```

## Server Startup Issues

### Port Already in Use

**Symptoms:**
- `Error: Port 8001 is already in use`
- `bind: address already in use`

**Diagnosis:**
```bash
# Check what's using the port
lsof -Pi :8001 -sTCP:LISTEN  # macOS/Linux
netstat -an | find ":8001"   # Windows
netstat -tulpn | grep :8001  # Linux detailed
```

**Solutions:**
```bash
# Use different port
./start-server.sh 8002  # Unix
start-server.bat 8002   # Windows

# Kill process using the port (if safe)
kill -9 $(lsof -ti:8001)  # Unix
# Windows: Use Task Manager or taskkill
```

### Permission Errors

**Symptoms:**
- `Permission denied` when starting server
- `cannot create file` errors

**Solutions:**

**Unix Systems:**
```bash
# Make scripts executable
chmod +x *.sh

# Check file permissions
ls -la start-server.sh

# Run with proper permissions
sudo ./start-server.sh  # If needed (not recommended)
```

**Windows:**
```cmd
# Run as Administrator if needed
# Right-click Command Prompt → "Run as administrator"

# Check file permissions in Properties
```

### R Package Loading Errors

**Symptoms:**
- `Error in library(plumber): there is no package called 'plumber'`
- Server starts but crashes immediately

**Diagnosis:**
```bash
# Test package loading
Rscript -e "library(plumber); library(data.table); library(jsonlite)"
```

**Solutions:**
```bash
# Reinstall packages
Rscript install-packages.R

# Check R library path
Rscript -e ".libPaths()"

# Install to user library if needed
Rscript -e "install.packages('plumber', lib = Sys.getenv('R_LIBS_USER'))"
```

## Runtime Issues

### Server Crashes or Hangs

**Symptoms:**
- Server starts but becomes unresponsive
- Memory errors or crashes under load
- Timeout errors from frontend

**Diagnosis:**
```bash
# Check server status
cd r-backend
./server-status.sh  # Unix
server-status.bat   # Windows

# Monitor server logs
tail -f r-server.log  # Unix
type r-server.log     # Windows

# Test server manually
curl http://localhost:8001/health
curl "http://localhost:8001/api/volcano-data?dataset_size=1000"
```

**Solutions:**

**Memory Issues:**
```bash
# Increase R memory limit
R_MAX_MEMORY="4G" ./start-server.sh

# Clear cache
curl -X POST http://localhost:8001/api/clear-cache

# Monitor memory usage
curl http://localhost:8001/api/cache-status
```

**Performance Issues:**
```bash
# Reduce dataset size for testing
curl "http://localhost:8001/api/volcano-data?dataset_size=1000&max_points=5000"

# Check system resources
top    # Unix
htop   # Linux (if installed)
# Task Manager on Windows
```

### API Endpoint Errors

**Symptoms:**
- `404 Not Found` for API endpoints
- `500 Internal Server Error`
- Malformed JSON responses

**Diagnosis:**
```bash
# Test individual endpoints
curl -v http://localhost:8001/health
curl -v http://localhost:8001/api/cache-status
curl -v "http://localhost:8001/api/volcano-data?dataset_size=1000"

# Check server logs for errors
grep "ERROR" r-server.log
```

**Solutions:**

**Endpoint Not Found:**
- Verify server is running on correct port
- Check API route definitions in `plumber-api.R`
- Ensure no typos in endpoint URLs

**Internal Server Errors:**
```bash
# Enable debug logging
R_LOG_LEVEL="DEBUG" ./start-server.sh

# Check parameter validation
curl "http://localhost:8001/api/volcano-data?dataset_size=invalid"

# Test with minimal parameters
curl "http://localhost:8001/api/volcano-data"
```

## Integration Issues

### Frontend Cannot Connect to R Backend

**Symptoms:**
- Frontend shows "R backend not available"
- Network errors in browser console
- Proxy errors in Next.js API routes

**Diagnosis:**
```bash
# Test R backend directly
curl http://localhost:8001/health

# Test Next.js proxy
curl http://localhost:3000/api/r-volcano-data

# Check environment variables
echo $R_API_URL
```

**Solutions:**

**Environment Configuration:**
```bash
# Set R backend URL
export R_API_URL="http://localhost:8001"

# For Next.js development
# Add to .env.local:
R_API_URL=http://localhost:8001
```

**CORS Issues:**
- Verify CORS headers in R backend
- Check browser console for CORS errors
- Ensure proper proxy configuration in Next.js

### Performance Comparison Issues

**Symptoms:**
- Benchmarks fail to run
- Inconsistent results between R and Python
- Timeout errors during comparison

**Diagnosis:**
```bash
# Test both backends
curl http://localhost:8000/health  # FastAPI
curl http://localhost:8001/health  # R backend

# Run health check benchmark
cd r-backend
Rscript quick-benchmark.R health
```

**Solutions:**

**Benchmark Setup:**
```bash
# Ensure both backends are running
npm run dev:api &  # FastAPI
npm run dev:r &    # R backend

# Run quick benchmark
Rscript quick-benchmark.R

# For detailed comparison
Rscript live-comparison-test.R
```

**Output Validation:**
```bash
# Compare outputs
Rscript compare-outputs.R r_response.json python_response.json

# Statistical validation
Rscript statistical-validation.R r_data.json python_data.json
```

## Development Issues

### Code Changes Not Reflected

**Symptoms:**
- R code changes don't take effect
- Server serves old responses
- Cache issues during development

**Solutions:**
```bash
# Restart R server
./stop-server.sh && ./start-server.sh

# Clear R cache
curl -X POST http://localhost:8001/api/clear-cache

# Force restart with process manager
./process-manager.sh restart
```

### Debugging R Code

**Enable Debug Logging:**
```bash
R_LOG_LEVEL="DEBUG" ./start-server.sh
```

**Add Debug Statements:**
```r
# In plumber-api.R functions
cat("DEBUG: Processing dataset size:", size, "\n")
print(str(data))  # Print data structure
```

**Interactive Debugging:**
```r
# Test functions interactively
source("plumber-api.R")
test_data <- generate_volcano_data(1000)
str(test_data)
```

## Platform-Specific Issues

### Windows-Specific

**Path Issues:**
```cmd
# Use full paths if needed
"C:\Program Files\R\R-4.3.0\bin\Rscript.exe" plumber-api.R

# Check PATH variable
echo %PATH%
```

**Script Execution:**
```cmd
# Enable script execution if needed
powershell Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### macOS-Specific

**Homebrew R Issues:**
```bash
# Update Homebrew R
brew upgrade r

# Check R installation
brew doctor
brew list r
```

**Permission Issues:**
```bash
# Fix permissions for R packages
sudo chown -R $(whoami) $(Rscript -e "cat(.libPaths()[1])")
```

### Linux-Specific

**Package Compilation:**
```bash
# Install build dependencies
sudo apt install build-essential gfortran

# For specific packages
sudo apt install libcurl4-openssl-dev libssl-dev libxml2-dev
```

**Service Management:**
```bash
# Create systemd service (optional)
sudo cp r-backend.service /etc/systemd/system/
sudo systemctl enable r-backend
sudo systemctl start r-backend
```

## Performance Optimization

### Memory Optimization

**Monitor Memory Usage:**
```bash
# Check cache status
curl http://localhost:8001/api/cache-status

# Monitor system memory
free -h  # Linux
vm_stat  # macOS
```

**Optimize Memory Settings:**
```bash
# Increase R memory limit
R_MAX_MEMORY="4G" ./start-server.sh

# Adjust cache settings in server.conf
CACHE_SIZE_LIMIT=2000000
```

### CPU Optimization

**Monitor CPU Usage:**
```bash
# Check system load
top
htop  # If available
```

**Optimize CPU Settings:**
```bash
# Set thread count
R_THREADS=4 ./start-server.sh

# Monitor performance
curl http://localhost:8001/api/cache-status
```

## Getting Additional Help

### Log Analysis

**Key Log Files:**
- `r-server.log` - Main server log
- `health-monitor.log` - Health monitoring
- `server-metrics.log` - Performance metrics

**Log Analysis Commands:**
```bash
# View recent errors
grep "ERROR" r-server.log | tail -20

# Monitor real-time logs
tail -f r-server.log

# Search for specific issues
grep -i "memory\|timeout\|connection" r-server.log
```

### Diagnostic Information

**System Information:**
```bash
# R version and configuration
Rscript -e "sessionInfo()"

# System information
uname -a  # Unix
systeminfo  # Windows

# Network configuration
netstat -an | grep 8001
```

**Package Information:**
```r
# Check package versions
packageVersion("plumber")
packageVersion("data.table")
packageVersion("jsonlite")

# Check package installation paths
.libPaths()
installed.packages()[c("plumber", "data.table", "jsonlite"), ]
```

### Support Resources

1. **Documentation**: Review all README files in `r-backend/`
2. **Test Scripts**: Run validation scripts to identify issues
3. **Logs**: Check server logs for detailed error information
4. **Community**: R community forums and Stack Overflow
5. **GitHub Issues**: Report bugs or request help

### Creating Support Requests

When seeking help, include:

1. **System Information**: OS, R version, package versions
2. **Error Messages**: Complete error messages and stack traces
3. **Log Files**: Relevant portions of server logs
4. **Steps to Reproduce**: Exact commands and procedures
5. **Expected vs Actual**: What you expected vs what happened

This troubleshooting guide should help resolve most common issues with the R backend integration. For persistent problems, systematic diagnosis using these procedures will help identify the root cause.