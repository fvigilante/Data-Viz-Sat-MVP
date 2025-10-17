#!/usr/bin/env Rscript

# Simple test to verify R backend foundation is properly set up
# This script tests the basic structure and functionality

cat("=== R Backend Foundation Test ===\n\n")

# Test 1: Check if plumber-api.R exists and is readable
cat("1. Testing plumber-api.R file...\n")
if (file.exists("plumber-api.R")) {
  cat("   ✓ plumber-api.R exists\n")
  
  # Try to source the file to check for syntax errors
  tryCatch({
    source("plumber-api.R", local = TRUE)
    cat("   ✓ plumber-api.R syntax is valid\n")
  }, error = function(e) {
    cat("   ✗ Syntax error in plumber-api.R:", e$message, "\n")
  })
} else {
  cat("   ✗ plumber-api.R not found\n")
}

# Test 2: Check if required scripts exist
cat("\n2. Testing required scripts...\n")
required_files <- c(
  "install-packages.R",
  "validate-setup.R", 
  "start-server.sh",
  "start-server.bat",
  "README.md"
)

for (file in required_files) {
  if (file.exists(file)) {
    cat("   ✓", file, "exists\n")
  } else {
    cat("   ✗", file, "missing\n")
  }
}

# Test 3: Check if we can create a basic plumber object (if plumber is available)
cat("\n3. Testing basic plumber functionality...\n")
if (require("plumber", quietly = TRUE)) {
  tryCatch({
    # Create a minimal plumber object
    pr <- plumber$new()
    pr$handle("GET", "/test", function() list(status = "ok"))
    cat("   ✓ Basic plumber object creation successful\n")
  }, error = function(e) {
    cat("   ✗ Plumber object creation failed:", e$message, "\n")
  })
} else {
  cat("   ⚠ Plumber package not installed - run install-packages.R first\n")
}

cat("\n=== Test Complete ===\n")
cat("If all tests pass, the R backend foundation is properly set up.\n")
cat("Next: Run 'Rscript install-packages.R' to install required packages.\n")