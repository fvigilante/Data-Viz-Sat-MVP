# Performance Benchmarking Framework

This directory contains a comprehensive performance benchmarking framework for comparing R vs Python volcano plot implementations. The framework provides multiple levels of testing from quick development checks to detailed performance analysis.

## Overview

The benchmarking framework consists of several components:

- **Quick Benchmark**: Fast performance comparison for development
- **Comprehensive Benchmark**: Detailed testing across multiple scenarios
- **Memory Profiler**: Resource usage monitoring and analysis
- **Automated Runners**: Cross-platform scripts for easy execution

## Components

### 1. Quick Benchmark (`quick-benchmark.R`)

Fast performance testing for development and debugging.

**Features:**
- Tests 3 dataset sizes (10K, 100K, 500K)
- 3 iterations per test
- Simple timing and comparison
- Health check functionality

**Usage:**
```bash
# Run quick benchmark
Rscript quick-benchmark.R

# Check API health only
Rscript quick-benchmark.R health
```

### 2. Comprehensive Benchmark (`benchmark-framework.R`)

Detailed performance testing across multiple scenarios.

**Features:**
- Tests 5 dataset sizes (10K to 1M)
- Multiple max_points settings
- Various p-value thresholds
- Different log fold change ranges
- 5 iterations per scenario
- Comprehensive metrics collection
- HTML report generation

**Usage:**
```bash
# Run full benchmark suite
Rscript benchmark-framework.R run [output_file.rds]

# Generate report from existing results
Rscript benchmark-framework.R report [results_file.rds]
```

### 3. Memory Profiler (`memory-profiler.R`)

Resource usage monitoring and analysis.

**Features:**
- Real-time memory monitoring
- Cross-platform memory tracking
- Peak and average memory usage
- Memory growth analysis
- Detailed profiling reports

**Usage:**
```bash
# Run memory profiling
Rscript memory-profiler.R profile

# Generate memory report
Rscript memory-profiler.R report [profile_file.rds]
```

### 4. Automated Runners

Cross-platform scripts for easy benchmark execution.

#### Windows (`benchmark-runner.bat`)
```cmd
# Quick benchmark
benchmark-runner.bat quick

# Full benchmark
benchmark-runner.bat full

# Health check
benchmark-runner.bat health

# Generate report
benchmark-runner.bat report results_file.rds
```

#### Unix/Linux/macOS (`benchmark-runner.sh`)
```bash
# Quick benchmark
./benchmark-runner.sh quick

# Full benchmark
./benchmark-runner.sh full

# Health check
./benchmark-runner.sh health

# Generate report
./benchmark-runner.sh report results_file.rds
```

## Setup Requirements

### Environment Variables

Set these environment variables to configure API endpoints:

```bash
# FastAPI endpoint (default: http://localhost:8000)
export FASTAPI_URL="http://localhost:8000"

# R API endpoint (default: http://localhost:8001)
export R_API_URL="http://localhost:8001"
```

### R Dependencies

Required R packages:
```r
install.packages(c("httr", "jsonlite", "data.table", "microbenchmark", "knitr"))
```

### API Requirements

Both APIs must be running and accessible:
- FastAPI server on port 8000 (or configured port)
- R Plumber API server on port 8001 (or configured port)

## Benchmark Scenarios

### Dataset Sizes Tested
- 10,000 points
- 50,000 points
- 100,000 points
- 500,000 points
- 1,000,000 points

### Parameter Variations
- **Max Points**: 10K, 20K, 50K, 100K
- **P-value Thresholds**: 0.001, 0.01, 0.05, 0.1
- **Log Fold Change Ranges**: [-0.5, 0.5], [-1.0, 1.0], [-2.0, 2.0]

### Metrics Collected
- **Response Time**: API call duration in milliseconds
- **Memory Usage**: Peak and average memory consumption
- **Success Rate**: Percentage of successful API calls
- **Data Points**: Number of points returned after filtering
- **Response Size**: JSON response size in bytes

## Output Files

### Benchmark Results
- `benchmark_results_YYYYMMDD_HHMMSS.rds`: Comprehensive benchmark data
- `quick_benchmark_YYYYMMDD_HHMMSS.rds`: Quick benchmark results
- `memory_profile_YYYYMMDD_HHMMSS.rds`: Memory profiling data

### Reports
- `performance_report.html`: Comprehensive performance comparison
- `memory_report.html`: Memory usage analysis

## Interpreting Results

### Performance Metrics

**Response Time Comparison:**
- Lower values indicate better performance
- Look for consistent patterns across dataset sizes
- Consider both mean and variance in timing

**Memory Usage:**
- Peak memory indicates maximum resource requirements
- Memory growth shows efficiency of data handling
- Compare ratios between R and Python implementations

**Success Rate:**
- Should be 100% for both implementations
- Lower rates indicate stability issues

### Example Output

```
SUMMARY
==================================================
   dataset_size fastapi_mean_ms r_mean_ms speedup_factor faster_api
1:        10000            45.2      38.7           1.17          R
2:       100000           156.3     142.8           1.09          R
3:       500000           678.2     721.4           0.94    FastAPI

Overall: R is 1.07x faster on average
```

## Troubleshooting

### Common Issues

**APIs Not Responding:**
```bash
# Check API health
./benchmark-runner.sh health
```

**R Packages Missing:**
```r
# Install required packages
source("install-packages.R")
```

**Permission Issues (Unix):**
```bash
# Make scripts executable
chmod +x benchmark-runner.sh
```

**Memory Issues:**
- Reduce dataset sizes in configuration
- Increase system memory allocation
- Monitor system resources during testing

### Error Messages

**"API request failed: 500"**
- Check API server logs
- Verify API endpoints are correct
- Ensure both servers are running

**"Rscript not found"**
- Install R and ensure it's in PATH
- Verify R installation with `R --version`

**"Connection refused"**
- Check if APIs are running on correct ports
- Verify firewall settings
- Test API endpoints manually

## Advanced Usage

### Custom Benchmark Configuration

Modify `BENCHMARK_CONFIG` in `benchmark-framework.R`:

```r
BENCHMARK_CONFIG <- list(
  dataset_sizes = c(10000, 100000),  # Custom sizes
  iterations = 3,                    # Fewer iterations
  # ... other parameters
)
```

### Automated Testing

Set up automated benchmarking with cron (Unix) or Task Scheduler (Windows):

```bash
# Daily benchmark at 2 AM
0 2 * * * /path/to/benchmark-runner.sh full
```

### Integration with CI/CD

Include benchmarking in your CI pipeline:

```yaml
# Example GitHub Actions step
- name: Run Performance Benchmark
  run: |
    ./r-backend/benchmark-runner.sh quick
    # Upload results as artifacts
```

## Performance Optimization Tips

### For R Implementation
- Use `data.table` for large dataset operations
- Implement efficient filtering algorithms
- Consider memory pre-allocation
- Use vectorized operations

### For Python Implementation
- Leverage Polars for data processing
- Optimize JSON serialization
- Consider async processing for large datasets
- Monitor memory usage patterns

## Contributing

When adding new benchmark scenarios:

1. Update configuration in `benchmark-framework.R`
2. Add corresponding test cases
3. Update documentation
4. Test on multiple platforms
5. Verify report generation works correctly

## Support

For issues with the benchmarking framework:

1. Check API health status
2. Review error logs
3. Verify environment configuration
4. Test with smaller dataset sizes
5. Check system resource availability