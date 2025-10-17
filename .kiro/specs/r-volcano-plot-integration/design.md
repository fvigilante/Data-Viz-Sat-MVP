# Design Document

## Overview

This design document outlines the integration of an R-based volcano plot backend into the existing Next.js + FastAPI Data Visualization Satellite application. The solution maintains architectural simplicity by leveraging the existing Next.js API route proxy pattern while adding R processing capabilities through lightweight integration methods. The design ensures functional parity with the Python implementation while enabling performance comparison and benchmarking.

## Architecture

### High-Level Architecture

The R integration follows the existing proxy pattern used by the FastAPI implementation:

```
Frontend (Next.js) → Next.js API Routes → R Backend Processing → JSON Response
```

### Integration Approach

**Option 1: Plumber R API Server (Recommended)**
- Lightweight R HTTP API server using the `plumber` package
- Runs on a separate port (e.g., 8001) alongside FastAPI (port 8000)
- Next.js API routes proxy requests to R server similar to FastAPI pattern
- Maintains clean separation and allows independent R process management

**Option 2: Direct R Script Execution**
- Next.js API routes execute R scripts using Node.js `child_process`
- R scripts read JSON input from stdin and output JSON to stdout
- Simpler setup but potentially higher latency per request
- Suitable for development and testing phases

### Component Integration

The design reuses existing frontend components with minimal modifications:

1. **New Page**: `/app/plots/volcano-r/page.tsx` - Duplicate of FastAPI page with R-specific branding
2. **New Component**: `RVolcanoPlot.tsx` - Clone of `FastAPIVolcanoPlot.tsx` with R API endpoints
3. **New API Routes**: `/app/api/r-volcano-*` - Proxy routes for R backend communication
4. **R Backend**: Standalone R server or script execution layer

## Components and Interfaces

### Frontend Components

#### 1. R Volcano Plot Page (`/app/plots/volcano-r/page.tsx`)
```typescript
// Identical structure to FastAPI page with R-specific styling
export default function VolcanoRPage() {
  return (
    <div className="flex-1 flex flex-col h-full">
      <div className="bg-white border-b border-slate-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Volcano Plot (R + data.table)</h1>
            <p className="text-sm text-slate-600 mt-1">
              High-performance server-side data processing with R and data.table
            </p>
          </div>
          <div className="flex items-center gap-2 text-sm text-blue-600">
            <div className="h-2 w-2 bg-blue-600 rounded-full"></div>
            <span>R + data.table Backend</span>
          </div>
        </div>
      </div>
      <div className="flex-1 bg-slate-50 overflow-auto">
        <RVolcanoPlot />
        <div className="p-6">
          <TechExplainer type="r" />
        </div>
      </div>
    </div>
  )
}
```

#### 2. R Volcano Plot Component (`/components/RVolcanoPlot.tsx`)
- Clone of `FastAPIVolcanoPlot.tsx` with modified API endpoints
- Identical UI controls, filtering, and visualization logic
- Updated API calls to use R-specific endpoints (`/api/r-volcano-data`, `/api/r-cache-status`, etc.)
- Same state management and user interaction patterns

### API Layer

#### Next.js API Routes
New API routes following the existing proxy pattern:

1. **`/app/api/r-volcano-data/route.ts`** - Main data endpoint
2. **`/app/api/r-cache-status/route.ts`** - Cache status endpoint  
3. **`/app/api/r-warm-cache/route.ts`** - Cache warming endpoint
4. **`/app/api/r-clear-cache/route.ts`** - Cache clearing endpoint

#### API Configuration Updates
Extend `lib/api-config.ts` to include R endpoints:

```typescript
export const API_CONFIG = {
  // ... existing config
  endpoints: {
    // ... existing endpoints
    rVolcanoData: '/api/r-volcano-data',
    rCacheStatus: '/api/r-cache-status', 
    rWarmCache: '/api/r-warm-cache',
    rClearCache: '/api/r-clear-cache',
  }
}
```

### R Backend Implementation

#### Option 1: Plumber API Server (`r-backend/plumber-api.R`)

