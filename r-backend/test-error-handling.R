#!/usr/bin/env Rscript

# Test script for R backend error handling and logging
# This script tests various error conditions and validates error responses

library(httr)
library(jsonlite)

# Configuration
BASE_URL <- "http://127.0.0.1:8001"
TEST_LOG_FILE <- "test-error-handling.log"

# Test results tracking
test_results <- list()
test_count <- 0

#' Log test results
log_test <- function(test_name, passed, message = "") {
  test_count <<- test_count + 1
  test_results[[test_count]] <<- list(
    name = test_name,
    passed = passed,
    message = message
  )
  
  status <- if (passed) "PASS" else "FAIL"
  cat(sprintf("[%s] %s: %s\n", status, test_name, message))
}

#' Test server health and availability
test_server_health <- function() {
  tryCatch({
    response <- GET(paste0(BASE_URL, "/health"))
    
    if (status_code(response) == 200) {
      content <- content(response, "parsed")
      if (!is.null(content$status) && content$status == "healthy") {
        log_test("Server Health Check", TRUE, "Server is healthy and responding")
        return(TRUE)
      } else {
        log_test("Server Health Check", FALSE, "Server responded but status is not healthy")
        return(FALSE)
      }
    } else {
      log_test("Server Health Check", FALSE, sprintf("Server returned status %d", status_code(response)))
      return(FALSE)
    }
  }, error = function(e) {
    log_test("Server Health Check", FALSE, sprintf("Cannot connect to server: %s", e$message))
    return(FALSE)
  })
}

