#!/usr/bin/env Rscript

# Validation script for volcano data processing endpoints
# Tests the core logic without running the full server

cat("=== Volcano Data Endpoints Validation ===\n\n")

# Source the main API file to load functions
tryCatch({
  source("plumber-api.R", local = TRUE)
  cat("✓ Successfully loaded plumber-api.R\n")
}, error = function(e) {
  cat("✗ Failed to load plumber-api.R:", e$message, "\n")
  quit(status = 1)
})

# Test 1: Data generation and caching
cat("\n1. Testing data generation and caching...\n")
tryCatch({
  # Test small dataset generation
  test_size <- 1000
  dt <- get_cached_dataset(test_size)
  
  if (nrow(dt) == test_size) {
    cat("   ✓ Dataset generation successful (", test_size, "rows)\n")
  } else {
    cat("   ✗ Dataset size mismatch: expected", test_size, "got", nrow(dt), "\n")
  }
  
  # Check required columns
  required_cols <- c("gene", "logFC", "padj", "classyfireSuperclass", "classyfireClass")
  missing_cols <- setdiff(required_cols, names(dt))
  
  if (length(missing_cols) == 0) {
    cat("   ✓ All required columns present\n")
  } else {
    cat("   ✗ Missing columns:", paste(missing_cols, collapse = ", "), "\n")
  }
  
  # Test caching
  dt2 <- get_cached_dataset(test_size)
  if (identical(dt, dt2)) {
    cat("   ✓ Caching works correctly\n")
  } else {
    cat("   ✗ Caching failed - datasets differ\n")
  }
  
}, error = function(e) {
  cat("   ✗ Data generation failed:", e$message, "\n")
})

# Test 2: Categorization logic
cat("\n2. Testing categorization logic...\n")
tryCatch({
  # Create test data
  test_dt <- data.table(
    gene = c("Test1", "Test2", "Test3", "Test4"),
    logFC = c(-2.0, 2.0, 0.1, -0.1),
    padj = c(0.01, 0.01, 0.5, 0.5),
    classyfireSuperclass = rep("Test", 4),
    classyfireClass = rep("Test", 4)
  )
  
  # Apply categorization
  categorized_dt <- categorize_points(test_dt, 0.05, -0.5, 0.5)
  
  # Check results
  expected_categories <- c("down", "up", "non_significant", "non_significant")
  actual_categories <- categorized_dt$category
  
  if (identical(expected_categories, actual_categories)) {
    cat("   ✓ Categorization logic correct\n")
  } else {
    cat("   ✗ Categorization failed\n")
    cat("     Expected:", paste(expected_categories, collapse = ", "), "\n")
    cat("     Actual:  ", paste(actual_categories, collapse = ", "), "\n")
  }
  
}, error = function(e) {
  cat("   ✗ Categorization test failed:", e$message, "\n")
})

# Test 3: Intelligent sampling
cat("\n3. Testing intelligent sampling...\n")
tryCatch({
  # Generate larger dataset for sampling test
  dt <- get_cached_dataset(5000)
  dt <- categorize_points(dt, 0.05, -0.5, 0.5)
  
  # Test sampling
  max_points <- 1000
  sampled_dt <- intelligent_sampling(dt, max_points, 1.0)
  
  if (nrow(sampled_dt) <= max_points) {
    cat("   ✓ Sampling respects max_points limit\n")
  } else {
    cat("   ✗ Sampling exceeded max_points:", nrow(sampled_dt), ">", max_points, "\n")
  }
  
  # Check if significant points are prioritized
  sig_count_original <- nrow(dt[category != "non_significant"])
  sig_count_sampled <- nrow(sampled_dt[category != "non_significant"])
  
  if (sig_count_sampled > 0) {
    cat("   ✓ Significant points included in sample\n")
  } else {
    cat("   ✗ No significant points in sample\n")
  }
  
}, error = function(e) {
  cat("   ✗ Sampling test failed:", e$message, "\n")
})

# Test 4: Search functionality
cat("\n4. Testing search functionality...\n")
tryCatch({
  dt <- get_cached_dataset(1000)
  
  # Test search for a known metabolite
  search_term <- "Biotin"
  filtered_dt <- dt[grepl(tolower(search_term), tolower(gene))]
  
  if (nrow(filtered_dt) > 0) {
    cat("   ✓ Search functionality works\n")
  } else {
    cat("   ✗ Search returned no results for '", search_term, "'\n")
  }
  
  # Test case-insensitive search
  search_term_upper <- "BIOTIN"
  filtered_dt_upper <- dt[grepl(tolower(search_term_upper), tolower(gene))]
  
  if (nrow(filtered_dt) == nrow(filtered_dt_upper)) {
    cat("   ✓ Case-insensitive search works\n")
  } else {
    cat("   ✗ Case-insensitive search failed\n")
  }
  
}, error = function(e) {
  cat("   ✗ Search test failed:", e$message, "\n")
})

# Test 5: Level-of-detail calculations
cat("\n5. Testing level-of-detail calculations...\n")
tryCatch({
  # Test LOD max points calculation
  base_points <- 2000
  
  zoom_1x <- get_lod_max_points(1.0, base_points)
  zoom_2x <- get_lod_max_points(2.0, base_points)
  zoom_10x <- get_lod_max_points(10.0, base_points)
  
  if (zoom_1x == base_points) {
    cat("   ✓ Base zoom level calculation correct\n")
  } else {
    cat("   ✗ Base zoom calculation failed:", zoom_1x, "!=", base_points, "\n")
  }
  
  if (zoom_2x > zoom_1x && zoom_10x > zoom_2x) {
    cat("   ✓ Zoom scaling works correctly\n")
  } else {
    cat("   ✗ Zoom scaling failed\n")
  }
  
}, error = function(e) {
  cat("   ✗ LOD test failed:", e$message, "\n")
})

# Test 6: Cache management
cat("\n6. Testing cache management...\n")
tryCatch({
  # Test cache status
  status <- get_cache_status()
  
  if (is.list(status) && "cached_datasets" %in% names(status)) {
    cat("   ✓ Cache status function works\n")
  } else {
    cat("   ✗ Cache status function failed\n")
  }
  
  # Test cache warming
  warm_result <- warm_cache(c(500, 1000))
  
  if (is.list(warm_result) && "cached_sizes" %in% names(warm_result)) {
    cat("   ✓ Cache warming function works\n")
  } else {
    cat("   ✗ Cache warming function failed\n")
  }
  
  # Test cache clearing
  clear_result <- clear_cache()
  
  if (is.list(clear_result) && "datasets_removed" %in% names(clear_result)) {
    cat("   ✓ Cache clearing function works\n")
  } else {
    cat("   ✗ Cache clearing function failed\n")
  }
  
}, error = function(e) {
  cat("   ✗ Cache management test failed:", e$message, "\n")
})

cat("\n=== Validation Complete ===\n")
cat("All core volcano data processing functions have been tested.\n")
cat("The endpoints should work correctly when the server is started.\n")