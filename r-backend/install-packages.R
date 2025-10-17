#!/usr/bin/env Rscript

# R Package Installation Script for Volcano Plot Backend
# This script installs all required R packages for the volcano plot API

cat("Installing required R packages for Volcano Plot API...\n")

# List of required packages
required_packages <- c(
  "plumber",      # Web API framework for R
  "data.table",   # High-performance data manipulation
  "jsonlite"      # JSON parsing and generation
)

# Function to install packages if not already installed
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat("Installing package:", pkg, "\n")
      install.packages(pkg, repos = "https://cran.r-project.org/")
      
      # Verify installation
      if (require(pkg, character.only = TRUE, quietly = TRUE)) {
        cat("✓ Successfully installed:", pkg, "\n")
      } else {
        cat("✗ Failed to install:", pkg, "\n")
        stop("Package installation failed")
      }
    } else {
      cat("✓ Package already installed:", pkg, "\n")
    }
  }
}

# Install packages
tryCatch({
  install_if_missing(required_packages)
  cat("\n✓ All required packages are installed successfully!\n")
  
  # Display package versions
  cat("\nInstalled package versions:\n")
  for (pkg in required_packages) {
    version <- packageVersion(pkg)
    cat("  ", pkg, ":", as.character(version), "\n")
  }
  
}, error = function(e) {
  cat("\n✗ Error during package installation:\n")
  cat(e$message, "\n")
  quit(status = 1)
})

cat("\nR backend setup complete!\n")