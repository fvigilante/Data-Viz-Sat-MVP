#!/usr/bin/env Rscript

# Test Suite for Output Validation and Comparison Utilities
# Tests the comparison and validation functions with various scenarios

library(jsonlite)
library(data.table)

# Load the utilities to test
source("r-backend/compare-outputs.R")
source("r-backend/statistical-validation.R")
source("r-backend/generate-comparison-report.R")

#' Run comprehensive tests for output validation utilities
run_validation_tests <- function() {
  
  cat("=== Running Output Validation Tests ===\n")
  
  test_results <- list(
    structure_validation = test_structure_validation(),
    data_consistency = test_data_consistency(),
    statistical_validation = test_statistical_validation(),
    report_generation = test_report_generation(),
    edge_cases = test_edge_cases()
  )
  
  # Summary
  all_passed <- all(sapply(test_results, function(x) x$passed))
  
  cat("\n=== TEST SUMMARY ===\n")
  for (test_name in names(test_results)) {
    status <- if (test_results[[test_name]]$passed) "PASS" else "FAIL"
    cat(paste(test_name, ":", status, "\n"))
  }
  
  cat(paste("Overall:", if (all_passed) "PASS" else "FAIL", "\n"))
  
  return(list(
    results = test_results,
    all_passed = all_passed
  ))
}

#' Test JSON structure validation
test_structure_validation <- function() {
  
  cat("Testing JSON structure validation...\n")
  
  # Test case 1: Identical structures
  r_resp1 <- list(
    data = list(list(metabolite_id = "M1", log2_fold_change = 1.5, p_value = 0.01)),
    stats = list(up_regulated = 10, down_regulated = 5, non_significant = 85),
    total_rows = 100,
    filtered_rows = 50
  )
  
  python_resp1 <- list(
    data = list(list(metabolite_id = "M2", log2_fold_change = -1.2, p_value = 0.03)),
    stats = list(up_regulated = 12, down_regulated = 3, non_significant = 85),
    total_rows = 100,
    filtered_rows = 50
  )
  
  result1 <- validate_json_structure(r_resp1, python_resp1)
  test1_pass <- result1$match
  
  # Test case 2: Different structures
  r_resp2 <- list(
    data = list(),
    stats = list(up_regulated = 10),
    total_rows = 100
  )
  
  python_resp2 <- list(
    data = list(),
    statistics = list(up_regulated = 10),  # Different key name
    total_rows = 100
  )
  
  result2 <- validate_json_structure(r_resp2, python_resp2)
  test2_pass <- !result2$match  # Should fail
  
  passed <- test1_pass && test2_pass
  
  return(list(
    passed = passed,
    details = list(
      identical_structures = test1_pass,
      different_structures = test2_pass
    )
  ))
}

#' Test data consistency validation
test_data_consistency <- function() {
  
  cat("Testing data consistency validation...\n")
  
  # Generate test data
  n <- 1000
  
  # Identical data
  base_data <- data.table(
    metabolite_id = paste0("M", 1:n),
    metabolite_name = paste0("Metabolite_", 1:n),
    log2_fold_change = rnorm(n, 0, 2),
    p_value = runif(n, 0, 1),
    category = sample(c("up", "down", "non_significant"), n, replace = TRUE)
  )
  
  base_data[, neg_log10_p := -log10(p_value)]
  
  # Test case 1: Identical data
  r_data1 <- copy(base_data)
  python_data1 <- copy(base_data)
  
  result1 <- validate_data_consistency(
    split(r_data1, seq(nrow(r_data1))),
    split(python_data1, seq(nrow(python_data1))),
    tolerance = 1e-10
  )
  test1_pass <- result1$match
  
  # Test case 2: Small numerical differences within tolerance
  r_data2 <- copy(base_data)
  python_data2 <- copy(base_data)
  python_data2[, log2_fold_change := log2_fold_change + rnorm(n, 0, 1e-8)]
  
  result2 <- validate_data_consistency(
    split(r_data2, seq(nrow(r_data2))),
    split(python_data2, seq(nrow(python_data2))),
    tolerance = 1e-6
  )
  test2_pass <- result2$match
  
  # Test case 3: Large differences exceeding tolerance
  r_data3 <- copy(base_data)
  python_data3 <- copy(base_data)
  python_data3[, log2_fold_change := log2_fold_change + 0.1]  # Large difference
  
  result3 <- validate_data_consistency(
    split(r_data3, seq(nrow(r_data3))),
    split(python_data3, seq(nrow(python_data3))),
    tolerance = 1e-6
  )
  test3_pass <- !result3$match  # Should fail
  
  passed <- test1_pass && test2_pass && test3_pass
  
  return(list(
    passed = passed,
    details = list(
      identical_data = test1_pass,
      small_differences = test2_pass,
      large_differences = test3_pass
    )
  ))
}

