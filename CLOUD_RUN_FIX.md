# Cloud Run API URL Fix

## Problem
Your Next.js frontend was hardcoded to call `http://localhost:8000`, which only works in local development. In Cloud Run multi-container setup, the frontend needs to call the internal API at `http://127.0.0.1:9000`.

## What We Fixed

### 1. Added Missing Health Check Endpoints
- Created `/app/api/health/route.ts`
- Created `/app/api/ready/route.ts`
- These are required by your `service.yaml` health checks

### 2. Updated Next.js Configuration
- Added `output: 'standalone'` to `next.config.mjs` for proper containerization
- Added build-time environment variables to `Dockerfile.production`

### 3. Environment Variable Configuration
- Created `.env.production` with correct Cloud Run settings
- Updated `Dockerfile.production` to use production environment variables during build
- The key fix: `NEXT_PUBLIC_API_URL=http://127.0.0.1:9000`

### 4. Deployment Scripts
- `fix-api-url.ps1` (Windows) - Quick fix for existing deployment
- `fix-api-url.sh` (Linux/Mac) - Quick fix for existing deployment  
- `deploy.ps1` (Windows) - Full deployment script
- `deploy.sh` (Linux/Mac) - Full deployment script
- `cloudbuild.yaml` - Cloud Build configuration

### 5. Testing and Documentation
- `test-deployment.ps1` - Verify deployment works
- `DEPLOYMENT.md` - Complete deployment guide
- `CLOUD_RUN_FIX.md` - This summary

## Quick Fix (For Existing Deployment)

If you already have a deployment running, use the quick fix:

### Windows PowerShell:
```powershell
.\fix-api-url.ps1 -ProjectId "your-project-id" -Region "europe-west1" -ServiceName "your-service-name"
```

### Linux/Mac:
```bash
chmod +x fix-api-url.sh
./fix-api-url.sh your-project-id europe-west1 your-service-name
```

## Full Redeployment (Recommended)

For a complete fix with all improvements:

### Windows PowerShell:
```powershell
.\deploy.ps1 -ProjectId "your-project-id" -Region "europe-west1"
```

### Linux/Mac:
```bash
chmod +x deploy.sh
./deploy.sh your-project-id europe-west1
```

## Verify the Fix

After deployment, test it:

```powershell
.\test-deployment.ps1 -ServiceUrl "https://your-service-url.run.app"
```

## Key Changes Summary

1. **Frontend now correctly calls**: `http://127.0.0.1:9000` (internal API)
2. **Health checks work**: `/api/health` and `/api/ready` endpoints added
3. **Proper containerization**: Standalone Next.js build
4. **Environment variables**: Set at build time and runtime
5. **Deployment automation**: Scripts for easy deployment and fixes

## Expected Result

- ✅ Frontend loads without API connection errors
- ✅ Volcano plots and PCA plots load data successfully  
- ✅ No more "localhost:8000" connection failures
- ✅ Health checks pass
- ✅ Both containers communicate internally

Your Cloud Run deployment should now work correctly with the frontend calling the internal API instead of trying to reach localhost:8000!