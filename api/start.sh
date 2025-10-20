#!/bin/bash

# Start R server in background
echo "Starting R backend server..."
cd r-backend
Rscript plumber-api-fixed.R &
R_PID=$!
cd ..

# Start Python FastAPI server
echo "Starting Python FastAPI server..."
python -m uvicorn main:app --host 0.0.0.0 --port ${PORT:-9000} &
PYTHON_PID=$!

# Wait for both processes
wait $PYTHON_PID $R_PID