#!/usr/bin/env pwsh
# Script per deploy e test della soluzione proxy

Write-Host "🚀 Deploy e Test della soluzione proxy..." -ForegroundColor Yellow

# Verifica che gcloud sia configurato
$project = gcloud config get-value project
if (-not $project) {
    Write-Host "❌ Errore: gcloud non è configurato" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Progetto attivo: $project" -ForegroundColor Green

try {
    # 1. Deploy del servizio aggiornato
    Write-Host "🔧 Step 1: Deploy configurazione aggiornata..." -ForegroundColor Blue
    Copy-Item "service.yaml" "service-deploy.yaml"
    gcloud run services replace service-deploy.yaml --region=europe-west1 --platform=managed
    
    if ($LASTEXITCODE -ne 0) {
        throw "Deploy fallito"
    }
    
    Write-Host "✅ Deploy configurazione completato" -ForegroundColor Green
    
    # 2. Build e deploy delle immagini aggiornate
    Write-Host "🔧 Step 2: Build e deploy immagini aggiornate..." -ForegroundColor Blue
    gcloud builds submit --config cloudbuild.yaml
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build fallito"
    }
    
    Write-Host "✅ Build completato" -ForegroundColor Green
    
    # 3. Attendi che il servizio sia pronto
    Write-Host "⏳ Step 3: Attesa che il servizio sia pronto..." -ForegroundColor Blue
    Start-Sleep -Seconds 30
    
    # 4. Ottieni URL del servizio
    $serviceUrl = gcloud run services describe data-viz-satellite --region=europe-west1 --format="value(status.url)"
    Write-Host "🌐 URL del servizio: $serviceUrl" -ForegroundColor Cyan
    
    # 5. Test delle API proxy
    Write-Host "🧪 Step 4: Test delle API proxy..." -ForegroundColor Blue
    
    # Test volcano-data endpoint
    Write-Host "  Testing /api/volcano-data..." -ForegroundColor White
    try {
        $volcanoUrl = "$serviceUrl/api/volcano-data?dataset_size=1000" + "&p_value_threshold=0.05" + "&log_fc_min=-0.5" + "&log_fc_max=0.5" + "&max_points=1000"
        $volcanoResponse = Invoke-WebRequest -Uri $volcanoUrl -Method GET -TimeoutSec 30
        if ($volcanoResponse.StatusCode -eq 200) {
            $volcanoData = $volcanoResponse.Content | ConvertFrom-Json
            Write-Host "    ✅ Volcano API: HTTP $($volcanoResponse.StatusCode) - Received $($volcanoData.data.Count) data points" -ForegroundColor Green
        } else {
            Write-Host "    ❌ Volcano API: HTTP $($volcanoResponse.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ❌ Volcano API: Error - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Test pca-data endpoint
    Write-Host "  Testing /api/pca-data..." -ForegroundColor White
    try {
        $pcaUrl = "$serviceUrl/api/pca-data?dataset_size=500" + "&n_features=50" + "&n_groups=3" + "&max_points=500"
        $pcaResponse = Invoke-WebRequest -Uri $pcaUrl -Method GET -TimeoutSec 30
        if ($pcaResponse.StatusCode -eq 200) {
            $pcaData = $pcaResponse.Content | ConvertFrom-Json
            Write-Host "    ✅ PCA API: HTTP $($pcaResponse.StatusCode) - Received $($pcaData.data.Count) data points" -ForegroundColor Green
        } else {
            Write-Host "    ❌ PCA API: HTTP $($pcaResponse.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "    ❌ PCA API: Error - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 6. Test della pagina volcano-fastapi
    Write-Host "🧪 Step 5: Test pagina volcano-fastapi..." -ForegroundColor Blue
    try {
        $pageResponse = Invoke-WebRequest -Uri "$serviceUrl/plots/volcano-fastapi" -Method GET -TimeoutSec 30
        if ($pageResponse.StatusCode -eq 200) {
            Write-Host "  ✅ Pagina volcano-fastapi: HTTP $($pageResponse.StatusCode)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Pagina volcano-fastapi: HTTP $($pageResponse.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host "  ❌ Pagina volcano-fastapi: Error - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 7. Mostra informazioni sulla revisione
    Write-Host "📊 Step 6: Informazioni revisione..." -ForegroundColor Blue
    $latestRevision = gcloud run services describe data-viz-satellite --region=europe-west1 --format="value(status.latestReadyRevisionName)"
    Write-Host "  Revisione attiva: $latestRevision" -ForegroundColor White
    
    # 8. Link ai log
    Write-Host "📋 Step 7: Link ai log..." -ForegroundColor Blue
    $logUrl = "https://console.cloud.google.com/logs/viewer?project=$project" + "&resource=cloud_run_revision/service_name/data-viz-satellite/revision_name/$latestRevision"
    Write-Host "  Log Cloud Run: $logUrl" -ForegroundColor Cyan
    
    Write-Host "`n🎉 Deploy e test completati!" -ForegroundColor Green
    Write-Host "🔗 Testa manualmente: $serviceUrl/plots/volcano-fastapi" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ Errore: $_" -ForegroundColor Red
    exit 1
} finally {
    # Pulisci file temporanei
    if (Test-Path "service-deploy.yaml") {
        Remove-Item "service-deploy.yaml"
    }
}