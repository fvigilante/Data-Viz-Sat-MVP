#!/usr/bin/env Rscript

# Test diretto delle funzioni senza API per verificare che funzionino

library(data.table)
library(jsonlite)

# Carica solo le funzioni necessarie dal file principale
source("r-backend/plumber-api.R")

cat("Testing direct function calls...\n")

# Test 1: get_cached_dataset
cat("1. Testing get_cached_dataset...\n")
tryCatch({
  dt <- get_cached_dataset(10000)
  cat(sprintf("   Success: Generated %d rows\n", nrow(dt)))
}, error = function(e) {
  cat(sprintf("   Error: %s\n", e$message))
})

# Test 2: categorize_points
cat("2. Testing categorize_points...\n")
tryCatch({
  if (exists("dt") && nrow(dt) > 0) {
    dt_cat <- categorize_points(dt, 0.05, -0.5, 0.5)
    cat(sprintf("   Success: Categorized %d rows\n", nrow(dt_cat)))
  } else {
    cat("   Skipped: No data from previous test\n")
  }
}, error = function(e) {
  cat(sprintf("   Error: %s\n", e$message))
})

# Test 3: convert_to_data_points_optimized
cat("3. Testing convert_to_data_points_optimized...\n")
tryCatch({
  if (exists("dt_cat") && nrow(dt_cat) > 0) {
    # Test con sample ridotto
    dt_sample <- dt_cat[1:min(1000, nrow(dt_cat))]
    data_points <- convert_to_data_points_optimized(dt_sample)
    cat(sprintf("   Success: Converted to %d data points\n", length(data_points)))
  } else {
    cat("   Skipped: No data from previous test\n")
  }
}, error = function(e) {
  cat(sprintf("   Error: %s\n", e$message))
})

cat("Direct function tests completed.\n")