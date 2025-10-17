#!/usr/bin/env Rscript

# Statistical validation test for R volcano plot data generation
# This test validates that the R implementation produces data with the same
# statistical properties as the Python implementation

cat("=== Statistical Validation of R Volcano Plot Data Generation ===\n\n")

# Load required libraries (will fail gracefully if not available)
packages_available <- TRUE
tryCatch({
  library(data.table)
  library(jsonlite)
}, error = function(e) {
  cat("Required packages not available. Please install with:\n")
  cat("Rscript install-packages.R\n")
  packages_available <<- FALSE
})

if (!packages_available) {
  quit(status = 1)
}

# Source the implementation
tryCatch({
  source("plumber-api.R")
}, error = function(e) {
  cat("Failed to source plumber-api.R:", e$message, "\n")
  quit(status = 1)
})

# Test parameters matching Python implementation
test_size <- 10000
p_threshold <- 0.05
log_fc_min <- -0.5
log_fc_max <- 0.5

cat(sprintf("Generating test dataset (size: %d)...\n", test_size))

# Generate test data
dt <- generate_volcano_data(test_size)

# Add categorization
dt <- categorize_points(dt, p_threshold, log_fc_min, log_fc_max)

cat(sprintf("Generated dataset: %d rows\n\n", nrow(dt)))

# Statistical validation tests
cat("1. Distribution Analysis:\n")

# Expected proportions from Python implementation
expected_non_sig <- 0.85
expected_up_reg <- 0.075
expected_down_reg <- 0.075

# Calculate actual proportions
category_counts <- dt[, .N, by = category]
setorder(category_counts, category)

total_points <- nrow(dt)
actual_proportions <- list()

for (i in 1:nrow(category_counts)) {
  cat_name <- category_counts$category[i]
  count <- category_counts$N[i]
  proportion <- count / total_points
  actual_proportions[[cat_name]] <- proportion
  
  cat(sprintf("   %s: %d points (%.3f)\n", cat_name, count, proportion))
}

cat("\n2. Proportion Validation:\n")

# Validate proportions are within reasonable range (±5% tolerance)
tolerance <- 0.05

validations <- list(
  list(name = "non_significant", actual = actual_proportions[["non_significant"]], expected = expected_non_sig),
  list(name = "up", actual = actual_proportions[["up"]], expected = expected_up_reg),
  list(name = "down", actual = actual_proportions[["down"]], expected = expected_down_reg)
)

all_valid <- TRUE
for (val in validations) {
  if (is.null(val$actual)) val$actual <- 0
  diff <- abs(val$actual - val$expected)
  is_valid <- diff <= tolerance
  
  status <- if (is_valid) "✓" else "✗"
  cat(sprintf("   %s %s: %.3f (expected %.3f, diff: %.3f)\n", 
              status, val$name, val$actual, val$expected, diff))
  
  if (!is_valid) all_valid <- FALSE
}

cat("\n3. Data Range Validation:\n")

# Validate logFC ranges
logfc_stats <- list(
  min = min(dt$logFC),
  max = max(dt$logFC),
  mean = mean(dt$logFC),
  sd = sd(dt$logFC)
)

cat(sprintf("   logFC range: %.3f to %.3f\n", logfc_stats$min, logfc_stats$max))
cat(sprintf("   logFC mean: %.3f (should be ~0)\n", logfc_stats$mean))
cat(sprintf("   logFC std dev: %.3f\n", logfc_stats$sd))

# Validate p-value ranges
padj_stats <- list(
  min = min(dt$padj),
  max = max(dt$padj),
  median = median(dt$padj)
)

cat(sprintf("   padj range: %.6f to %.6f\n", padj_stats$min, padj_stats$max))
cat(sprintf("   padj median: %.6f\n", padj_stats$median))

# Check for invalid values
invalid_logfc <- sum(is.na(dt$logFC) | is.infinite(dt$logFC))
invalid_padj <- sum(is.na(dt$padj) | is.infinite(dt$padj) | dt$padj < 0 | dt$padj > 1)

cat(sprintf("   Invalid logFC values: %d (should be 0)\n", invalid_logfc))
cat(sprintf("   Invalid padj values: %d (should be 0)\n", invalid_padj))

cat("\n4. Volcano Plot Shape Validation:\n")

# Check that significant points have appropriate fold changes
sig_up <- dt[category == "up"]
sig_down <- dt[category == "down"]
non_sig <- dt[category == "non_significant"]

if (nrow(sig_up) > 0) {
  up_logfc_mean <- mean(sig_up$logFC)
  up_padj_mean <- mean(sig_up$padj)
  cat(sprintf("   Up-regulated: mean logFC = %.3f (should be > %.1f), mean padj = %.6f\n", 
              up_logfc_mean, log_fc_max, up_padj_mean))
}

if (nrow(sig_down) > 0) {
  down_logfc_mean <- mean(sig_down$logFC)
  down_padj_mean <- mean(sig_down$padj)
  cat(sprintf("   Down-regulated: mean logFC = %.3f (should be < %.1f), mean padj = %.6f\n", 
              down_logfc_mean, log_fc_min, down_padj_mean))
}

if (nrow(non_sig) > 0) {
  nonsig_padj_mean <- mean(non_sig$padj)
  cat(sprintf("   Non-significant: mean padj = %.6f (should be > %.2f)\n", 
              nonsig_padj_mean, p_threshold))
}

cat("\n5. Reproducibility Test:\n")

# Test that the same seed produces identical results
dt1 <- generate_volcano_data(1000)
dt2 <- generate_volcano_data(1000)

if (identical(dt1, dt2)) {
  cat("   ✓ Reproducible results with same seed\n")
} else {
  cat("   ✗ Results not reproducible with same seed\n")
}

cat("\n6. Performance Test:\n")

# Test generation time for different sizes
sizes <- c(1000, 10000, 100000)
for (size in sizes) {
  start_time <- Sys.time()
  test_dt <- generate_volcano_data(size)
  end_time <- Sys.time()
  
  duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
  cat(sprintf("   Size %d: %.3f seconds (%.0f rows/sec)\n", 
              size, duration, size / duration))
}

cat("\n=== Statistical Validation Summary ===\n")

if (all_valid && invalid_logfc == 0 && invalid_padj == 0) {
  cat("✓ All statistical validations passed\n")
  cat("✓ Data generation matches Python implementation expectations\n")
  cat("✓ R implementation is ready for integration\n")
} else {
  cat("✗ Some validations failed\n")
  cat("✗ Review implementation for consistency with Python version\n")
}

cat("\n")