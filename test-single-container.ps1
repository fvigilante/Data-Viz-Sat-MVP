# Test script for single container deployment
Write-Host "Building single container with Next.js + FastAPI + R..." -ForegroundColor Green

# Build the container
docker build -t data-viz-satellite-single -f Dockerfile .

if ($LASTEXITCODE -eq 0) {
    Write-Host "Build successful! Starting container..." -ForegroundColor Green
    
    # Run the container
    docker run -p 8080:8080 --name data-viz-test data-viz-satellite-single
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}