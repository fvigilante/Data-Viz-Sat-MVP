#!/usr/bin/env Rscript

# Automated Benchmark Execution Script
# Runs scheduled benchmarks and generates comparison reports

library(httr)
library(jsonlite)
library(data.table)

# Configuration for automated benchmarking
AUTO_CONFIG <- list(
  # Benchmark schedules
  schedules = list(
    daily = list(
      dataset_sizes = c(10000, 100000, 500000),
      iterations = 3,
      max_points = 50000
    ),
    weekly = list(
      dataset_sizes = c(10000, 50000, 100000, 500000, 1000000),
      iterations = 5,
      max_points = c(10000, 50000, 100000)
    ),
    stress = list(
      dataset_sizes = c(1000000, 5000000),
      iterations = 10,
      max_points = c(50000, 100000)
    )
  ),
  
  # Output configuration
  output_dir = "benchmark_results",
  keep_results_days = 30,
  
  # Notification thresholds
  performance_degradation_threshold = 1.5,  # Alert if 50% slower
  memory_increase_threshold = 2.0           # Alert if 2x more memory
)

# Ensure output directory exists
if (!dir.exists(AUTO_CONFIG$output_dir)) {
  dir.create(AUTO_CONFIG$output_dir, recursive = TRUE)
}

# Run automated benchmark with specific configuration
run_automated_benchmark <- function(schedule_name = "daily") {
  cat(sprintf("Running automated benchmark: %s\n", schedule_name))
  cat("=" %R% 50, "\n")
  
  if (!schedule_name %in% names(AUTO_CONFIG$schedules)) {
    stop(paste("Unknown schedule:", schedule_name))
  }
  
  config <- AUTO_CONFIG$schedules[[schedule_name]]
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Check API health first
  if (!check_apis_available()) {
    stop("One or both APIs are not available")
  }
  
  results <- list()
  test_counter <- 1
  
  # Run benchmarks based on schedule configuration
  for (dataset_size in config$dataset_sizes) {
    cat(sprintf("Testing dataset size: %s\n", format(dataset_size, big.mark = ",")))
    
    max_points_list <- if (is.list(config$max_points)) config$max_points else list(config$max_points)
    
    for (max_points in max_points_list) {
      if (max_points > dataset_size) next
      
      params <- list(
        dataset_size = dataset_size,
        max_points = max_points,
        p_value_threshold = 0.05,
        log_fc_min = -1.0,
        log_fc_max = 1.0
      )
      
      cat(sprintf("  Test %d: max_points=%s\n", test_counter, format(max_points, big.mark = ",")))
      
      # Run benchmark iterations
      fastapi_times <- c()
      r_times <- c()
      
      for (i in 1:config$iterations) {
        # FastAPI test
        fastapi_result <- time_single_call("fastapi", "/api/volcano-data", params)
        if (fastapi_result$success) {
          fastapi_times <- c(fastapi_times, fastapi_result$duration_ms)
        }
        
        # R API test
        r_result <- time_single_call("r", "/api/volcano-data", params)
        if (r_result$success) {
          r_times <- c(r_times, r_result$duration_ms)
        }
        
        cat(".")
      }
      cat("\n")
      
      # Store results
      if (length(fastapi_times) > 0 && length(r_times) > 0) {
        results[[test_counter]] <- list(
          test_id = test_counter,
          schedule = schedule_name,
          timestamp = Sys.time(),
          params = params,
          fastapi_times = fastapi_times,
          r_times = r_times,
          fastapi_mean = mean(fastapi_times),
          r_mean = mean(r_times),
          speedup_factor = mean(fastapi_times) / mean(r_times)
        )
      }
      
      test_counter <- test_counter + 1
    }
  }
  
  # Save results
  output_file <- file.path(AUTO_CONFIG$output_dir, 
                          sprintf("auto_benchmark_%s_%s.rds", schedule_name, timestamp))
  saveRDS(results, output_file)
  
  # Generate report
  report_file <- file.path(AUTO_CONFIG$output_dir, 
                          sprintf("auto_report_%s_%s.html", schedule_name, timestamp))
  generate_automated_report(results, report_file, schedule_name)
  
  cat(sprintf("Automated benchmark completed. Results: %s\n", output_file))
  cat(sprintf("Report generated: %s\n", report_file))
  
  # Check for performance alerts
  check_performance_alerts(results, schedule_name)
  
  results
}

# Time a single API call
time_single_call <- function(api_type, endpoint, params) {
  url <- if (api_type == "fastapi") {
    paste0(Sys.getenv("FASTAPI_URL", "http://localhost:8000"), endpoint)
  } else {
    paste0(Sys.getenv("R_API_URL", "http://localhost:8001"), endpoint)
  }
  
  start_time <- Sys.time()
  
  tryCatch({
    response <- GET(url, query = params)
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      response_data <- content(response, "parsed")
      
      list(
        success = TRUE,
        duration_ms = duration_ms,
        data_points = response_data$filtered_rows %||% NA
      )
    } else {
      list(success = FALSE, error = paste("HTTP", status_code(response)))
    }
  }, error = function(e) {
    list(success = FALSE, error = e$message)
  })
}

# Check if both APIs are available
check_apis_available <- function() {
  fastapi_url <- Sys.getenv("FASTAPI_URL", "http://localhost:8000")
  r_url <- Sys.getenv("R_API_URL", "http://localhost:8001")
  
  fastapi_ok <- tryCatch({
    response <- GET(paste0(fastapi_url, "/health"))
    status_code(response) == 200
  }, error = function(e) FALSE)
  
  r_ok <- tryCatch({
    response <- GET(paste0(r_url, "/health"))
    status_code(response) == 200
  }, error = function(e) FALSE)
  
  if (!fastapi_ok) cat("Warning: FastAPI not available\n")
  if (!r_ok) cat("Warning: R API not available\n")
  
  fastapi_ok && r_ok
}

