#!/usr/bin/env python3
"""
Development script to run both FastAPI and Next.js concurrently
"""

import subprocess
import sys
import os
import signal
import time
from pathlib import Path

def run_fastapi():
    """Run FastAPI development server"""
    api_dir = Path(__file__).parent.parent / "api"
    os.chdir(api_dir)
    
    # Install dependencies if needed
    subprocess.run(["py", "-m", "pip", "install", "-r", "requirements.txt"], check=True)
    
    # Run FastAPI with uvicorn
    return subprocess.Popen([
        "py", "-m", "uvicorn", "main:app", 
        "--reload", 
        "--host", "0.0.0.0", 
        "--port", "8000"
    ])

def run_nextjs():
    """Run Next.js development server"""
    root_dir = Path(__file__).parent.parent
    os.chdir(root_dir)
    
    # Set environment variable for API URL
    env = os.environ.copy()
    env["NEXT_PUBLIC_API_URL"] = "http://localhost:8000"
    
    # Run Next.js dev server
    return subprocess.Popen(["npm", "run", "dev"], env=env)

def main():
    """Main function to run both servers"""
    print("🚀 Starting Data Viz Satellite development servers...")
    print("📊 FastAPI: http://localhost:8000")
    print("🌐 Next.js: http://localhost:3000")
    print("📖 API Docs: http://localhost:8000/docs")
    print("\nPress Ctrl+C to stop both servers\n")
    
    processes = []
    
    try:
        # Start FastAPI
        print("Starting FastAPI server...")
        fastapi_process = run_fastapi()
        processes.append(fastapi_process)
        time.sleep(2)  # Give FastAPI time to start
        
        # Start Next.js
        print("Starting Next.js server...")
        nextjs_process = run_nextjs()
        processes.append(nextjs_process)
        
        # Wait for processes
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n🛑 Shutting down servers...")
        
        for process in processes:
            if process.poll() is None:  # Process is still running
                process.terminate()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.kill()
        
        print("✅ All servers stopped")

if __name__ == "__main__":
    main()