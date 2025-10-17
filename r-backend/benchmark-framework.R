#!/usr/bin/env Rscript

# Performance Benchmarking Framework for R vs Python Volcano Plot Comparison
# This script provides comprehensive performance testing and comparison utilities

library(httr)
library(jsonlite)
library(data.table)
library(microbenchmark)

# Configuration
FASTAPI_BASE_URL <- Sys.getenv("FASTAPI_URL", "http://localhost:8000")
R_API_BASE_URL <- Sys.getenv("R_API_URL", "http://localhost:8001")

# Benchmark configuration
BENCHMARK_CONFIG <- list(
  dataset_sizes = c(10000, 50000, 100000, 500000, 1000000),
  max_points_options = c(10000, 20000, 50000, 100000),
  p_value_thresholds = c(0.001, 0.01, 0.05, 0.1),
  log_fc_ranges = list(
    c(-0.5, 0.5),
    c(-1.0, 1.0),
    c(-2.0, 2.0)
  ),
  iterations = 5,
  warmup_iterations = 2
)

# Utility functions for API calls
call_fastapi_endpoint <- function(endpoint, params = list()) {
  url <- paste0(FASTAPI_BASE_URL, endpoint)
  response <- GET(url, query = params)
  
  if (status_code(response) != 200) {
    stop(paste("FastAPI request failed:", status_code(response)))
  }
  
  content(response, "parsed")
}

call_r_api_endpoint <- function(endpoint, params = list()) {
  url <- paste0(R_API_BASE_URL, endpoint)
  response <- GET(url, query = params)
  
  if (status_code(response) != 200) {
    stop(paste("R API request failed:", status_code(response)))
  }
  
  content(response, "parsed")
}

# Memory and CPU monitoring functions
get_system_metrics <- function() {
  # Get current memory usage
  memory_info <- system("wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /format:csv", intern = TRUE)
  
  # Parse memory info (Windows-specific, adjust for other OS)
  if (Sys.info()["sysname"] == "Windows") {
    # Windows memory parsing
    memory_lines <- memory_info[grepl("^[^,]*,[0-9]", memory_info)]
    if (length(memory_lines) > 0) {
      parts <- strsplit(memory_lines[1], ",")[[1]]
      free_memory <- as.numeric(parts[2])
      total_memory <- as.numeric(parts[3])
      used_memory <- total_memory - free_memory
      memory_usage_percent <- (used_memory / total_memory) * 100
    } else {
      memory_usage_percent <- NA
    }
  } else {
    # Unix-like systems
    memory_usage_percent <- NA
  }
  
  list(
    timestamp = Sys.time(),
    memory_usage_percent = memory_usage_percent,
    available_memory_kb = if (exists("free_memory")) free_memory else NA
  )
}

# Single endpoint benchmark function
benchmark_endpoint <- function(api_type, endpoint, params, iterations = 5) {
  results <- list()
  
  # Warmup calls
  for (i in 1:2) {
    tryCatch({
      if (api_type == "fastapi") {
        call_fastapi_endpoint(endpoint, params)
      } else {
        call_r_api_endpoint(endpoint, params)
      }
    }, error = function(e) {
      warning(paste("Warmup call failed:", e$message))
    })
  }
  
  # Actual benchmark iterations
  for (i in 1:iterations) {
    start_metrics <- get_system_metrics()
    start_time <- Sys.time()
    
    tryCatch({
      if (api_type == "fastapi") {
        response <- call_fastapi_endpoint(endpoint, params)
      } else {
        response <- call_r_api_endpoint(endpoint, params)
      }
      
      end_time <- Sys.time()
      end_metrics <- get_system_metrics()
      
      # Calculate metrics
      duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      
      results[[i]] <- list(
        iteration = i,
        duration_ms = duration_ms,
        success = TRUE,
        response_size = length(toJSON(response)),
        data_points = if (!is.null(response$filtered_rows)) response$filtered_rows else NA,
        memory_start = start_metrics$memory_usage_percent,
        memory_end = end_metrics$memory_usage_percent,
        timestamp = start_time
      )
      
    }, error = function(e) {
      end_time <- Sys.time()
      duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      
      results[[i]] <- list(
        iteration = i,
        duration_ms = duration_ms,
        success = FALSE,
        error_message = e$message,
        timestamp = start_time
      )
    })
    
    # Small delay between iterations
    Sys.sleep(0.1)
  }
  
  results
}

