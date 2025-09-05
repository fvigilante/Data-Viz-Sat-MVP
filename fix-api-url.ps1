# Quick fix script to update the API URL in your existing Cloud Run deployment
param(
    [string]$ProjectId = "data-viz-satellite-mvp",
    [string]$Region = "europe-west1",
    [string]$ServiceName = "data-viz-sat-mvp"
)

Write-Host "🔧 Fixing API URL configuration for Cloud Run service" -ForegroundColor Green
Write-Host "Project: $ProjectId" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Service: $ServiceName" -ForegroundColor Cyan
Write-Host ""

# Set the project
gcloud config set project $ProjectId

# Update the service with correct environment variables
Write-Host "📝 Updating service configuration..." -ForegroundColor Blue

# Create a temporary service.yaml with your actual project ID
$tempServiceFile = "service-temp.yaml"
(Get-Content service.yaml) -replace 'PROJECT_ID', $ProjectId | Set-Content $tempServiceFile

# Deploy the updated configuration
gcloud run services replace $tempServiceFile --region=$Region --platform=managed

# Clean up
Remove-Item $tempServiceFile

# Get the service URL
Write-Host "🌐 Getting service URL..." -ForegroundColor Blue
$ServiceUrl = gcloud run services describe $ServiceName --region=$Region --format="value(status.url)"

Write-Host ""
Write-Host "✅ Configuration updated!" -ForegroundColor Green
Write-Host "🌍 Service URL: $ServiceUrl" -ForegroundColor Cyan
Write-Host ""
Write-Host "The frontend should now correctly call the API at http://127.0.0.1:9000" -ForegroundColor Yellow
Write-Host "Test your deployment at: $ServiceUrl" -ForegroundColor Cyan