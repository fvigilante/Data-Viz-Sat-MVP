#!/usr/bin/env Rscript

# Memory and CPU Profiling Utilities for R vs Python Comparison
# Provides detailed resource usage monitoring during benchmark execution

library(httr)
library(jsonlite)
library(data.table)

# Memory profiling configuration
PROFILING_CONFIG <- list(
  sampling_interval_ms = 100,  # Sample every 100ms
  max_duration_seconds = 300,  # Maximum 5 minutes per test
  memory_threshold_mb = 1000   # Alert if memory usage exceeds 1GB
)

# Cross-platform memory monitoring
get_memory_usage <- function() {
  if (Sys.info()["sysname"] == "Windows") {
    # Windows memory monitoring
    tryCatch({
      # Get process memory info
      pid <- Sys.getpid()
      cmd <- sprintf('wmic process where "ProcessId=%d" get WorkingSetSize /format:csv', pid)
      result <- system(cmd, intern = TRUE)
      
      # Parse result
      lines <- result[grepl("^[^,]*,[0-9]", result)]
      if (length(lines) > 0) {
        memory_bytes <- as.numeric(strsplit(lines[1], ",")[[1]][2])
        memory_mb <- memory_bytes / (1024 * 1024)
      } else {
        memory_mb <- NA
      }
      
      # Get system memory
      sys_cmd <- 'wmic OS get TotalVisibleMemorySize,FreePhysicalMemory /format:csv'
      sys_result <- system(sys_cmd, intern = TRUE)
      sys_lines <- sys_result[grepl("^[^,]*,[0-9]", sys_result)]
      
      if (length(sys_lines) > 0) {
        parts <- strsplit(sys_lines[1], ",")[[1]]
        free_kb <- as.numeric(parts[2])
        total_kb <- as.numeric(parts[3])
        system_memory_usage_percent <- ((total_kb - free_kb) / total_kb) * 100
      } else {
        system_memory_usage_percent <- NA
      }
      
      list(
        process_memory_mb = memory_mb,
        system_memory_usage_percent = system_memory_usage_percent,
        timestamp = Sys.time()
      )
    }, error = function(e) {
      list(
        process_memory_mb = NA,
        system_memory_usage_percent = NA,
        timestamp = Sys.time(),
        error = e$message
      )
    })
  } else {
    # Unix-like systems (Linux, macOS)
    tryCatch({
      # Get process memory from /proc/self/status (Linux) or ps (macOS)
      if (file.exists("/proc/self/status")) {
        # Linux
        status_lines <- readLines("/proc/self/status")
        vmrss_line <- grep("^VmRSS:", status_lines, value = TRUE)
        if (length(vmrss_line) > 0) {
          memory_kb <- as.numeric(gsub(".*?([0-9]+).*", "\\1", vmrss_line[1]))
          memory_mb <- memory_kb / 1024
        } else {
          memory_mb <- NA
        }
      } else {
        # macOS or other Unix
        pid <- Sys.getpid()
        ps_result <- system(sprintf("ps -o rss= -p %d", pid), intern = TRUE)
        if (length(ps_result) > 0) {
          memory_kb <- as.numeric(trimws(ps_result[1]))
          memory_mb <- memory_kb / 1024
        } else {
          memory_mb <- NA
        }
      }
      
      # System memory usage (simplified)
      system_memory_usage_percent <- NA
      
      list(
        process_memory_mb = memory_mb,
        system_memory_usage_percent = system_memory_usage_percent,
        timestamp = Sys.time()
      )
    }, error = function(e) {
      list(
        process_memory_mb = NA,
        system_memory_usage_percent = NA,
        timestamp = Sys.time(),
        error = e$message
      )
    })
  }
}

# CPU usage monitoring (simplified)
get_cpu_usage <- function() {
  # This is a simplified CPU monitoring - for more accurate results,
  # consider using system-specific tools or the 'ps' package
  tryCatch({
    if (Sys.info()["sysname"] == "Windows") {
      # Windows CPU monitoring (basic)
      pid <- Sys.getpid()
      cmd <- sprintf('wmic process where "ProcessId=%d" get PageFileUsage,WorkingSetSize /format:csv', pid)
      result <- system(cmd, intern = TRUE)
      
      # For now, return placeholder - real CPU monitoring requires more complex implementation
      list(
        cpu_percent = NA,
        timestamp = Sys.time()
      )
    } else {
      # Unix-like systems
      list(
        cpu_percent = NA,
        timestamp = Sys.time()
      )
    }
  }, error = function(e) {
    list(
      cpu_percent = NA,
      timestamp = Sys.time(),
      error = e$message
    )
  })
}

