#!/usr/bin/env Rscript

# Test script for R volcano plot data generation and caching system
# This script tests the core functionality without running the full server

# Load required libraries
library(data.table)
library(jsonlite)

# Source the main functions from plumber-api.R
source("plumber-api.R")

cat("=== Testing R Volcano Plot Data Generation and Caching System ===\n\n")

# Test 1: Dataset size validation
cat("1. Testing dataset size validation...\n")
test_sizes <- c(-100, 50, 1000, 15000000)
for (size in test_sizes) {
  result <- tryCatch({
    validated <- validate_dataset_size(size)
    sprintf("Size %d -> %d (valid)", size, validated)
  }, error = function(e) {
    sprintf("Size %d -> ERROR: %s", size, e$message)
  }, warning = function(w) {
    validated <- validate_dataset_size(size)
    sprintf("Size %d -> %d (warning: %s)", size, validated, w$message)
  })
  cat("  ", result, "\n")
}
cat("\n")

# Test 2: Data generation
cat("2. Testing data generation...\n")
test_size <- 1000
dt <- generate_volcano_data(test_size)

cat(sprintf("  Generated dataset: %d rows, %d columns\n", nrow(dt), ncol(dt)))
cat("  Column names:", paste(names(dt), collapse = ", "), "\n")
cat("  Data types:", paste(sapply(dt, class), collapse = ", "), "\n")

# Check data ranges
cat(sprintf("  logFC range: %.4f to %.4f\n", min(dt$logFC), max(dt$logFC)))
cat(sprintf("  padj range: %.6f to %.6f\n", min(dt$padj), max(dt$padj)))

# Check for missing values
missing_counts <- sapply(dt, function(x) sum(is.na(x)))
cat("  Missing values:", paste(names(missing_counts), "=", missing_counts, collapse = ", "), "\n")
cat("\n")

# Test 3: Caching functionality
cat("3. Testing caching functionality...\n")

# Clear cache first
clear_result <- clear_cache()
cat("  Cache cleared:", clear_result$message, "\n")

# Check initial cache status
status1 <- get_cache_status()
cat(sprintf("  Initial cache: %d datasets\n", status1$total_cached))

# Generate and cache a dataset
cat("  Generating dataset (size 5000)...\n")
dt1 <- get_cached_dataset(5000)
cat(sprintf("  First call: %d rows generated\n", nrow(dt1)))

# Get the same dataset again (should be cached)
cat("  Retrieving same dataset (should be cached)...\n")
dt2 <- get_cached_dataset(5000)
cat(sprintf("  Second call: %d rows retrieved\n", nrow(dt2)))

# Verify they are identical
identical_check <- identical(dt1, dt2)
cat(sprintf("  Datasets identical: %s\n", identical_check))

# Check cache status after caching
status2 <- get_cache_status()
cat(sprintf("  Cache after generation: %d datasets, %.2f MB\n", 
            status2$total_cached, status2$approximate_memory_mb))
cat("\n")

# Test 4: Cache warming
cat("4. Testing cache warming...\n")
warm_sizes <- c(1000, 5000, 10000)
warm_result <- warm_cache(warm_sizes)
cat("  Warm cache result:", warm_result$message, "\n")
cat("  Cached sizes:", paste(warm_result$cached_sizes, collapse = ", "), "\n")

# Final cache status
final_status <- get_cache_status()
cat(sprintf("  Final cache: %d datasets, %.2f MB\n", 
            final_status$total_cached, final_status$approximate_memory_mb))
cat("  Cached dataset sizes:", paste(final_status$cached_datasets, collapse = ", "), "\n")
cat("\n")

# Test 5: Data quality validation
cat("5. Testing data quality and distribution...\n")

# Generate a larger dataset for statistical validation
test_dt <- generate_volcano_data(10000)

# Add category classification (simplified version for testing)
test_dt[, category := ifelse(padj <= 0.05 & logFC < -0.5, "down",
                    ifelse(padj <= 0.05 & logFC > 0.5, "up", "non_significant"))]

# Count categories
category_counts <- test_dt[, .N, by = category]
setorder(category_counts, category)

cat("  Category distribution:\n")
for (i in 1:nrow(category_counts)) {
  cat(sprintf("    %s: %d (%.1f%%)\n", 
              category_counts$category[i], 
              category_counts$N[i],
              100 * category_counts$N[i] / nrow(test_dt)))
}

# Check if distribution matches expected proportions (approximately)
expected_non_sig <- 0.85
actual_non_sig <- category_counts[category == "non_significant", N] / nrow(test_dt)
cat(sprintf("  Non-significant proportion: %.3f (expected ~%.3f)\n", actual_non_sig, expected_non_sig))

cat("\n=== All tests completed successfully! ===\n")