# Single Container Cloud Run Deployment Script
param(
    [string]$ProjectId = $env:GOOGLE_CLOUD_PROJECT,
    [string]$Region = "europe-west1"
)

if (-not $ProjectId) {
    Write-Host "Error: PROJECT_ID not set. Use -ProjectId parameter or set GOOGLE_CLOUD_PROJECT environment variable." -ForegroundColor Red
    exit 1
}

Write-Host "Deploying single container to Cloud Run..." -ForegroundColor Green
Write-Host "Project ID: $ProjectId" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan

# Build and deploy using Cloud Build
Write-Host "`nStarting Cloud Build..." -ForegroundColor Yellow
gcloud builds submit --config cloudbuild-single.yaml --substitutions=_DEPLOY_REGION=$Region

if ($LASTEXITCODE -eq 0) {
    Write-Host "`nDeployment successful!" -ForegroundColor Green
    Write-Host "Service URL: https://data-viz-sat-mvp-single-$($ProjectId.Replace(':', '-')).a.run.app" -ForegroundColor Cyan
    
    Write-Host "`nTesting endpoints..." -ForegroundColor Yellow
    $serviceUrl = "https://data-viz-sat-mvp-single-$($ProjectId.Replace(':', '-')).a.run.app"
    
    Write-Host "Health check: $serviceUrl/api/health" -ForegroundColor Cyan
    Write-Host "R Health: $serviceUrl/api/r-health" -ForegroundColor Cyan
    Write-Host "R Volcano Data: $serviceUrl/api/r-volcano-data-new?dataset_size=100" -ForegroundColor Cyan
} else {
    Write-Host "`nDeployment failed!" -ForegroundColor Red
    exit 1
}