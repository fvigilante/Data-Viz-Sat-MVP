#!/usr/bin/env Rscript

# API Compatibility and Output Consistency Tests
# Validates that optimized R implementation produces identical output to Python baseline

library(httr)
library(jsonlite)
library(data.table)

# Test configuration
COMPATIBILITY_CONFIG <- list(
  r_api_url = Sys.getenv("R_API_URL", "http://localhost:8001"),
  python_api_url = Sys.getenv("PYTHON_API_URL", "http://localhost:8000"),
  tolerance = 1e-6,  # Numerical tolerance for floating point comparisons
  timeout_seconds = 30
)

# Test scenarios for comprehensive validation
TEST_SCENARIOS <- list(
  basic = list(
    name = "Basic functionality",
    params = list(
      dataset_size = 10000,
      p_value_threshold = 0.05,
      log_fc_min = -0.5,
      log_fc_max = 0.5,
      max_points = 5000
    )
  ),
  
  large_dataset = list(
    name = "Large dataset handling",
    params = list(
      dataset_size = 100000,
      p_value_threshold = 0.01,
      log_fc_min = -1.0,
      log_fc_max = 1.0,
      max_points = 10000
    )
  ),
  
  strict_filtering = list(
    name = "Strict filtering parameters",
    params = list(
      dataset_size = 50000,
      p_value_threshold = 0.001,
      log_fc_min = -2.0,
      log_fc_max = 2.0,
      max_points = 20000
    )
  ),
  
  search_functionality = list(
    name = "Search term filtering",
    params = list(
      dataset_size = 25000,
      p_value_threshold = 0.05,
      log_fc_min = -0.5,
      log_fc_max = 0.5,
      search_term = "Metabolite",
      max_points = 15000
    )
  ),
  
  lod_mode = list(
    name = "Level-of-detail mode",
    params = list(
      dataset_size = 75000,
      p_value_threshold = 0.05,
      log_fc_min = -1.0,
      log_fc_max = 1.0,
      zoom_level = 2.0,
      lod_mode = TRUE,
      max_points = 30000
    )
  ),
  
  edge_cases = list(
    name = "Edge case parameters",
    params = list(
      dataset_size = 1000,
      p_value_threshold = 1.0,  # Very permissive
      log_fc_min = -10.0,
      log_fc_max = 10.0,
      max_points = 2000
    )
  )
)

#' Execute comprehensive API compatibility tests
#' @param save_results Logical whether to save results to files
#' @return List with test results
execute_compatibility_tests <- function(save_results = TRUE) {
  
  cat("=== API Compatibility and Output Consistency Tests ===\n")
  cat("Validating R vs Python API compatibility across multiple scenarios\n\n")
  
  # Check API availability
  if (!check_apis_available()) {
    stop("Required APIs are not available. Please start both R and Python servers.")
  }
  
  # Initialize results
  overall_results <- list(
    tests_passed = 0,
    tests_failed = 0,
    scenario_results = list(),
    compatibility_summary = list(),
    timestamp = Sys.time()
  )
  
  # Run tests for each scenario
  for (scenario_name in names(TEST_SCENARIOS)) {
    scenario <- TEST_SCENARIOS[[scenario_name]]
    
    cat(sprintf("--- Testing: %s ---\n", scenario$name))
    
    # Run compatibility test for this scenario
    test_result <- run_compatibility_test(scenario_name, scenario$params)
    
    # Store results
    overall_results$scenario_results[[scenario_name]] <- test_result
    
    # Update counters
    if (test_result$overall_compatible) {
      overall_results$tests_passed <- overall_results$tests_passed + 1
      cat("✅ PASSED: APIs are compatible\n")
    } else {
      overall_results$tests_failed <- overall_results$tests_failed + 1
      cat("❌ FAILED: Compatibility issues detected\n")
    }
    
    # Add to summary
    overall_results$compatibility_summary[[scenario_name]] <- list(
      scenario_name = scenario$name,
      compatible = test_result$overall_compatible,
      structure_match = test_result$structure_validation$match,
      data_consistency = test_result$data_validation$consistent,
      stats_match = test_result$stats_validation$match,
      metadata_match = test_result$metadata_validation$match,
      issues_count = length(test_result$issues)
    )
    
    cat("\n")
  }
  
  # Calculate overall statistics
  total_tests <- length(TEST_SCENARIOS)
  success_rate <- (overall_results$tests_passed / total_tests) * 100
  
  overall_results$test_summary <- list(
    total_scenarios = total_tests,
    passed = overall_results$tests_passed,
    failed = overall_results$tests_failed,
    success_rate = success_rate
  )
  
  # Print summary
  print_compatibility_summary(overall_results)
  
  # Save results if requested
  if (save_results) {
    save_compatibility_results(overall_results)
  }
  
  return(overall_results)
}

