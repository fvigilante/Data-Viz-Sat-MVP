#!/usr/bin/env Rscript

# Simple Performance Test - R vs Python Volcano Plot API
# Test di performance semplificato e funzionante

library(httr)
library(jsonlite)

cat("=== R vs PYTHON PERFORMANCE TEST ===\n\n")

# URLs delle API
r_url <- "http://localhost:8001/api/volcano-data"
python_url <- "http://localhost:8000/api/volcano-data"

# Test con diversi dataset sizes
test_sizes <- c(1000, 5000, 10000, 50000, 100000)
iterations <- 3

results <- data.frame(
  dataset_size = integer(),
  r_time_ms = numeric(),
  python_time_ms = numeric(),
  r_faster = numeric(),
  stringsAsFactors = FALSE
)

cat("Testing dataset sizes:", paste(test_sizes, collapse = ", "), "\n")
cat("Iterations per test:", iterations, "\n\n")

for (size in test_sizes) {
  cat("Testing dataset size:", size, "\n")
  
  # Test R API
  r_times <- numeric(iterations)
  for (i in 1:iterations) {
    start_time <- Sys.time()
    tryCatch({
      response <- GET(paste0(r_url, "?dataset_size=", size))
      if (status_code(response) == 200) {
        content(response, "parsed")
      }
    }, error = function(e) NULL)
    end_time <- Sys.time()
    r_times[i] <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
  }
  
  # Test Python API
  python_times <- numeric(iterations)
  for (i in 1:iterations) {
    start_time <- Sys.time()
    tryCatch({
      response <- GET(paste0(python_url, "?dataset_size=", size))
      if (status_code(response) == 200) {
        content(response, "parsed")
      }
    }, error = function(e) NULL)
    end_time <- Sys.time()
    python_times[i] <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
  }
  
  # Calcola medie
  r_avg <- mean(r_times, na.rm = TRUE)
  python_avg <- mean(python_times, na.rm = TRUE)
  speedup <- python_avg / r_avg
  
  # Aggiungi ai risultati
  results <- rbind(results, data.frame(
    dataset_size = size,
    r_time_ms = round(r_avg, 1),
    python_time_ms = round(python_avg, 1),
    r_faster = round(speedup, 2)
  ))
  
  cat("  R:", round(r_avg, 1), "ms")
  cat(" | Python:", round(python_avg, 1), "ms")
  cat(" | R is", round(speedup, 2), "x faster\n")
}

cat("\n=== PERFORMANCE SUMMARY ===\n")
print(results)

cat("\n=== PERFORMANCE MATRIX FOR DOCUMENTATION ===\n")
cat("| Dataset Size | R Time (ms) | Python Time (ms) | R Speedup |\n")
cat("|--------------|-------------|------------------|------------|\n")
for (i in 1:nrow(results)) {
  cat(sprintf("| %s | %s | %s | %sx |\n", 
              format(results$dataset_size[i], big.mark = ","),
              results$r_time_ms[i],
              results$python_time_ms[i],
              results$r_faster[i]))
}

cat("\nOverall average R speedup:", round(mean(results$r_faster), 2), "x\n")