# R Backend for Volcano Plot API

This directory contains the R-based backend implementation for volcano plot data processing using Plumber API framework.

## Setup

### 1. Install Required R Packages

Run the package installation script:

```bash
Rscript install-packages.R
```

This will install:
- `plumber` - Web API framework for R
- `data.table` - High-performance data manipulation
- `jsonlite` - JSON parsing and generation

### 2. Start the R API Server

```bash
# Start server on default port 8001
Rscript plumber-api.R

# Start server on custom port
Rscript plumber-api.R 8002
```

### 3. Test the Health Check

Once the server is running, test the health check endpoint:

```bash
curl http://localhost:8001/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T12:00:00Z",
  "backend": "R + data.table",
  "version": "R version 4.x.x",
  "packages": {
    "plumber": "1.x.x",
    "data.table": "1.x.x", 
    "jsonlite": "1.x.x"
  }
}
```

## API Endpoints

### Health Check
- **GET** `/health` - Server health status and package versions

## Development

The server runs on `http://127.0.0.1:8001` by default and includes CORS headers for frontend integration.

## Next Steps

Additional endpoints for volcano plot data processing will be implemented in subsequent tasks.