```r
library(plumber)
library(data.table)
library(jsonlite)
library(plotly)

# Global cache for datasets
.volcano_cache <- new.env()

#* @apiTitle R Volcano Plot API
#* @apiDescription R-based volcano plot data processing

#* Get volcano plot data
#* @param p_value_threshold:numeric P-value threshold
#* @param log_fc_min:numeric Minimum log fold change
#* @param log_fc_max:numeric Maximum log fold change  
#* @param dataset_size:int Dataset size
#* @param max_points:int Maximum points to return
#* @param search_term:character Search term (optional)
#* @get /api/volcano-data
function(p_value_threshold = 0.05, log_fc_min = -0.5, log_fc_max = 0.5, 
         dataset_size = 10000, max_points = 50000, search_term = NULL) {
  
  # Generate or retrieve cached dataset
  df <- get_cached_dataset(as.integer(dataset_size))
  
  # Apply filters and processing (detailed implementation in R)
  # ... filtering logic similar to Python version
  
  # Return JSON response matching FastAPI structure
  list(
    data = processed_data,
    stats = list(
      up_regulated = sum(df$category == "up"),
      down_regulated = sum(df$category == "down"), 
      non_significant = sum(df$category == "non_significant")
    ),
    total_rows = nrow(df),
    filtered_rows = nrow(processed_data),
    points_before_sampling = points_before_sampling,
    is_downsampled = is_downsampled
  )
}
```

#### Option 2: Script Execution (`r-backend/volcano-script.R`)

```r
#!/usr/bin/env Rscript

# Read JSON input from stdin
input_json <- readLines("stdin", warn = FALSE)
params <- jsonlite::fromJSON(input_json)

# Process data using same logic as Plumber version
result <- process_volcano_data(params)

# Output JSON to stdout
cat(jsonlite::toJSON(result, auto_unbox = TRUE))
```

## Data Models

### Input/Output Compatibility

The R backend maintains identical JSON structures to the FastAPI implementation:

#### Request Parameters
```typescript
interface FilterParams {
  p_value_threshold: number
  log_fc_min: number  
  log_fc_max: number
  search_term?: string
  dataset_size: number
  max_points: number
}
```

#### Response Structure
```typescript
interface VolcanoResponse {
  data: VolcanoDataPoint[]
  stats: {
    up_regulated: number
    down_regulated: number
    non_significant: number
  }
  total_rows: number
  filtered_rows: number
  points_before_sampling: number
  is_downsampled: boolean
}
```

### R Data Processing

#### Synthetic Data Generation
R implementation uses `data.table` for high-performance data generation:

```r
generate_volcano_data <- function(size) {
  # Vectorized data generation similar to Python numpy approach
  # Use data.table for efficient operations
  # Maintain same statistical distributions as Python version
}
```

#### Filtering and Sampling
```r
filter_and_sample <- function(dt, params) {
  # Use data.table syntax for efficient filtering
  # Implement intelligent sampling prioritizing significant points
  # Match Python sampling logic for consistency
}
```

## Error Handling

### R Backend Error Management
1. **Graceful Degradation**: R errors don't affect Python implementation
2. **Error Logging**: Comprehensive logging for debugging R-specific issues
3. **Timeout Handling**: Request timeouts to prevent hanging processes
4. **Resource Limits**: Memory and CPU limits for R processes

### Frontend Error Handling
- Reuse existing error handling patterns from FastAPI component
- R-specific error messages and status indicators
- Fallback mechanisms if R backend is unavailable

## Testing Strategy

### Unit Testing
1. **R Backend Tests**: Test data generation, filtering, and sampling logic
2. **API Route Tests**: Test Next.js proxy functionality for R endpoints
3. **Component Tests**: Test R volcano plot component functionality

### Integration Testing  
1. **End-to-End Tests**: Complete workflow from frontend to R backend
2. **Compatibility Tests**: Verify identical outputs between R and Python
3. **Performance Tests**: Benchmark R vs Python implementations

### Comparison Testing
1. **Output Validation**: Statistical comparison of R vs Python results
2. **Performance Benchmarking**: Latency, memory, and CPU usage comparison
3. **Visual Validation**: Ensure identical plot rendering and interactivity

## Performance Considerations

### R Optimization
1. **data.table Usage**: Leverage data.table for high-performance operations
2. **Vectorization**: Use vectorized operations instead of loops
3. **Memory Management**: Efficient memory usage for large datasets
4. **Caching Strategy**: Implement dataset caching similar to Python version

### Benchmarking Framework
1. **Metrics Collection**: Runtime, memory usage, CPU utilization
2. **Test Scenarios**: Various dataset sizes and filter combinations
3. **Comparison Reports**: Automated comparison between R and Python results

## Deployment Strategy

### Development Environment
1. **Branch Strategy**: Develop in `feature/r-volcano-integration` branch
2. **Local Testing**: R backend runs alongside FastAPI for comparison
3. **Environment Variables**: Configure R backend port and settings

### Production Considerations
1. **Process Management**: R server process monitoring and restart capabilities
2. **Resource Allocation**: Memory and CPU limits for R processes  
3. **Health Checks**: R backend health monitoring endpoints
4. **Scaling**: Considerations for future horizontal scaling of R processes