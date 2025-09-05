# Test script to verify your Cloud Run deployment
param(
    [string]$ServiceUrl
)

if (-not $ServiceUrl) {
    Write-Host "❌ Please provide the service URL:" -ForegroundColor Red
    Write-Host "   .\test-deployment.ps1 -ServiceUrl 'https://your-service-url.run.app'" -ForegroundColor Yellow
    exit 1
}

Write-Host "🧪 Testing Cloud Run deployment" -ForegroundColor Green
Write-Host "Service URL: $ServiceUrl" -ForegroundColor Cyan
Write-Host ""

# Test frontend health
Write-Host "🔍 Testing frontend health..." -ForegroundColor Blue
try {
    $frontendHealth = Invoke-RestMethod -Uri "$ServiceUrl/api/health" -Method Get -TimeoutSec 10
    Write-Host "✅ Frontend health: $($frontendHealth.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test frontend ready
Write-Host "🔍 Testing frontend ready..." -ForegroundColor Blue
try {
    $frontendReady = Invoke-RestMethod -Uri "$ServiceUrl/api/ready" -Method Get -TimeoutSec 10
    Write-Host "✅ Frontend ready: $($frontendReady.status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Frontend ready check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test API endpoints (these should be accessible internally)
Write-Host "🔍 Testing API connection through frontend..." -ForegroundColor Blue
try {
    # This tests if the frontend can reach the API internally
    $response = Invoke-WebRequest -Uri "$ServiceUrl" -Method Get -TimeoutSec 15
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Frontend loads successfully" -ForegroundColor Green
        
        # Check if the page contains any API error messages
        if ($response.Content -match "API.*Error|Connection.*Error|localhost:8000") {
            Write-Host "⚠️  Warning: Page may contain API connection errors" -ForegroundColor Yellow
            Write-Host "   Check the browser console for API call failures" -ForegroundColor Gray
        } else {
            Write-Host "✅ No obvious API connection errors detected" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "❌ Frontend loading failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🌐 Open your browser and navigate to: $ServiceUrl" -ForegroundColor Cyan
Write-Host "📊 Check the browser console (F12) for any API connection errors" -ForegroundColor Yellow