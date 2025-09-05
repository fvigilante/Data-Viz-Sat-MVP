# Deployment Guide

This guide covers deploying the Data Viz Satellite MVP to Google Cloud Run using a multi-container setup.

## Architecture

The application uses a multi-container deployment on Google Cloud Run:
- **Frontend Container**: Next.js app running on port 8080
- **Backend Container**: FastAPI app running on port 9000
- **Internal Communication**: Containers communicate via `127.0.0.1` (localhost)

## Prerequisites

1. **Google Cloud SDK**: Install and authenticate
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

2. **Enable Required APIs**:
   ```bash
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable containerregistry.googleapis.com
   ```

## Quick Fix for Existing Deployment

If you already have a deployment but the frontend is calling `localhost:8000` instead of the internal API:

```powershell
# Windows PowerShell
.\fix-api-url.ps1 -ProjectId "your-project-id" -Region "europe-west1" -ServiceName "your-service-name"
```

```bash
# Linux/Mac
./fix-api-url.sh your-project-id europe-west1 your-service-name
```

## Full Deployment

### Option 1: Using Cloud Build (Recommended)

1. **Update Configuration**:
   - Edit `service.yaml` and replace `PROJECT_ID` with your actual project ID
   - Verify the region in `cloudbuild.yaml` matches your target region

2. **Deploy**:
   ```powershell
   # Windows PowerShell
   .\deploy.ps1 -ProjectId "your-project-id" -Region "europe-west1"
   ```

   ```bash
   # Linux/Mac
   ./deploy.sh your-project-id europe-west1
   ```

### Option 2: Manual Deployment

1. **Build Images**:
   ```bash
   # Build API image
   docker build -t gcr.io/YOUR_PROJECT_ID/data-viz-satellite-api:latest -f api/Dockerfile ./api
   
   # Build Frontend image
   docker build -t gcr.io/YOUR_PROJECT_ID/data-viz-satellite-frontend:latest -f Dockerfile.production .
   ```

2. **Push Images**:
   ```bash
   docker push gcr.io/YOUR_PROJECT_ID/data-viz-satellite-api:latest
   docker push gcr.io/YOUR_PROJECT_ID/data-viz-satellite-frontend:latest
   ```

3. **Deploy Service**:
   ```bash
   # Update service.yaml with your project ID
   sed 's/PROJECT_ID/YOUR_PROJECT_ID/g' service.yaml > service-deploy.yaml
   
   # Deploy
   gcloud run services replace service-deploy.yaml --region=europe-west1 --platform=managed
   ```

## Environment Variables

### Production (Cloud Run Multi-Container)
- **Frontend**: `NEXT_PUBLIC_API_URL=http://127.0.0.1:9000`
- **Backend**: `FRONTEND_URL=http://127.0.0.1:8080`

### Local Development
- **Frontend**: `NEXT_PUBLIC_API_URL=http://localhost:8000`
- **Backend**: `FRONTEND_URL=http://localhost:3000`

## Testing Deployment

```powershell
# Test your deployment
.\test-deployment.ps1 -ServiceUrl "https://your-service-url.run.app"
```

## Troubleshooting

### Frontend Shows API Connection Errors

1. **Check Environment Variables**:
   ```bash
   gcloud run services describe YOUR_SERVICE_NAME --region=YOUR_REGION --format="export"
   ```

2. **Verify Internal Communication**:
   - Frontend should call `http://127.0.0.1:9000`
   - Backend should be accessible on port 9000

3. **Check Logs**:
   ```bash
   # Frontend logs
   gcloud logging read 'resource.type=cloud_run_revision AND resource.labels.service_name=YOUR_SERVICE_NAME AND labels."k8s.io/container_name"=web' --limit=50

   # Backend logs  
   gcloud logging read 'resource.type=cloud_run_revision AND resource.labels.service_name=YOUR_SERVICE_NAME AND labels."k8s.io/container_name"=api' --limit=50
   ```

### Build Failures

1. **Check Cloud Build Logs**:
   ```bash
   gcloud builds list --limit=5
   gcloud builds log BUILD_ID
   ```

2. **Common Issues**:
   - Insufficient permissions: Ensure Cloud Build service account has necessary roles
   - Resource limits: Use `machineType: 'E2_HIGHCPU_8'` in cloudbuild.yaml
   - Docker context: Verify Dockerfile paths are correct

### Performance Issues

1. **Increase Resources**:
   - Edit `service.yaml` to increase CPU/memory limits
   - Adjust `containerConcurrency` and `maxScale`

2. **Monitor Metrics**:
   ```bash
   gcloud run services describe YOUR_SERVICE_NAME --region=YOUR_REGION
   ```

## Configuration Files

- `service.yaml`: Cloud Run service configuration
- `cloudbuild.yaml`: Cloud Build pipeline
- `Dockerfile.production`: Frontend container build
- `api/Dockerfile`: Backend container build
- `.env.production`: Production environment variables

## Security Considerations

- Containers communicate via localhost (127.0.0.1) - no external network exposure
- Health checks ensure both containers are running
- Resource limits prevent resource exhaustion
- No sensitive data in environment variables (use Secret Manager for secrets)

## Monitoring

- **Cloud Run Metrics**: CPU, memory, request count, latency
- **Cloud Logging**: Application logs from both containers
- **Error Reporting**: Automatic error detection and alerting
- **Health Checks**: Automated container health monitoring