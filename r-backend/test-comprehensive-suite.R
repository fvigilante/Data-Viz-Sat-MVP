#!/usr/bin/env Rscript

# Comprehensive R Unit Test Suite for Volcano Plot Integration
# Tests all R data generation and filtering functions

cat("=== R Volcano Plot Comprehensive Unit Test Suite ===\n\n")

# Load required libraries and source API
tryCatch({
  library(data.table)
  library(jsonlite)
  source("plumber-api.R", local = TRUE)
  cat("✓ Successfully loaded dependencies and plumber-api.R\n")
}, error = function(e) {
  cat("✗ Failed to load dependencies:", e$message, "\n")
  quit(status = 1)
})

# Test counter
test_count <- 0
passed_count <- 0
failed_count <- 0

# Test helper function
run_test <- function(test_name, test_func) {
  test_count <<- test_count + 1
  cat(sprintf("\n%d. %s\n", test_count, test_name))
  
  tryCatch({
    result <- test_func()
    if (isTRUE(result)) {
      cat("   ✓ PASSED\n")
      passed_count <<- passed_count + 1
    } else {
      cat("   ✗ FAILED:", result, "\n")
      failed_count <<- failed_count + 1
    }
  }, error = function(e) {
    cat("   ✗ ERROR:", e$message, "\n")
    failed_count <<- failed_count + 1
  })
}

# Unit Test 1: Dataset size validation
run_test("Dataset size validation", function() {
  # Test valid sizes
  valid_sizes <- c(1000, 10000, 100000, 1000000)
  for (size in valid_sizes) {
    validated <- validate_dataset_size(size)
    if (validated != size) {
      return(sprintf("Valid size %d changed to %d", size, validated))
    }
  }
  
  # Test invalid sizes (should be clamped)
  invalid_tests <- list(
    list(input = -100, expected_min = 100),
    list(input = 50, expected_min = 100),
    list(input = 15000000, expected_max = 10000000)
  )
  
  for (test in invalid_tests) {
    validated <- validate_dataset_size(test$input)
    if (test$input < 100 && validated < 100) {
      return(sprintf("Size %d not properly clamped to minimum", test$input))
    }
    if (test$input > 10000000 && validated > 10000000) {
      return(sprintf("Size %d not properly clamped to maximum", test$input))
    }
  }
  
  TRUE
})

# Unit Test 2: Data generation structure and quality
run_test("Data generation structure and quality", function() {
  test_size <- 1000
  dt <- generate_volcano_data(test_size)
  
  # Check basic structure
  if (nrow(dt) != test_size) {
    return(sprintf("Expected %d rows, got %d", test_size, nrow(dt)))
  }
  
  required_cols <- c("gene", "logFC", "padj", "classyfireSuperclass", "classyfireClass")
  missing_cols <- setdiff(required_cols, names(dt))
  if (length(missing_cols) > 0) {
    return(sprintf("Missing columns: %s", paste(missing_cols, collapse = ", ")))
  }
  
  # Check data types
  if (!is.character(dt$gene)) return("gene column should be character")
  if (!is.numeric(dt$logFC)) return("logFC column should be numeric")
  if (!is.numeric(dt$padj)) return("padj column should be numeric")
  
  # Check data ranges
  if (any(dt$padj < 0) || any(dt$padj > 1)) {
    return("padj values should be between 0 and 1")
  }
  
  # Check for missing values
  if (any(is.na(dt))) {
    return("Generated data contains missing values")
  }
  
  # Check gene name uniqueness
  if (length(unique(dt$gene)) != nrow(dt)) {
    return("Gene names are not unique")
  }
  
  TRUE
})

# Unit Test 3: Categorization logic
run_test("Categorization logic", function() {
  # Create test data with known outcomes
  test_dt <- data.table(
    gene = paste0("Test", 1:10),
    logFC = c(-2.0, -1.0, -0.5, -0.3, 0.0, 0.3, 0.5, 1.0, 2.0, 0.1),
    padj = c(0.001, 0.01, 0.05, 0.1, 0.5, 0.1, 0.05, 0.01, 0.001, 0.001),
    classyfireSuperclass = rep("Test", 10),
    classyfireClass = rep("Test", 10)
  )
  
  # Apply categorization
  categorized <- categorize_points(test_dt, 0.05, -0.5, 0.5)
  
  # Expected categories (p <= 0.05 AND |logFC| > 0.5)
  expected <- c("down", "down", "non_significant", "non_significant", 
                "non_significant", "non_significant", "non_significant", 
                "up", "up", "non_significant")
  
  actual <- categorized$category
  
  if (!identical(expected, actual)) {
    mismatches <- which(expected != actual)
    return(sprintf("Categorization mismatch at positions: %s", 
                   paste(mismatches, collapse = ", ")))
  }
  
  # Test edge cases (exactly at thresholds)
  edge_dt <- data.table(
    gene = c("Edge1", "Edge2", "Edge3"),
    logFC = c(-0.5, 0.5, 0.0),
    padj = c(0.05, 0.05, 0.05),
    classyfireSuperclass = rep("Test", 3),
    classyfireClass = rep("Test", 3)
  )
  
  edge_categorized <- categorize_points(edge_dt, 0.05, -0.5, 0.5)
  edge_expected <- c("non_significant", "non_significant", "non_significant")
  
  if (!identical(edge_expected, edge_categorized$category)) {
    return("Edge case categorization failed")
  }
  
  TRUE
})