# Generate automated benchmark report
generate_automated_report <- function(results, output_file, schedule_name) {
  # Process results into summary
  summary_data <- rbindlist(lapply(results, function(r) {
    data.table(
      test_id = r$test_id,
      dataset_size = r$params$dataset_size,
      max_points = r$params$max_points,
      fastapi_mean = r$fastapi_mean,
      r_mean = r$r_mean,
      speedup_factor = r$speedup_factor,
      faster_api = if (r$speedup_factor > 1) "R" else "FastAPI",
      timestamp = r$timestamp
    )
  }))
  
  # Calculate overall statistics
  overall_speedup <- mean(summary_data$speedup_factor, na.rm = TRUE)
  r_wins <- sum(summary_data$speedup_factor > 1, na.rm = TRUE)
  total_tests <- nrow(summary_data)
  
  # Generate HTML report
  html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
    <title>Automated Benchmark Report - %s</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: right; }
        th { background-color: #f2f2f2; text-align: center; }
        .summary { background-color: #f9f9f9; padding: 15px; margin: 20px 0; }
        .alert { background-color: #ffe6e6; border-left: 4px solid #ff0000; padding: 10px; margin: 10px 0; }
        .success { background-color: #e6ffe6; border-left: 4px solid #00aa00; padding: 10px; margin: 10px 0; }
    </style>
</head>
<body>
    <h1>Automated Benchmark Report: %s</h1>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><strong>Schedule:</strong> %s</p>
        <p><strong>Generated:</strong> %s</p>
        <p><strong>Total Tests:</strong> %d</p>
        <p><strong>R Wins:</strong> %d/%d (%.1f%%)</p>
        <p><strong>Overall Speedup:</strong> %s is %.2fx faster on average</p>
    </div>
    
    <h2>Detailed Results</h2>
    %s
    
    <div class="summary">
        <h3>Performance Trends</h3>
        <p>This automated benchmark provides regular performance monitoring between R and Python implementations.</p>
        <p>Use these results to track performance changes over time and identify optimization opportunities.</p>
    </div>
</body>
</html>',
    schedule_name,
    schedule_name,
    schedule_name,
    Sys.time(),
    total_tests,
    r_wins, total_tests, (r_wins/total_tests)*100,
    if (overall_speedup > 1) "R" else "FastAPI",
    if (overall_speedup > 1) overall_speedup else 1/overall_speedup,
    knitr::kable(summary_data, format = "html", digits = 2)
  )
  
  writeLines(html_content, output_file)
}

# Check for performance alerts
check_performance_alerts <- function(results, schedule_name) {
  # This is a simplified alert system - in production, you might want to
  # compare against historical baselines or send notifications
  
  summary_data <- rbindlist(lapply(results, function(r) {
    data.table(
      dataset_size = r$params$dataset_size,
      fastapi_mean = r$fastapi_mean,
      r_mean = r$r_mean,
      speedup_factor = r$speedup_factor
    )
  }))
  
  # Check for significant performance differences
  extreme_ratios <- summary_data[speedup_factor > AUTO_CONFIG$performance_degradation_threshold | 
                                speedup_factor < (1/AUTO_CONFIG$performance_degradation_threshold)]
  
  if (nrow(extreme_ratios) > 0) {
    cat("\n⚠️  PERFORMANCE ALERTS:\n")
    for (i in 1:nrow(extreme_ratios)) {
      row <- extreme_ratios[i]
      if (row$speedup_factor > AUTO_CONFIG$performance_degradation_threshold) {
        cat(sprintf("  Dataset %s: R is %.1fx faster than FastAPI (%.1f ms vs %.1f ms)\n",
                   format(row$dataset_size, big.mark = ","),
                   row$speedup_factor, row$r_mean, row$fastapi_mean))
      } else {
        cat(sprintf("  Dataset %s: FastAPI is %.1fx faster than R (%.1f ms vs %.1f ms)\n",
                   format(row$dataset_size, big.mark = ","),
                   1/row$speedup_factor, row$fastapi_mean, row$r_mean))
      }
    }
  } else {
    cat("\n✅ No significant performance alerts detected.\n")
  }
}

# Clean up old benchmark results
cleanup_old_results <- function() {
  if (!dir.exists(AUTO_CONFIG$output_dir)) return()
  
  files <- list.files(AUTO_CONFIG$output_dir, pattern = "auto_benchmark_.*\\.(rds|html)", full.names = TRUE)
  cutoff_date <- Sys.Date() - AUTO_CONFIG$keep_results_days
  
  old_files <- files[file.mtime(files) < as.POSIXct(cutoff_date)]
  
  if (length(old_files) > 0) {
    cat(sprintf("Cleaning up %d old benchmark files...\n", length(old_files)))
    file.remove(old_files)
  }
}

# Helper function for string repetition
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    cat("Usage: Rscript automated-benchmark.R [schedule] [options]\n")
    cat("Available schedules: daily, weekly, stress\n")
    cat("Options:\n")
    cat("  cleanup - Clean up old benchmark results\n")
    return()
  }
  
  command <- args[1]
  
  if (command == "cleanup") {
    cleanup_old_results()
    return()
  }
  
  if (command %in% names(AUTO_CONFIG$schedules)) {
    # Clean up old results first
    cleanup_old_results()
    
    # Run the benchmark
    results <- run_automated_benchmark(command)
    cat("Automated benchmark completed successfully!\n")
  } else {
    cat("Unknown schedule:", command, "\n")
    cat("Available schedules:", paste(names(AUTO_CONFIG$schedules), collapse = ", "), "\n")
  }
}

# Execute if run directly
if (!interactive()) {
  main()
}