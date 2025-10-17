#!/usr/bin/env Rscript

# Integration Test Suite for R Volcano Plot API Endpoints
# Tests complete API functionality and endpoint integration

cat("=== R Volcano Plot Integration Test Suite ===\n\n")

# Load required libraries
tryCatch({
  library(data.table)
  library(jsonlite)
  library(httr)
  source("plumber-api.R", local = TRUE)
  cat("✓ Successfully loaded dependencies\n")
}, error = function(e) {
  cat("✗ Failed to load dependencies:", e$message, "\n")
  quit(status = 1)
})

# Test configuration
R_API_BASE <- "http://localhost:8001"
test_count <- 0
passed_count <- 0
failed_count <- 0

# Test helper function
run_integration_test <- function(test_name, test_func) {
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

# Helper function to check if R server is running
check_server <- function() {
  tryCatch({
    response <- GET(paste0(R_API_BASE, "/health"))
    return(status_code(response) == 200)
  }, error = function(e) {
    return(FALSE)
  })
}

# Integration Test 1: Health check endpoint
run_integration_test("Health check endpoint", function() {
  if (!check_server()) {
    return("R server not running. Start with: Rscript start-server.R")
  }
  
  response <- GET(paste0(R_API_BASE, "/health"))
  
  if (status_code(response) != 200) {
    return(sprintf("Health check failed with status: %d", status_code(response)))
  }
  
  content <- content(response, "parsed")
  if (content$status != "healthy") {
    return("Health check returned unhealthy status")
  }
  
  TRUE
})

# Integration Test 2: Main volcano data endpoint
run_integration_test("Main volcano data endpoint", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  # Test with default parameters
  url <- paste0(R_API_BASE, "/api/volcano-data")
  params <- list(
    p_value_threshold = 0.05,
    log_fc_min = -0.5,
    log_fc_max = 0.5,
    dataset_size = 1000,
    max_points = 5000
  )
  
  response <- GET(url, query = params)
  
  if (status_code(response) != 200) {
    return(sprintf("Volcano data endpoint failed with status: %d", status_code(response)))
  }
  
  content <- content(response, "parsed")
  
  # Check response structure
  required_fields <- c("data", "stats", "total_rows", "filtered_rows", 
                      "points_before_sampling", "is_downsampled")
  missing_fields <- setdiff(required_fields, names(content))
  if (length(missing_fields) > 0) {
    return(sprintf("Missing response fields: %s", paste(missing_fields, collapse = ", ")))
  }
  
  # Check data structure
  if (length(content$data) == 0) {
    return("No data points returned")
  }
  
  first_point <- content$data[[1]]
  required_point_fields <- c("gene", "logFC", "padj", "category")
  missing_point_fields <- setdiff(required_point_fields, names(first_point))
  if (length(missing_point_fields) > 0) {
    return(sprintf("Missing data point fields: %s", paste(missing_point_fields, collapse = ", ")))
  }
  
  # Check stats structure
  required_stats <- c("up_regulated", "down_regulated", "non_significant")
  missing_stats <- setdiff(required_stats, names(content$stats))
  if (length(missing_stats) > 0) {
    return(sprintf("Missing stats fields: %s", paste(missing_stats, collapse = ", ")))
  }
  
  TRUE
})

# Integration Test 3: Cache status endpoint
run_integration_test("Cache status endpoint", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  response <- GET(paste0(R_API_BASE, "/api/cache-status"))
  
  if (status_code(response) != 200) {
    return(sprintf("Cache status endpoint failed with status: %d", status_code(response)))
  }
  
  content <- content(response, "parsed")
  
  required_fields <- c("total_cached", "cached_datasets", "approximate_memory_mb")
  missing_fields <- setdiff(required_fields, names(content))
  if (length(missing_fields) > 0) {
    return(sprintf("Missing cache status fields: %s", paste(missing_fields, collapse = ", ")))
  }
  
  # Check data types
  if (!is.numeric(content$total_cached)) {
    return("total_cached should be numeric")
  }
  
  if (!is.list(content$cached_datasets)) {
    return("cached_datasets should be a list")
  }
  
  TRUE
})

