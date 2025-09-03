# Build and Deploy Script for Google Cloud Run Multi-Container
# Usage: .\scripts\build-and-deploy.ps1 [PROJECT_ID] [REGION]

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectId = $env:GOOGLE_CLOUD_PROJECT,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "europe-west1"
)

$Repository = "data-viz-satellite"

if (-not $ProjectId) {
    Write-Error "PROJECT_ID is required. Provide it as parameter or set GOOGLE_CLOUD_PROJECT environment variable"
    Write-Host "Usage: .\scripts\build-and-deploy.ps1 <PROJECT_ID> [REGION]"
    exit 1
}

Write-Host "🚀 Building and deploying Data Viz Satellite to Google Cloud Run" -ForegroundColor Green
Write-Host "Project ID: $ProjectId"
Write-Host "Region: $Region"
Write-Host "Repository: $Repository"
Write-Host ""

# Configure Docker authentication
Write-Host "🔐 Configuring Docker authentication..." -ForegroundColor Yellow
gcloud auth configure-docker "$Region-docker.pkg.dev"

# Build and push frontend image
Write-Host "🏗️  Building frontend image..." -ForegroundColor Yellow
docker build -f Dockerfile.production -t "$Region-docker.pkg.dev/$ProjectId/$Repository/frontend:latest" .

Write-Host "📤 Pushing frontend image..." -ForegroundColor Yellow
docker push "$Region-docker.pkg.dev/$ProjectId/$Repository/frontend:latest"

# Build and push API image
Write-Host "🏗️  Building API image..." -ForegroundColor Yellow
docker build -f api/Dockerfile -t "$Region-docker.pkg.dev/$ProjectId/$Repository/api:latest" ./api

Write-Host "📤 Pushing API image..." -ForegroundColor Yellow
docker push "$Region-docker.pkg.dev/$ProjectId/$Repository/api:latest"

# Update service.yaml with project details
Write-Host "📝 Updating service.yaml..." -ForegroundColor Yellow
Copy-Item service.yaml service-deploy.yaml
(Get-Content service-deploy.yaml) -replace 'PROJECT_ID', $ProjectId | Set-Content service-deploy.yaml
(Get-Content service-deploy.yaml) -replace 'gcr.io', "$Region-docker.pkg.dev" | Set-Content service-deploy.yaml

# Deploy to Cloud Run
Write-Host "🚀 Deploying to Cloud Run..." -ForegroundColor Yellow
gcloud run services replace service-deploy.yaml --region=$Region --allow-unauthenticated

# Get service URL
Write-Host "✅ Deployment complete!" -ForegroundColor Green
$ServiceUrl = gcloud run services describe data-viz-satellite --region=$Region --format="value(status.url)"

Write-Host ""
Write-Host "🌐 Service URL: $ServiceUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 You can now access your Data Viz Satellite application!" -ForegroundColor Green

# Clean up temporary file
Remove-Item service-deploy.yaml