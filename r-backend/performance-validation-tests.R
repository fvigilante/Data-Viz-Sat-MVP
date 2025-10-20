#!/usr/bin/env Rscript

# Performance Validation Tests for R Optimization
# Tests performance against Python FastAPI baseline and validates targets

library(httr)
library(jsonlite)
library(data.table)

# Performance targets from design document
PERFORMANCE_TARGETS <- list(
  "10000" = list(target_ms = 200, python_baseline_ms = 100),
  "100000" = list(target_ms = 2000, python_baseline_ms = 800),
  "500000" = list(target_ms = 8000, python_baseline_ms = 3000),
  "1000000" = list(target_ms = 15000, python_baseline_ms = 6000)
)

# Test configuration
TEST_CONFIG <- list(
  r_api_url = Sys.getenv("R_API_URL", "http://localhost:8001"),
  python_api_url = Sys.getenv("PYTHON_API_URL", "http://localhost:8000"),
  iterations = 3,
  warmup_iterations = 1,
  timeout_seconds = 60
)

#' Execute performance validation tests
#' @param dataset_sizes Vector of dataset sizes to test
#' @param save_results Logical whether to save results to file
#' @return List with test results
execute_performance_validation <- function(dataset_sizes = c(10000, 100000, 500000, 1000000), 
                                         save_results = TRUE) {
  
  cat("=== R Performance Optimization Validation Tests ===\n")
  cat("Testing dataset sizes:", paste(format(dataset_sizes, big.mark = ","), collapse = ", "), "\n")
  cat("Target: R performance within 50% of Python baseline\n\n")
  
  # Check API availability
  if (!check_apis_available()) {
    stop("Required APIs are not available. Please start both R and Python servers.")
  }
  
  # Warm up caches
  cat("Warming up caches...\n")
  warm_up_caches(dataset_sizes)
  
  results <- list()
  overall_results <- list(
    tests_passed = 0,
    tests_failed = 0,
    performance_summary = list(),
    detailed_results = list()
  )
  
  for (size in dataset_sizes) {
    cat(sprintf("\n--- Testing dataset size: %s ---\n", format(size, big.mark = ",")))
    
    # Get performance targets for this size
    size_key <- as.character(size)
    targets <- PERFORMANCE_TARGETS[[size_key]]
    
    if (is.null(targets)) {
      cat("No performance targets defined for size", size, "- using interpolated targets\n")
      targets <- interpolate_targets(size)
    }
    
    # Test parameters
    test_params <- list(
      dataset_size = size,
      max_points = min(50000, size),
      p_value_threshold = 0.05,
      log_fc_min = -1.0,
      log_fc_max = 1.0
    )
    
    # Run performance tests
    test_result <- run_performance_comparison(test_params, targets)
    
    # Store results
    results[[size_key]] <- test_result
    overall_results$detailed_results[[size_key]] <- test_result
    
    # Update summary
    if (test_result$meets_targets) {
      overall_results$tests_passed <- overall_results$tests_passed + 1
      cat("✅ PASSED: Performance targets met\n")
    } else {
      overall_results$tests_failed <- overall_results$tests_failed + 1
      cat("❌ FAILED: Performance targets not met\n")
    }
    
    # Add to performance summary
    overall_results$performance_summary[[size_key]] <- list(
      dataset_size = size,
      r_mean_ms = test_result$r_performance$mean_ms,
      python_mean_ms = test_result$python_performance$mean_ms,
      speedup_factor = test_result$performance_comparison$speedup_factor,
      meets_target = test_result$meets_targets,
      target_ms = targets$target_ms,
      overhead_percent = test_result$performance_comparison$overhead_percent
    )
  }
  
  # Generate final report
  overall_results$test_summary <- list(
    total_tests = length(dataset_sizes),
    tests_passed = overall_results$tests_passed,
    tests_failed = overall_results$tests_failed,
    success_rate = round(overall_results$tests_passed / length(dataset_sizes) * 100, 1),
    timestamp = Sys.time()
  )
  
  # Print summary
  print_validation_summary(overall_results)
  
  # Save results if requested
  if (save_results) {
    save_validation_results(overall_results)
  }
  
  return(overall_results)
}

