#!/usr/bin/env Rscript

# Output Validation and Comparison Utilities
# Compares R vs Python volcano plot outputs for consistency

library(jsonlite)
library(data.table)

# Load utility functions
source("r-backend/validate-setup.R")

#' Compare R and Python volcano plot outputs
#' @param r_response JSON response from R backend
#' @param python_response JSON response from Python backend
#' @param tolerance Numerical tolerance for comparisons
#' @return List with comparison results
compare_volcano_outputs <- function(r_response, python_response, tolerance = 1e-6) {
  
  cat("=== Volcano Plot Output Comparison ===\n")
  
  results <- list(
    structure_match = FALSE,
    data_consistency = FALSE,
    stats_match = FALSE,
    metadata_match = FALSE,
    detailed_results = list()
  )
  
  # 1. JSON Structure Validation
  cat("1. Validating JSON structure...\n")
  structure_result <- validate_json_structure(r_response, python_response)
  results$structure_match <- structure_result$match
  results$detailed_results$structure <- structure_result
  
  # 2. Data Point Consistency
  cat("2. Validating data point consistency...\n")
  data_result <- validate_data_consistency(r_response$data, python_response$data, tolerance)
  results$data_consistency <- data_result$match
  results$detailed_results$data <- data_result
  
  # 3. Statistics Validation
  cat("3. Validating statistics...\n")
  stats_result <- validate_statistics(r_response$stats, python_response$stats)
  results$stats_match <- stats_result$match
  results$detailed_results$stats <- stats_result
  
  # 4. Metadata Validation
  cat("4. Validating metadata...\n")
  metadata_result <- validate_metadata(r_response, python_response)
  results$metadata_match <- metadata_result$match
  results$detailed_results$metadata <- metadata_result
  
  # Overall result
  results$overall_match <- all(c(
    results$structure_match,
    results$data_consistency,
    results$stats_match,
    results$metadata_match
  ))
  
  return(results)
}

#' Validate JSON structure between R and Python responses
validate_json_structure <- function(r_resp, python_resp) {
  
  result <- list(match = FALSE, issues = c())
  
  # Check top-level keys
  r_keys <- names(r_resp)
  python_keys <- names(python_resp)
  
  if (!identical(sort(r_keys), sort(python_keys))) {
    result$issues <- c(result$issues, 
      paste("Top-level keys differ:", 
            "R:", paste(r_keys, collapse=", "),
            "Python:", paste(python_keys, collapse=", ")))
  }
  
  # Check data structure
  if ("data" %in% r_keys && "data" %in% python_keys) {
    if (length(r_resp$data) > 0 && length(python_resp$data) > 0) {
      r_data_keys <- names(r_resp$data[[1]])
      python_data_keys <- names(python_resp$data[[1]])
      
      if (!identical(sort(r_data_keys), sort(python_data_keys))) {
        result$issues <- c(result$issues,
          paste("Data point keys differ:",
                "R:", paste(r_data_keys, collapse=", "),
                "Python:", paste(python_data_keys, collapse=", ")))
      }
    }
  }
  
  # Check stats structure
  if ("stats" %in% r_keys && "stats" %in% python_keys) {
    r_stats_keys <- names(r_resp$stats)
    python_stats_keys <- names(python_resp$stats)
    
    if (!identical(sort(r_stats_keys), sort(python_stats_keys))) {
      result$issues <- c(result$issues,
        paste("Stats keys differ:",
              "R:", paste(r_stats_keys, collapse=", "),
              "Python:", paste(python_stats_keys, collapse=", ")))
    }
  }
  
  result$match <- length(result$issues) == 0
  return(result)
}

