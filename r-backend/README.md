# R Backend - Volcano Plot API

## 📁 File Structure

```
r-backend/
├── plumber-api-fixed.R           # Main R API server (UNIFIED & OPTIMIZED)
├── install-packages.R            # R package installation script
├── performance-profiling-tests.R # Performance comparison tests (R vs Python)
├── Dockerfile                    # Container configuration
└── README.md                     # This file
```

## 🚀 Quick Start

### Prerequisites
- R (>= 4.0.0)
- Required packages: `plumber`, `data.table`, `jsonlite`

### Installation
```bash
# Install R packages
Rscript install-packages.R

# Start the server
Rscript plumber-api-fixed.R
```

### API Endpoints
- **Health Check**: `GET /health`
- **Volcano Data**: `GET /api/volcano-data`
- **Clear Cache**: `POST /api/clear-cache`
- **Performance Metrics**: `GET /api/performance-metrics`

## ⚡ Performance Features

- **Multi-threading**: Uses all available CPU cores
- **Feature Flag**: `MONITOR_ENABLED=FALSE` (disabled by default for production)
- **Optimized Data Generation**: 3.4x faster than Python in isolated tests
- **Smart Caching**: Automatic dataset caching for repeated requests
- **JSON Compatibility**: Proper format for frontend Plotly integration

## 🧪 Performance Testing

Run performance comparison between R and Python:
```bash
Rscript performance-profiling-tests.R
```

## 🐳 Docker

```bash
# Build image
docker build -t r-volcano-api .

# Run container
docker run -p 8001:8001 r-volcano-api
```

## 🔧 Configuration

### Environment Variables
- `PORT`: Server port (default: 8001)
- `MONITOR_ENABLED`: Enable performance monitoring (default: FALSE)

### Development vs Production
- **Development**: Set `MONITOR_ENABLED=TRUE` for detailed metrics
- **Production**: Keep `MONITOR_ENABLED=FALSE` for optimal performance

## 📊 API Response Format

```json
{
  "data": [
    {
      "gene": "Gene_1",
      "logFC": 1.6452,
      "padj": 0.8851,
      "classyfireSuperclass": "Organoheterocyclic compounds",
      "classyfireClass": "Benzoxazines", 
      "category": "non_significant"
    }
  ],
  "stats": {
    "up_regulated": 7,
    "down_regulated": 7,
    "non_significant": 86
  },
  "total_rows": 100,
  "filtered_rows": 100,
  "points_before_sampling": 100,
  "is_downsampled": false
}
```

## 🎯 Integration

This R backend integrates seamlessly with the Next.js frontend and can be used alongside or instead of the Python FastAPI backend for volcano plot visualization.