#!/usr/bin/env Rscript

# Quick Performance Benchmark Script
# Provides fast performance comparison for development and testing

library(httr)
library(jsonlite)
library(data.table)

# Configuration
FASTAPI_BASE_URL <- Sys.getenv("FASTAPI_URL", "http://localhost:8000")
R_API_BASE_URL <- Sys.getenv("R_API_URL", "http://localhost:8001")

# Quick benchmark configuration (smaller test set)
QUICK_CONFIG <- list(
  dataset_sizes = c(10000, 100000, 500000),
  max_points = 50000,
  p_value_threshold = 0.05,
  log_fc_min = -1.0,
  log_fc_max = 1.0,
  iterations = 3
)

# Simple timing function
time_api_call <- function(api_type, endpoint, params) {
  url <- if (api_type == "fastapi") {
    paste0(FASTAPI_BASE_URL, endpoint)
  } else {
    paste0(R_API_BASE_URL, endpoint)
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
        data_points = response_data$filtered_rows %||% NA,
        total_rows = response_data$total_rows %||% NA
      )
    } else {
      list(
        success = FALSE,
        error = paste("HTTP", status_code(response))
      )
    }
  }, error = function(e) {
    end_time <- Sys.time()
    duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
    
    list(
      success = FALSE,
      duration_ms = duration_ms,
      error = e$message
    )
  })
}

# Run quick benchmark
run_quick_benchmark <- function() {
  cat("Running quick performance benchmark...\n")
  cat("=" %R% 50, "\n")
  
  results <- data.table()
  
  for (dataset_size in QUICK_CONFIG$dataset_sizes) {
    cat(sprintf("Testing dataset size: %s\n", format(dataset_size, big.mark = ",")))
    
    params <- list(
      dataset_size = dataset_size,
      max_points = QUICK_CONFIG$max_points,
      p_value_threshold = QUICK_CONFIG$p_value_threshold,
      log_fc_min = QUICK_CONFIG$log_fc_min,
      log_fc_max = QUICK_CONFIG$log_fc_max
    )
    
    # Test FastAPI
    fastapi_times <- c()
    r_times <- c()
    
    for (i in 1:QUICK_CONFIG$iterations) {
      # FastAPI test
      fastapi_result <- time_api_call("fastapi", "/api/volcano-data", params)
      if (fastapi_result$success) {
        fastapi_times <- c(fastapi_times, fastapi_result$duration_ms)
      }
      
      # R API test
      r_result <- time_api_call("r", "/api/volcano-data", params)
      if (r_result$success) {
        r_times <- c(r_times, r_result$duration_ms)
      }
      
      cat(".")
    }
    cat("\n")
    
    # Calculate statistics
    if (length(fastapi_times) > 0 && length(r_times) > 0) {
      fastapi_mean <- mean(fastapi_times)
      r_mean <- mean(r_times)
      speedup <- fastapi_mean / r_mean
      
      results <- rbind(results, data.table(
        dataset_size = dataset_size,
        fastapi_mean_ms = fastapi_mean,
        r_mean_ms = r_mean,
        speedup_factor = speedup,
        faster_api = if (speedup > 1) "R" else "FastAPI"
      ))
      
      cat(sprintf("  FastAPI: %.1f ms (avg)\n", fastapi_mean))
      cat(sprintf("  R API:   %.1f ms (avg)\n", r_mean))
      cat(sprintf("  %s is %.2fx faster\n", 
                 if (speedup > 1) "R" else "FastAPI", 
                 if (speedup > 1) speedup else 1/speedup))
    } else {
      cat("  Error: One or both APIs failed\n")
    }
    cat("\n")
  }
  
  # Summary
  cat("SUMMARY\n")
  cat("=" %R% 50, "\n")
  print(results)
  
  if (nrow(results) > 0) {
    overall_speedup <- mean(results$speedup_factor)
    cat(sprintf("\nOverall: %s is %.2fx faster on average\n", 
               if (overall_speedup > 1) "R" else "FastAPI",
               if (overall_speedup > 1) overall_speedup else 1/overall_speedup))
  }
  
  invisible(results)
}

# Health check function
check_api_health <- function() {
  cat("Checking API health...\n")
  
  # Check FastAPI
  fastapi_health <- tryCatch({
    response <- GET(paste0(FASTAPI_BASE_URL, "/health"))
    status_code(response) == 200
  }, error = function(e) FALSE)
  
  # Check R API
  r_health <- tryCatch({
    response <- GET(paste0(R_API_BASE_URL, "/health"))
    status_code(response) == 200
  }, error = function(e) FALSE)
  
  cat(sprintf("FastAPI (%s): %s\n", FASTAPI_BASE_URL, 
             if (fastapi_health) "✓ OK" else "✗ FAILED"))
  cat(sprintf("R API (%s): %s\n", R_API_BASE_URL, 
             if (r_health) "✓ OK" else "✗ FAILED"))
  
  if (!fastapi_health || !r_health) {
    cat("\nPlease ensure both APIs are running before benchmarking.\n")
    return(FALSE)
  }
  
  TRUE
}

# Main execution
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) > 0 && args[1] == "health") {
    check_api_health()
    return()
  }
  
  if (!check_api_health()) {
    return()
  }
  
  cat("\n")
  results <- run_quick_benchmark()
  
  # Save results
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  output_file <- paste0("quick_benchmark_", timestamp, ".rds")
  saveRDS(results, output_file)
  cat(sprintf("\nResults saved to: %s\n", output_file))
}

# Helper function for string repetition
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Execute if run directly
if (!interactive()) {
  main()
}