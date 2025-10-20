#!/usr/bin/env Rscript

# Test Performance Comparison: Original vs Optimized R API
# Confronta le performance tra API R originale e ottimizzata

library(httr)
library(jsonlite)

# Configurazione test
TEST_CONFIG <- list(
  original_r_url = "http://localhost:8001",
  optimized_r_url = "http://localhost:8002", 
  python_url = "http://localhost:8000",
  test_size = 10000,
  iterations = 3
)

#' Testa performance di un singolo endpoint
#' @param url URL base dell'API
#' @param endpoint Endpoint da testare
#' @param params Parametri della richiesta
#' @param name Nome dell'API per il logging
#' @return Lista con risultati performance
test_api_performance <- function(url, endpoint, params, name) {
  
  cat(sprintf("Testing %s...\n", name))
  
  times_ms <- c()
  errors <- c()
  
  for (i in 1:TEST_CONFIG$iterations) {
    tryCatch({
      start_time <- Sys.time()
      
      response <- GET(paste0(url, endpoint), query = params, timeout(30))
      
      end_time <- Sys.time()
      duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      
      if (status_code(response) == 200) {
        times_ms <- c(times_ms, duration_ms)
        cat(sprintf("  Iteration %d: %.1f ms\n", i, duration_ms))
      } else {
        errors <- c(errors, paste("HTTP", status_code(response)))
        cat(sprintf("  Iteration %d: ERROR HTTP %d\n", i, status_code(response)))
      }
      
    }, error = function(e) {
      errors <- c(errors, e$message)
      cat(sprintf("  Iteration %d: ERROR %s\n", i, e$message))
    })
  }
  
  if (length(times_ms) > 0) {
    mean_ms <- mean(times_ms)
    cat(sprintf("  %s Average: %.1f ms\n", name, mean_ms))
    
    return(list(
      name = name,
      mean_ms = mean_ms,
      times = times_ms,
      successful_iterations = length(times_ms),
      errors = errors
    ))
  } else {
    cat(sprintf("  %s: ALL FAILED\n", name))
    return(list(
      name = name,
      mean_ms = Inf,
      times = c(),
      successful_iterations = 0,
      errors = errors
    ))
  }
}

#' Esegui confronto performance completo
execute_performance_comparison <- function() {
  
  cat("=== PERFORMANCE COMPARISON: ORIGINAL vs OPTIMIZED R API ===\n")
  cat("Testing with dataset size:", TEST_CONFIG$test_size, "\n\n")
  
  # Parametri test
  test_params <- list(
    dataset_size = TEST_CONFIG$test_size,
    max_points = 5000,
    p_value_threshold = 0.05,
    log_fc_min = -0.5,
    log_fc_max = 0.5
  )
  
  results <- list()
  
  # Test Python API (baseline)
  cat("1. PYTHON API (Baseline)\n")
  cat("=" %R% 30, "\n")
  results$python <- test_api_performance(
    TEST_CONFIG$python_url, "/api/volcano-data", test_params, "Python FastAPI"
  )
  
  cat("\n")
  
  # Test Original R API
  cat("2. ORIGINAL R API (With Monitoring)\n")
  cat("=" %R% 30, "\n")
  results$original_r <- test_api_performance(
    TEST_CONFIG$original_r_url, "/api/volcano-data", test_params, "Original R API"
  )
  
  cat("\n")
  
  # Test Optimized R API
  cat("3. OPTIMIZED R API (No Monitoring)\n")
  cat("=" %R% 30, "\n")
  results$optimized_r <- test_api_performance(
    TEST_CONFIG$optimized_r_url, "/api/volcano-data", test_params, "Optimized R API"
  )
  
  cat("\n")
  
  # Analisi risultati
  analyze_results(results)
  
  return(results)
}

