#!/bin/bash

# Development script to run both FastAPI and Next.js concurrently

echo "🚀 Starting Data Viz Satellite development servers..."
echo "📊 FastAPI: http://localhost:8000"
echo "🌐 Next.js: http://localhost:3000"
echo "📖 API Docs: http://localhost:8000/docs"
echo ""
echo "Press Ctrl+C to stop both servers"
echo ""

# Function to cleanup processes on exit
cleanup() {
    echo ""
    echo "🛑 Shutting down servers..."
    kill $FASTAPI_PID $NEXTJS_PID 2>/dev/null
    wait $FASTAPI_PID $NEXTJS_PID 2>/dev/null
    echo "✅ All servers stopped"
    exit 0
}

# Set trap to cleanup on Ctrl+C
trap cleanup SIGINT SIGTERM

# Start FastAPI in background
echo "Starting FastAPI server..."
cd api
pip install -r requirements.txt > /dev/null 2>&1
uvicorn main:app --reload --host 0.0.0.0 --port 8000 &
FASTAPI_PID=$!
cd ..

# Wait a moment for FastAPI to start
sleep 3

# Start Next.js in background
echo "Starting Next.js server..."
export NEXT_PUBLIC_API_URL="http://localhost:8000"
npm run dev &
NEXTJS_PID=$!

# Wait for both processes
wait $FASTAPI_PID $NEXTJS_PID