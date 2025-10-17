#!/usr/bin/env Rscript

# Automated Comparison Report Generator
# Generates comprehensive HTML reports comparing R vs Python outputs

library(jsonlite)
library(data.table)

# Load comparison utilities
source("r-backend/compare-outputs.R")
source("r-backend/statistical-validation.R")

#' Generate comprehensive comparison report
#' @param r_response R backend response
#' @param python_response Python backend response
#' @param output_file Output HTML file path
#' @param tolerance Numerical tolerance for comparisons
generate_comparison_report <- function(r_response, python_response, 
                                     output_file = "comparison_report.html", 
                                     tolerance = 1e-6) {
  
  cat("Generating comprehensive comparison report...\n")
  
  # Perform all comparisons
  output_comparison <- compare_volcano_outputs(r_response, python_response, tolerance)
  
  # Extract data for statistical validation
  r_data <- r_response$data
  python_data <- python_response$data
  
  statistical_validation <- validate_data_generation_statistics(r_data, python_data)
  
  # Generate HTML report
  html_content <- generate_html_report(
    output_comparison, 
    statistical_validation, 
    r_response, 
    python_response
  )
  
  # Write to file
  writeLines(html_content, output_file)
  cat(paste("Report generated:", output_file, "\n"))
  
  return(list(
    output_comparison = output_comparison,
    statistical_validation = statistical_validation,
    report_file = output_file
  ))
}

