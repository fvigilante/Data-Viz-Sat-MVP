#!/bin/bash
set -e

# Function to cleanup processes on exit
cleanup() {
    echo "Shutting down services..."
    if [ ! -z "$R_PID" ]; then
        kill $R_PID 2>/dev/null || true
    fi
    if [ ! -z "$PYTHON_PID" ]; then
        kill $PYTHON_PID 2>/dev/null || true
    fi
    exit
}
trap cleanup SIGTERM SIGINT EXIT

# Health check function
check_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            echo "$service_name is healthy"
            return 0
        fi
        echo "Waiting for $service_name... (attempt $attempt/$max_attempts)"
        sleep 1
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: $service_name failed to start"
    return 1
}

# Start R server in background
echo "Starting R backend server..."
cd r-backend
Rscript plumber-api-fixed.R &
R_PID=$!
cd ..
echo "R server started with PID: $R_PID"

# Wait for R server to be ready
check_service "http://127.0.0.1:8001/health" "R backend"

# Start Python FastAPI server
echo "Starting Python FastAPI server..."
python3 -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-9000} &
PYTHON_PID=$!
echo "Python server started with PID: $PYTHON_PID"

# Wait for Python server to be ready
check_service "http://127.0.0.1:${PORT:-9000}/health" "Python FastAPI"

echo "All services are running successfully!"
echo "R Backend: http://127.0.0.1:8001"
echo "Python API: http://0.0.0.0:${PORT:-9000}"

# Wait for both processes
wait $PYTHON_PID $R_PID