#' Test parameter validation errors
test_parameter_validation <- function() {
  # Test invalid p_value_threshold
  tryCatch({
    response <- GET(paste0(BASE_URL, "/api/volcano-data"), 
                   query = list(p_value_threshold = 1.5))
    
    if (status_code(response) == 400) {
      content <- content(response, "parsed")
      if (!is.null(content$error) && content$error == TRUE) {
        log_test("Invalid p_value_threshold", TRUE, "Correctly rejected invalid p_value_threshold")
      } else {
        log_test("Invalid p_value_threshold", FALSE, "Did not return proper error structure")
      }
    } else {
      log_test("Invalid p_value_threshold", FALSE, sprintf("Expected 400, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Invalid p_value_threshold", FALSE, sprintf("Request failed: %s", e$message))
  })
  
  # Test invalid dataset_size
  tryCatch({
    response <- GET(paste0(BASE_URL, "/api/volcano-data"), 
                   query = list(dataset_size = 50))
    
    if (status_code(response) == 400) {
      content <- content(response, "parsed")
      if (!is.null(content$error_type) && content$error_type == "validation_error") {
        log_test("Invalid dataset_size", TRUE, "Correctly rejected invalid dataset_size")
      } else {
        log_test("Invalid dataset_size", FALSE, "Did not return proper error type")
      }
    } else {
      log_test("Invalid dataset_size", FALSE, sprintf("Expected 400, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Invalid dataset_size", FALSE, sprintf("Request failed: %s", e$message))
  })
  
  # Test invalid zoom_level
  tryCatch({
    response <- GET(paste0(BASE_URL, "/api/volcano-data"), 
                   query = list(zoom_level = 150))
    
    if (status_code(response) == 400) {
      content <- content(response, "parsed")
      if (!is.null(content$details$errors)) {
        log_test("Invalid zoom_level", TRUE, "Correctly rejected invalid zoom_level")
      } else {
        log_test("Invalid zoom_level", FALSE, "Did not return error details")
      }
    } else {
      log_test("Invalid zoom_level", FALSE, sprintf("Expected 400, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Invalid zoom_level", FALSE, sprintf("Request failed: %s", e$message))
  })
}

#' Test POST request with invalid JSON
test_invalid_json <- function() {
  tryCatch({
    response <- POST(paste0(BASE_URL, "/api/volcano-data"),
                    body = "invalid json {",
                    content_type("application/json"))
    
    if (status_code(response) == 500) {
      content <- content(response, "parsed")
      if (!is.null(content$error) && content$error == TRUE) {
        log_test("Invalid JSON Body", TRUE, "Correctly handled invalid JSON")
      } else {
        log_test("Invalid JSON Body", FALSE, "Did not return proper error structure")
      }
    } else {
      log_test("Invalid JSON Body", FALSE, sprintf("Expected 500, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Invalid JSON Body", FALSE, sprintf("Request failed: %s", e$message))
  })
}

#' Test POST request with empty body
test_empty_body <- function() {
  tryCatch({
    response <- POST(paste0(BASE_URL, "/api/volcano-data"),
                    body = "",
                    content_type("application/json"))
    
    if (status_code(response) == 400) {
      content <- content(response, "parsed")
      if (!is.null(content$error_type) && content$error_type == "missing_body") {
        log_test("Empty POST Body", TRUE, "Correctly rejected empty body")
      } else {
        log_test("Empty POST Body", FALSE, "Did not return proper error type")
      }
    } else {
      log_test("Empty POST Body", FALSE, sprintf("Expected 400, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Empty POST Body", FALSE, sprintf("Request failed: %s", e$message))
  })
}

#' Test cache operations error handling
test_cache_operations <- function() {
  # Test cache status
  tryCatch({
    response <- GET(paste0(BASE_URL, "/api/cache-status"))
    
    if (status_code(response) == 200) {
      content <- content(response, "parsed")
      if (!is.null(content$total_cached)) {
        log_test("Cache Status", TRUE, "Cache status retrieved successfully")
      } else {
        log_test("Cache Status", FALSE, "Cache status missing expected fields")
      }
    } else {
      log_test("Cache Status", FALSE, sprintf("Expected 200, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Cache Status", FALSE, sprintf("Request failed: %s", e$message))
  })
  
  # Test cache warming with invalid sizes
  tryCatch({
    response <- POST(paste0(BASE_URL, "/api/warm-cache"),
                    body = toJSON(list(sizes = c(50, 20000000)), auto_unbox = TRUE),
                    content_type("application/json"))
    
    if (status_code(response) == 200) {
      content <- content(response, "parsed")
      if (!is.null(content$failed_sizes) && length(content$failed_sizes) > 0) {
        log_test("Cache Warming with Invalid Sizes", TRUE, "Correctly handled invalid cache sizes")
      } else {
        log_test("Cache Warming with Invalid Sizes", FALSE, "Did not report failed sizes")
      }
    } else {
      log_test("Cache Warming with Invalid Sizes", FALSE, sprintf("Expected 200, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Cache Warming with Invalid Sizes", FALSE, sprintf("Request failed: %s", e$message))
  })
}

#' Test successful requests to ensure normal operation
test_successful_requests <- function() {
  # Test valid GET request
  tryCatch({
    response <- GET(paste0(BASE_URL, "/api/volcano-data"), 
                   query = list(dataset_size = 1000, max_points = 500))
    
    if (status_code(response) == 200) {
      content <- content(response, "parsed")
      if (!is.null(content$data) && !is.null(content$stats)) {
        log_test("Valid GET Request", TRUE, sprintf("Retrieved %d data points", length(content$data)))
      } else {
        log_test("Valid GET Request", FALSE, "Response missing expected fields")
      }
    } else {
      log_test("Valid GET Request", FALSE, sprintf("Expected 200, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Valid GET Request", FALSE, sprintf("Request failed: %s", e$message))
  })
  
  # Test valid POST request
  tryCatch({
    request_body <- list(
      dataset_size = 1000,
      max_points = 500,
      p_value_threshold = 0.05,
      search_term = "metabolite"
    )
    
    response <- POST(paste0(BASE_URL, "/api/volcano-data"),
                    body = toJSON(request_body, auto_unbox = TRUE),
                    content_type("application/json"))
    
    if (status_code(response) == 200) {
      content <- content(response, "parsed")
      if (!is.null(content$data) && !is.null(content$stats)) {
        log_test("Valid POST Request", TRUE, sprintf("Retrieved %d data points with search", length(content$data)))
      } else {
        log_test("Valid POST Request", FALSE, "Response missing expected fields")
      }
    } else {
      log_test("Valid POST Request", FALSE, sprintf("Expected 200, got %d", status_code(response)))
    }
  }, error = function(e) {
    log_test("Valid POST Request", FALSE, sprintf("Request failed: %s", e$message))
  })
}

#' Run all tests
run_all_tests <- function() {
  cat("=== R Backend Error Handling and Logging Tests ===\n\n")
  
  # Check if server is running
  if (!test_server_health()) {
    cat("\nServer is not available. Please start the R backend server first.\n")
    cat("Run: Rscript r-backend/plumber-api.R\n")
    return(FALSE)
  }
  
  cat("\nRunning error handling tests...\n")
  test_parameter_validation()
  test_invalid_json()
  test_empty_body()
  test_cache_operations()
  
  cat("\nRunning successful operation tests...\n")
  test_successful_requests()
  
  # Summary
  cat("\n=== Test Summary ===\n")
  passed_tests <- sum(sapply(test_results, function(x) x$passed))
  total_tests <- length(test_results)
  
  cat(sprintf("Passed: %d/%d tests (%.1f%%)\n", passed_tests, total_tests, 
              passed_tests / total_tests * 100))
  
  if (passed_tests < total_tests) {
    cat("\nFailed tests:\n")
    for (result in test_results) {
      if (!result$passed) {
        cat(sprintf("- %s: %s\n", result$name, result$message))
      }
    }
  }
  
  return(passed_tests == total_tests)
}

# Run tests if script is executed directly
if (!interactive()) {
  success <- run_all_tests()
  if (!success) {
    quit(status = 1)
  }
}