#' Generate HTML report content
generate_html_report <- function(output_comp, stat_valid, r_resp, python_resp) {
  
  # HTML template start
  html <- paste0('
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>R vs Python Volcano Plot Comparison Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; line-height: 1.6; }
        .header { background: #f4f4f4; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .section { margin-bottom: 30px; }
        .success { color: #28a745; font-weight: bold; }
        .warning { color: #ffc107; font-weight: bold; }
        .error { color: #dc3545; font-weight: bold; }
        .info { color: #17a2b8; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .metric { display: inline-block; margin: 10px; padding: 10px; border: 1px solid #ddd; border-radius: 5px; }
        .pass { background-color: #d4edda; border-color: #c3e6cb; }
        .fail { background-color: #f8d7da; border-color: #f5c6cb; }
        .code { background-color: #f8f9fa; padding: 10px; border-radius: 3px; font-family: monospace; }
        .summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>R vs Python Volcano Plot Comparison Report</h1>
        <p>Generated on: ', Sys.time(), '</p>
        <p>Overall Status: <span class="', 
        if (output_comp$overall_match && stat_valid$overall_valid) 'success">✓ PASS' else 'error">✗ FAIL', 
        '</span></p>
    </div>
  ')
  
  # Executive Summary
  html <- paste0(html, '
    <div class="section">
        <h2>Executive Summary</h2>
        <div class="summary-grid">
            <div class="metric ', if (output_comp$structure_match) 'pass' else 'fail', '">
                <h4>JSON Structure</h4>
                <p>', if (output_comp$structure_match) '✓ Match' else '✗ Mismatch', '</p>
            </div>
            <div class="metric ', if (output_comp$data_consistency) 'pass' else 'fail', '">
                <h4>Data Consistency</h4>
                <p>', if (output_comp$data_consistency) '✓ Consistent' else '✗ Inconsistent', '</p>
            </div>
            <div class="metric ', if (output_comp$stats_match) 'pass' else 'fail', '">
                <h4>Statistics Match</h4>
                <p>', if (output_comp$stats_match) '✓ Match' else '✗ Mismatch', '</p>
            </div>
            <div class="metric ', if (output_comp$metadata_match) 'pass' else 'fail', '">
                <h4>Metadata Match</h4>
                <p>', if (output_comp$metadata_match) '✓ Match' else '✗ Mismatch', '</p>
            </div>
            <div class="metric ', if (stat_valid$distribution_tests$all_passed) 'pass' else 'fail', '">
                <h4>Distribution Tests</h4>
                <p>', if (stat_valid$distribution_tests$all_passed) '✓ Pass' else '✗ Fail', '</p>
            </div>
            <div class="metric ', if (stat_valid$correlation_tests$all_passed) 'pass' else 'fail', '">
                <h4>Correlation Tests</h4>
                <p>', if (stat_valid$correlation_tests$all_passed) '✓ Pass' else '✗ Fail', '</p>
            </div>
        </div>
    </div>
  ')
  
  # Data Overview
  html <- paste0(html, '
    <div class="section">
        <h2>Data Overview</h2>
        <table>
            <tr><th>Metric</th><th>R Backend</th><th>Python Backend</th><th>Status</th></tr>
            <tr>
                <td>Total Rows</td>
                <td>', r_resp$total_rows, '</td>
                <td>', python_resp$total_rows, '</td>
                <td class="', if (r_resp$total_rows == python_resp$total_rows) 'success">✓' else 'error">✗', '</td>
            </tr>
            <tr>
                <td>Filtered Rows</td>
                <td>', r_resp$filtered_rows, '</td>
                <td>', python_resp$filtered_rows, '</td>
                <td class="', if (r_resp$filtered_rows == python_resp$filtered_rows) 'success">✓' else 'error">✗', '</td>
            </tr>
            <tr>
                <td>Data Points Returned</td>
                <td>', length(r_resp$data), '</td>
                <td>', length(python_resp$data), '</td>
                <td class="', if (length(r_resp$data) == length(python_resp$data)) 'success">✓' else 'error">✗', '</td>
            </tr>
        </table>
    </div>
  ')
  
  # Statistics Comparison
  if (!is.null(r_resp$stats) && !is.null(python_resp$stats)) {
    html <- paste0(html, '
      <div class="section">
          <h2>Statistics Comparison</h2>
          <table>
              <tr><th>Category</th><th>R Backend</th><th>Python Backend</th><th>Difference</th><th>Status</th></tr>
    ')
    
    stat_fields <- c("up_regulated", "down_regulated", "non_significant")
    for (field in stat_fields) {
      if (field %in% names(r_resp$stats) && field %in% names(python_resp$stats)) {
        r_val <- r_resp$stats[[field]]
        python_val <- python_resp$stats[[field]]
        diff_val <- abs(r_val - python_val)
        status <- if (r_val == python_val) 'success">✓' else 'error">✗'
        
        html <- paste0(html, '
              <tr>
                  <td>', gsub("_", " ", tools::toTitleCase(field)), '</td>
                  <td>', r_val, '</td>
                  <td>', python_val, '</td>
                  <td>', diff_val, '</td>
                  <td class="', status, '</td>
              </tr>
        ')
      }
    }
    
    html <- paste0(html, '
          </table>
      </div>
    ')
  }
  
  # Statistical Tests Results
  if (!is.null(stat_valid$distribution_tests$tests)) {
    html <- paste0(html, '
      <div class="section">
          <h2>Statistical Distribution Tests</h2>
          <table>
              <tr><th>Column</th><th>KS Test p-value</th><th>Wilcoxon p-value</th><th>Overall Status</th></tr>
    ')
    
    for (col_name in names(stat_valid$distribution_tests$tests)) {
      test_result <- stat_valid$distribution_tests$tests[[col_name]]
      ks_p <- round(test_result$ks_test$p_value, 6)
      wilcox_p <- round(test_result$wilcox_test$p_value, 6)
      status <- if (test_result$overall_passed) 'success">✓ Pass' else 'error">✗ Fail'
      
      html <- paste0(html, '
              <tr>
                  <td>', col_name, '</td>
                  <td>', ks_p, '</td>
                  <td>', wilcox_p, '</td>
                  <td class="', status, '</td>
              </tr>
      ')
    }
    
    html <- paste0(html, '
          </table>
          <p><em>Note: p-values > 0.05 indicate distributions are not significantly different (good)</em></p>
      </div>
    ')
  }
  
  # Issues and Recommendations
  all_issues <- c()
  for (category in names(output_comp$detailed_results)) {
    if (length(output_comp$detailed_results[[category]]$issues) > 0) {
      all_issues <- c(all_issues, output_comp$detailed_results[[category]]$issues)
    }
  }
  
  if (length(all_issues) > 0) {
    html <- paste0(html, '
      <div class="section">
          <h2>Issues Found</h2>
          <ul>
    ')
    
    for (issue in all_issues) {
      html <- paste0(html, '<li class="error">', issue, '</li>')
    }
    
    html <- paste0(html, '
          </ul>
      </div>
    ')
  }
  
  # Recommendations
  html <- paste0(html, '
    <div class="section">
        <h2>Recommendations</h2>
        <ul>
  ')
  
  if (!output_comp$overall_match) {
    html <- paste0(html, '<li>Review data generation algorithms for consistency</li>')
    html <- paste0(html, '<li>Check filtering and sampling logic implementation</li>')
  }
  
  if (!stat_valid$overall_valid) {
    html <- paste0(html, '<li>Investigate statistical distribution differences</li>')
    html <- paste0(html, '<li>Verify random seed handling between R and Python</li>')
  }
  
  if (output_comp$overall_match && stat_valid$overall_valid) {
    html <- paste0(html, '<li class="success">✓ All validations passed - implementations are consistent</li>')
  }
  
  html <- paste0(html, '
        </ul>
    </div>
  ')
  
  # Footer
  html <- paste0(html, '
    <div class="section">
        <h2>Technical Details</h2>
        <div class="code">
            <p><strong>Comparison Tolerance:</strong> 1e-6</p>
            <p><strong>Statistical Significance Level:</strong> 0.05</p>
            <p><strong>Tests Performed:</strong> Kolmogorov-Smirnov, Wilcoxon Rank-Sum, Chi-Square</p>
        </div>
    </div>
    
    <footer style="margin-top: 50px; padding-top: 20px; border-top: 1px solid #ddd; color: #666;">
        <p>Generated by R vs Python Volcano Plot Comparison Utilities</p>
    </footer>
</body>
</html>
  ')
  
  return(html)
}

# Batch comparison function for multiple test scenarios
run_batch_comparison <- function(test_scenarios, output_dir = "comparison_reports") {
  
  cat("Running batch comparison for multiple scenarios...\n")
  
  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  results <- list()
  
  for (i in seq_along(test_scenarios)) {
    scenario <- test_scenarios[[i]]
    scenario_name <- names(test_scenarios)[i]
    
    cat(paste("Processing scenario:", scenario_name, "\n"))
    
    # Load responses
    r_response <- fromJSON(scenario$r_file)
    python_response <- fromJSON(scenario$python_file)
    
    # Generate report
    report_file <- file.path(output_dir, paste0(scenario_name, "_report.html"))
    
    scenario_results <- generate_comparison_report(
      r_response, 
      python_response, 
      report_file,
      scenario$tolerance %||% 1e-6
    )
    
    results[[scenario_name]] <- scenario_results
  }
  
  # Generate summary report
  generate_batch_summary_report(results, file.path(output_dir, "batch_summary.html"))
  
  return(results)
}

# Generate batch summary report
generate_batch_summary_report <- function(batch_results, output_file) {
  
  html <- paste0('
<!DOCTYPE html>
<html>
<head>
    <title>Batch Comparison Summary</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .pass { color: green; font-weight: bold; }
        .fail { color: red; font-weight: bold; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Batch Comparison Summary</h1>
    <p>Generated on: ', Sys.time(), '</p>
    
    <table>
        <tr>
            <th>Scenario</th>
            <th>Overall Match</th>
            <th>Structure</th>
            <th>Data</th>
            <th>Statistics</th>
            <th>Metadata</th>
            <th>Report</th>
        </tr>
  ')
  
  for (scenario_name in names(batch_results)) {
    result <- batch_results[[scenario_name]]
    output_comp <- result$output_comparison
    
    html <- paste0(html, '
        <tr>
            <td>', scenario_name, '</td>
            <td class="', if (output_comp$overall_match) 'pass">✓' else 'fail">✗', '</td>
            <td class="', if (output_comp$structure_match) 'pass">✓' else 'fail">✗', '</td>
            <td class="', if (output_comp$data_consistency) 'pass">✓' else 'fail">✗', '</td>
            <td class="', if (output_comp$stats_match) 'pass">✓' else 'fail">✗', '</td>
            <td class="', if (output_comp$metadata_match) 'pass">✓' else 'fail">✗', '</td>
            <td><a href="', basename(result$report_file), '">View Report</a></td>
        </tr>
    ')
  }
  
  html <- paste0(html, '
    </table>
</body>
</html>
  ')
  
  writeLines(html, output_file)
  cat(paste("Batch summary report generated:", output_file, "\n"))
}

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) < 2) {
    cat("Usage: Rscript generate-comparison-report.R <r_response.json> <python_response.json> [output.html]\n")
    quit(status = 1)
  }
  
  r_file <- args[1]
  python_file <- args[2]
  output_file <- if (length(args) >= 3) args[3] else "comparison_report.html"
  
  # Load responses
  r_response <- fromJSON(r_file)
  python_response <- fromJSON(python_file)
  
  # Generate report
  results <- generate_comparison_report(r_response, python_response, output_file)
  
  cat(paste("Comparison report generated successfully:", output_file, "\n"))
  
  # Exit with appropriate status
  overall_success <- results$output_comparison$overall_match && results$statistical_validation$overall_valid
  quit(status = if (overall_success) 0 else 1)
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x

# Run main if script is executed directly
if (!interactive()) {
  main()
}