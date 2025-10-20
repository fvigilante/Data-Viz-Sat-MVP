#!/usr/bin/env Rscript

# Test script for JSON conversion optimization
library(data.table)
library(jsonlite)

# Load only the functions we need without starting the server
source("plumber-api.R", local = TRUE)

# Create test data
test_dt <- data.table(
  gene = c("Gene_A", "Gene_B", "Gene_C"),
  logFC = c(1.5, -1.2, 0.3),
  padj = c(0.01, 0.02, 0.8),
  classyfireSuperclass = c("Organic acids", "Lipids", "Others"),
  classyfireClass = c("Carboxylic acids", "Fatty acids", "Unknown"),
  category = c("up", "down", "non_significant")
)

cat("Testing optimized JSON conversion...\n")
cat("Input data:\n")
print(test_dt)

# Test the optimized function
start_time <- Sys.time()
result <- convert_to_data_points_optimized(test_dt)
end_time <- Sys.time()

cat("\nOptimized conversion completed in", as.numeric(difftime(end_time, start_time, units = "secs")), "seconds\n")
cat("Result length:", length(result), "\n")
cat("First result item:\n")
print(result[[1]])

# Test performance metrics
cat("\nTesting performance metrics...\n")
metrics <- get_json_performance_metrics()
cat("Total conversions:", metrics$total_conversions, "\n")

cat("\nOptimization test completed successfully!\n")