# Profile a single API call with resource monitoring
profile_api_call <- function(api_type, endpoint, params, profile_duration = 30) {
  cat(sprintf("Profiling %s API call...\n", api_type))
  
  # Prepare monitoring
  monitoring_data <- list()
  start_time <- Sys.time()
  
  # Start background monitoring
  monitoring_active <- TRUE
  
  # Make the API call in a separate thread (simulated with tryCatch)
  api_result <- tryCatch({
    url <- if (api_type == "fastapi") {
      paste0(Sys.getenv("FASTAPI_URL", "http://localhost:8000"), endpoint)
    } else {
      paste0(Sys.getenv("R_API_URL", "http://localhost:8001"), endpoint)
    }
    
    call_start <- Sys.time()
    
    # Monitor resources during the call
    monitor_count <- 1
    while (TRUE) {
      # Take resource snapshot
      memory_info <- get_memory_usage()
      cpu_info <- get_cpu_usage()
      
      monitoring_data[[monitor_count]] <- list(
        timestamp = Sys.time(),
        elapsed_seconds = as.numeric(difftime(Sys.time(), call_start, units = "secs")),
        memory_mb = memory_info$process_memory_mb,
        system_memory_percent = memory_info$system_memory_usage_percent,
        cpu_percent = cpu_info$cpu_percent
      )
      
      monitor_count <- monitor_count + 1
      
      # Check if we should continue monitoring
      if (as.numeric(difftime(Sys.time(), call_start, units = "secs")) > profile_duration) {
        break
      }
      
      # Make the actual API call (only once, at the beginning)
      if (monitor_count == 2) {
        response <- GET(url, query = params)
        api_response_time <- Sys.time()
        
        if (status_code(response) == 200) {
          response_data <- content(response, "parsed")
          api_success <- TRUE
        } else {
          api_success <- FALSE
          response_data <- NULL
        }
      }
      
      # Small delay between samples
      Sys.sleep(PROFILING_CONFIG$sampling_interval_ms / 1000)
    }
    
    list(
      success = api_success,
      response_data = response_data,
      response_time = if (exists("api_response_time")) api_response_time else NA
    )
    
  }, error = function(e) {
    list(
      success = FALSE,
      error = e$message,
      response_time = NA
    )
  })
  
  end_time <- Sys.time()
  
  # Process monitoring data
  monitoring_dt <- rbindlist(monitoring_data, fill = TRUE)
  
  # Calculate statistics
  profile_stats <- list(
    api_type = api_type,
    endpoint = endpoint,
    params = params,
    total_duration_seconds = as.numeric(difftime(end_time, start_time, units = "secs")),
    api_success = api_result$success,
    api_response_time = api_result$response_time,
    monitoring_samples = nrow(monitoring_dt),
    memory_stats = if (nrow(monitoring_dt) > 0) {
      list(
        peak_memory_mb = max(monitoring_dt$memory_mb, na.rm = TRUE),
        avg_memory_mb = mean(monitoring_dt$memory_mb, na.rm = TRUE),
        memory_growth_mb = if (sum(!is.na(monitoring_dt$memory_mb)) > 1) {
          max(monitoring_dt$memory_mb, na.rm = TRUE) - min(monitoring_dt$memory_mb, na.rm = TRUE)
        } else NA
      )
    } else NULL,
    monitoring_data = monitoring_dt
  )
  
  profile_stats
}