#' Run performance comparison between R and Python APIs
#' @param test_params List of test parameters
#' @param targets List with performance targets
#' @return List with comparison results
run_performance_comparison <- function(test_params, targets) {
  
  cat("Running performance comparison...\n")
  
  # Test R API performance
  cat("  Testing R API...")
  r_results <- test_api_performance(TEST_CONFIG$r_api_url, "/api/volcano-data", test_params)
  cat(sprintf(" %.1f ms (avg)\n", r_results$mean_ms))
  
  # Test Python API performance
  cat("  Testing Python API...")
  python_results <- test_api_performance(TEST_CONFIG$python_api_url, "/api/volcano-data", test_params)
  cat(sprintf(" %.1f ms (avg)\n", python_results$mean_ms))
  
  # Calculate performance metrics
  speedup_factor <- python_results$mean_ms / r_results$mean_ms
  overhead_percent <- ((r_results$mean_ms - python_results$mean_ms) / python_results$mean_ms) * 100
  
  # Check if targets are met
  meets_target_time <- r_results$mean_ms <= targets$target_ms
  meets_overhead_limit <- overhead_percent <= 50  # Max 50% overhead vs Python
  
  performance_comparison <- list(
    speedup_factor = speedup_factor,
    overhead_percent = overhead_percent,
    faster_api = if (speedup_factor > 1) "R" else "Python",
    meets_target_time = meets_target_time,
    meets_overhead_limit = meets_overhead_limit
  )
  
  cat(sprintf("  Performance: R=%.1fms, Python=%.1fms, Overhead=%.1f%%\n", 
             r_results$mean_ms, python_results$mean_ms, overhead_percent))
  
  return(list(
    r_performance = r_results,
    python_performance = python_results,
    performance_comparison = performance_comparison,
    meets_targets = meets_target_time && meets_overhead_limit,
    targets = targets,
    test_params = test_params
  ))
}

#' Test API performance with multiple iterations
#' @param base_url Base URL of the API
#' @param endpoint API endpoint to test
#' @param params Request parameters
#' @return List with performance statistics
test_api_performance <- function(base_url, endpoint, params) {
  
  url <- paste0(base_url, endpoint)
  times_ms <- c()
  response_sizes <- c()
  errors <- c()
  
  # Warmup iteration
  tryCatch({
    GET(url, query = params, timeout(10))
  }, error = function(e) {
    # Ignore warmup errors
  })
  
  # Performance iterations
  for (i in 1:TEST_CONFIG$iterations) {
    tryCatch({
      start_time <- Sys.time()
      
      response <- GET(url, query = params, timeout(TEST_CONFIG$timeout_seconds))
      
      end_time <- Sys.time()
      duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      
      if (status_code(response) == 200) {
        times_ms <- c(times_ms, duration_ms)
        
        # Get response size
        response_data <- content(response, "parsed")
        if (!is.null(response_data$data)) {
          response_sizes <- c(response_sizes, length(response_data$data))
        }
      } else {
        errors <- c(errors, paste("HTTP", status_code(response)))
      }
      
    }, error = function(e) {
      errors <- c(errors, e$message)
    })
  }
  
  # Calculate statistics
  if (length(times_ms) > 0) {
    return(list(
      mean_ms = mean(times_ms),
      median_ms = median(times_ms),
      min_ms = min(times_ms),
      max_ms = max(times_ms),
      std_ms = sd(times_ms),
      successful_iterations = length(times_ms),
      total_iterations = TEST_CONFIG$iterations,
      success_rate = length(times_ms) / TEST_CONFIG$iterations,
      avg_response_size = if (length(response_sizes) > 0) mean(response_sizes) else 0,
      errors = errors
    ))
  } else {
    return(list(
      mean_ms = Inf,
      successful_iterations = 0,
      total_iterations = TEST_CONFIG$iterations,
      success_rate = 0,
      errors = errors
    ))
  }
}

#' Check if both APIs are available
#' @return Logical indicating if both APIs are available
check_apis_available <- function() {
  
  cat("Checking API availability...\n")
  
  # Check R API
  r_available <- tryCatch({
    response <- GET(paste0(TEST_CONFIG$r_api_url, "/health"), timeout(5))
    status_code(response) == 200
  }, error = function(e) {
    cat("R API not available:", e$message, "\n")
    FALSE
  })
  
  # Check Python API
  python_available <- tryCatch({
    response <- GET(paste0(TEST_CONFIG$python_api_url, "/health"), timeout(5))
    status_code(response) == 200
  }, error = function(e) {
    cat("Python API not available:", e$message, "\n")
    FALSE
  })
  
  cat("R API:", if (r_available) "✅ Available" else "❌ Not available", "\n")
  cat("Python API:", if (python_available) "✅ Available" else "❌ Not available", "\n")
  
  return(r_available && python_available)
}

