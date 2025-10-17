# Output Validation and Comparison Utilities

This directory contains comprehensive utilities for validating and comparing outputs between R and Python volcano plot implementations. These tools ensure functional parity and statistical consistency between the two backends.

## Overview

The validation suite consists of four main components:

1. **Output Comparison** (`compare-outputs.R`) - Compares JSON responses for structural and data consistency
2. **Statistical Validation** (`statistical-validation.R`) - Validates statistical properties of generated data
3. **Report Generation** (`generate-comparison-report.R`) - Creates comprehensive HTML reports
4. **Live Testing** (`live-comparison-test.R`) - Tests live backends via API calls

## Quick Start

### 1. Basic Output Comparison

Compare two JSON response files:

```bash
# Compare saved responses
Rscript r-backend/compare-outputs.R r_response.json python_response.json

# With custom tolerance
Rscript r-backend/compare-outputs.R r_response.json python_response.json 1e-8
```

### 2. Statistical Validation

Validate statistical consistency of data generation:

```bash
# Basic statistical validation
Rscript r-backend/statistical-validation.R r_data.json python_data.json

# With custom significance level
Rscript r-backend/statistical-validation.R r_data.json python_data.json 0.01
```

### 3. Generate Comparison Report

Create comprehensive HTML reports:

```bash
# Generate report
Rscript r-backend/generate-comparison-report.R r_response.json python_response.json report.html
```

### 4. Live Backend Testing

Test running backends directly:

```bash
# Test volcano plot endpoints (requires both backends running)
Rscript r-backend/live-comparison-test.R

# Comprehensive testing including cache endpoints
Rscript r-backend/live-comparison-test.R --comprehensive

# Test only cache endpoints
Rscript r-backend/live-comparison-test.R --cache-only
```

### 5. Run Test Suite

Execute the complete validation test suite:

```bash
# Run all validation tests
Rscript r-backend/test-output-validation.R

# Create sample test files
Rscript r-backend/test-output-validation.R --create-samples
```

## Detailed Usage

### Output Comparison (`compare-outputs.R`)

Compares two volcano plot JSON responses for:
- JSON structure consistency
- Data point accuracy (within tolerance)
- Statistics matching
- Metadata consistency

**Input Format:**
```json
{
  "data": [
    {
      "metabolite_id": "M1",
      "metabolite_name": "Metabolite_1",
      "log2_fold_change": 1.5,
      "p_value": 0.01,
      "neg_log10_p": 2.0,
      "category": "up"
    }
  ],
  "stats": {
    "up_regulated": 150,
    "down_regulated": 120,
    "non_significant": 8730
  },
  "total_rows": 10000,
  "filtered_rows": 9000,
  "points_before_sampling": 9000,
  "is_downsampled": false
}
```

**Output:**
- Console summary of comparison results
- Detailed JSON results file (`comparison_results.json`)
- Exit code 0 for success, 1 for failure

### Statistical Validation (`statistical-validation.R`)

Performs comprehensive statistical tests:

**Distribution Tests:**
- Kolmogorov-Smirnov test
- Wilcoxon rank-sum test (Mann-Whitney U)
- Anderson-Darling test (if available)

**Correlation Analysis:**
- Correlation matrix comparison
- Maximum correlation difference validation

**Summary Statistics:**
- Mean, median, standard deviation comparison
- Quantile analysis (25th, 75th percentiles)
- Relative difference calculations

**Category Distribution:**
- Chi-square test for category proportions

**Output:**
- Statistical test results with p-values
- Summary statistics comparison
- JSON results file (`statistical_validation_results.json`)

### Report Generation (`generate-comparison-report.R`)

Creates comprehensive HTML reports including:

**Executive Summary:**
- Overall validation status
- Key metrics dashboard
- Pass/fail indicators

**Detailed Analysis:**
- Data overview tables
- Statistical test results
- Performance comparisons
- Issue identification

**Visual Elements:**
- Color-coded status indicators
- Responsive grid layouts
- Professional styling

**Batch Processing:**
Multiple scenarios can be processed using the batch function:

```r
# Example batch configuration
test_scenarios <- list(
  small_dataset = list(
    r_file = "r_small.json",
    python_file = "python_small.json",
    tolerance = 1e-6
  ),
  large_dataset = list(
    r_file = "r_large.json", 
    python_file = "python_large.json",
    tolerance = 1e-8
  )
)

results <- run_batch_comparison(test_scenarios, "reports/")
```

### Live Testing (`live-comparison-test.R`)

Tests live backends with configurable scenarios:

**Default Test Scenarios:**
1. **Small Dataset** - 10K points, basic filtering
2. **Large Dataset** - 100K points, strict filtering  
3. **Filtered Search** - 50K points with search term

**Custom Scenarios:**
```r
custom_scenarios <- list(
  stress_test = list(
    dataset_size = 1000000,
    max_points = 100000,
    p_value_threshold = 0.001,
    log_fc_min = -3.0,
    log_fc_max = 3.0,
    search_term = "kinase"
  )
)

results <- live_comparison_test(
  r_base_url = "http://localhost:8001",
  python_base_url = "http://localhost:8000", 
  test_scenarios = custom_scenarios
)
```

