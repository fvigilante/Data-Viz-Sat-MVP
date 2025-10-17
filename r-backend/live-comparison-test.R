#!/usr/bin/env Rscript

# Live Comparison Test Utility
# Tests R vs Python backends by making actual API calls and comparing responses

library(jsonlite)
library(httr)

# Load comparison utilities
source("r-backend/compare-outputs.R")
source("r-backend/statistical-validation.R")
source("r-backend/generate-comparison-report.R")

#' Perform live comparison between R and Python backends
#' @param r_base_url Base URL for R backend (e.g., "http://localhost:8001")
#' @param python_base_url Base URL for Python backend (e.g., "http://localhost:8000")
#' @param test_scenarios List of test scenarios with parameters
live_comparison_test <- function(r_base_url = "http://localhost:8001", 
                                python_base_url = "http://localhost:8000",
                                test_scenarios = NULL) {
  
  cat("=== Live R vs Python Backend Comparison ===\n")
  
  # Default test scenarios if none provided
  if (is.null(test_scenarios)) {
    test_scenarios <- list(
      small_dataset = list(
        dataset_size = 10000,
        max_points = 10000,
        p_value_threshold = 0.05,
        log_fc_min = -0.5,
        log_fc_max = 0.5
      ),
      large_dataset = list(
        dataset_size = 100000,
        max_points = 50000,
        p_value_threshold = 0.01,
        log_fc_min = -1.0,
        log_fc_max = 1.0
      ),
      filtered_search = list(
        dataset_size = 50000,
        max_points = 20000,
        p_value_threshold = 0.001,
        log_fc_min = -2.0,
        log_fc_max = 2.0,
        search_term = "protein"
      )
    )
  }
  
  results <- list()
  
  # Test each scenario
  for (scenario_name in names(test_scenarios)) {
    cat(paste("\nTesting scenario:", scenario_name, "\n"))
    
    scenario <- test_scenarios[[scenario_name]]
    
    # Test R backend
    cat("  Calling R backend...\n")
    r_result <- call_volcano_endpoint(r_base_url, scenario, "R")
    
    # Test Python backend  
    cat("  Calling Python backend...\n")
    python_result <- call_volcano_endpoint(python_base_url, scenario, "Python")
    
    if (r_result$success && python_result$success) {
      
      # Compare responses
      cat("  Comparing responses...\n")
      comparison <- compare_volcano_outputs(r_result$response, python_result$response)
      
      # Statistical validation
      cat("  Performing statistical validation...\n")
      stat_validation <- validate_data_generation_statistics(
        r_result$response$data, 
        python_result$response$data
      )
      
      # Generate report
      report_file <- paste0("live_comparison_", scenario_name, ".html")
      generate_comparison_report(
        r_result$response, 
        python_result$response, 
        report_file
      )
      
      results[[scenario_name]] <- list(
        scenario = scenario,
        r_response_time = r_result$response_time,
        python_response_time = python_result$response_time,
        comparison = comparison,
        statistical_validation = stat_validation,
        report_file = report_file,
        success = TRUE
      )
      
      cat(paste("  Report generated:", report_file, "\n"))
      
    } else {
      results[[scenario_name]] <- list(
        scenario = scenario,
        r_success = r_result$success,
        python_success = python_result$success,
        r_error = r_result$error,
        python_error = python_result$error,
        success = FALSE
      )
    }
  }
  
  # Generate summary
  generate_live_test_summary(results)
  
  return(results)
}

#' Call volcano plot endpoint
call_volcano_endpoint <- function(base_url, params, backend_name) {
  
  # Construct URL
  endpoint <- "/api/volcano-data"
  url <- paste0(base_url, endpoint)
  
  # Prepare query parameters
  query_params <- list(
    dataset_size = params$dataset_size,
    max_points = params$max_points,
    p_value_threshold = params$p_value_threshold,
    log_fc_min = params$log_fc_min,
    log_fc_max = params$log_fc_max
  )
  
  if (!is.null(params$search_term)) {
    query_params$search_term <- params$search_term
  }
  
  # Make request with timing
  start_time <- Sys.time()
  
  result <- tryCatch({
    response <- GET(url, query = query_params, timeout(30))
    
    if (status_code(response) == 200) {
      content_data <- content(response, "text", encoding = "UTF-8")
      parsed_data <- fromJSON(content_data)
      
      list(
        success = TRUE,
        response = parsed_data,
        status_code = status_code(response),
        error = NULL
      )
    } else {
      list(
        success = FALSE,
        response = NULL,
        status_code = status_code(response),
        error = paste("HTTP", status_code(response))
      )
    }
    
  }, error = function(e) {
    list(
      success = FALSE,
      response = NULL,
      status_code = NULL,
      error = e$message
    )
  })
  
  end_time <- Sys.time()
  result$response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  if (!result$success) {
    cat(paste("    Error calling", backend_name, "backend:", result$error, "\n"))
  } else {
    cat(paste("    ", backend_name, "response time:", round(result$response_time, 3), "seconds\n"))
  }
  
  return(result)
}

