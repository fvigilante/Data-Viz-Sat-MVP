#!/usr/bin/env python3
"""
Development script to run FastAPI, R backend, and Next.js concurrently
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

def run_r_backend():
    """Run R backend server"""
    r_dir = Path(__file__).parent.parent / "r-backend"
    os.chdir(r_dir)
    
    # Define R paths (similar to how Python uses 'py')
    r_paths = [
        "Rscript",  # Try PATH first
        r"C:\Program Files\R\R-4.5.1\bin\Rscript.exe",  # Windows default
        r"C:\Program Files\R\R-4.4.1\bin\Rscript.exe",  # Alternative version
        r"C:\Program Files\R\R-4.3.2\bin\Rscript.exe",  # Alternative version
    ]
    
    # Find working R installation
    rscript_cmd = None
    for r_path in r_paths:
        try:
            subprocess.run([r_path, "--version"], check=True, capture_output=True)
            rscript_cmd = r_path
            print(f"✓ Found R at: {r_path}")
            break
        except (subprocess.CalledProcessError, FileNotFoundError):
            continue
    
    if rscript_cmd is None:
        print("⚠️  R not found. Installing R packages will be skipped.")
        print("   Install R and run: Rscript r-backend/install-packages.R")
        return None
    
    # Install R packages if needed
    try:
        print("📦 Installing R packages...")
        subprocess.run([rscript_cmd, "install-packages.R"], check=True)
    except subprocess.CalledProcessError:
        print("⚠️  R package installation failed. R backend may not work properly.")
    
    # Run R server
    return subprocess.Popen([rscript_cmd, "plumber-api.R"])

def run_nextjs():
    """Run Next.js development server"""
    root_dir = Path(__file__).parent.parent
    os.chdir(root_dir)
    
    # Set environment variables
    env = os.environ.copy()
    env["NEXT_PUBLIC_API_URL"] = "http://localhost:8000"
    env["NEXT_PUBLIC_R_BACKEND_URL"] = "http://localhost:8001"
    env["NEXT_PUBLIC_R_BACKEND_ENABLED"] = "true"
    
    # Determine npm command based on OS
    npm_cmd = "npm.cmd" if os.name == "nt" else "npm"
    
    # Run Next.js dev server
    return subprocess.Popen([npm_cmd, "run", "dev"], env=env, shell=True)

def main():
    """Main function to run all servers"""
    print("🚀 Starting Data Viz Satellite development servers...")
    print("📊 FastAPI: http://localhost:8000")
    print("🔬 R Backend: http://localhost:8001")
    print("🌐 Next.js: http://localhost:3000")
    print("📖 API Docs: http://localhost:8000/docs")
    print("📊 R API Docs: http://localhost:8001/__docs__/")
    print("\nPress Ctrl+C to stop all servers\n")
    
    processes = []
    
    try:
        # Start FastAPI
        print("Starting FastAPI server...")
        fastapi_process = run_fastapi()
        processes.append(fastapi_process)
        time.sleep(2)  # Give FastAPI time to start
        
        # Start R backend
        print("Starting R backend server...")
        r_process = run_r_backend()
        if r_process:
            processes.append(r_process)
            time.sleep(3)  # Give R server time to start
        
        # Start Next.js
        print("Starting Next.js server...")
        nextjs_process = run_nextjs()
        processes.append(nextjs_process)
        
        print("\n✅ All servers started successfully!")
        print("🎯 Visit: http://localhost:3000/plots/volcano-r")
        print("🎯 Compare: http://localhost:3000/plots/volcano-fastapi")
        
        # Wait for processes
        while True:
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\n🛑 Shutting down all servers...")
        
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