# Unit Test 4: Intelligent sampling algorithm
run_test("Intelligent sampling algorithm", function() {
  # Generate test dataset
  dt <- generate_volcano_data(5000)
  dt <- categorize_points(dt, 0.05, -0.5, 0.5)
  
  original_sig <- nrow(dt[category != "non_significant"])
  original_total <- nrow(dt)
  
  # Test sampling with different limits
  max_points <- 1000
  sampled_dt <- intelligent_sampling(dt, max_points, 1.0)
  
  # Check size constraint
  if (nrow(sampled_dt) > max_points) {
    return(sprintf("Sampling exceeded limit: %d > %d", nrow(sampled_dt), max_points))
  }
  
  # Check significant point prioritization
  sampled_sig <- nrow(sampled_dt[category != "non_significant"])
  sig_ratio_original <- original_sig / original_total
  sig_ratio_sampled <- sampled_sig / nrow(sampled_dt)
  
  if (sig_ratio_sampled < sig_ratio_original * 0.9) {  # Allow 10% tolerance
    return(sprintf("Significant points not prioritized: %.3f < %.3f", 
                   sig_ratio_sampled, sig_ratio_original))
  }
  
  # Test zoom level adaptation
  zoom_2x_points <- get_lod_max_points(2.0, 1000)
  zoom_1x_points <- get_lod_max_points(1.0, 1000)
  
  if (zoom_2x_points <= zoom_1x_points) {
    return("Zoom level adaptation not working")
  }
  
  TRUE
})

# Unit Test 5: Search functionality
run_test("Search functionality", function() {
  dt <- generate_volcano_data(1000)
  
  # Test exact search (case insensitive)
  search_term <- "biotin"
  filtered_exact <- dt[grepl(tolower(search_term), tolower(gene))]
  
  # Test partial search
  partial_term <- "acid"
  filtered_partial <- dt[grepl(tolower(partial_term), tolower(gene))]
  
  # Test empty search (should return all)
  filtered_empty <- dt[grepl(tolower(""), tolower(gene))]
  
  if (nrow(filtered_empty) != nrow(dt)) {
    return("Empty search should return all results")
  }
  
  # Test case insensitivity
  upper_term <- "BIOTIN"
  filtered_upper <- dt[grepl(tolower(upper_term), tolower(gene))]
  
  if (nrow(filtered_exact) != nrow(filtered_upper)) {
    return("Search is not case insensitive")
  }
  
  # Test that search actually filters
  if (nrow(filtered_partial) >= nrow(dt)) {
    return("Search did not filter results")
  }
  
  TRUE
})

# Unit Test 6: Caching system
run_test("Caching system", function() {
  # Clear cache first
  clear_result <- clear_cache()
  if (!grepl("cleared", clear_result$message, ignore.case = TRUE)) {
    return("Cache clear failed")
  }
  
  # Check initial empty cache
  status1 <- get_cache_status()
  if (status1$total_cached != 0) {
    return("Cache not properly cleared")
  }
  
  # Generate and cache dataset
  size1 <- 1000
  dt1 <- get_cached_dataset(size1)
  
  # Check cache status
  status2 <- get_cache_status()
  if (status2$total_cached != 1) {
    return("Dataset not properly cached")
  }
  
  # Retrieve same dataset (should be identical)
  dt2 <- get_cached_dataset(size1)
  if (!identical(dt1, dt2)) {
    return("Cached dataset not identical to original")
  }
  
  # Test cache warming
  warm_sizes <- c(500, 2000)
  warm_result <- warm_cache(warm_sizes)
  
  status3 <- get_cache_status()
  if (status3$total_cached < 2) {  # Should have at least the warmed caches
    return("Cache warming failed")
  }
  
  TRUE
})