#' Test cache endpoints
test_cache_endpoints <- function(r_base_url = "http://localhost:8001", 
                                python_base_url = "http://localhost:8000") {
  
  cat("=== Testing Cache Endpoints ===\n")
  
  results <- list()
  
  # Test cache status
  cat("Testing cache status endpoints...\n")
  r_cache_status <- call_cache_endpoint(r_base_url, "/api/cache-status", "R")
  python_cache_status <- call_cache_endpoint(python_base_url, "/api/cache-status", "Python")
  
  results$cache_status <- list(
    r_success = r_cache_status$success,
    python_success = python_cache_status$success,
    r_response = r_cache_status$response,
    python_response = python_cache_status$response
  )
  
  # Test cache warming
  cat("Testing cache warming endpoints...\n")
  warm_params <- list(dataset_sizes = "10000,50000")
  
  r_warm <- call_cache_endpoint(r_base_url, "/api/warm-cache", "R", warm_params)
  python_warm <- call_cache_endpoint(python_base_url, "/api/warm-cache", "Python", warm_params)
  
  results$cache_warm <- list(
    r_success = r_warm$success,
    python_success = python_warm$success,
    r_response = r_warm$response,
    python_response = python_warm$response
  )
  
  return(results)
}

#' Call cache endpoint
call_cache_endpoint <- function(base_url, endpoint, backend_name, params = NULL) {
  
  url <- paste0(base_url, endpoint)
  
  result <- tryCatch({
    if (is.null(params)) {
      response <- GET(url, timeout(30))
    } else {
      response <- GET(url, query = params, timeout(30))
    }
    
    if (status_code(response) == 200) {
      content_data <- content(response, "text", encoding = "UTF-8")
      parsed_data <- fromJSON(content_data)
      
      list(
        success = TRUE,
        response = parsed_data,
        status_code = status_code(response)
      )
    } else {
      list(
        success = FALSE,
        response = NULL,
        status_code = status_code(response)
      )
    }
    
  }, error = function(e) {
    list(
      success = FALSE,
      response = NULL,
      error = e$message
    )
  })
  
  cat(paste("  ", backend_name, "cache endpoint:", if (result$success) "SUCCESS" else "FAILED", "\n"))
  
  return(result)
}

#' Generate live test summary
generate_live_test_summary <- function(results) {
  
  cat("\n=== LIVE TEST SUMMARY ===\n")
  
  total_tests <- length(results)
  successful_tests <- sum(sapply(results, function(x) x$success))
  
  cat(paste("Total scenarios tested:", total_tests, "\n"))
  cat(paste("Successful comparisons:", successful_tests, "\n"))
  cat(paste("Success rate:", round(successful_tests / total_tests * 100, 1), "%\n"))
  
  cat("\nScenario Results:\n")
  for (scenario_name in names(results)) {
    result <- results[[scenario_name]]
    
    if (result$success) {
      overall_match <- result$comparison$overall_match
      stat_valid <- result$statistical_validation$overall_valid
      
      status <- if (overall_match && stat_valid) "✓ PASS" else "✗ FAIL"
      
      cat(paste("  ", scenario_name, ":", status, "\n"))
      cat(paste("    R response time:", round(result$r_response_time, 3), "s\n"))
      cat(paste("    Python response time:", round(result$python_response_time, 3), "s\n"))
      cat(paste("    Output match:", if (overall_match) "✓" else "✗", "\n"))
      cat(paste("    Statistical validation:", if (stat_valid) "✓" else "✗", "\n"))
      
    } else {
      cat(paste("  ", scenario_name, ": ✗ FAILED\n"))
      if (!result$r_success) {
        cat(paste("    R backend error:", result$r_error, "\n"))
      }
      if (!result$python_success) {
        cat(paste("    Python backend error:", result$python_error, "\n"))
      }
    }
  }
  
  # Performance comparison
  if (successful_tests > 0) {
    cat("\nPerformance Summary:\n")
    
    r_times <- sapply(results[sapply(results, function(x) x$success)], function(x) x$r_response_time)
    python_times <- sapply(results[sapply(results, function(x) x$success)], function(x) x$python_response_time)
    
    cat(paste("  R backend avg response time:", round(mean(r_times), 3), "s\n"))
    cat(paste("  Python backend avg response time:", round(mean(python_times), 3), "s\n"))
    
    if (mean(r_times) < mean(python_times)) {
      cat("  R backend is faster on average\n")
    } else {
      cat("  Python backend is faster on average\n")
    }
  }
}