#' Test statistical validation
test_statistical_validation <- function() {
  
  cat("Testing statistical validation...\n")
  
  # Generate test datasets
  n <- 5000
  
  # Test case 1: Data from same distribution
  set.seed(123)
  r_data1 <- data.table(
    log2_fold_change = rnorm(n, 0, 2),
    p_value = runif(n, 0, 1),
    category = sample(c("up", "down", "non_significant"), n, replace = TRUE, prob = c(0.1, 0.1, 0.8))
  )
  r_data1[, neg_log10_p := -log10(p_value)]
  
  set.seed(124)  # Different seed but same distribution
  python_data1 <- data.table(
    log2_fold_change = rnorm(n, 0, 2),
    p_value = runif(n, 0, 1),
    category = sample(c("up", "down", "non_significant"), n, replace = TRUE, prob = c(0.1, 0.1, 0.8))
  )
  python_data1[, neg_log10_p := -log10(p_value)]
  
  result1 <- validate_data_generation_statistics(r_data1, python_data1, alpha = 0.01)
  test1_pass <- result1$overall_valid
  
  # Test case 2: Data from different distributions
  set.seed(125)
  r_data2 <- data.table(
    log2_fold_change = rnorm(n, 0, 2),
    p_value = runif(n, 0, 1),
    category = sample(c("up", "down", "non_significant"), n, replace = TRUE, prob = c(0.1, 0.1, 0.8))
  )
  r_data2[, neg_log10_p := -log10(p_value)]
  
  set.seed(126)
  python_data2 <- data.table(
    log2_fold_change = rnorm(n, 1, 3),  # Different mean and sd
    p_value = rbeta(n, 2, 5),  # Different distribution
    category = sample(c("up", "down", "non_significant"), n, replace = TRUE, prob = c(0.3, 0.2, 0.5))  # Different proportions
  )
  python_data2[, neg_log10_p := -log10(p_value)]
  
  result2 <- validate_data_generation_statistics(r_data2, python_data2, alpha = 0.01)
  test2_pass <- !result2$overall_valid  # Should fail
  
  passed <- test1_pass && test2_pass
  
  return(list(
    passed = passed,
    details = list(
      same_distribution = test1_pass,
      different_distribution = test2_pass
    )
  ))
}

#' Test report generation
test_report_generation <- function() {
  
  cat("Testing report generation...\n")
  
  # Create test responses
  r_response <- list(
    data = list(
      list(metabolite_id = "M1", metabolite_name = "Met1", log2_fold_change = 1.5, p_value = 0.01, neg_log10_p = 2, category = "up"),
      list(metabolite_id = "M2", metabolite_name = "Met2", log2_fold_change = -1.2, p_value = 0.03, neg_log10_p = 1.5, category = "down")
    ),
    stats = list(up_regulated = 1, down_regulated = 1, non_significant = 0),
    total_rows = 2,
    filtered_rows = 2,
    points_before_sampling = 2,
    is_downsampled = FALSE
  )
  
  python_response <- list(
    data = list(
      list(metabolite_id = "M1", metabolite_name = "Met1", log2_fold_change = 1.5, p_value = 0.01, neg_log10_p = 2, category = "up"),
      list(metabolite_id = "M2", metabolite_name = "Met2", log2_fold_change = -1.2, p_value = 0.03, neg_log10_p = 1.5, category = "down")
    ),
    stats = list(up_regulated = 1, down_regulated = 1, non_significant = 0),
    total_rows = 2,
    filtered_rows = 2,
    points_before_sampling = 2,
    is_downsampled = FALSE
  )
  
  # Test report generation
  test_report_file <- "test_comparison_report.html"
  
  tryCatch({
    result <- generate_comparison_report(r_response, python_response, test_report_file)
    
    # Check if file was created
    file_exists <- file.exists(test_report_file)
    
    # Check if file has content
    if (file_exists) {
      file_size <- file.info(test_report_file)$size
      has_content <- file_size > 1000  # Should be substantial HTML
      
      # Clean up
      if (file.exists(test_report_file)) {
        file.remove(test_report_file)
      }
      
      passed <- file_exists && has_content
    } else {
      passed <- FALSE
    }
    
  }, error = function(e) {
    cat(paste("Report generation error:", e$message, "\n"))
    passed <- FALSE
  })
  
  return(list(
    passed = passed,
    details = list(
      file_created = file_exists %||% FALSE,
      has_content = has_content %||% FALSE
    )
  ))
}