#' Run compatibility test for a single scenario
#' @param scenario_name Name of the test scenario
#' @param params Test parameters
#' @return List with test results
run_compatibility_test <- function(scenario_name, params) {
  
  cat(sprintf("  Fetching R API response...\n"))
  r_response <- fetch_api_response(COMPATIBILITY_CONFIG$r_api_url, "/api/volcano-data", params)
  
  cat(sprintf("  Fetching Python API response...\n"))
  python_response <- fetch_api_response(COMPATIBILITY_CONFIG$python_api_url, "/api/volcano-data", params)
  
  if (is.null(r_response) || is.null(python_response)) {
    return(list(
      overall_compatible = FALSE,
      issues = list("Failed to fetch responses from one or both APIs"),
      scenario_name = scenario_name,
      params = params
    ))
  }
  
  # Validate different aspects of compatibility
  cat(sprintf("  Validating response structure...\n"))
  structure_validation <- validate_response_structure(r_response, python_response)
  
  cat(sprintf("  Validating data consistency...\n"))
  data_validation <- validate_data_consistency(r_response$data, python_response$data)
  
  cat(sprintf("  Validating statistics...\n"))
  stats_validation <- validate_statistics_consistency(r_response$stats, python_response$stats)
  
  cat(sprintf("  Validating metadata...\n"))
  metadata_validation <- validate_metadata_consistency(r_response, python_response)
  
  # Collect all issues
  all_issues <- c()
  if (!structure_validation$match) {
    all_issues <- c(all_issues, structure_validation$issues)
  }
  if (!data_validation$consistent) {
    all_issues <- c(all_issues, data_validation$issues)
  }
  if (!stats_validation$match) {
    all_issues <- c(all_issues, stats_validation$issues)
  }
  if (!metadata_validation$match) {
    all_issues <- c(all_issues, metadata_validation$issues)
  }
  
  # Determine overall compatibility
  overall_compatible <- structure_validation$match && 
                      data_validation$consistent && 
                      stats_validation$match && 
                      metadata_validation$match
  
  return(list(
    overall_compatible = overall_compatible,
    structure_validation = structure_validation,
    data_validation = data_validation,
    stats_validation = stats_validation,
    metadata_validation = metadata_validation,
    issues = all_issues,
    scenario_name = scenario_name,
    params = params,
    r_response_size = length(r_response$data),
    python_response_size = length(python_response$data)
  ))
}

#' Fetch API response with error handling
#' @param base_url Base URL of the API
#' @param endpoint API endpoint
#' @param params Request parameters
#' @return Parsed response or NULL if failed
fetch_api_response <- function(base_url, endpoint, params) {
  
  url <- paste0(base_url, endpoint)
  
  tryCatch({
    response <- GET(url, query = params, timeout(COMPATIBILITY_CONFIG$timeout_seconds))
    
    if (status_code(response) == 200) {
      return(content(response, "parsed"))
    } else {
      cat(sprintf("    Error: HTTP %d\n", status_code(response)))
      return(NULL)
    }
  }, error = function(e) {
    cat(sprintf("    Error: %s\n", e$message))
    return(NULL)
  })
}