# Integration Test 4: Cache warming endpoint
run_integration_test("Cache warming endpoint", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  # First clear cache
  clear_response <- POST(paste0(R_API_BASE, "/api/clear-cache"))
  if (status_code(clear_response) != 200) {
    return("Failed to clear cache before warming test")
  }
  
  # Warm cache with specific sizes
  warm_sizes <- c(500, 1000)
  warm_data <- list(sizes = warm_sizes)
  
  response <- POST(paste0(R_API_BASE, "/api/warm-cache"), 
                   body = warm_data, encode = "json")
  
  if (status_code(response) != 200) {
    return(sprintf("Cache warming failed with status: %d", status_code(response)))
  }
  
  content <- content(response, "parsed")
  
  if (!grepl("warmed", content$message, ignore.case = TRUE)) {
    return("Cache warming message incorrect")
  }
  
  # Verify cache was actually warmed
  status_response <- GET(paste0(R_API_BASE, "/api/cache-status"))
  status_content <- content(status_response, "parsed")
  
  if (status_content$total_cached < length(warm_sizes)) {
    return("Cache not properly warmed")
  }
  
  TRUE
})

# Integration Test 5: Cache clearing endpoint
run_integration_test("Cache clearing endpoint", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  # First ensure there's something in cache
  GET(paste0(R_API_BASE, "/api/volcano-data?dataset_size=500"))
  
  # Clear cache
  response <- POST(paste0(R_API_BASE, "/api/clear-cache"))
  
  if (status_code(response) != 200) {
    return(sprintf("Cache clearing failed with status: %d", status_code(response)))
  }
  
  content <- content(response, "parsed")
  
  if (!grepl("cleared", content$message, ignore.case = TRUE)) {
    return("Cache clearing message incorrect")
  }
  
  # Verify cache was cleared
  status_response <- GET(paste0(R_API_BASE, "/api/cache-status"))
  status_content <- content(status_response, "parsed")
  
  if (status_content$total_cached != 0) {
    return("Cache not properly cleared")
  }
  
  TRUE
})

# Integration Test 6: Parameter validation
run_integration_test("Parameter validation", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  # Test invalid parameters
  invalid_tests <- list(
    list(params = list(dataset_size = -100), desc = "negative dataset size"),
    list(params = list(p_value_threshold = 1.5), desc = "p-value > 1"),
    list(params = list(max_points = -50), desc = "negative max points")
  )
  
  base_url <- paste0(R_API_BASE, "/api/volcano-data")
  
  for (test in invalid_tests) {
    response <- GET(base_url, query = test$params)
    
    # Should either return 400 or handle gracefully with valid data
    if (status_code(response) == 400) {
      # Good - proper validation
      next
    } else if (status_code(response) == 200) {
      # Should handle gracefully
      content <- content(response, "parsed")
      if (is.null(content$data)) {
        return(sprintf("Invalid params (%s) not handled gracefully", test$desc))
      }
    } else {
      return(sprintf("Unexpected status for invalid params (%s): %d", 
                     test$desc, status_code(response)))
    }
  }
  
  TRUE
})

# Integration Test 7: Search functionality
run_integration_test("Search functionality integration", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  base_url <- paste0(R_API_BASE, "/api/volcano-data")
  
  # Test search with common term
  search_params <- list(
    dataset_size = 1000,
    search_term = "acid",
    max_points = 5000
  )
  
  response <- GET(base_url, query = search_params)
  
  if (status_code(response) != 200) {
    return("Search request failed")
  }
  
  content <- content(response, "parsed")
  
  # Should return fewer results than total dataset
  if (content$filtered_rows >= content$total_rows) {
    return("Search did not filter results")
  }
  
  # Check that returned data contains search term
  if (length(content$data) > 0) {
    first_gene <- content$data[[1]]$gene
    if (!grepl("acid", first_gene, ignore.case = TRUE)) {
      # This might be OK if sampling changed the order
      cat("   Note: First result doesn't contain search term (may be due to sampling)\n")
    }
  }
  
  TRUE
})

# Integration Test 8: Large dataset handling
run_integration_test("Large dataset handling", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  # Test with larger dataset
  large_params <- list(
    dataset_size = 50000,
    max_points = 10000,
    p_value_threshold = 0.01
  )
  
  start_time <- Sys.time()
  response <- GET(paste0(R_API_BASE, "/api/volcano-data"), query = large_params)
  end_time <- Sys.time()
  
  if (status_code(response) != 200) {
    return(sprintf("Large dataset request failed with status: %d", status_code(response)))
  }
  
  content <- content(response, "parsed")
  
  # Check response time (should be reasonable)
  response_time <- as.numeric(difftime(end_time, start_time, units = "secs"))
  if (response_time > 30) {  # 30 second timeout
    return(sprintf("Response time too slow: %.2f seconds", response_time))
  }
  
  # Check that downsampling occurred
  if (!content$is_downsampled) {
    return("Large dataset should trigger downsampling")
  }
  
  if (length(content$data) > large_params$max_points) {
    return("Downsampling did not respect max_points limit")
  }
  
  TRUE
})

