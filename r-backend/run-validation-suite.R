#!/usr/bin/env Rscript

# Comprehensive Validation Test Suite Runner
# Executes both performance validation and API compatibility tests

library(httr)
library(jsonlite)

# Test suite configuration
SUITE_CONFIG <- list(
  r_api_url = Sys.getenv("R_API_URL", "http://localhost:8001"),
  python_api_url = Sys.getenv("PYTHON_API_URL", "http://localhost:8000"),
  output_dir = "validation_results",
  run_performance_tests = TRUE,
  run_compatibility_tests = TRUE,
  dataset_sizes = c(10000, 100000, 500000, 1000000)
)

#' Execute the complete validation test suite
#' @param config Test configuration list
#' @return List with overall results
execute_validation_suite <- function(config = SUITE_CONFIG) {
  
  cat("=== R OPTIMIZATION VALIDATION TEST SUITE ===\n")
  cat("=" %R% 50, "\n")
  cat("Testing R performance optimization implementation\n")
  cat("Validating performance targets and API compatibility\n\n")
  
  # Create output directory
  if (!dir.exists(config$output_dir)) {
    dir.create(config$output_dir, recursive = TRUE)
    cat("Created output directory:", config$output_dir, "\n")
  }
  
  # Initialize overall results
  suite_results <- list(
    start_time = Sys.time(),
    performance_results = NULL,
    compatibility_results = NULL,
    overall_success = FALSE,
    summary = list()
  )
  
  # Check API availability first
  if (!check_suite_apis_available(config)) {
    stop("Required APIs are not available. Please start both R and Python servers.")
  }
  
  # Run performance validation tests
  if (config$run_performance_tests) {
    cat("\n" %R% 40, "\n")
    cat("PHASE 1: PERFORMANCE VALIDATION TESTS\n")
    cat("=" %R% 40, "\n")
    
    tryCatch({
      # Source and run performance tests
      source("r-backend/performance-validation-tests.R")
      
      perf_results <- execute_performance_validation(
        dataset_sizes = config$dataset_sizes,
        save_results = FALSE  # We'll save everything together
      )
      
      suite_results$performance_results <- perf_results
      
      cat("✅ Performance validation tests completed\n")
      
    }, error = function(e) {
      cat("❌ Performance validation tests failed:", e$message, "\n")
      suite_results$performance_results <- list(
        error = e$message,
        test_summary = list(success_rate = 0)
      )
    })
  }
  
  # Run API compatibility tests
  if (config$run_compatibility_tests) {
    cat("\n" %R% 40, "\n")
    cat("PHASE 2: API COMPATIBILITY TESTS\n")
    cat("=" %R% 40, "\n")
    
    tryCatch({
      # Source and run compatibility tests
      source("r-backend/api-compatibility-tests.R")
      
      compat_results <- execute_compatibility_tests(save_results = FALSE)
      
      suite_results$compatibility_results <- compat_results
      
      cat("✅ API compatibility tests completed\n")
      
    }, error = function(e) {
      cat("❌ API compatibility tests failed:", e$message, "\n")
      suite_results$compatibility_results <- list(
        error = e$message,
        test_summary = list(success_rate = 0)
      )
    })
  }
  
  # Calculate overall results
  suite_results$end_time <- Sys.time()
  suite_results <- calculate_suite_summary(suite_results)
  
  # Print final summary
  print_suite_summary(suite_results)
  
  # Save comprehensive results
  save_suite_results(suite_results, config$output_dir)
  
  return(suite_results)
}