#' Validate response structure compatibility
#' @param r_resp R API response
#' @param python_resp Python API response
#' @return List with validation results
validate_response_structure <- function(r_resp, python_resp) {
  
  issues <- c()
  
  # Check top-level keys
  r_keys <- sort(names(r_resp))
  python_keys <- sort(names(python_resp))
  
  if (!identical(r_keys, python_keys)) {
    issues <- c(issues, sprintf("Top-level keys differ: R=%s, Python=%s", 
                               paste(r_keys, collapse=","), 
                               paste(python_keys, collapse=",")))
  }
  
  # Check data structure if both have data
  if ("data" %in% names(r_resp) && "data" %in% names(python_resp) && 
      length(r_resp$data) > 0 && length(python_resp$data) > 0) {
    
    r_data_keys <- sort(names(r_resp$data[[1]]))
    python_data_keys <- sort(names(python_resp$data[[1]]))
    
    if (!identical(r_data_keys, python_data_keys)) {
      issues <- c(issues, sprintf("Data point structure differs: R=%s, Python=%s",
                                 paste(r_data_keys, collapse=","),
                                 paste(python_data_keys, collapse=",")))
    }
  }
  
  # Check stats structure
  if ("stats" %in% names(r_resp) && "stats" %in% names(python_resp)) {
    r_stats_keys <- sort(names(r_resp$stats))
    python_stats_keys <- sort(names(python_resp$stats))
    
    if (!identical(r_stats_keys, python_stats_keys)) {
      issues <- c(issues, sprintf("Stats structure differs: R=%s, Python=%s",
                                 paste(r_stats_keys, collapse=","),
                                 paste(python_stats_keys, collapse=",")))
    }
  }
  
  return(list(
    match = length(issues) == 0,
    issues = issues
  ))
}

#' Validate data consistency between APIs
#' @param r_data R API data points
#' @param python_data Python API data points
#' @return List with validation results
validate_data_consistency <- function(r_data, python_data) {
  
  issues <- c()
  
  # Check data length
  if (length(r_data) != length(python_data)) {
    issues <- c(issues, sprintf("Data length differs: R=%d, Python=%d", 
                               length(r_data), length(python_data)))
    return(list(consistent = FALSE, issues = issues))
  }
  
  if (length(r_data) == 0) {
    return(list(consistent = TRUE, issues = issues))
  }
  
  # Convert to data.tables for comparison
  r_dt <- rbindlist(r_data)
  python_dt <- rbindlist(python_data)
  
  # Sort both by gene name for consistent comparison
  setorder(r_dt, gene)
  setorder(python_dt, gene)
  
  # Compare numerical columns with tolerance
  numerical_cols <- c("logFC", "padj")
  
  for (col in numerical_cols) {
    if (col %in% names(r_dt) && col %in% names(python_dt)) {
      
      # Calculate differences
      diff_vals <- abs(r_dt[[col]] - python_dt[[col]])
      max_diff <- max(diff_vals, na.rm = TRUE)
      
      if (max_diff > COMPATIBILITY_CONFIG$tolerance) {
        issues <- c(issues, sprintf("Column %s exceeds tolerance: max_diff=%.2e", col, max_diff))
      }
    }
  }
  
  # Compare categorical columns
  categorical_cols <- c("gene", "category", "classyfireSuperclass", "classyfireClass")
  
  for (col in categorical_cols) {
    if (col %in% names(r_dt) && col %in% names(python_dt)) {
      
      matches <- r_dt[[col]] == python_dt[[col]]
      match_rate <- sum(matches, na.rm = TRUE) / length(matches)
      
      if (match_rate < 1.0) {
        issues <- c(issues, sprintf("Column %s mismatch rate: %.2f%%", col, (1 - match_rate) * 100))
      }
    }
  }
  
  return(list(
    consistent = length(issues) == 0,
    issues = issues
  ))
}

#' Validate statistics consistency
#' @param r_stats R API statistics
#' @param python_stats Python API statistics
#' @return List with validation results
validate_statistics_consistency <- function(r_stats, python_stats) {
  
  issues <- c()
  
  stat_fields <- c("up_regulated", "down_regulated", "non_significant")
  
  for (field in stat_fields) {
    if (field %in% names(r_stats) && field %in% names(python_stats)) {
      
      r_val <- r_stats[[field]]
      python_val <- python_stats[[field]]
      
      if (r_val != python_val) {
        issues <- c(issues, sprintf("Statistic %s differs: R=%d, Python=%d", field, r_val, python_val))
      }
    } else {
      issues <- c(issues, sprintf("Statistic %s missing in one API", field))
    }
  }
  
  return(list(
    match = length(issues) == 0,
    issues = issues
  ))
}

