#!/usr/bin/env pwsh
# Script semplificato per deploy

Write-Host "Deploy della soluzione proxy..." -ForegroundColor Yellow

try {
    # Deploy configurazione
    Write-Host "Deploy configurazione..." -ForegroundColor Blue
    Copy-Item "service.yaml" "service-deploy.yaml"
    gcloud run services replace service-deploy.yaml --region=europe-west1 --platform=managed
    
    if ($LASTEXITCODE -ne 0) {
        throw "Deploy configurazione fallito"
    }
    
    # Build immagini
    Write-Host "Build immagini..." -ForegroundColor Blue
    gcloud builds submit --config cloudbuild.yaml
    
    if ($LASTEXITCODE -ne 0) {
        throw "Build fallito"
    }
    
    Write-Host "Deploy completato!" -ForegroundColor Green
    
    # Mostra URL
    $serviceUrl = gcloud run services describe data-viz-satellite --region=europe-west1 --format="value(status.url)"
    Write-Host "URL servizio: $serviceUrl" -ForegroundColor Cyan
    Write-Host "Test manualmente: $serviceUrl/plots/volcano-fastapi" -ForegroundColor Yellow
    
} catch {
    Write-Host "Errore: $_" -ForegroundColor Red
    exit 1
} finally {
    if (Test-Path "service-deploy.yaml") {
        Remove-Item "service-deploy.yaml"
    }
}