#' Test edge cases
test_edge_cases <- function() {
  
  cat("Testing edge cases...\n")
  
  tests_passed <- c()
  
  # Test case 1: Empty data
  empty_r <- list(data = list(), stats = list(), total_rows = 0)
  empty_python <- list(data = list(), stats = list(), total_rows = 0)
  
  tryCatch({
    result1 <- compare_volcano_outputs(empty_r, empty_python)
    tests_passed <- c(tests_passed, TRUE)
  }, error = function(e) {
    cat(paste("Empty data test failed:", e$message, "\n"))
    tests_passed <- c(tests_passed, FALSE)
  })
  
  # Test case 2: Missing fields
  incomplete_r <- list(data = list())
  incomplete_python <- list(data = list(), stats = list())
  
  tryCatch({
    result2 <- compare_volcano_outputs(incomplete_r, incomplete_python)
    tests_passed <- c(tests_passed, TRUE)
  }, error = function(e) {
    cat(paste("Missing fields test failed:", e$message, "\n"))
    tests_passed <- c(tests_passed, FALSE)
  })
  
  # Test case 3: NULL values
  null_r <- list(data = NULL, stats = NULL)
  null_python <- list(data = NULL, stats = NULL)
  
  tryCatch({
    result3 <- compare_volcano_outputs(null_r, null_python)
    tests_passed <- c(tests_passed, TRUE)
  }, error = function(e) {
    cat(paste("NULL values test failed:", e$message, "\n"))
    tests_passed <- c(tests_passed, FALSE)
  })
  
  passed <- all(tests_passed)
  
  return(list(
    passed = passed,
    details = list(
      empty_data = tests_passed[1] %||% FALSE,
      missing_fields = tests_passed[2] %||% FALSE,
      null_values = tests_passed[3] %||% FALSE
    )
  ))
}

# Create sample test data files for demonstration
create_sample_test_files <- function() {
  
  cat("Creating sample test data files...\n")
  
  # Sample R response
  r_sample <- list(
    data = lapply(1:100, function(i) {
      list(
        metabolite_id = paste0("M", i),
        metabolite_name = paste0("Metabolite_", i),
        log2_fold_change = rnorm(1, 0, 2),
        p_value = runif(1, 0, 1),
        neg_log10_p = -log10(runif(1, 0, 1)),
        category = sample(c("up", "down", "non_significant"), 1)
      )
    }),
    stats = list(
      up_regulated = 15,
      down_regulated = 12,
      non_significant = 73
    ),
    total_rows = 10000,
    filtered_rows = 100,
    points_before_sampling = 100,
    is_downsampled = FALSE
  )
  
  # Sample Python response (slightly different)
  python_sample <- r_sample
  python_sample$stats$up_regulated <- 16  # Small difference
  python_sample$filtered_rows <- 101  # Small difference
  
  # Write sample files
  write(toJSON(r_sample, pretty = TRUE, auto_unbox = TRUE), "sample_r_response.json")
  write(toJSON(python_sample, pretty = TRUE, auto_unbox = TRUE), "sample_python_response.json")
  
  cat("Sample files created: sample_r_response.json, sample_python_response.json\n")
}

# Main execution function
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) > 0 && args[1] == "--create-samples") {
    create_sample_test_files()
    return()
  }
  
  # Run all tests
  test_results <- run_validation_tests()
  
  # Create sample files for manual testing
  create_sample_test_files()
  
  cat("\n=== USAGE EXAMPLES ===\n")
  cat("1. Compare outputs:\n")
  cat("   Rscript compare-outputs.R sample_r_response.json sample_python_response.json\n")
  cat("2. Statistical validation:\n")
  cat("   Rscript statistical-validation.R sample_r_response.json sample_python_response.json\n")
  cat("3. Generate report:\n")
  cat("   Rscript generate-comparison-report.R sample_r_response.json sample_python_response.json\n")
  
  # Exit with appropriate status
  quit(status = if (test_results$all_passed) 0 else 1)
}

# Helper function for null coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x

# Run main if script is executed directly
if (!interactive()) {
  main()
}