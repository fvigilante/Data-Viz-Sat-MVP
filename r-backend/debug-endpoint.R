#!/usr/bin/env Rscript

# Debug dell'endpoint volcano-data

library(httr)
library(jsonlite)

# Test con parametri espliciti
cat("Testing volcano-data endpoint...\n")

response <- GET("http://localhost:8001/api/volcano-data", 
               query = list(
                 dataset_size = 10000,
                 max_points = 5000,
                 p_value_threshold = 0.05,
                 log_fc_min = -0.5,
                 log_fc_max = 0.5
               ))

cat(sprintf("Status: %d\n", status_code(response)))

if (status_code(response) != 200) {
  cat("Error response:\n")
  error_content <- content(response, "text")
  cat(error_content, "\n")
} else {
  cat("Success!\n")
  response_data <- content(response, "parsed")
  cat(sprintf("Data points returned: %d\n", length(response_data$data)))
}