#' Run comprehensive live testing
run_comprehensive_live_test <- function() {
  
  cat("=== Comprehensive Live Backend Testing ===\n")
  
  # Check if backends are running
  cat("Checking backend availability...\n")
  
  r_available <- check_backend_availability("http://localhost:8001")
  python_available <- check_backend_availability("http://localhost:8000")
  
  if (!r_available) {
    cat("ERROR: R backend not available at http://localhost:8001\n")
    cat("Please start the R backend first.\n")
    return(FALSE)
  }
  
  if (!python_available) {
    cat("ERROR: Python backend not available at http://localhost:8000\n")
    cat("Please start the Python backend first.\n")
    return(FALSE)
  }
  
  cat("Both backends are available. Starting tests...\n")
  
  # Run volcano plot comparisons
  volcano_results <- live_comparison_test()
  
  # Run cache endpoint tests
  cache_results <- test_cache_endpoints()
  
  # Generate comprehensive report
  generate_comprehensive_live_report(volcano_results, cache_results)
  
  return(list(
    volcano_results = volcano_results,
    cache_results = cache_results
  ))
}

#' Check if backend is available
check_backend_availability <- function(base_url) {
  
  tryCatch({
    response <- GET(paste0(base_url, "/health"), timeout(5))
    return(status_code(response) == 200)
  }, error = function(e) {
    return(FALSE)
  })
}

#' Generate comprehensive live report
generate_comprehensive_live_report <- function(volcano_results, cache_results) {
  
  report_file <- "comprehensive_live_test_report.html"
  
  # Create detailed HTML report combining all results
  html_content <- paste0('
<!DOCTYPE html>
<html>
<head>
    <title>Comprehensive Live Backend Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Comprehensive Live Backend Test Report</h1>
    <p>Generated on: ', Sys.time(), '</p>
    
    <div class="section">
        <h2>Test Summary</h2>
        <p>This report contains results from live testing of R and Python volcano plot backends.</p>
    </div>
    
    <div class="section">
        <h2>Volcano Plot Comparison Results</h2>
        <table>
            <tr><th>Scenario</th><th>Status</th><th>R Time (s)</th><th>Python Time (s)</th><th>Output Match</th></tr>
  ')
  
  for (scenario_name in names(volcano_results)) {
    result <- volcano_results[[scenario_name]]
    if (result$success) {
      status_class <- if (result$comparison$overall_match) "success" else "error"
      status_text <- if (result$comparison$overall_match) "✓ PASS" else "✗ FAIL"
      
      html_content <- paste0(html_content, '
            <tr>
                <td>', scenario_name, '</td>
                <td class="', status_class, '">', status_text, '</td>
                <td>', round(result$r_response_time, 3), '</td>
                <td>', round(result$python_response_time, 3), '</td>
                <td class="', status_class, '">', if (result$comparison$overall_match) "✓" else "✗", '</td>
            </tr>
      ')
    }
  }
  
  html_content <- paste0(html_content, '
        </table>
    </div>
</body>
</html>
  ')
  
  writeLines(html_content, report_file)
  cat(paste("Comprehensive report generated:", report_file, "\n"))
}

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) > 0 && args[1] == "--comprehensive") {
    run_comprehensive_live_test()
  } else if (length(args) > 0 && args[1] == "--cache-only") {
    test_cache_endpoints()
  } else {
    # Default: run volcano plot comparisons
    live_comparison_test()
  }
}

# Run main if script is executed directly
if (!interactive()) {
  main()
}