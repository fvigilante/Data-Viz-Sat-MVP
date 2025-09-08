# Development script for Windows PowerShell
param(
    [string]$Command = "up"
)

switch ($Command) {
    "up" {
        Write-Host "Starting development environment..." -ForegroundColor Green
        docker-compose -f docker-compose.dev.yml up -d
        Write-Host "Development environment started!" -ForegroundColor Green
        Write-Host "Frontend: http://localhost:3000" -ForegroundColor Cyan
        Write-Host "API: http://localhost:8000" -ForegroundColor Cyan
    }
    "down" {
        Write-Host "Stopping development environment..." -ForegroundColor Yellow
        docker-compose -f docker-compose.dev.yml down
        Write-Host "Development environment stopped!" -ForegroundColor Yellow
    }
    "logs" {
        docker-compose -f docker-compose.dev.yml logs -f
    }
    "build" {
        Write-Host "Building development containers..." -ForegroundColor Blue
        docker-compose -f docker-compose.dev.yml build
        Write-Host "Build complete!" -ForegroundColor Blue
    }
    "restart" {
        Write-Host "Restarting development environment..." -ForegroundColor Yellow
        docker-compose -f docker-compose.dev.yml restart
        Write-Host "Development environment restarted!" -ForegroundColor Green
    }
    default {
        Write-Host "Usage: .\dev.ps1 [up|down|logs|build|restart]" -ForegroundColor White
        Write-Host "  up      - Start development environment" -ForegroundColor Gray
        Write-Host "  down    - Stop development environment" -ForegroundColor Gray
        Write-Host "  logs    - Show logs" -ForegroundColor Gray
        Write-Host "  build   - Build containers" -ForegroundColor Gray
        Write-Host "  restart - Restart containers" -ForegroundColor Gray
    }
}