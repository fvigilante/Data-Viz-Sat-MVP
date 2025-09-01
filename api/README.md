# Data Viz Satellite API

FastAPI + Polars backend for high-performance volcano plot data processing.

## Features

- **FastAPI**: Modern, fast web framework for building APIs
- **Polars**: Lightning-fast DataFrame library for data processing
- **Server-side Filtering**: p-value, log2FC ranges, and search filtering
- **Optimized Performance**: Handles 100K+ data points efficiently
- **CORS Support**: Ready for Next.js frontend integration

## API Endpoints

### GET /api/volcano-data

Query parameters:
- `p_value_threshold` (float): P-value threshold (0.0-1.0, default: 0.05)
- `log_fc_min` (float): Minimum log2FC (-10.0-10.0, default: -0.5)
- `log_fc_max` (float): Maximum log2FC (-10.0-10.0, default: 0.5)
- `search_term` (string, optional): Search term for metabolite names
- `dataset_size` (int): Number of synthetic data points (100-1000000, default: 10000)

### POST /api/volcano-data

JSON body:
```json
{
  "p_value_threshold": 0.05,
  "log_fc_min": -0.5,
  "log_fc_max": 0.5,
  "search_term": "methionine",
  "dataset_size": 10000
}
```

## Response Format

```json
{
  "data": [
    {
      "gene": "Methionine",
      "logFC": 2.34,
      "padj": 0.001,
      "classyfireSuperclass": "Organic acids and derivatives",
      "classyfireClass": "Carboxylic acids and derivatives",
      "category": "up"
    }
  ],
  "stats": {
    "up_regulated": 150,
    "down_regulated": 120,
    "non_significant": 9730
  },
  "total_rows": 10000,
  "filtered_rows": 10000
}
```

## Development

### Local Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Docker

```bash
# Build image
docker build -t data-viz-api .

# Run container
docker run -p 8000:8000 data-viz-api
```

## Performance

- **Polars Processing**: 10x faster than pandas for large datasets
- **Memory Efficient**: Optimized for 100K+ data points
- **Lazy Evaluation**: Efficient query planning and execution
- **Parallel Processing**: Multi-threaded operations

## Integration

The API is designed to integrate seamlessly with the Next.js frontend:

```typescript
// Frontend integration example
const response = await fetch('/api/volcano-data?' + new URLSearchParams({
  p_value_threshold: '0.05',
  log_fc_min: '-0.5',
  log_fc_max: '0.5',
  search_term: 'methionine',
  dataset_size: '10000'
}))

const data = await response.json()
```