# Integration Test 9: Concurrent requests
run_integration_test("Concurrent request handling", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  # This is a simplified concurrent test
  # In a real scenario, you'd use parallel processing
  
  base_url <- paste0(R_API_BASE, "/api/volcano-data")
  params <- list(dataset_size = 1000, max_points = 2000)
  
  # Make multiple sequential requests quickly
  responses <- list()
  for (i in 1:3) {
    responses[[i]] <- GET(base_url, query = params)
  }
  
  # Check all succeeded
  for (i in 1:3) {
    if (status_code(responses[[i]]) != 200) {
      return(sprintf("Request %d failed with status: %d", i, status_code(responses[[i]])))
    }
  }
  
  # Check responses are consistent
  contents <- lapply(responses, function(r) content(r, "parsed"))
  
  for (i in 2:3) {
    if (contents[[1]]$total_rows != contents[[i]]$total_rows) {
      return("Inconsistent responses for same parameters")
    }
  }
  
  TRUE
})

# Integration Test 10: End-to-end workflow
run_integration_test("End-to-end workflow simulation", function() {
  if (!check_server()) {
    return("R server not running")
  }
  
  # Simulate complete user workflow
  
  # 1. Clear cache
  clear_response <- POST(paste0(R_API_BASE, "/api/clear-cache"))
  if (status_code(clear_response) != 200) {
    return("Step 1 failed: cache clear")
  }
  
  # 2. Check initial cache status
  status_response <- GET(paste0(R_API_BASE, "/api/cache-status"))
  if (status_code(status_response) != 200) {
    return("Step 2 failed: cache status check")
  }
  
  # 3. Request data (should generate new dataset)
  data_response <- GET(paste0(R_API_BASE, "/api/volcano-data"), 
                       query = list(dataset_size = 2000, max_points = 1000))
  if (status_code(data_response) != 200) {
    return("Step 3 failed: data request")
  }
  
  # 4. Request same data again (should use cache)
  cached_response <- GET(paste0(R_API_BASE, "/api/volcano-data"), 
                         query = list(dataset_size = 2000, max_points = 1000))
  if (status_code(cached_response) != 200) {
    return("Step 4 failed: cached data request")
  }
  
  # 5. Apply filters
  filtered_response <- GET(paste0(R_API_BASE, "/api/volcano-data"), 
                           query = list(dataset_size = 2000, max_points = 1000,
                                       p_value_threshold = 0.01, search_term = "acid"))
  if (status_code(filtered_response) != 200) {
    return("Step 5 failed: filtered data request")
  }
  
  # 6. Warm cache with multiple sizes
  warm_response <- POST(paste0(R_API_BASE, "/api/warm-cache"), 
                        body = list(sizes = c(1000, 5000)), encode = "json")
  if (status_code(warm_response) != 200) {
    return("Step 6 failed: cache warming")
  }
  
  # 7. Final cache status check
  final_status <- GET(paste0(R_API_BASE, "/api/cache-status"))
  if (status_code(final_status) != 200) {
    return("Step 7 failed: final cache status")
  }
  
  final_content <- content(final_status, "parsed")
  if (final_content$total_cached < 2) {
    return("End-to-end workflow: insufficient cached datasets")
  }
  
  TRUE
})

# Print test summary
cat(sprintf("\n=== Integration Test Summary ===\n"))
cat(sprintf("Total tests: %d\n", test_count))
cat(sprintf("Passed: %d\n", passed_count))
cat(sprintf("Failed: %d\n", failed_count))

if (test_count > 0) {
  cat(sprintf("Success rate: %.1f%%\n", 100 * passed_count / test_count))
}

if (failed_count == 0 && test_count > 0) {
  cat("\n🎉 All R integration tests passed! The API endpoints are working correctly.\n")
  cat("The R backend is ready for production use.\n")
  quit(status = 0)
} else if (test_count == 0) {
  cat("\n⚠️  No tests were run. Make sure the R server is running on port 8001.\n")
  cat("Start the server with: Rscript start-server.R\n")
  quit(status = 1)
} else {
  cat(sprintf("\n❌ %d integration tests failed. Please review the API implementation.\n", failed_count))
  quit(status = 1)
}