# Unit Test 7: Spatial filtering
run_test("Spatial filtering", function() {
  dt <- generate_volcano_data(1000)
  
  # Test spatial filter with reasonable ranges
  x_range <- c(-2, 2)
  y_range <- c(0, 3)
  
  filtered_dt <- apply_spatial_filter(dt, x_range, y_range)
  
  # Should filter some points
  if (nrow(filtered_dt) >= nrow(dt)) {
    return("Spatial filter did not reduce dataset size")
  }
  
  # Check that filtered points are within range
  if (any(filtered_dt$logFC < x_range[1] | filtered_dt$logFC > x_range[2])) {
    return("Spatial filter failed for X range")
  }
  
  y_values <- -log10(filtered_dt$padj)
  if (any(y_values < y_range[1] | y_values > y_range[2])) {
    return("Spatial filter failed for Y range")
  }
  
  TRUE
})

# Unit Test 8: Level-of-detail calculations
run_test("Level-of-detail calculations", function() {
  base_points <- 1000
  zoom_levels <- c(1.0, 2.0, 5.0, 10.0)
  
  lod_points <- sapply(zoom_levels, function(z) get_lod_max_points(z, base_points))
  
  # Should be increasing with zoom level
  if (!all(diff(lod_points) >= 0)) {
    return("LOD points not increasing with zoom level")
  }
  
  # Should be reasonable multiples
  if (lod_points[1] != base_points) {
    return("Base zoom level should return base points")
  }
  
  # Higher zoom should give more points
  if (lod_points[4] <= lod_points[1]) {
    return("Higher zoom level should allow more points")
  }
  
  TRUE
})

# Unit Test 9: Error handling and edge cases
run_test("Error handling and edge cases", function() {
  # Test with very small dataset
  small_dt <- generate_volcano_data(10)
  if (nrow(small_dt) != 10) {
    return("Small dataset generation failed")
  }
  
  # Test sampling with more points requested than available
  over_sampled <- intelligent_sampling(small_dt, 100, 1.0)
  if (nrow(over_sampled) > nrow(small_dt)) {
    return("Over-sampling created more points than available")
  }
  
  # Test categorization with extreme thresholds
  extreme_dt <- categorize_points(small_dt, 0.001, -10.0, 10.0)
  if (!"category" %in% names(extreme_dt)) {
    return("Extreme threshold categorization failed")
  }
  
  # Test empty search results
  empty_search <- small_dt[grepl("NONEXISTENT_METABOLITE_NAME", gene)]
  if (nrow(empty_search) != 0) {
    return("Empty search should return 0 results")
  }
  
  TRUE
})

# Unit Test 10: Data consistency and reproducibility
run_test("Data consistency and reproducibility", function() {
  # Generate same dataset multiple times
  size <- 1000
  dt1 <- generate_volcano_data(size)
  dt2 <- generate_volcano_data(size)
  
  # Should have same structure
  if (!identical(names(dt1), names(dt2))) {
    return("Generated datasets have different column names")
  }
  
  if (nrow(dt1) != nrow(dt2)) {
    return("Generated datasets have different row counts")
  }
  
  # Should have similar statistical properties
  mean_diff_logFC <- abs(mean(dt1$logFC) - mean(dt2$logFC))
  if (mean_diff_logFC > 0.1) {  # Allow some variation
    return("LogFC means too different between generations")
  }
  
  # Check that gene names follow expected pattern
  if (!all(grepl("^[A-Za-z]", dt1$gene))) {
    return("Gene names don't follow expected pattern")
  }
  
  # Check classification distributions are reasonable
  dt1_cat <- categorize_points(dt1, 0.05, -0.5, 0.5)
  cat_counts <- dt1_cat[, .N, by = category]
  
  non_sig_prop <- cat_counts[category == "non_significant", N] / nrow(dt1_cat)
  if (non_sig_prop < 0.7 || non_sig_prop > 0.95) {
    return(sprintf("Non-significant proportion unrealistic: %.3f", non_sig_prop))
  }
  
  TRUE
})

# Print test summary
cat(sprintf("\n=== Test Summary ===\n"))
cat(sprintf("Total tests: %d\n", test_count))
cat(sprintf("Passed: %d\n", passed_count))
cat(sprintf("Failed: %d\n", failed_count))
cat(sprintf("Success rate: %.1f%%\n", 100 * passed_count / test_count))

if (failed_count == 0) {
  cat("\n🎉 All R unit tests passed! The data generation and filtering functions are working correctly.\n")
  quit(status = 0)
} else {
  cat(sprintf("\n❌ %d tests failed. Please review the implementation.\n", failed_count))
  quit(status = 1)
}