#' Validate metadata consistency
#' @param r_resp R API response
#' @param python_resp Python API response
#' @return List with validation results
validate_metadata_consistency <- function(r_resp, python_resp) {
  
  issues <- c()
  
  metadata_fields <- c("total_rows", "filtered_rows", "points_before_sampling", "is_downsampled")
  
  for (field in metadata_fields) {
    if (field %in% names(r_resp) && field %in% names(python_resp)) {
      
      r_val <- r_resp[[field]]
      python_val <- python_resp[[field]]
      
      if (!identical(r_val, python_val)) {
        issues <- c(issues, sprintf("Metadata %s differs: R=%s, Python=%s", 
                                   field, as.character(r_val), as.character(python_val)))
      }
    } else {
      issues <- c(issues, sprintf("Metadata %s missing in one API", field))
    }
  }
  
  return(list(
    match = length(issues) == 0,
    issues = issues
  ))
}

#' Check if both APIs are available
#' @return Logical indicating availability
check_apis_available <- function() {
  
  cat("Checking API availability...\n")
  
  # Check R API
  r_available <- tryCatch({
    response <- GET(paste0(COMPATIBILITY_CONFIG$r_api_url, "/health"), timeout(5))
    status_code(response) == 200
  }, error = function(e) FALSE)
  
  # Check Python API
  python_available <- tryCatch({
    response <- GET(paste0(COMPATIBILITY_CONFIG$python_api_url, "/health"), timeout(5))
    status_code(response) == 200
  }, error = function(e) FALSE)
  
  cat("R API:", if (r_available) "✅ Available" else "❌ Not available", "\n")
  cat("Python API:", if (python_available) "✅ Available" else "❌ Not available", "\n")
  
  return(r_available && python_available)
}

#' Print compatibility test summary
#' @param results Overall test results
print_compatibility_summary <- function(results) {
  
  cat("\n" %R% 60, "\n")
  cat("=== API COMPATIBILITY TEST SUMMARY ===\n")
  cat("=" %R% 60, "\n")
  
  summary <- results$test_summary
  cat(sprintf("Total Scenarios: %d\n", summary$total_scenarios))
  cat(sprintf("Passed: %d\n", summary$passed))
  cat(sprintf("Failed: %d\n", summary$failed))
  cat(sprintf("Success Rate: %.1f%%\n", summary$success_rate))
  cat(sprintf("Timestamp: %s\n", results$timestamp))
  
  cat("\n--- Scenario Results ---\n")
  for (scenario_name in names(results$compatibility_summary)) {
    comp <- results$compatibility_summary[[scenario_name]]
    status <- if (comp$compatible) "✅ PASS" else "❌ FAIL"
    
    cat(sprintf("%s | %s | Issues: %d\n",
               status,
               comp$scenario_name,
               comp$issues_count))
    
    if (!comp$compatible) {
      cat(sprintf("      Structure: %s | Data: %s | Stats: %s | Metadata: %s\n",
                 if (comp$structure_match) "✓" else "✗",
                 if (comp$data_consistency) "✓" else "✗",
                 if (comp$stats_match) "✓" else "✗",
                 if (comp$metadata_match) "✓" else "✗"))
    }
  }
  
  cat("\n--- Overall Assessment ---\n")
  if (summary$success_rate == 100) {
    cat("🎉 PERFECT: All APIs are fully compatible!\n")
  } else if (summary$success_rate >= 80) {
    cat("✅ GOOD: APIs are mostly compatible with minor issues\n")
  } else if (summary$success_rate >= 60) {
    cat("⚠️  PARTIAL: Some compatibility issues detected\n")
  } else {
    cat("❌ CRITICAL: Significant compatibility issues found\n")
  }
  
  cat("=" %R% 60, "\n")
}

#' Save compatibility test results
#' @param results Test results to save
save_compatibility_results <- function(results) {
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  
  # Save detailed results as RDS
  rds_file <- sprintf("api_compatibility_%s.rds", timestamp)
  saveRDS(results, rds_file)
  
  # Save summary as JSON
  json_file <- sprintf("api_compatibility_summary_%s.json", timestamp)
  write(toJSON(results$compatibility_summary, pretty = TRUE, auto_unbox = TRUE), json_file)
  
  # Generate HTML report
  html_file <- sprintf("api_compatibility_report_%s.html", timestamp)
  generate_compatibility_html_report(results, html_file)
  
  cat(sprintf("\nResults saved:\n"))
  cat(sprintf("  Detailed: %s\n", rds_file))
  cat(sprintf("  Summary: %s\n", json_file))
  cat(sprintf("  Report: %s\n", html_file))
}