# Run memory profiling comparison
run_memory_comparison <- function(dataset_sizes = c(10000, 100000, 500000)) {
  cat("Running memory usage comparison between R and Python APIs...\n")
  cat("=" %R% 60, "\n")
  
  results <- list()
  
  for (i in seq_along(dataset_sizes)) {
    dataset_size <- dataset_sizes[i]
    cat(sprintf("Testing dataset size: %s\n", format(dataset_size, big.mark = ",")))
    
    params <- list(
      dataset_size = dataset_size,
      max_points = min(50000, dataset_size),
      p_value_threshold = 0.05,
      log_fc_min = -1.0,
      log_fc_max = 1.0
    )
    
    # Profile FastAPI
    cat("  Profiling FastAPI...")
    fastapi_profile <- profile_api_call("fastapi", "/api/volcano-data", params, 15)
    cat(" Done\n")
    
    # Small delay between tests
    Sys.sleep(2)
    
    # Profile R API
    cat("  Profiling R API...")
    r_profile <- profile_api_call("r", "/api/volcano-data", params, 15)
    cat(" Done\n")
    
    results[[i]] <- list(
      dataset_size = dataset_size,
      fastapi_profile = fastapi_profile,
      r_profile = r_profile,
      timestamp = Sys.time()
    )
    
    # Display immediate results
    if (!is.null(fastapi_profile$memory_stats) && !is.null(r_profile$memory_stats)) {
      cat(sprintf("  FastAPI peak memory: %.1f MB\n", fastapi_profile$memory_stats$peak_memory_mb))
      cat(sprintf("  R API peak memory:   %.1f MB\n", r_profile$memory_stats$peak_memory_mb))
      
      memory_ratio <- r_profile$memory_stats$peak_memory_mb / fastapi_profile$memory_stats$peak_memory_mb
      cat(sprintf("  Memory ratio (R/Python): %.2fx\n", memory_ratio))
    }
    cat("\n")
  }
  
  # Save detailed results
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  output_file <- paste0("memory_profile_", timestamp, ".rds")
  saveRDS(results, output_file)
  cat(sprintf("Memory profiling results saved to: %s\n", output_file))
  
  results
}

# Generate memory usage report
generate_memory_report <- function(profile_results, output_file = "memory_report.html") {
  cat("Generating memory usage report...\n")
  
  # Extract summary statistics
  summary_data <- rbindlist(lapply(profile_results, function(result) {
    fastapi_mem <- result$fastapi_profile$memory_stats
    r_mem <- result$r_profile$memory_stats
    
    if (!is.null(fastapi_mem) && !is.null(r_mem)) {
      data.table(
        dataset_size = result$dataset_size,
        fastapi_peak_mb = fastapi_mem$peak_memory_mb,
        fastapi_avg_mb = fastapi_mem$avg_memory_mb,
        r_peak_mb = r_mem$peak_memory_mb,
        r_avg_mb = r_mem$avg_memory_mb,
        memory_ratio = r_mem$peak_memory_mb / fastapi_mem$peak_memory_mb,
        fastapi_success = result$fastapi_profile$api_success,
        r_success = result$r_profile$api_success
      )
    }
  }), fill = TRUE)
  
  # Generate HTML report
  html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
    <title>Memory Usage Comparison Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: right; }
        th { background-color: #f2f2f2; text-align: center; }
        .summary { background-color: #f9f9f9; padding: 15px; margin: 20px 0; }
        .efficient { color: green; font-weight: bold; }
        .inefficient { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Memory Usage Comparison: R vs Python</h1>
    <div class="summary">
        <h2>Summary</h2>
        <p>Generated on: %s</p>
        <p>Tests completed: %d</p>
        <p>Average memory ratio (R/Python): %.2fx</p>
    </div>
    
    <h2>Memory Usage by Dataset Size</h2>
    %s
</body>
</html>',
    Sys.time(),
    nrow(summary_data),
    if (nrow(summary_data) > 0) mean(summary_data$memory_ratio, na.rm = TRUE) else 0,
    if (nrow(summary_data) > 0) knitr::kable(summary_data, format = "html") else "No data available"
  )
  
  writeLines(html_content, output_file)
  cat(sprintf("Memory report generated: %s\n", output_file))
  
  summary_data
}

# Helper function for string repetition
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    cat("Usage: Rscript memory-profiler.R [profile|report] [options]\n")
    cat("  profile - Run memory profiling comparison\n")
    cat("  report  - Generate report from existing results\n")
    return()
  }
  
  command <- args[1]
  
  if (command == "profile") {
    results <- run_memory_comparison()
    report_data <- generate_memory_report(results)
    cat("Memory profiling completed!\n")
    
  } else if (command == "report") {
    input_file <- if (length(args) > 1) args[2] else {
      # Find most recent memory profile file
      files <- list.files(pattern = "memory_profile_.*\\.rds")
      if (length(files) > 0) {
        files[order(file.mtime(files), decreasing = TRUE)][1]
      } else {
        stop("No memory profile results found")
      }
    }
    
    if (!file.exists(input_file)) {
      stop(paste("Results file not found:", input_file))
    }
    
    results <- readRDS(input_file)
    report_data <- generate_memory_report(results)
    cat("Memory report generated!\n")
    
  } else {
    cat("Unknown command:", command, "\n")
  }
}

# Execute if run directly
if (!interactive()) {
  main()
}