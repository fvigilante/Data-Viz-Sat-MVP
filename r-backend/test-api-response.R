#!/usr/bin/env Rscript

# Test della risposta API per capire perché il plot è vuoto

library(httr)
library(jsonlite)

cat("Testing R API response...\n")

response <- GET("http://localhost:8001/api/volcano-data", 
               query = list(
                 dataset_size = 10000,
                 max_points = 5000,
                 p_value_threshold = 0.05,
                 log_fc_min = -0.5,
                 log_fc_max = 0.5
               ))

cat(sprintf("Status: %d\n", status_code(response)))

if (status_code(response) == 200) {
  data <- content(response, "parsed")
  
  cat("=== RESPONSE ANALYSIS ===\n")
  cat(sprintf("Data points returned: %d\n", length(data$data)))
  cat(sprintf("Total rows: %s\n", data$total_rows))
  cat(sprintf("Filtered rows: %s\n", data$filtered_rows))
  cat(sprintf("Is downsampled: %s\n", data$is_downsampled))
  
  if (!is.null(data$stats)) {
    cat("Statistics:\n")
    cat(sprintf("  Up regulated: %s\n", data$stats$up_regulated))
    cat(sprintf("  Down regulated: %s\n", data$stats$down_regulated))
    cat(sprintf("  Non significant: %s\n", data$stats$non_significant))
  }
  
  if (length(data$data) > 0) {
    cat("\nFirst data point:\n")
    first_point <- data$data[[1]]
    cat(sprintf("  Gene: %s\n", first_point$gene))
    cat(sprintf("  LogFC: %s\n", first_point$logFC))
    cat(sprintf("  P-adj: %s\n", first_point$padj))
    cat(sprintf("  Category: %s\n", first_point$category))
  } else {
    cat("\n❌ NO DATA POINTS RETURNED!\n")
  }
  
} else {
  cat("ERROR response:\n")
  error_content <- content(response, "text")
  cat(error_content, "\n")
}