#!/usr/bin/env Rscript

# Master Test Runner for R Volcano Plot Integration
# Runs all R-related tests in sequence

cat("=== R Volcano Plot Test Suite Runner ===\n\n")

# Test configuration
tests_to_run <- list(
  list(
    name = "Unit Tests (Data Generation & Filtering)",
    script = "test-comprehensive-suite.R",
    description = "Tests core R functions for data generation, filtering, and caching"
  ),
  list(
    name = "Integration Tests (API Endpoints)", 
    script = "test-integration-suite.R",
    description = "Tests R API endpoints and complete workflow integration"
  ),
  list(
    name = "Existing Volcano Endpoints",
    script = "test-volcano-endpoints.R", 
    description = "Tests volcano data processing endpoints"
  ),
  list(
    name = "Cache System Tests",
    script = "test-cache-endpoints.R",
    description = "Tests caching functionality and endpoints"
  ),
  list(
    name = "Data Generation Tests",
    script = "test-data-generation.R",
    description = "Tests synthetic data generation system"
  ),
  list(
    name = "Error Handling Tests",
    script = "test-error-handling.R",
    description = "Tests error handling and edge cases"
  )
)

# Results tracking
total_tests <- length(tests_to_run)
passed_tests <- 0
failed_tests <- 0
skipped_tests <- 0
test_results <- list()

cat(sprintf("Found %d test suites to run\n\n", total_tests))

# Run each test suite
for (i in seq_along(tests_to_run)) {
  test <- tests_to_run[[i]]
  
  cat(sprintf("[%d/%d] Running: %s\n", i, total_tests, test$name))
  cat(sprintf("Description: %s\n", test$description))
  cat(sprintf("Script: %s\n", test$script))
  
  if (!file.exists(test$script)) {
    cat("   ⚠️  SKIPPED - Test script not found\n\n")
    skipped_tests <- skipped_tests + 1
    test_results[[test$name]] <- "SKIPPED"
    next
  }
  
  # Run the test script
  start_time <- Sys.time()
  
  tryCatch({
    # Capture output and exit status
    result <- system2("Rscript", args = test$script, 
                     stdout = TRUE, stderr = TRUE, 
                     wait = TRUE)
    
    end_time <- Sys.time()
    duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
    
    # Check exit status
    exit_status <- attr(result, "status")
    if (is.null(exit_status)) exit_status <- 0
    
    if (exit_status == 0) {
      cat(sprintf("   ✅ PASSED (%.2f seconds)\n", duration))
      passed_tests <- passed_tests + 1
      test_results[[test$name]] <- "PASSED"
    } else {
      cat(sprintf("   ❌ FAILED (exit code: %d, %.2f seconds)\n", exit_status, duration))
      failed_tests <- failed_tests + 1
      test_results[[test$name]] <- "FAILED"
      
      # Show last few lines of output for debugging
      if (length(result) > 0) {
        cat("   Last output lines:\n")
        tail_lines <- tail(result, 3)
        for (line in tail_lines) {
          cat("     ", line, "\n")
        }
      }
    }
    
  }, error = function(e) {
    end_time <- Sys.time()
    duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
    
    cat(sprintf("   ❌ ERROR (%.2f seconds): %s\n", duration, e$message))
    failed_tests <- failed_tests + 1
    test_results[[test$name]] <- "ERROR"
  })
  
  cat("\n")
}

# Print summary
cat("=== Test Suite Summary ===\n")
cat(sprintf("Total test suites: %d\n", total_tests))
cat(sprintf("Passed: %d\n", passed_tests))
cat(sprintf("Failed: %d\n", failed_tests))
cat(sprintf("Skipped: %d\n", skipped_tests))

if (total_tests > 0) {
  success_rate <- (passed_tests / (total_tests - skipped_tests)) * 100
  cat(sprintf("Success rate: %.1f%%\n", success_rate))
}

cat("\n=== Detailed Results ===\n")
for (test_name in names(test_results)) {
  status <- test_results[[test_name]]
  status_icon <- switch(status,
    "PASSED" = "✅",
    "FAILED" = "❌", 
    "ERROR" = "💥",
    "SKIPPED" = "⚠️"
  )
  cat(sprintf("%s %s: %s\n", status_icon, test_name, status))
}

# Additional recommendations
cat("\n=== Recommendations ===\n")

if (failed_tests > 0) {
  cat("❌ Some tests failed. Please review the implementation:\n")
  cat("   - Check R backend server is running (for integration tests)\n")
  cat("   - Verify all required R packages are installed\n")
  cat("   - Review error messages above for specific issues\n")
}

if (skipped_tests > 0) {
  cat("⚠️  Some tests were skipped:\n")
  cat("   - Ensure all test scripts are present in r-backend directory\n")
  cat("   - Run individual test scripts to check for missing dependencies\n")
}

if (passed_tests == total_tests - skipped_tests && total_tests > 0) {
  cat("🎉 All available tests passed! The R integration is working correctly.\n")
  cat("\nNext steps:\n")
  cat("   - Run frontend tests: npm run test\n")
  cat("   - Run end-to-end tests: npm run test:integration\n")
  cat("   - Start the R server: Rscript start-server.R\n")
  cat("   - Test the complete application workflow\n")
}

# Exit with appropriate code
if (failed_tests > 0) {
  cat("\n❌ Test suite completed with failures.\n")
  quit(status = 1)
} else if (passed_tests == 0 && skipped_tests == total_tests) {
  cat("\n⚠️  All tests were skipped - nothing was actually tested.\n")
  quit(status = 1)
} else {
  cat("\n✅ Test suite completed successfully.\n")
  quit(status = 0)
}