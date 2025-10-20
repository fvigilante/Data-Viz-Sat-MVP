#!/usr/bin/env Rscript

# Simple test for JSON conversion optimization
library(data.table)
library(jsonlite)

# Define the optimized function directly for testing
convert_to_data_points_optimized <- function(dt) {
  if (nrow(dt) == 0) {
    return(list())
  }
  
  # OPTIMIZATION: Use jsonlite::toJSON() directly on data.table
  json_string <- jsonlite::toJSON(dt, dataframe = "rows", auto_unbox = TRUE)
  
  # Parse back to R list structure for API compatibility
  result <- jsonlite::fromJSON(json_string, simplifyVector = FALSE)
  
  return(result)
}

# Define the old inefficient function for comparison
convert_to_data_points_old <- function(dt) {
  if (nrow(dt) == 0) {
    return(list())
  }
  
  # Old inefficient approach with explicit loop
  n_rows <- nrow(dt)
  result <- vector("list", n_rows)
  
  for (i in seq_len(n_rows)) {
    result[[i]] <- list(
      gene = as.character(dt$gene[i]),
      logFC = as.numeric(dt$logFC[i]),
      padj = as.numeric(dt$padj[i]),
      classyfireSuperclass = as.character(dt$classyfireSuperclass[i]),
      classyfireClass = as.character(dt$classyfireClass[i]),
      category = as.character(dt$category[i])
    )
  }
  
  return(result)
}

# Create test data
test_sizes <- c(100, 1000, 10000)

for (size in test_sizes) {
  cat(sprintf("\n=== Testing with %d rows ===\n", size))
  
  # Generate test data
  test_dt <- data.table(
    gene = paste0("Gene_", 1:size),
    logFC = rnorm(size),
    padj = runif(size),
    classyfireSuperclass = sample(c("Organic acids", "Lipids", "Others"), size, replace = TRUE),
    classyfireClass = sample(c("Carboxylic acids", "Fatty acids", "Unknown"), size, replace = TRUE),
    category = sample(c("up", "down", "non_significant"), size, replace = TRUE)
  )
  
  # Test old method
  start_time <- Sys.time()
  result_old <- convert_to_data_points_old(test_dt)
  old_duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  # Test optimized method
  start_time <- Sys.time()
  result_optimized <- convert_to_data_points_optimized(test_dt)
  optimized_duration <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  # Calculate speedup
  speedup <- old_duration / optimized_duration
  
  cat(sprintf("Old method: %.4f seconds\n", old_duration))
  cat(sprintf("Optimized method: %.4f seconds\n", optimized_duration))
  cat(sprintf("Speedup: %.2fx faster\n", speedup))
  
  # Verify results are equivalent
  if (length(result_old) == length(result_optimized)) {
    cat("✓ Result lengths match\n")
  } else {
    cat("✗ Result lengths differ\n")
  }
  
  # Check first element structure
  if (length(result_old) > 0 && length(result_optimized) > 0) {
    old_keys <- sort(names(result_old[[1]]))
    opt_keys <- sort(names(result_optimized[[1]]))
    if (identical(old_keys, opt_keys)) {
      cat("✓ Result structures match\n")
    } else {
      cat("✗ Result structures differ\n")
    }
  }
}

cat("\nJSON optimization test completed!\n")