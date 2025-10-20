# Single Container Cloud Run Deployment

This document describes the single container deployment that combines Next.js frontend, FastAPI backend, and R integration in one Cloud Run service.

## Architecture

```
┌─────────────────────────────────────────┐
│           Cloud Run Container           │
├─────────────────────────────────────────┤
│  Supervisor (Process Manager)           │
│  ├─ Next.js (Port 8080) ──────────────┐ │
│  └─ FastAPI (Port 8001) ──────────────┐ │
│                                       │ │
│  Next.js Routes:                      │ │
│  ├─ /_health (health check)           │ │
│  ├─ /api/r-health (proxy to FastAPI)  │ │
│  └─ /api/r-volcano-data (proxy)       │ │
│                                       │ │
│  FastAPI Endpoints:                   │ │
│  ├─ /api/r/health                     │ │
│  ├─ /api/r/volcano-data               │ │
│  └─ R subprocess calls                │ │
└─────────────────────────────────────────┘
```

## Key Components

### 1. Dockerfile
- **Multi-stage build**: Builds Next.js, then combines with Python + R runtime
- **Base image**: `rocker/r-ver:4.3.2` (includes R)
- **Installs**: Node.js 18, Python 3, Supervisor
- **R packages**: `data.table`, `jsonlite`
- **Exposes**: Port 8080 (Next.js)

### 2. Supervisor Configuration (`supervisord.conf`)
- **Program 1**: FastAPI on `127.0.0.1:8001`
- **Program 2**: Next.js on `0.0.0.0:8080`
- **Environment**: `MONITOR_ENABLED=false` (disables R monitoring)

### 3. Health Checks
- **Container health**: `/_health` endpoint
- **Checks**: Next.js + FastAPI + R integration
- **Timeout**: 10s with 3 retries

### 4. API Integration
- **Internal communication**: Next.js → FastAPI via `http://127.0.0.1:8001`
- **R execution**: FastAPI calls R via `subprocess.run(['Rscript', ...])`
- **No separate R server**: Direct R script execution

## Deployment

### Local Testing
```powershell
# Build and test locally
.\test-single-container.ps1

# Or manually:
docker build -t data-viz-satellite-single -f Dockerfile .
docker run -p 8080:8080 data-viz-satellite-single
```

### Cloud Build
```bash
# Deploy using Cloud Build
gcloud builds submit --config cloudbuild-single.yaml
```

### Manual Cloud Run Deploy
```bash
# Build and push
docker build -t gcr.io/PROJECT_ID/data-viz-satellite-combined:latest .
docker push gcr.io/PROJECT_ID/data-viz-satellite-combined:latest

# Deploy
gcloud run services replace service-single.yaml --region=europe-west1
```

## Environment Variables

| Variable | Value | Description |
|----------|-------|-------------|
| `PORT` | `8080` | Next.js server port (exposed) |
| `API_INTERNAL_URL` | `http://127.0.0.1:8001` | Internal FastAPI URL |
| `MONITOR_ENABLED` | `false` | Disables R monitoring |
| `NODE_ENV` | `production` | Next.js environment |

## Endpoints

### Public (via Next.js)
- `GET /_health` - Combined health check
- `GET /api/r-health` - R integration health (proxy)
- `GET /api/r-volcano-data` - R volcano data (proxy)

### Internal (FastAPI only)
- `GET /api/r/health` - Direct R health check
- `GET /api/r/volcano-data` - Direct R volcano data

## Resource Requirements

- **CPU**: 2-4 cores
- **Memory**: 4-8 GB
- **Startup time**: ~60 seconds
- **Max scale**: 10 instances

## Troubleshooting

### Container won't start
1. Check supervisor logs: `docker logs <container>`
2. Verify R packages installed: `docker exec <container> Rscript -e "library(data.table)"`
3. Check port conflicts: Ensure 8080 and 8001 are available

### Health check fails
1. Test individual services:
   - Next.js: `curl http://localhost:8080`
   - FastAPI: `curl http://localhost:8001/health`
2. Check R integration: `curl http://localhost:8001/api/r/health`

### R subprocess errors
1. Verify R installation: `docker exec <container> which Rscript`
2. Test R packages: `docker exec <container> Rscript -e "library(jsonlite)"`
3. Check permissions: Ensure R scripts are executable

## Performance Notes

- **Cold start**: ~30-60 seconds (includes R package loading)
- **Warm requests**: <100ms for cached data
- **R execution**: 1-5 seconds depending on dataset size
- **Memory usage**: ~2-4 GB baseline + data processing

## Security

- **Internal communication**: All FastAPI traffic on localhost only
- **No external R server**: Reduces attack surface
- **Process isolation**: Supervisor manages process lifecycle
- **Health monitoring**: Automatic restart on failures