**Prerequisites:**
- R backend running on port 8001
- Python backend running on port 8000
- `httr` package installed

## Validation Criteria

### Structural Validation
- ✅ Identical JSON schema
- ✅ Same top-level keys
- ✅ Consistent data point structure
- ✅ Matching statistics fields

### Data Consistency
- ✅ Numerical values within tolerance (default: 1e-6)
- ✅ Categorical values exact match
- ✅ Same number of data points
- ✅ Consistent sorting/ordering

### Statistical Validation
- ✅ Distribution similarity (p > 0.05)
- ✅ Correlation structure preservation
- ✅ Summary statistics within 5% tolerance
- ✅ Category proportions consistency

### Performance Validation
- ✅ Response time measurement
- ✅ Memory usage tracking
- ✅ Throughput comparison
- ✅ Error rate monitoring

## Troubleshooting

### Common Issues

**1. Tolerance Errors**
```
Column log2_fold_change exceeds tolerance. Max diff: 1.2e-5
```
- **Solution:** Increase tolerance or investigate algorithm differences
- **Command:** `Rscript compare-outputs.R file1.json file2.json 1e-4`

**2. Distribution Test Failures**
```
Distribution Tests Passed: FALSE
```
- **Solution:** Check random seed handling and data generation logic
- **Investigation:** Review statistical validation details in JSON output

**3. Backend Connection Errors**
```
ERROR: R backend not available at http://localhost:8001
```
- **Solution:** Ensure R backend is running: `Rscript r-backend/plumber-api.R`
- **Check:** Verify port configuration and firewall settings

**4. Missing Dependencies**
```
Error: package 'httr' not available
```
- **Solution:** Install required packages: `install.packages(c("httr", "jsonlite", "data.table"))`

### Performance Issues

**Large Dataset Timeouts:**
- Increase timeout in live testing: modify `timeout(30)` to `timeout(60)`
- Use smaller test datasets for initial validation
- Check backend resource allocation

**Memory Errors:**
- Monitor R memory usage: `gc()` and `memory.size()`
- Use streaming comparison for very large datasets
- Implement data chunking for batch processing

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Backend Validation
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup R
        uses: r-lib/actions/setup-r@v2
        
      - name: Install R dependencies
        run: |
          install.packages(c("jsonlite", "data.table", "httr"))
        shell: Rscript {0}
        
      - name: Start backends
        run: |
          # Start R backend in background
          Rscript r-backend/plumber-api.R &
          # Start Python backend
          python api/main.py &
          sleep 10
          
      - name: Run validation tests
        run: |
          Rscript r-backend/test-output-validation.R
          Rscript r-backend/live-comparison-test.R --comprehensive
          
      - name: Upload reports
        uses: actions/upload-artifact@v2
        with:
          name: validation-reports
          path: "*.html"
```

### Docker Integration

```dockerfile
# Add to existing Dockerfile
RUN apt-get update && apt-get install -y r-base
COPY r-backend/ /app/r-backend/
RUN Rscript -e "install.packages(c('jsonlite', 'data.table', 'httr'))"

# Validation stage
FROM base as validation
RUN Rscript /app/r-backend/test-output-validation.R
```

## File Structure

```
r-backend/
├── compare-outputs.R              # Core comparison logic
├── statistical-validation.R       # Statistical tests
├── generate-comparison-report.R   # HTML report generation
├── live-comparison-test.R         # Live backend testing
├── test-output-validation.R       # Test suite
├── OUTPUT-VALIDATION-README.md    # This documentation
└── sample_*.json                  # Generated test files
```

## API Reference

### Core Functions

#### `compare_volcano_outputs(r_response, python_response, tolerance = 1e-6)`
Compares two volcano plot responses for consistency.

**Parameters:**
- `r_response`: R backend JSON response
- `python_response`: Python backend JSON response  
- `tolerance`: Numerical comparison tolerance

**Returns:** List with comparison results and detailed analysis

#### `validate_data_generation_statistics(r_data, python_data, alpha = 0.05)`
Validates statistical properties of generated data.

**Parameters:**
- `r_data`: R-generated data points
- `python_data`: Python-generated data points
- `alpha`: Statistical significance level

**Returns:** List with statistical test results

#### `generate_comparison_report(r_response, python_response, output_file, tolerance = 1e-6)`
Generates comprehensive HTML comparison report.

**Parameters:**
- `r_response`: R backend response
- `python_response`: Python backend response
- `output_file`: Output HTML file path
- `tolerance`: Comparison tolerance

**Returns:** Report generation results and file path

## Contributing

When adding new validation features:

1. **Add tests** to `test-output-validation.R`
2. **Update documentation** in this README
3. **Follow naming conventions** (`validate_*`, `test_*`, `compare_*`)
4. **Include error handling** with informative messages
5. **Add usage examples** in function documentation

## License

These validation utilities are part of the R Volcano Plot Integration project and follow the same license as the main application.