#' Warm up API caches
#' @param dataset_sizes Vector of dataset sizes to warm up
warm_up_caches <- function(dataset_sizes) {
  
  # Warm up R API cache
  tryCatch({
    POST(paste0(TEST_CONFIG$r_api_url, "/api/warm-cache"),
         body = list(sizes = dataset_sizes),
         encode = "json",
         timeout(30))
    cat("R API cache warmed up\n")
  }, error = function(e) {
    cat("Warning: Failed to warm R API cache:", e$message, "\n")
  })
  
  # Warm up Python API cache
  tryCatch({
    POST(paste0(TEST_CONFIG$python_api_url, "/api/warm-cache"),
         body = dataset_sizes,
         encode = "json",
         timeout(30))
    cat("Python API cache warmed up\n")
  }, error = function(e) {
    cat("Warning: Failed to warm Python API cache:", e$message, "\n")
  })
}

#' Interpolate performance targets for sizes not explicitly defined
#' @param size Dataset size
#' @return List with interpolated targets
interpolate_targets <- function(size) {
  
  # Use linear interpolation based on existing targets
  sizes <- as.numeric(names(PERFORMANCE_TARGETS))
  target_times <- sapply(PERFORMANCE_TARGETS, function(x) x$target_ms)
  python_times <- sapply(PERFORMANCE_TARGETS, function(x) x$python_baseline_ms)
  
  # Simple linear interpolation
  target_ms <- approx(sizes, target_times, xout = size, rule = 2)$y
  python_baseline_ms <- approx(sizes, python_times, xout = size, rule = 2)$y
  
  return(list(
    target_ms = target_ms,
    python_baseline_ms = python_baseline_ms
  ))
}

#' Print validation summary
#' @param results Overall test results
print_validation_summary <- function(results) {
  
  cat("\n" %R% 60, "\n")
  cat("=== PERFORMANCE VALIDATION SUMMARY ===\n")
  cat("=" %R% 60, "\n")
  
  summary <- results$test_summary
  cat(sprintf("Total Tests: %d\n", summary$total_tests))
  cat(sprintf("Passed: %d\n", summary$tests_passed))
  cat(sprintf("Failed: %d\n", summary$tests_failed))
  cat(sprintf("Success Rate: %.1f%%\n", summary$success_rate))
  cat(sprintf("Timestamp: %s\n", summary$timestamp))
  
  cat("\n--- Performance Breakdown ---\n")
  for (size_key in names(results$performance_summary)) {
    perf <- results$performance_summary[[size_key]]
    status <- if (perf$meets_target) "✅ PASS" else "❌ FAIL"
    
    cat(sprintf("%s | Size: %s | R: %.1fms | Python: %.1fms | Overhead: %.1f%% | Target: %.1fms\n",
               status,
               format(perf$dataset_size, big.mark = ","),
               perf$r_mean_ms,
               perf$python_mean_ms,
               perf$overhead_percent,
               perf$target_ms))
  }
  
  cat("\n--- Overall Assessment ---\n")
  if (summary$success_rate >= 75) {
    cat("🎉 EXCELLENT: Performance optimization is successful!\n")
  } else if (summary$success_rate >= 50) {
    cat("⚠️  PARTIAL: Some performance targets met, optimization partially successful\n")
  } else {
    cat("❌ NEEDS WORK: Performance targets not met, further optimization required\n")
  }
  
  cat("=" %R% 60, "\n")
}

#' Save validation results to file
#' @param results Test results to save
save_validation_results <- function(results) {
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Save detailed results as RDS
  rds_file <- sprintf("performance_validation_%s.rds", timestamp)
  saveRDS(results, rds_file)
  
  # Save summary as JSON
  json_file <- sprintf("performance_validation_summary_%s.json", timestamp)
  write(toJSON(results$performance_summary, pretty = TRUE, auto_unbox = TRUE), json_file)
  
  # Generate HTML report
  html_file <- sprintf("performance_validation_report_%s.html", timestamp)
  generate_html_report(results, html_file)
  
  cat(sprintf("\nResults saved:\n"))
  cat(sprintf("  Detailed: %s\n", rds_file))
  cat(sprintf("  Summary: %s\n", json_file))
  cat(sprintf("  Report: %s\n", html_file))
}

