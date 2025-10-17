#!/usr/bin/env Rscript

# R Backend Setup Validation Script
# This script validates that the R environment is properly configured

cat("=== R Backend Setup Validation ===\n\n")

# Check R version
cat("1. Checking R version...\n")
cat("   R Version:", R.version.string, "\n")

# Check if required packages can be loaded
required_packages <- c("plumber", "data.table", "jsonlite")
missing_packages <- c()

cat("\n2. Checking required packages...\n")

for (pkg in required_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    version <- packageVersion(pkg)
    cat("   ✓", pkg, "version", as.character(version), "\n")
  } else {
    cat("   ✗", pkg, "- NOT INSTALLED\n")
    missing_packages <- c(missing_packages, pkg)
  }
}

# Check if plumber can create a basic API
cat("\n3. Testing Plumber API creation...\n")
tryCatch({
  library(plumber)
  
  # Create a minimal API to test functionality
  pr <- plumber$new()
  pr$handle("GET", "/test", function() {
    list(status = "ok", message = "Plumber is working")
  })
  
  cat("   ✓ Plumber API creation successful\n")
  
}, error = function(e) {
  cat("   ✗ Plumber API creation failed:", e$message, "\n")
})

# Check data.table functionality
cat("\n4. Testing data.table functionality...\n")
tryCatch({
  library(data.table)
  
  # Create a test data.table
  dt <- data.table(x = 1:5, y = letters[1:5])
  result <- dt[x > 2]
  
  if (nrow(result) == 3) {
    cat("   ✓ data.table operations working correctly\n")
  } else {
    cat("   ✗ data.table operations not working as expected\n")
  }
  
}, error = function(e) {
  cat("   ✗ data.table test failed:", e$message, "\n")
})

# Check JSON functionality
cat("\n5. Testing JSON functionality...\n")
tryCatch({
  library(jsonlite)
  
  # Test JSON serialization/deserialization
  test_data <- list(status = "test", values = c(1, 2, 3))
  json_str <- toJSON(test_data, auto_unbox = TRUE)
  parsed_data <- fromJSON(json_str)
  
  if (parsed_data$status == "test" && length(parsed_data$values) == 3) {
    cat("   ✓ JSON operations working correctly\n")
  } else {
    cat("   ✗ JSON operations not working as expected\n")
  }
  
}, error = function(e) {
  cat("   ✗ JSON test failed:", e$message, "\n")
})

# Summary
cat("\n=== Validation Summary ===\n")

if (length(missing_packages) == 0) {
  cat("✓ All required packages are installed and working\n")
  cat("✓ R backend is ready for volcano plot API development\n")
  cat("\nNext steps:\n")
  cat("  1. Run 'Rscript plumber-api.R' to start the server\n")
  cat("  2. Test health endpoint: curl http://localhost:8001/health\n")
} else {
  cat("✗ Missing packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("✗ Run 'Rscript install-packages.R' to install missing packages\n")
}

cat("\n")