#' Analizza e presenta i risultati del confronto
#' @param results Lista con risultati di tutti i test
analyze_results <- function(results) {
  
  cat("=" %R% 60, "\n")
  cat("=== PERFORMANCE ANALYSIS ===\n")
  cat("=" %R% 60, "\n")
  
  python_ms <- results$python$mean_ms
  original_r_ms <- results$original_r$mean_ms
  optimized_r_ms <- results$optimized_r$mean_ms
  
  cat(sprintf("Python FastAPI:     %.1f ms\n", python_ms))
  cat(sprintf("Original R API:     %.1f ms\n", original_r_ms))
  cat(sprintf("Optimized R API:    %.1f ms\n", optimized_r_ms))
  
  cat("\n--- PERFORMANCE RATIOS ---\n")
  
  if (python_ms < Inf && original_r_ms < Inf) {
    original_slowdown <- original_r_ms / python_ms
    cat(sprintf("Original R vs Python:   %.1fx slower\n", original_slowdown))
  }
  
  if (python_ms < Inf && optimized_r_ms < Inf) {
    optimized_slowdown <- optimized_r_ms / python_ms
    cat(sprintf("Optimized R vs Python:  %.1fx slower\n", optimized_slowdown))
  }
  
  if (original_r_ms < Inf && optimized_r_ms < Inf) {
    optimization_improvement <- original_r_ms / optimized_r_ms
    improvement_percent <- ((original_r_ms - optimized_r_ms) / original_r_ms) * 100
    cat(sprintf("Optimization Improvement: %.1fx faster (%.1f%% reduction)\n", 
               optimization_improvement, improvement_percent))
  }
  
  cat("\n--- MONITORING OVERHEAD ANALYSIS ---\n")
  
  if (original_r_ms < Inf && optimized_r_ms < Inf) {
    monitoring_overhead_ms <- original_r_ms - optimized_r_ms
    monitoring_overhead_percent <- (monitoring_overhead_ms / original_r_ms) * 100
    
    cat(sprintf("Monitoring Overhead:    %.1f ms (%.1f%% of total time)\n", 
               monitoring_overhead_ms, monitoring_overhead_percent))
    
    if (monitoring_overhead_percent > 50) {
      cat("🔴 CRITICAL: Monitoring overhead is >50% of total response time!\n")
    } else if (monitoring_overhead_percent > 25) {
      cat("⚠️  WARNING: Monitoring overhead is >25% of total response time\n")
    } else {
      cat("✅ Monitoring overhead is acceptable (<25%)\n")
    }
  }
  
  cat("\n--- RECOMMENDATIONS ---\n")
  
  if (optimized_r_ms < Inf && python_ms < Inf) {
    if (optimized_r_ms <= python_ms * 1.5) {  # Within 50% of Python
      cat("🎉 SUCCESS: Optimized R is within 50% of Python performance!\n")
      cat("   Recommendation: Remove monitoring overhead from production API\n")
    } else if (optimized_r_ms <= python_ms * 2.0) {  # Within 100% of Python
      cat("✅ GOOD: Optimized R is within 100% of Python performance\n")
      cat("   Recommendation: Consider removing monitoring for better performance\n")
    } else {
      cat("⚠️  NEEDS WORK: Optimized R still significantly slower than Python\n")
      cat("   Recommendation: Further optimization needed beyond monitoring removal\n")
    }
  }
  
  cat("=" %R% 60, "\n")
}

# Helper function
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution
main <- function() {
  
  # Controlla disponibilità APIs
  cat("Checking API availability...\n")
  
  apis_available <- TRUE
  
  # Check Python API
  tryCatch({
    response <- GET(paste0(TEST_CONFIG$python_url, "/health"), timeout(5))
    if (status_code(response) == 200) {
      cat("Python API: ✅ Available\n")
    } else {
      cat("Python API: ❌ Not responding\n")
      apis_available <- FALSE
    }
  }, error = function(e) {
    cat("Python API: ❌ Not available\n")
    apis_available <- FALSE
  })
  
  # Check Original R API
  tryCatch({
    response <- GET(paste0(TEST_CONFIG$original_r_url, "/health"), timeout(5))
    if (status_code(response) == 200) {
      cat("Original R API: ✅ Available\n")
    } else {
      cat("Original R API: ❌ Not responding\n")
      apis_available <- FALSE
    }
  }, error = function(e) {
    cat("Original R API: ❌ Not available\n")
    apis_available <- FALSE
  })
  
  # Check Optimized R API
  tryCatch({
    response <- GET(paste0(TEST_CONFIG$optimized_r_url, "/health"), timeout(5))
    if (status_code(response) == 200) {
      cat("Optimized R API: ✅ Available\n")
    } else {
      cat("Optimized R API: ❌ Not responding\n")
      apis_available <- FALSE
    }
  }, error = function(e) {
    cat("Optimized R API: ❌ Not available\n")
    apis_available <- FALSE
  })
  
  if (!apis_available) {
    cat("\nError: Not all APIs are available. Please start all required servers.\n")
    quit(save = "no", status = 1)
  }
  
  cat("\n")
  
  # Esegui test performance
  tryCatch({
    results <- execute_performance_comparison()
    
    # Salva risultati
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    saveRDS(results, sprintf("optimization_comparison_%s.rds", timestamp))
    cat(sprintf("\nResults saved to: optimization_comparison_%s.rds\n", timestamp))
    
  }, error = function(e) {
    cat("Error during performance comparison:", e$message, "\n")
    quit(save = "no", status = 1)
  })
}

# Execute if run directly
if (!interactive()) {
  main()
}