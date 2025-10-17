# Development Guide

## 🚀 Quick Start

### Start All Servers (Recommended)
```bash
npm run dev:full
```

This single command starts:
- ✅ **FastAPI Server** (port 8000) - Python backend
- ✅ **R Backend Server** (port 8001) - R statistical computing
- ✅ **Next.js Dev Server** (port 3000) - Frontend

### Access Your Applications
- **Homepage**: http://localhost:3000
- **FastAPI Volcano Plot**: http://localhost:3000/plots/volcano-fastapi
- **R Volcano Plot**: http://localhost:3000/plots/volcano-r ⭐ **NEW!**
- **API Documentation**: http://localhost:8000/docs
- **R API Documentation**: http://localhost:8001/__docs__/

## 🔧 Individual Server Commands

If you need to start servers individually:

```bash
# Next.js only
npm run dev

# FastAPI only  
npm run dev:api

# R Backend only
npm run dev:r

# R Backend with custom script
npm run dev:r-start
```

## 📋 Prerequisites

### Required
- **Node.js** (v18+)
- **Python** (v3.8+)
- **pip** (Python package manager)

### Optional (for R features)
- **R** (v4.0+)
- **R packages**: Will be installed automatically

## 🎯 Feature Comparison

| Feature | FastAPI Version | R Version |
|---------|----------------|-----------|
| **URL** | `/plots/volcano-fastapi` | `/plots/volcano-r` |
| **Backend** | Python + Polars | R + data.table |
| **Performance** | High | High |
| **Data Generation** | Synthetic | Synthetic |
| **UI/UX** | ✅ Identical | ✅ Identical |
| **Export** | CSV + PNG | CSV + PNG |
| **Caching** | ✅ | ✅ |

## 🚨 Troubleshooting

### R Backend Issues
If R backend fails to start:
1. Install R: https://cran.r-project.org/
2. Install packages: `Rscript r-backend/install-packages.R`
3. Check R version: `Rscript --version`

### Python Issues
If FastAPI fails to start:
1. Install Python dependencies: `pip install -r api/requirements.txt`
2. Check Python version: `python --version`

### Port Conflicts
If ports are in use:
- FastAPI: Change port in `scripts/dev.py` (line with `--port 8000`)
- R Backend: Change port in `r-backend/plumber-api.R`
- Next.js: Use `npm run dev -- -p 3001`

## 📊 Testing

```bash
# Run all tests
npm test

# R-specific tests
npm run test:r

# Integration tests
npm run test:integration

# Performance benchmarks
npm run benchmark:quick
```

## 🐳 Docker Alternative

```bash
# Build and start all services
npm run docker:up

# Stop all services
npm run docker:down
```

## 🎉 Success Indicators

When `npm run dev:full` works correctly, you should see:

```
🚀 Starting Data Viz Satellite development servers...
📊 FastAPI: http://localhost:8000
🔬 R Backend: http://localhost:8001  
🌐 Next.js: http://localhost:3000
📖 API Docs: http://localhost:8000/docs
📊 R API Docs: http://localhost:8001/__docs__/

Starting FastAPI server...
Starting R backend server...
Starting Next.js server...

✅ All servers started successfully!
🎯 Visit: http://localhost:3000/plots/volcano-r
🎯 Compare: http://localhost:3000/plots/volcano-fastapi
```

**Now you can visit both volcano plot implementations and compare them side by side!** 🎉