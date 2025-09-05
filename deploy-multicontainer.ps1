# Deploy multi-container setup to Cloud Run
param(
    [string]$ProjectId = "data-viz-satellite-mvp",
    [string]$Region = "europe-west1",
    [string]$ServiceName = "data-viz-sat-mvp"
)

Write-Host "🚀 Deploying Multi-Container Setup to Cloud Run" -ForegroundColor Green
Write-Host "Project: $ProjectId" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Service: $ServiceName" -ForegroundColor Cyan
Write-Host ""

# Set the project
gcloud config set project $ProjectId

# Enable required APIs
Write-Host "🔧 Enabling required APIs..." -ForegroundColor Blue
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build and push images manually
Write-Host "🏗️  Building FastAPI backend image..." -ForegroundColor Blue
docker build -t gcr.io/$ProjectId/data-viz-satellite-api:latest -f api/Dockerfile ./api

Write-Host "🏗️  Building Next.js frontend image..." -ForegroundColor Blue
docker build -t gcr.io/$ProjectId/data-viz-satellite-frontend:latest -f Dockerfile.production .

Write-Host "📤 Pushing images to Container Registry..." -ForegroundColor Blue
docker push gcr.io/$ProjectId/data-viz-satellite-api:latest
docker push gcr.io/$ProjectId/data-viz-satellite-frontend:latest

# Deploy the multi-container service
Write-Host "🚀 Deploying multi-container service..." -ForegroundColor Blue
gcloud run services replace service.yaml --region=$Region --platform=managed

# Get the service URL
Write-Host "🌐 Getting service URL..." -ForegroundColor Blue
$ServiceUrl = gcloud run services describe $ServiceName --region=$Region --format="value(status.url)"

Write-Host ""
Write-Host "✅ Multi-container deployment complete!" -ForegroundColor Green
Write-Host "🌍 Service URL: $ServiceUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔍 Frontend will call API at: http://127.0.0.1:9000" -ForegroundColor Yellow
Write-Host "📊 Test your deployment at: $ServiceUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Check logs in Cloud Console or use gcloud logging commands" -ForegroundColor Yellow