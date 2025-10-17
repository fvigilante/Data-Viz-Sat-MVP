# R Backend Error Handling and Logging System

## Overview

The R backend implements comprehensive error handling and logging to ensure system stability, facilitate debugging, and maintain compatibility with the existing FastAPI error response format.

## Logging System

### Log Levels

The logging system supports four levels in hierarchical order:

- **DEBUG**: Detailed information for debugging (parameter validation, performance metrics)
- **INFO**: General information about operations (cache operations, successful requests)
- **WARN**: Warning conditions that don't prevent operation (parameter adjustments, cache issues)
- **ERROR**: Error conditions that prevent normal operation

### Configuration

Configure logging through environment variables:

```bash
# Set log level (DEBUG, INFO, WARN, ERROR)
export R_LOG_LEVEL=INFO

# Set log file path (empty = console only)
export R_LOG_FILE=/path/to/logfile.log
```

### Log Format

```
[TIMESTAMP] LEVEL [CONTEXT]: MESSAGE
```

Example:
```
[2024-01-15 14:30:25] INFO [API]: Volcano data GET endpoint called [req_1705329025]
[2024-01-15 14:30:25] DEBUG [VALIDATION]: Dataset size 10000 validated successfully
[2024-01-15 14:30:26] INFO [PERFORMANCE]: get_dataset_req_1705329025 completed in 0.123 seconds, memory change: 2.45 MB
```

## Error Response Format

All errors return a standardized JSON structure matching the FastAPI format:

```json
{
  "error": true,
  "message": "Human-readable error description",
  "error_type": "validation_error|processing_error|cache_error|etc",
  "status_code": 400,
  "timestamp": "2024-01-15T14:30:25",
  "backend": "R + data.table",
  "details": {
    "errors": ["Specific validation errors"],
    "original_error": "Original R error message",
    "request_id": "req_1705329025"
  }
}
```

## Error Types and HTTP Status Codes

### 400 Bad Request
- **validation_error**: Invalid parameters (out of range, wrong type)
- **missing_body**: POST request without body

### 500 Internal Server Error
- **processing_error**: Data processing failures
- **cache_error**: Cache operation failures
- **unhandled_error**: Unexpected errors caught by global handler

### 503 Service Unavailable
- **health_check_error**: Health check failures

## Parameter Validation

### Validation Rules

| Parameter | Type | Range | Default |
|-----------|------|-------|---------|
| p_value_threshold | numeric | 0-1 | 0.05 |
| log_fc_min | numeric | -10 to 10 | -0.5 |
| log_fc_max | numeric | -10 to 10 | 0.5 |
| dataset_size | integer | 100-10,000,000 | 10,000 |
| max_points | integer | 1,000-200,000 | 50,000 |
| zoom_level | numeric | 0.1-100 | 1.0 |
| search_term | string | max 100 chars | null |
| lod_mode | boolean | true/false | true |

### Validation Process

1. **Type Conversion**: Attempt to convert parameters to expected types
2. **Range Checking**: Validate parameters are within acceptable ranges
3. **Sanitization**: Clean search terms to prevent injection
4. **Error Aggregation**: Collect all validation errors before returning

## Performance Monitoring

### Monitored Operations

- Dataset generation and caching
- Data filtering and categorization
- Intelligent sampling
- Spatial filtering

### Metrics Collected

- **Execution Time**: Function runtime in seconds
- **Memory Usage**: Memory change during operation
- **Request Tracking**: Unique request IDs for tracing

### Performance Logging

```r
# Example performance log entry
[2024-01-15 14:30:26] INFO [PERFORMANCE]: generate_volcano_data completed in 0.456 seconds, memory change: 15.23 MB
```

## Cache Error Handling

### Cache Integrity Checks

- Validate cached data structure on retrieval
- Detect and remove corrupted cache entries
- Graceful fallback to data regeneration

### Cache Operation Errors

- **Cache Status**: Handle environment access errors
- **Cache Warming**: Continue with valid sizes, report failures
- **Cache Clearing**: Ensure memory cleanup even on partial failures

## Request Tracing

### Request IDs

Each request receives a unique identifier for tracing:
- GET requests: `req_[timestamp]`
- POST requests: `post_req_[timestamp]`

### Trace Context

Request IDs are included in:
- All log messages for the request
- Error response details
- Performance monitoring logs

## Error Recovery Strategies

### Graceful Degradation

1. **Parameter Validation**: Use defaults for invalid optional parameters
2. **Cache Failures**: Regenerate data if cache is corrupted
3. **Memory Issues**: Automatic garbage collection on cache operations
4. **Processing Errors**: Return detailed error information without crashing

### Isolation Principles

- R backend errors don't affect Python FastAPI functionality
- Individual request failures don't impact server stability
- Cache corruption doesn't prevent new data generation

## Testing Error Handling

### Test Script

Run the comprehensive error handling test:

```bash
Rscript r-backend/test-error-handling.R
```

### Test Coverage

- Parameter validation errors
- Invalid JSON handling
- Empty request bodies
- Cache operation failures
- Successful request processing

### Expected Test Results

All tests should pass, demonstrating:
- Proper error response format
- Correct HTTP status codes
- Detailed error information
- System stability under error conditions

## Debugging Guide

### Common Issues

1. **Server Won't Start**
   - Check port availability
   - Verify R package dependencies
   - Review startup logs

2. **Parameter Validation Failures**
   - Check parameter types and ranges
   - Review validation error details
   - Verify request format

3. **Cache Issues**
   - Monitor cache memory usage
   - Check for corrupted entries
   - Review cache operation logs

4. **Performance Problems**
   - Enable DEBUG logging
   - Monitor performance metrics
   - Check memory usage patterns

### Log Analysis

```bash
# Filter logs by level
grep "ERROR" /path/to/logfile.log

# Filter logs by context
grep "\[CACHE\]" /path/to/logfile.log

# Filter logs by request ID
grep "req_1705329025" /path/to/logfile.log
```

## Integration with Next.js API Routes

### Error Propagation

Next.js API routes should:
1. Check R backend response for `error: true`
2. Preserve error structure and status codes
3. Add frontend-specific error handling
4. Log errors for monitoring

### Example Integration

```javascript
// app/api/r-volcano-data/route.ts
try {
  const response = await fetch(R_BACKEND_URL, options);
  const data = await response.json();
  
  if (data.error) {
    return NextResponse.json(data, { status: data.status_code });
  }
  
  return NextResponse.json(data);
} catch (error) {
  return NextResponse.json({
    error: true,
    message: "R backend communication failed",
    error_type: "backend_error",
    status_code: 502
  }, { status: 502 });
}
```

## Monitoring and Alerting

### Key Metrics to Monitor

- Error rate by endpoint
- Response time percentiles
- Memory usage trends
- Cache hit/miss ratios

### Alert Conditions

- Error rate > 5%
- Response time > 10 seconds
- Memory usage > 80%
- Cache corruption events

This comprehensive error handling and logging system ensures the R backend maintains high reliability while providing detailed diagnostic information for debugging and monitoring.