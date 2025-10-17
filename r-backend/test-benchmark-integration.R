#!/usr/bin/env Rscript

# Integration Test for Benchmarking Framework
# Tests the framework components without requiring live APIs

library(jsonlite)
library(data.table)

cat("Benchmarking Framework Integration Test\n")
cat("=" %R% 50, "\n")

# Test 1: Configuration Loading
test_configuration_loading <- function() {
  cat("Test 1: Configuration Loading...\n")
  
  # Source the benchmark framework to load configurations
  tryCatch({
    source("benchmark-framework.R", local = TRUE)
    
    # Check if BENCHMARK_CONFIG exists and has required fields
    required_fields <- c("dataset_sizes", "max_points_options", "p_value_thresholds", "iterations")
    
    if (exists("BENCHMARK_CONFIG")) {
      missing_fields <- setdiff(required_fields, names(BENCHMARK_CONFIG))
      if (length(missing_fields) == 0) {
        cat("  ✓ BENCHMARK_CONFIG loaded successfully\n")
        cat(sprintf("  ✓ Dataset sizes: %s\n", paste(BENCHMARK_CONFIG$dataset_sizes, collapse = ", ")))
        return(TRUE)
      } else {
        cat(sprintf("  ✗ Missing fields in BENCHMARK_CONFIG: %s\n", paste(missing_fields, collapse = ", ")))
        return(FALSE)
      }
    } else {
      cat("  ✗ BENCHMARK_CONFIG not found\n")
      return(FALSE)
    }
  }, error = function(e) {
    cat(sprintf("  ✗ Error loading configuration: %s\n", e$message))
    return(FALSE)
  })
}

# Test 2: Utility Functions
test_utility_functions <- function() {
  cat("Test 2: Utility Functions...\n")
  
  tryCatch({
    source("benchmark-framework.R", local = TRUE)
    
    # Test get_system_metrics function
    metrics <- get_system_metrics()
    
    if (is.list(metrics) && "timestamp" %in% names(metrics)) {
      cat("  ✓ get_system_metrics() works\n")
    } else {
      cat("  ✗ get_system_metrics() returned invalid format\n")
      return(FALSE)
    }
    
    # Test memory profiler functions
    source("memory-profiler.R", local = TRUE)
    
    memory_info <- get_memory_usage()
    if (is.list(memory_info) && "timestamp" %in% names(memory_info)) {
      cat("  ✓ get_memory_usage() works\n")
    } else {
      cat("  ✗ get_memory_usage() returned invalid format\n")
      return(FALSE)
    }
    
    return(TRUE)
    
  }, error = function(e) {
    cat(sprintf("  ✗ Error testing utility functions: %s\n", e$message))
    return(FALSE)
  })
}

# Test 3: Mock API Response Processing
test_mock_api_processing <- function() {
  cat("Test 3: Mock API Response Processing...\n")
  
  # Create mock API response data
  mock_response <- list(
    data = data.frame(
      metabolite_name = paste0("metabolite_", 1:100),
      log2_fc = rnorm(100),
      p_value = runif(100, 0, 0.1),
      category = sample(c("up", "down", "non_significant"), 100, replace = TRUE)
    ),
    stats = list(
      up_regulated = 30,
      down_regulated = 25,
      non_significant = 45
    ),
    total_rows = 1000,
    filtered_rows = 100,
    points_before_sampling = 500,
    is_downsampled = TRUE
  )
  
  tryCatch({
    # Test JSON serialization/deserialization
    json_str <- toJSON(mock_response, auto_unbox = TRUE)
    parsed_response <- fromJSON(json_str)
    
    if (is.list(parsed_response) && "data" %in% names(parsed_response)) {
      cat("  ✓ JSON processing works\n")
    } else {
      cat("  ✗ JSON processing failed\n")
      return(FALSE)
    }
    
    # Test data.table operations
    dt <- as.data.table(parsed_response$data)
    
    # Simulate filtering operations
    filtered_dt <- dt[p_value < 0.05]
    
    if (nrow(filtered_dt) <= nrow(dt)) {
      cat("  ✓ Data filtering works\n")
    } else {
      cat("  ✗ Data filtering failed\n")
      return(FALSE)
    }
    
    return(TRUE)
    
  }, error = function(e) {
    cat(sprintf("  ✗ Error in mock API processing: %s\n", e$message))
    return(FALSE)
  })
}