#' Generate HTML performance report
#' @param results Test results
#' @param output_file Output HTML file path
generate_html_report <- function(results, output_file) {
  
  # Create performance table
  perf_rows <- ""
  for (size_key in names(results$performance_summary)) {
    perf <- results$performance_summary[[size_key]]
    status_class <- if (perf$meets_target) "success" else "failure"
    status_text <- if (perf$meets_target) "PASS" else "FAIL"
    
    perf_rows <- paste0(perf_rows, sprintf('
    <tr class="%s">
      <td>%s</td>
      <td>%.1f</td>
      <td>%.1f</td>
      <td>%.1f</td>
      <td>%.1f</td>
      <td>%.1f%%</td>
      <td>%s</td>
    </tr>',
      status_class,
      format(perf$dataset_size, big.mark = ","),
      perf$r_mean_ms,
      perf$python_mean_ms,
      perf$target_ms,
      perf$speedup_factor,
      perf$overhead_percent,
      status_text
    ))
  }
  
  html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
    <title>R Performance Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f5f5f5; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .summary { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        table { border-collapse: collapse; width: 100%%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: center; }
        th { background-color: #f2f2f2; font-weight: bold; }
        .success { background-color: #d4edda; }
        .failure { background-color: #f8d7da; }
        .metric { display: inline-block; margin: 10px 20px; text-align: center; }
        .metric-value { font-size: 24px; font-weight: bold; color: #007bff; }
        .metric-label { font-size: 14px; color: #666; }
    </style>
</head>
<body>
    <div class="header">
        <h1>R Performance Optimization Validation Report</h1>
        <p><strong>Generated:</strong> %s</p>
        <p><strong>Objective:</strong> Validate that optimized R implementation meets performance targets</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <div class="metric">
            <div class="metric-value">%d/%d</div>
            <div class="metric-label">Tests Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value">%.1f%%</div>
            <div class="metric-label">Success Rate</div>
        </div>
        <div class="metric">
            <div class="metric-value">%d</div>
            <div class="metric-label">Dataset Sizes Tested</div>
        </div>
    </div>
    
    <h2>Performance Results</h2>
    <table>
        <thead>
            <tr>
                <th>Dataset Size</th>
                <th>R Performance (ms)</th>
                <th>Python Baseline (ms)</th>
                <th>Target (ms)</th>
                <th>Speedup Factor</th>
                <th>Overhead %%</th>
                <th>Status</th>
            </tr>
        </thead>
        <tbody>
            %s
        </tbody>
    </table>
    
    <div class="summary">
        <h3>Performance Targets</h3>
        <ul>
            <li><strong>Target:</strong> R performance within defined time limits</li>
            <li><strong>Overhead Limit:</strong> Maximum 50%% slower than Python baseline</li>
            <li><strong>Success Criteria:</strong> Both target time and overhead limit must be met</li>
        </ul>
    </div>
    
    <div class="summary">
        <h3>Optimization Impact</h3>
        <p>This report validates the performance improvements achieved through R code optimization, 
        particularly the JSON conversion bottleneck elimination and memory management enhancements.</p>
    </div>
</body>
</html>',
    Sys.time(),
    results$test_summary$tests_passed,
    results$test_summary$total_tests,
    results$test_summary$success_rate,
    results$test_summary$total_tests,
    perf_rows
  )
  
  writeLines(html_content, output_file)
}

# Helper function for string repetition
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  # Parse command line arguments
  dataset_sizes <- c(10000, 100000, 500000, 1000000)  # Default sizes
  save_results <- TRUE
  
  if (length(args) > 0) {
    if (args[1] == "--help" || args[1] == "-h") {
      cat("Usage: Rscript performance-validation-tests.R [options]\n")
      cat("Options:\n")
      cat("  --sizes SIZE1,SIZE2,...  Comma-separated dataset sizes to test\n")
      cat("  --no-save               Don't save results to files\n")
      cat("  --help                  Show this help message\n")
      return()
    }
    
    for (i in 1:length(args)) {
      if (args[i] == "--sizes" && i < length(args)) {
        dataset_sizes <- as.numeric(strsplit(args[i + 1], ",")[[1]])
      } else if (args[i] == "--no-save") {
        save_results <- FALSE
      }
    }
  }
  
  # Execute validation tests
  tryCatch({
    results <- execute_performance_validation(dataset_sizes, save_results)
    
    # Exit with appropriate code
    exit_code <- if (results$test_summary$success_rate >= 75) 0 else 1
    quit(save = "no", status = exit_code)
    
  }, error = function(e) {
    cat("Error executing performance validation:", e$message, "\n")
    quit(save = "no", status = 1)
  })
}

# Execute if run directly
if (!interactive()) {
  main()
}