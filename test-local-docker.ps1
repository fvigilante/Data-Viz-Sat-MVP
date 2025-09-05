#!/usr/bin/env pwsh

# Test script per l'applicazione Docker locale
Write-Host "🧪 Test dell'applicazione Docker locale" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Verifica che i container siano in esecuzione
Write-Host "`n📋 Verifica stato container..." -ForegroundColor Yellow
$containers = docker-compose ps --format json | ConvertFrom-Json

if ($containers.Count -eq 0) {
    Write-Host "❌ Nessun container in esecuzione. Avvia prima con: docker-compose up -d" -ForegroundColor Red
    exit 1
}

foreach ($container in $containers) {
    $status = if ($container.State -eq "running") { "✅" } else { "❌" }
    Write-Host "$status $($container.Name): $($container.State)" -ForegroundColor $(if ($container.State -eq "running") { "Green" } else { "Red" })
}

# Test API Backend
Write-Host "`n🔧 Test API Backend (FastAPI)..." -ForegroundColor Yellow

try {
    $healthResponse = Invoke-WebRequest -Uri "http://localhost:8000/health" -Method GET
    if ($healthResponse.StatusCode -eq 200) {
        Write-Host "✅ Health check API: OK" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Health check API: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $volcanoResponse = Invoke-WebRequest -Uri "http://localhost:8000/api/volcano-data?dataset_size=100" -Method GET
    if ($volcanoResponse.StatusCode -eq 200) {
        $data = $volcanoResponse.Content | ConvertFrom-Json
        Write-Host "✅ Volcano data API: OK ($($data.data.Count) punti dati)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Volcano data API: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test Frontend
Write-Host "`n🌐 Test Frontend (Next.js)..." -ForegroundColor Yellow

try {
    $frontendResponse = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET
    if ($frontendResponse.StatusCode -eq 200) {
        Write-Host "✅ Homepage frontend: OK" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Homepage frontend: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

try {
    $volcanoPageResponse = Invoke-WebRequest -Uri "http://localhost:3000/plots/volcano-fastapi" -Method GET
    if ($volcanoPageResponse.StatusCode -eq 200) {
        Write-Host "✅ Pagina volcano FastAPI: OK" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Pagina volcano FastAPI: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test comunicazione Frontend -> Backend
Write-Host "`n🔄 Test comunicazione Frontend -> Backend..." -ForegroundColor Yellow

try {
    $proxyResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/volcano-data?dataset_size=100" -Method GET
    if ($proxyResponse.StatusCode -eq 200) {
        $proxyData = $proxyResponse.Content | ConvertFrom-Json
        Write-Host "✅ Proxy frontend -> backend: OK ($($proxyData.data.Count) punti dati)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Proxy frontend -> backend: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test cache status
Write-Host "`n💾 Test cache status..." -ForegroundColor Yellow

try {
    $cacheResponse = Invoke-WebRequest -Uri "http://localhost:8000/api/cache-status" -Method GET
    if ($cacheResponse.StatusCode -eq 200) {
        $cacheData = $cacheResponse.Content | ConvertFrom-Json
        Write-Host "✅ Cache status: OK ($($cacheData.total_cached) dataset cached)" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Cache status: FAILED" -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Test completati!" -ForegroundColor Green
Write-Host "📱 Apri il browser su: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🔧 API disponibile su: http://localhost:8000" -ForegroundColor Cyan
Write-Host "📚 Documentazione API: http://localhost:8000/docs" -ForegroundColor Cyan

Write-Host "`n🛠️  Comandi utili:" -ForegroundColor Yellow
Write-Host "   docker-compose logs web    # Log frontend" -ForegroundColor Gray
Write-Host "   docker-compose logs api    # Log backend" -ForegroundColor Gray
Write-Host "   docker-compose down        # Ferma i container" -ForegroundColor Gray
Write-Host "   docker-compose up -d       # Avvia i container" -ForegroundColor Gray