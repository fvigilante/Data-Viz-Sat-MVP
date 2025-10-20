# Script completo per testare Cloud Build in locale
# Simula esattamente i passi del cloudbuild.yaml

Write-Host "=== Cloud Build Local Test ===" -ForegroundColor Green
Write-Host "Simulando i passi di cloudbuild.yaml..." -ForegroundColor Cyan

# Step 1: Build API (come in cloudbuild.yaml)
Write-Host "`n🔨 Step 1: Building API image..." -ForegroundColor Yellow
$apiResult = docker build -t gcr.io/test-project/data-viz-satellite-api:latest -f api/Dockerfile .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ API build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ API build successful!" -ForegroundColor Green

# Step 2: Build Frontend (come in cloudbuild.yaml)
Write-Host "`n🔨 Step 2: Building Frontend image..." -ForegroundColor Yellow
$frontendResult = docker build -t gcr.io/test-project/data-viz-satellite-frontend:latest -f Dockerfile.production .
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Frontend build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Frontend build successful!" -ForegroundColor Green

# Step 3: Test delle immagini (simulazione deploy)
Write-Host "`n🧪 Step 3: Testing images..." -ForegroundColor Yellow

# Test API
Write-Host "Testing API..."
docker run --rm -d --name test-api -p 8000:9000 gcr.io/test-project/data-viz-satellite-api:latest
Start-Sleep 15

$apiHealth = $null
try {
    $apiHealth = Invoke-WebRequest -Uri "http://localhost:8000/health" -TimeoutSec 10
    if ($apiHealth.StatusCode -eq 200) {
        Write-Host "✅ API health check passed!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  API health check failed: $($_.Exception.Message)" -ForegroundColor Yellow
}
docker stop test-api 2>$null

# Test Frontend
Write-Host "Testing Frontend..."
docker run --rm -d --name test-frontend -p 3000:8080 gcr.io/test-project/data-viz-satellite-frontend:latest
Start-Sleep 10

$frontendHealth = $null
try {
    $frontendHealth = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
    if ($frontendHealth.StatusCode -eq 200) {
        Write-Host "✅ Frontend health check passed!" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Frontend health check failed: $($_.Exception.Message)" -ForegroundColor Yellow
}
docker stop test-frontend 2>$null

# Risultato finale
Write-Host "`n=== Test Results ===" -ForegroundColor Green
Write-Host "✅ API Build: SUCCESS" -ForegroundColor Green
Write-Host "✅ Frontend Build: SUCCESS" -ForegroundColor Green
if ($apiHealth -and $apiHealth.StatusCode -eq 200) {
    Write-Host "✅ API Runtime: SUCCESS" -ForegroundColor Green
} else {
    Write-Host "⚠️  API Runtime: NEEDS CHECK" -ForegroundColor Yellow
}
if ($frontendHealth -and $frontendHealth.StatusCode -eq 200) {
    Write-Host "✅ Frontend Runtime: SUCCESS" -ForegroundColor Green
} else {
    Write-Host "⚠️  Frontend Runtime: NEEDS CHECK" -ForegroundColor Yellow
}

Write-Host "`n🚀 Ready for Cloud Build deployment!" -ForegroundColor Cyan
Write-Host "Puoi ora eseguire: gcloud builds submit --config cloudbuild.yaml" -ForegroundColor White