#' Check if required APIs are available
#' @param config Test configuration
#' @return Logical indicating availability
check_suite_apis_available <- function(config) {
  
  cat("Checking API availability...\n")
  
  # Check R API
  r_available <- tryCatch({
    response <- GET(paste0(config$r_api_url, "/health"), timeout(10))
    if (status_code(response) == 200) {
      health_data <- content(response, "parsed")
      cat("R API: ✅ Available -", health_data$backend %||% "R API", "\n")
      TRUE
    } else {
      cat("R API: ❌ HTTP", status_code(response), "\n")
      FALSE
    }
  }, error = function(e) {
    cat("R API: ❌ Not available -", e$message, "\n")
    FALSE
  })
  
  # Check Python API
  python_available <- tryCatch({
    response <- GET(paste0(config$python_api_url, "/health"), timeout(10))
    if (status_code(response) == 200) {
      cat("Python API: ✅ Available - FastAPI\n")
      TRUE
    } else {
      cat("Python API: ❌ HTTP", status_code(response), "\n")
      False
    }
  }, error = function(e) {
    cat("Python API: ❌ Not available -", e$message, "\n")
    FALSE
  })
  
  return(r_available && python_available)
}

#' Calculate overall suite summary
#' @param suite_results Results from all tests
#' @return Updated results with summary
calculate_suite_summary <- function(suite_results) {
  
  # Initialize summary
  summary <- list(
    total_duration_sec = as.numeric(difftime(suite_results$end_time, suite_results$start_time, units = "secs")),
    performance_success_rate = 0,
    compatibility_success_rate = 0,
    overall_success_rate = 0,
    tests_run = 0,
    tests_passed = 0
  )
  
  # Process performance results
  if (!is.null(suite_results$performance_results) && 
      !is.null(suite_results$performance_results$test_summary)) {
    
    perf_summary <- suite_results$performance_results$test_summary
    summary$performance_success_rate <- perf_summary$success_rate %||% 0
    summary$tests_run <- summary$tests_run + (perf_summary$total_tests %||% 0)
    summary$tests_passed <- summary$tests_passed + (perf_summary$tests_passed %||% 0)
  }
  
  # Process compatibility results
  if (!is.null(suite_results$compatibility_results) && 
      !is.null(suite_results$compatibility_results$test_summary)) {
    
    compat_summary <- suite_results$compatibility_results$test_summary
    summary$compatibility_success_rate <- compat_summary$success_rate %||% 0
    summary$tests_run <- summary$tests_run + (compat_summary$total_scenarios %||% 0)
    summary$tests_passed <- summary$tests_passed + (compat_summary$passed %||% 0)
  }
  
  # Calculate overall success rate
  if (summary$tests_run > 0) {
    summary$overall_success_rate <- (summary$tests_passed / summary$tests_run) * 100
  }
  
  # Determine overall success
  suite_results$overall_success <- summary$performance_success_rate >= 75 && 
                                  summary$compatibility_success_rate >= 80
  
  suite_results$summary <- summary
  
  return(suite_results)
}

#' Print comprehensive suite summary
#' @param suite_results Complete test results
print_suite_summary <- function(suite_results) {
  
  cat("\n" %R% 60, "\n")
  cat("=== VALIDATION SUITE SUMMARY ===\n")
  cat("=" %R% 60, "\n")
  
  summary <- suite_results$summary
  
  cat(sprintf("Total Duration: %.1f seconds\n", summary$total_duration_sec))
  cat(sprintf("Tests Run: %d\n", summary$tests_run))
  cat(sprintf("Tests Passed: %d\n", summary$tests_passed))
  cat(sprintf("Overall Success Rate: %.1f%%\n", summary$overall_success_rate))
  
  cat("\n--- Test Phase Results ---\n")
  
  # Performance results
  if (!is.null(suite_results$performance_results)) {
    if (!is.null(suite_results$performance_results$error)) {
      cat("Performance Tests: ❌ FAILED -", suite_results$performance_results$error, "\n")
    } else {
      perf_rate <- summary$performance_success_rate
      status <- if (perf_rate >= 75) "✅ PASSED" else "❌ FAILED"
      cat(sprintf("Performance Tests: %s (%.1f%% success rate)\n", status, perf_rate))
    }
  } else {
    cat("Performance Tests: ⏭️ SKIPPED\n")
  }
  
  # Compatibility results
  if (!is.null(suite_results$compatibility_results)) {
    if (!is.null(suite_results$compatibility_results$error)) {
      cat("Compatibility Tests: ❌ FAILED -", suite_results$compatibility_results$error, "\n")
    } else {
      compat_rate <- summary$compatibility_success_rate
      status <- if (compat_rate >= 80) "✅ PASSED" else "❌ FAILED"
      cat(sprintf("Compatibility Tests: %s (%.1f%% success rate)\n", status, compat_rate))
    }
  } else {
    cat("Compatibility Tests: ⏭️ SKIPPED\n")
  }
  
  cat("\n--- Overall Assessment ---\n")
  if (suite_results$overall_success) {
    cat("🎉 SUCCESS: R optimization implementation is validated!\n")
    cat("   ✓ Performance targets met\n")
    cat("   ✓ API compatibility confirmed\n")
    cat("   ✓ Ready for production use\n")
  } else {
    cat("⚠️  ISSUES DETECTED: Optimization needs attention\n")
    
    if (summary$performance_success_rate < 75) {
      cat("   ❌ Performance targets not consistently met\n")
    }
    if (summary$compatibility_success_rate < 80) {
      cat("   ❌ API compatibility issues detected\n")
    }
    
    cat("   📋 Review detailed results for specific issues\n")
  }
  
  cat("=" %R% 60, "\n")
}