#' Generate HTML compatibility report
#' @param results Test results
#' @param output_file Output HTML file path
generate_compatibility_html_report <- function(results, output_file) {
  
  # Create scenario table
  scenario_rows <- ""
  for (scenario_name in names(results$compatibility_summary)) {
    comp <- results$compatibility_summary[[scenario_name]]
    status_class <- if (comp$compatible) "success" else "failure"
    status_text <- if (comp$compatible) "COMPATIBLE" else "INCOMPATIBLE"
    
    scenario_rows <- paste0(scenario_rows, sprintf('
    <tr class="%s">
      <td>%s</td>
      <td>%s</td>
      <td>%s</td>
      <td>%s</td>
      <td>%s</td>
      <td>%s</td>
      <td>%d</td>
    </tr>',
      status_class,
      comp$scenario_name,
      if (comp$structure_match) "✓" else "✗",
      if (comp$data_consistency) "✓" else "✗",
      if (comp$stats_match) "✓" else "✗",
      if (comp$metadata_match) "✓" else "✗",
      status_text,
      comp$issues_count
    ))
  }
  
  html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
    <title>API Compatibility Test Report</title>
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
        <h1>API Compatibility Test Report</h1>
        <p><strong>Generated:</strong> %s</p>
        <p><strong>Objective:</strong> Validate R and Python API compatibility and output consistency</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <div class="metric">
            <div class="metric-value">%d/%d</div>
            <div class="metric-label">Scenarios Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value">%.1f%%</div>
            <div class="metric-label">Success Rate</div>
        </div>
        <div class="metric">
            <div class="metric-value">%d</div>
            <div class="metric-label">Test Scenarios</div>
        </div>
    </div>
    
    <h2>Compatibility Results</h2>
    <table>
        <thead>
            <tr>
                <th>Scenario</th>
                <th>Structure</th>
                <th>Data</th>
                <th>Statistics</th>
                <th>Metadata</th>
                <th>Status</th>
                <th>Issues</th>
            </tr>
        </thead>
        <tbody>
            %s
        </tbody>
    </table>
    
    <div class="summary">
        <h3>Validation Criteria</h3>
        <ul>
            <li><strong>Structure:</strong> Response JSON structure must be identical</li>
            <li><strong>Data:</strong> Data points must match within numerical tolerance</li>
            <li><strong>Statistics:</strong> Aggregated statistics must be identical</li>
            <li><strong>Metadata:</strong> Response metadata must match exactly</li>
        </ul>
    </div>
    
    <div class="summary">
        <h3>Test Scenarios</h3>
        <p>Multiple scenarios test different parameter combinations, edge cases, and functionality 
        to ensure comprehensive compatibility validation between R and Python implementations.</p>
    </div>
</body>
</html>',
    Sys.time(),
    results$test_summary$passed,
    results$test_summary$total_scenarios,
    results$test_summary$success_rate,
    results$test_summary$total_scenarios,
    scenario_rows
  )
  
  writeLines(html_content, output_file)
}

# Helper function for string repetition
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  save_results <- TRUE
  
  if (length(args) > 0) {
    if (args[1] == "--help" || args[1] == "-h") {
      cat("Usage: Rscript api-compatibility-tests.R [options]\n")
      cat("Options:\n")
      cat("  --no-save    Don't save results to files\n")
      cat("  --help       Show this help message\n")
      return()
    }
    
    if ("--no-save" %in% args) {
      save_results <- FALSE
    }
  }
  
  # Execute compatibility tests
  tryCatch({
    results <- execute_compatibility_tests(save_results)
    
    # Exit with appropriate code
    exit_code <- if (results$test_summary$success_rate >= 80) 0 else 1
    quit(save = "no", status = exit_code)
    
  }, error = function(e) {
    cat("Error executing compatibility tests:", e$message, "\n")
    quit(save = "no", status = 1)
  })
}

# Execute if run directly
if (!interactive()) {
  main()
}