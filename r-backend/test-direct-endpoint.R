#!/usr/bin/env Rscript

# Test diretto dell'endpoint per capire il problema

library(httr)
library(jsonlite)

cat("Testing R API endpoint directly...\n")

# Test con parametri molto espliciti
response <- GET("http://localhost:8001/api/volcano-data", 
               query = list(
                 dataset_size = "10000",
                 max_points = "5000",
                 p_value_threshold = "0.05",
                 log_fc_min = "-0.5",
                 log_fc_max = "0.5"
               ),
               timeout(30))

cat(sprintf("Status: %d\n", status_code(response)))

if (status_code(response) == 200) {
  cat("SUCCESS! Endpoint is working\n")
  response_data <- content(response, "parsed")
  cat(sprintf("Data points returned: %d\n", length(response_data$data)))
} else {
  cat("ERROR response:\n")
  error_content <- content(response, "text")
  cat(error_content, "\n")
}