#!/usr/bin/env pwsh
# Script per correggere le variabili d'ambiente di Cloud Run

Write-Host "Correzione variabili d'ambiente Cloud Run..." -ForegroundColor Yellow

# Verifica che gcloud sia configurato
$project = gcloud config get-value project
if (-not $project) {
    Write-Host "Errore: gcloud non e' configurato. Esegui 'gcloud auth login' e 'gcloud config set project data-viz-satellite-mvp'" -ForegroundColor Red
    exit 1
}

Write-Host "Progetto attivo: $project" -ForegroundColor Green

# Deploy del servizio con le nuove variabili d'ambiente
Write-Host "Deploying servizio con variabili corrette..." -ForegroundColor Blue

try {
    # Copia il service.yaml per il deploy
    Copy-Item "service.yaml" "service-deploy.yaml"
    
    # Deploy del servizio
    gcloud run services replace service-deploy.yaml --region=europe-west1 --platform=managed
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Deploy completato con successo!" -ForegroundColor Green
        
        Write-Host "URL del servizio:" -ForegroundColor Cyan
        gcloud run services describe data-viz-satellite --region=europe-west1 --format="value(status.url)"
        
        Write-Host "IMPORTANTE: Ora devi fare un nuovo build del frontend per iniettare le variabili corrette nel bundle JavaScript!" -ForegroundColor Yellow
        Write-Host "Esegui: gcloud builds submit --config cloudbuild.yaml" -ForegroundColor White
        
    } else {
        Write-Host "Errore durante il deploy" -ForegroundColor Red
        exit 1
    }
    
} catch {
    Write-Host "Errore: $_" -ForegroundColor Red
    exit 1
} finally {
    # Pulisci il file temporaneo
    if (Test-Path "service-deploy.yaml") {
        Remove-Item "service-deploy.yaml"
    }
}

Write-Host "Correzione completata!" -ForegroundColor Green