#' Validate data consistency between R and Python outputs
validate_data_consistency <- function(r_data, python_data, tolerance = 1e-6) {
  
  result <- list(match = FALSE, issues = c(), statistics = list())
  
  if (length(r_data) != length(python_data)) {
    result$issues <- c(result$issues, 
      paste("Data length differs: R =", length(r_data), "Python =", length(python_data)))
    return(result)
  }
  
  if (length(r_data) == 0) {
    result$match <- TRUE
    return(result)
  }
  
  # Convert to data.tables for comparison
  r_dt <- rbindlist(r_data)
  python_dt <- rbindlist(python_data)
  
  # Check column consistency
  if (!identical(sort(names(r_dt)), sort(names(python_dt)))) {
    result$issues <- c(result$issues, "Column names differ between R and Python data")
    return(result)
  }
  
  # Sort both datasets by metabolite_id for consistent comparison
  if ("metabolite_id" %in% names(r_dt)) {
    setorder(r_dt, metabolite_id)
    setorder(python_dt, metabolite_id)
  }
  
  # Compare numerical columns
  numerical_cols <- c("log2_fold_change", "p_value", "neg_log10_p")
  
  for (col in numerical_cols) {
    if (col %in% names(r_dt) && col %in% names(python_dt)) {
      
      # Calculate differences
      diff_vals <- abs(r_dt[[col]] - python_dt[[col]])
      max_diff <- max(diff_vals, na.rm = TRUE)
      mean_diff <- mean(diff_vals, na.rm = TRUE)
      
      result$statistics[[col]] <- list(
        max_difference = max_diff,
        mean_difference = mean_diff,
        within_tolerance = max_diff <= tolerance
      )
      
      if (max_diff > tolerance) {
        result$issues <- c(result$issues, 
          paste("Column", col, "exceeds tolerance. Max diff:", max_diff))
      }
    }
  }
  
  # Compare categorical columns
  categorical_cols <- c("metabolite_name", "category")
  
  for (col in categorical_cols) {
    if (col %in% names(r_dt) && col %in% names(python_dt)) {
      
      matches <- r_dt[[col]] == python_dt[[col]]
      match_rate <- sum(matches, na.rm = TRUE) / length(matches)
      
      result$statistics[[col]] <- list(
        match_rate = match_rate,
        perfect_match = match_rate == 1.0
      )
      
      if (match_rate < 1.0) {
        result$issues <- c(result$issues,
          paste("Column", col, "match rate:", round(match_rate * 100, 2), "%"))
      }
    }
  }
  
  result$match <- length(result$issues) == 0
  return(result)
}

#' Validate statistics between R and Python responses
validate_statistics <- function(r_stats, python_stats) {
  
  result <- list(match = FALSE, issues = c(), differences = list())
  
  stat_fields <- c("up_regulated", "down_regulated", "non_significant")
  
  for (field in stat_fields) {
    if (field %in% names(r_stats) && field %in% names(python_stats)) {
      
      r_val <- r_stats[[field]]
      python_val <- python_stats[[field]]
      
      result$differences[[field]] <- list(
        r_value = r_val,
        python_value = python_val,
        difference = abs(r_val - python_val),
        match = r_val == python_val
      )
      
      if (r_val != python_val) {
        result$issues <- c(result$issues,
          paste("Statistic", field, "differs: R =", r_val, "Python =", python_val))
      }
    }
  }
  
  result$match <- length(result$issues) == 0
  return(result)
}

#' Validate metadata between R and Python responses
validate_metadata <- function(r_resp, python_resp) {
  
  result <- list(match = FALSE, issues = c(), differences = list())
  
  metadata_fields <- c("total_rows", "filtered_rows", "points_before_sampling", "is_downsampled")
  
  for (field in metadata_fields) {
    if (field %in% names(r_resp) && field %in% names(python_resp)) {
      
      r_val <- r_resp[[field]]
      python_val <- python_resp[[field]]
      
      result$differences[[field]] <- list(
        r_value = r_val,
        python_value = python_val,
        match = identical(r_val, python_val)
      )
      
      if (!identical(r_val, python_val)) {
        result$issues <- c(result$issues,
          paste("Metadata", field, "differs: R =", r_val, "Python =", python_val))
      }
    }
  }
  
  result$match <- length(result$issues) == 0
  return(result)
}

# Main execution function for command line usage
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) < 2) {
    cat("Usage: Rscript compare-outputs.R <r_response.json> <python_response.json> [tolerance]\n")
    quit(status = 1)
  }
  
  r_file <- args[1]
  python_file <- args[2]
  tolerance <- if (length(args) >= 3) as.numeric(args[3]) else 1e-6
  
  # Load responses
  r_response <- fromJSON(r_file)
  python_response <- fromJSON(python_file)
  
  # Compare outputs
  results <- compare_volcano_outputs(r_response, python_response, tolerance)
  
  # Print summary
  cat("\n=== COMPARISON SUMMARY ===\n")
  cat("Overall Match:", results$overall_match, "\n")
  cat("Structure Match:", results$structure_match, "\n")
  cat("Data Consistency:", results$data_consistency, "\n")
  cat("Stats Match:", results$stats_match, "\n")
  cat("Metadata Match:", results$metadata_match, "\n")
  
  if (!results$overall_match) {
    cat("\n=== ISSUES FOUND ===\n")
    for (category in names(results$detailed_results)) {
      if (length(results$detailed_results[[category]]$issues) > 0) {
        cat(paste("Category:", category, "\n"))
        for (issue in results$detailed_results[[category]]$issues) {
          cat(paste("  -", issue, "\n"))
        }
      }
    }
  }
  
  # Save detailed results
  output_file <- "comparison_results.json"
  write(toJSON(results, pretty = TRUE, auto_unbox = TRUE), output_file)
  cat(paste("\nDetailed results saved to:", output_file, "\n"))
  
  # Exit with appropriate code
  quit(status = if (results$overall_match) 0 else 1)
}

# Run main if script is executed directly
if (!interactive()) {
  main()
}