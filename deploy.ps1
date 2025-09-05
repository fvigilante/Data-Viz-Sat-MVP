# Deploy script for Google Cloud Run multi-container setup
param(
    [string]$ProjectId = "your-project-id",
    [string]$Region = "europe-west1"
)

$ServiceName = "data-viz-satellite"

Write-Host "🚀 Deploying Data Viz Satellite to Google Cloud Run" -ForegroundColor Green
Write-Host "Project: $ProjectId" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Service: $ServiceName" -ForegroundColor Cyan
Write-Host ""

# Check if gcloud is authenticated
$activeAccount = gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>$null
if (-not $activeAccount) {
    Write-Host "❌ Please authenticate with gcloud first:" -ForegroundColor Red
    Write-Host "   gcloud auth login" -ForegroundColor Yellow
    exit 1
}

# Set the project
Write-Host "📋 Setting project..." -ForegroundColor Blue
gcloud config set project $ProjectId

# Enable required APIs
Write-Host "🔧 Enabling required APIs..." -ForegroundColor Blue
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Submit build to Cloud Build
Write-Host "🏗️  Building and deploying with Cloud Build..." -ForegroundColor Blue
gcloud builds submit --config cloudbuild.yaml --substitutions="_DEPLOY_REGION=$Region"

# Get the service URL
Write-Host "🌐 Getting service URL..." -ForegroundColor Blue
$ServiceUrl = gcloud run services describe $ServiceName --region=$Region --format="value(status.url)"

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌍 Service URL: $ServiceUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔍 To view logs:" -ForegroundColor Yellow
Write-Host "   gcloud logging read 'resource.type=cloud_run_revision AND resource.labels.service_name=$ServiceName' --limit=50 --format='table(timestamp,textPayload)'" -ForegroundColor Gray
Write-Host ""
Write-Host "📊 To view service details:" -ForegroundColor Yellow
Write-Host "   gcloud run services describe $ServiceName --region=$Region" -ForegroundColor Gray