# Comprehensive benchmark suite
run_comprehensive_benchmark <- function(output_file = NULL) {
  cat("Starting comprehensive R vs Python benchmark suite...\n")
  
  all_results <- list()
  test_counter <- 1
  
  # Test different dataset sizes
  for (dataset_size in BENCHMARK_CONFIG$dataset_sizes) {
    cat(sprintf("Testing dataset size: %d\n", dataset_size))
    
    # Test different max_points settings
    for (max_points in BENCHMARK_CONFIG$max_points_options) {
      if (max_points > dataset_size) next  # Skip if max_points > dataset_size
      
      # Test different p-value thresholds
      for (p_threshold in BENCHMARK_CONFIG$p_value_thresholds) {
        
        # Test different log FC ranges
        for (log_fc_range in BENCHMARK_CONFIG$log_fc_ranges) {
          
          params <- list(
            dataset_size = dataset_size,
            max_points = max_points,
            p_value_threshold = p_threshold,
            log_fc_min = log_fc_range[1],
            log_fc_max = log_fc_range[2]
          )
          
          cat(sprintf("  Test %d: size=%d, max_points=%d, p_val=%.3f, log_fc=[%.1f,%.1f]\n", 
                     test_counter, dataset_size, max_points, p_threshold, 
                     log_fc_range[1], log_fc_range[2]))
          
          # Benchmark FastAPI
          fastapi_results <- benchmark_endpoint("fastapi", "/api/volcano-data", params, 
                                              BENCHMARK_CONFIG$iterations)
          
          # Benchmark R API
          r_results <- benchmark_endpoint("r", "/api/volcano-data", params, 
                                        BENCHMARK_CONFIG$iterations)
          
          # Store results
          all_results[[test_counter]] <- list(
            test_id = test_counter,
            params = params,
            fastapi_results = fastapi_results,
            r_results = r_results,
            timestamp = Sys.time()
          )
          
          test_counter <- test_counter + 1
        }
      }
    }
  }
  
  # Save results if output file specified
  if (!is.null(output_file)) {
    saveRDS(all_results, output_file)
    cat(sprintf("Results saved to: %s\n", output_file))
  }
  
  all_results
}

# Generate performance comparison report
generate_performance_report <- function(benchmark_results, output_file = "performance_report.html") {
  cat("Generating performance comparison report...\n")
  
  # Process results into data.table for analysis
  processed_results <- rbindlist(lapply(benchmark_results, function(test) {
    fastapi_stats <- rbindlist(lapply(test$fastapi_results, function(r) {
      if (r$success) {
        data.table(
          test_id = test$test_id,
          api_type = "FastAPI",
          iteration = r$iteration,
          duration_ms = r$duration_ms,
          success = r$success,
          data_points = r$data_points %||% NA,
          response_size = r$response_size %||% NA,
          dataset_size = test$params$dataset_size,
          max_points = test$params$max_points,
          p_threshold = test$params$p_value_threshold
        )
      }
    }), fill = TRUE)
    
    r_stats <- rbindlist(lapply(test$r_results, function(r) {
      if (r$success) {
        data.table(
          test_id = test$test_id,
          api_type = "R",
          iteration = r$iteration,
          duration_ms = r$duration_ms,
          success = r$success,
          data_points = r$data_points %||% NA,
          response_size = r$response_size %||% NA,
          dataset_size = test$params$dataset_size,
          max_points = test$params$max_points,
          p_threshold = test$params$p_threshold
        )
      }
    }), fill = TRUE)
    
    rbind(fastapi_stats, r_stats, fill = TRUE)
  }), fill = TRUE)
  
  # Calculate summary statistics
  summary_stats <- processed_results[success == TRUE, .(
    mean_duration = mean(duration_ms, na.rm = TRUE),
    median_duration = median(duration_ms, na.rm = TRUE),
    min_duration = min(duration_ms, na.rm = TRUE),
    max_duration = max(duration_ms, na.rm = TRUE),
    sd_duration = sd(duration_ms, na.rm = TRUE),
    success_rate = mean(success, na.rm = TRUE),
    total_tests = .N
  ), by = .(api_type, dataset_size, max_points)]
  
  # Generate HTML report
  html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
    <title>R vs Python Performance Benchmark Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .summary { background-color: #f9f9f9; padding: 15px; margin: 20px 0; }
        .faster { color: green; font-weight: bold; }
        .slower { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>R vs Python Volcano Plot Performance Benchmark</h1>
    <div class="summary">
        <h2>Executive Summary</h2>
        <p>Generated on: %s</p>
        <p>Total benchmark tests: %d</p>
        <p>Dataset sizes tested: %s</p>
    </div>
    
    <h2>Performance Summary by Dataset Size</h2>
    %s
    
    <h2>Detailed Results</h2>
    %s
</body>
</html>',
    Sys.time(),
    length(benchmark_results),
    paste(unique(processed_results$dataset_size), collapse = ", "),
    knitr::kable(summary_stats, format = "html", table.attr = 'class="summary-table"'),
    knitr::kable(processed_results[1:min(100, nrow(processed_results))], format = "html")
  )
  
  writeLines(html_content, output_file)
  cat(sprintf("Performance report generated: %s\n", output_file))
  
  return(list(
    summary_stats = summary_stats,
    detailed_results = processed_results
  ))
}

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    cat("Usage: Rscript benchmark-framework.R [run|report] [options]\n")
    cat("  run    - Execute benchmark suite\n")
    cat("  report - Generate report from existing results\n")
    return()
  }
  
  command <- args[1]
  
  if (command == "run") {
    output_file <- if (length(args) > 1) args[2] else "benchmark_results.rds"
    results <- run_comprehensive_benchmark(output_file)
    
    # Generate immediate report
    report_data <- generate_performance_report(results)
    cat("Benchmark completed successfully!\n")
    
  } else if (command == "report") {
    input_file <- if (length(args) > 1) args[2] else "benchmark_results.rds"
    
    if (!file.exists(input_file)) {
      stop(paste("Results file not found:", input_file))
    }
    
    results <- readRDS(input_file)
    report_data <- generate_performance_report(results)
    cat("Report generated successfully!\n")
    
  } else {
    cat("Unknown command:", command, "\n")
  }
}

# Execute main function if script is run directly
if (!interactive()) {
  main()
}