#' Save comprehensive suite results
#' @param suite_results Complete test results
#' @param output_dir Output directory
save_suite_results <- function(suite_results, output_dir) {
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Save complete results as RDS
  rds_file <- file.path(output_dir, sprintf("validation_suite_%s.rds", timestamp))
  saveRDS(suite_results, rds_file)
  
  # Save summary as JSON
  json_file <- file.path(output_dir, sprintf("validation_summary_%s.json", timestamp))
  write(toJSON(suite_results$summary, pretty = TRUE, auto_unbox = TRUE), json_file)
  
  # Generate comprehensive HTML report
  html_file <- file.path(output_dir, sprintf("validation_report_%s.html", timestamp))
  generate_suite_html_report(suite_results, html_file)
  
  cat(sprintf("\nValidation suite results saved:\n"))
  cat(sprintf("  Complete Results: %s\n", rds_file))
  cat(sprintf("  Summary: %s\n", json_file))
  cat(sprintf("  HTML Report: %s\n", html_file))
}

#' Generate comprehensive HTML report
#' @param suite_results Complete test results
#' @param output_file Output HTML file path
generate_suite_html_report <- function(suite_results, output_file) {
  
  summary <- suite_results$summary
  
  # Performance section
  perf_section <- ""
  if (!is.null(suite_results$performance_results) && 
      !is.null(suite_results$performance_results$performance_summary)) {
    
    perf_rows <- ""
    for (size_key in names(suite_results$performance_results$performance_summary)) {
      perf <- suite_results$performance_results$performance_summary[[size_key]]
      status_class <- if (perf$meets_target) "success" else "failure"
      
      perf_rows <- paste0(perf_rows, sprintf('
      <tr class="%s">
        <td>%s</td>
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
        perf$overhead_percent,
        if (perf$meets_target) "PASS" else "FAIL"
      ))
    }
    
    perf_section <- sprintf('
    <h2>Performance Validation Results</h2>
    <table>
      <thead>
        <tr>
          <th>Dataset Size</th>
          <th>R Performance (ms)</th>
          <th>Python Baseline (ms)</th>
          <th>Target (ms)</th>
          <th>Overhead %%</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>%s</tbody>
    </table>', perf_rows)
  }
  
  # Compatibility section
  compat_section <- ""
  if (!is.null(suite_results$compatibility_results) && 
      !is.null(suite_results$compatibility_results$compatibility_summary)) {
    
    compat_rows <- ""
    for (scenario_name in names(suite_results$compatibility_results$compatibility_summary)) {
      comp <- suite_results$compatibility_results$compatibility_summary[[scenario_name]]
      status_class <- if (comp$compatible) "success" else "failure"
      
      compat_rows <- paste0(compat_rows, sprintf('
      <tr class="%s">
        <td>%s</td>
        <td>%s</td>
        <td>%s</td>
        <td>%s</td>
        <td>%s</td>
        <td>%s</td>
      </tr>',
        status_class,
        comp$scenario_name,
        if (comp$structure_match) "✓" else "✗",
        if (comp$data_consistency) "✓" else "✗",
        if (comp$stats_match) "✓" else "✗",
        if (comp$compatible) "COMPATIBLE" else "INCOMPATIBLE"
      ))
    }
    
    compat_section <- sprintf('
    <h2>API Compatibility Results</h2>
    <table>
      <thead>
        <tr>
          <th>Test Scenario</th>
          <th>Structure</th>
          <th>Data</th>
          <th>Statistics</th>
          <th>Status</th>
        </tr>
      </thead>
      <tbody>%s</tbody>
    </table>', compat_rows)
  }
  
  html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
    <title>R Optimization Validation Suite Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f5f5f5; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .summary { background: #e8f4fd; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .success-summary { background: #d4edda; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .failure-summary { background: #f8d7da; padding: 15px; border-radius: 5px; margin: 20px 0; }
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
        <h1>R Performance Optimization Validation Suite</h1>
        <p><strong>Generated:</strong> %s</p>
        <p><strong>Duration:</strong> %.1f seconds</p>
        <p><strong>Objective:</strong> Comprehensive validation of R performance optimization implementation</p>
    </div>
    
    <div class="%s">
        <h2>Overall Results</h2>
        <div class="metric">
            <div class="metric-value">%d/%d</div>
            <div class="metric-label">Tests Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value">%.1f%%</div>
            <div class="metric-label">Success Rate</div>
        </div>
        <div class="metric">
            <div class="metric-value">%.1f%%</div>
            <div class="metric-label">Performance</div>
        </div>
        <div class="metric">
            <div class="metric-value">%.1f%%</div>
            <div class="metric-label">Compatibility</div>
        </div>
    </div>
    
    %s
    
    %s
    
    <div class="summary">
        <h3>Validation Objectives</h3>
        <ul>
            <li><strong>Performance:</strong> R implementation meets defined performance targets</li>
            <li><strong>Compatibility:</strong> R and Python APIs produce identical outputs</li>
            <li><strong>Optimization:</strong> Verify JSON conversion and memory management improvements</li>
        </ul>
    </div>
</body>
</html>',
    Sys.time(),
    summary$total_duration_sec,
    if (suite_results$overall_success) "success-summary" else "failure-summary",
    summary$tests_passed,
    summary$tests_run,
    summary$overall_success_rate,
    summary$performance_success_rate,
    summary$compatibility_success_rate,
    perf_section,
    compat_section
  )
  
  writeLines(html_content, output_file)
}

# Helper function for string repetition
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  config <- SUITE_CONFIG
  
  if (length(args) > 0) {
    if (args[1] == "--help" || args[1] == "-h") {
      cat("Usage: Rscript run-validation-suite.R [options]\n")
      cat("Options:\n")
      cat("  --performance-only    Run only performance validation tests\n")
      cat("  --compatibility-only  Run only API compatibility tests\n")
      cat("  --sizes SIZE1,SIZE2   Comma-separated dataset sizes for performance tests\n")
      cat("  --output-dir DIR      Output directory for results (default: validation_results)\n")
      cat("  --help               Show this help message\n")
      return()
    }
    
    for (i in 1:length(args)) {
      if (args[i] == "--performance-only") {
        config$run_compatibility_tests <- FALSE
      } else if (args[i] == "--compatibility-only") {
        config$run_performance_tests <- FALSE
      } else if (args[i] == "--sizes" && i < length(args)) {
        config$dataset_sizes <- as.numeric(strsplit(args[i + 1], ",")[[1]])
      } else if (args[i] == "--output-dir" && i < length(args)) {
        config$output_dir <- args[i + 1]
      }
    }
  }
  
  # Execute validation suite
  tryCatch({
    results <- execute_validation_suite(config)
    
    # Exit with appropriate code
    exit_code <- if (results$overall_success) 0 else 1
    quit(save = "no", status = exit_code)
    
  }, error = function(e) {
    cat("Error executing validation suite:", e$message, "\n")
    quit(save = "no", status = 1)
  })
}

# Execute if run directly
if (!interactive()) {
  main()
}