# Test 4: Report Generation Structure
test_report_generation <- function() {
  cat("Test 4: Report Generation Structure...\n")
  
  # Create mock benchmark results
  mock_results <- list(
    list(
      test_id = 1,
      params = list(dataset_size = 10000, max_points = 5000),
      fastapi_results = list(
        list(success = TRUE, duration_ms = 150, data_points = 4500),
        list(success = TRUE, duration_ms = 145, data_points = 4500)
      ),
      r_results = list(
        list(success = TRUE, duration_ms = 130, data_points = 4500),
        list(success = TRUE, duration_ms = 135, data_points = 4500)
      )
    ),
    list(
      test_id = 2,
      params = list(dataset_size = 50000, max_points = 10000),
      fastapi_results = list(
        list(success = TRUE, duration_ms = 450, data_points = 9800),
        list(success = TRUE, duration_ms = 440, data_points = 9800)
      ),
      r_results = list(
        list(success = TRUE, duration_ms = 420, data_points = 9800),
        list(success = TRUE, duration_ms = 430, data_points = 9800)
      )
    )
  )
  
  tryCatch({
    # Process mock results into summary format
    summary_data <- rbindlist(lapply(mock_results, function(test) {
      fastapi_times <- sapply(test$fastapi_results, function(r) if(r$success) r$duration_ms else NA)
      r_times <- sapply(test$r_results, function(r) if(r$success) r$duration_ms else NA)
      
      data.table(
        test_id = test$test_id,
        dataset_size = test$params$dataset_size,
        fastapi_mean = mean(fastapi_times, na.rm = TRUE),
        r_mean = mean(r_times, na.rm = TRUE),
        speedup_factor = mean(fastapi_times, na.rm = TRUE) / mean(r_times, na.rm = TRUE)
      )
    }))
    
    if (nrow(summary_data) == 2 && all(c("fastapi_mean", "r_mean", "speedup_factor") %in% names(summary_data))) {
      cat("  ✓ Results processing works\n")
      cat(sprintf("  ✓ Processed %d test results\n", nrow(summary_data)))
      
      # Test basic statistics
      overall_speedup <- mean(summary_data$speedup_factor)
      cat(sprintf("  ✓ Overall speedup calculation: %.2fx\n", overall_speedup))
      
      return(TRUE)
    } else {
      cat("  ✗ Results processing failed\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat(sprintf("  ✗ Error in report generation: %s\n", e$message))
    return(FALSE)
  })
}

# Test 5: File Structure Validation
test_file_structure <- function() {
  cat("Test 5: File Structure Validation...\n")
  
  required_files <- c(
    "benchmark-framework.R",
    "quick-benchmark.R", 
    "memory-profiler.R",
    "automated-benchmark.R",
    "benchmark-runner.bat",
    "benchmark-runner.sh",
    "BENCHMARKING-README.md"
  )
  
  missing_files <- c()
  
  for (file in required_files) {
    if (file.exists(file)) {
      cat(sprintf("  ✓ %s exists\n", file))
    } else {
      cat(sprintf("  ✗ %s missing\n", file))
      missing_files <- c(missing_files, file)
    }
  }
  
  if (length(missing_files) == 0) {
    cat("  ✓ All required files present\n")
    return(TRUE)
  } else {
    cat(sprintf("  ✗ Missing files: %s\n", paste(missing_files, collapse = ", ")))
    return(FALSE)
  }
}

# Run all tests
run_integration_tests <- function() {
  tests <- list(
    "Configuration Loading" = test_configuration_loading,
    "Utility Functions" = test_utility_functions,
    "Mock API Processing" = test_mock_api_processing,
    "Report Generation" = test_report_generation,
    "File Structure" = test_file_structure
  )
  
  results <- list()
  
  for (test_name in names(tests)) {
    cat("\n")
    result <- tests[[test_name]]()
    results[[test_name]] <- result
  }
  
  # Summary
  cat("\n")
  cat("=" %R% 50, "\n")
  cat("INTEGRATION TEST SUMMARY\n")
  cat("=" %R% 50, "\n")
  
  passed <- sum(unlist(results))
  total <- length(results)
  
  for (test_name in names(results)) {
    status <- if (results[[test_name]]) "PASS" else "FAIL"
    cat(sprintf("%-25s: %s\n", test_name, status))
  }
  
  cat("\n")
  cat(sprintf("Tests passed: %d/%d (%.1f%%)\n", passed, total, (passed/total)*100))
  
  if (passed == total) {
    cat("✅ All integration tests PASSED\n")
    cat("\nBenchmarking framework is ready for use!\n")
    cat("\nNext steps:\n")
    cat("1. Install R packages: httr, jsonlite, data.table, microbenchmark, knitr\n")
    cat("2. Start FastAPI server on port 8000\n")
    cat("3. Start R Plumber API server on port 8001\n")
    cat("4. Run: benchmark-runner.bat health (Windows) or ./benchmark-runner.sh health (Unix)\n")
    cat("5. Execute benchmarks: benchmark-runner.bat quick\n")
  } else {
    cat("❌ Some integration tests FAILED\n")
    cat("Please review the errors above before using the framework.\n")
  }
  
  return(passed == total)
}

# Helper function for string repetition
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution
if (!interactive()) {
  success <- run_integration_tests()
  quit(status = if (success) 0 else 1)
}