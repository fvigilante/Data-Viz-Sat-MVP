#!/usr/bin/env Rscript

# Test finale delle performance dopo ottimizzazione
# Confronta R ottimizzato vs Python

library(httr)
library(jsonlite)

# Configurazione test
TEST_CONFIG <- list(
  r_url = "http://localhost:8001",
  python_url = "http://localhost:8000",
  test_sizes = c(10000, 50000, 100000),
  iterations = 5
)

#' Testa performance di un singolo endpoint
#' @param url URL base dell'API
#' @param endpoint Endpoint da testare
#' @param params Parametri della richiesta
#' @param name Nome dell'API per il logging
#' @return Lista con risultati performance
test_api_performance <- function(url, endpoint, params, name) {
  
  cat(sprintf("Testing %s (size: %s)...\n", name, format(params$dataset_size, big.mark = ",")))
  
  times_ms <- c()
  errors <- c()
  response_sizes <- c()
  
  for (i in 1:TEST_CONFIG$iterations) {
    tryCatch({
      start_time <- Sys.time()
      
      response <- GET(paste0(url, endpoint), query = params, timeout(60))
      
      end_time <- Sys.time()
      duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      
      if (status_code(response) == 200) {
        times_ms <- c(times_ms, duration_ms)
        
        # Get response size
        response_data <- content(response, "parsed")
        if (!is.null(response_data$data)) {
          response_sizes <- c(response_sizes, length(response_data$data))
        }
        
        cat(sprintf("  Iteration %d: %.1f ms (%d points)\n", i, duration_ms, 
                   if (length(response_sizes) > 0) tail(response_sizes, 1) else 0))
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
    median_ms <- median(times_ms)
    min_ms <- min(times_ms)
    max_ms <- max(times_ms)
    
    cat(sprintf("  %s Results: Mean=%.1fms, Median=%.1fms, Min=%.1fms, Max=%.1fms\n", 
               name, mean_ms, median_ms, min_ms, max_ms))
    
    return(list(
      name = name,
      dataset_size = params$dataset_size,
      mean_ms = mean_ms,
      median_ms = median_ms,
      min_ms = min_ms,
      max_ms = max_ms,
      times = times_ms,
      successful_iterations = length(times_ms),
      avg_response_size = if (length(response_sizes) > 0) mean(response_sizes) else 0,
      errors = errors
    ))
  } else {
    cat(sprintf("  %s: ALL FAILED\n", name))
    return(list(
      name = name,
      dataset_size = params$dataset_size,
      mean_ms = Inf,
      successful_iterations = 0,
      errors = errors
    ))
  }
}

#' Esegui test completo delle performance
execute_final_performance_test <- function() {
  
  cat("=== FINAL PERFORMANCE TEST: OPTIMIZED R vs PYTHON ===\n")
  cat("Testing multiple dataset sizes with optimized R implementation\n\n")
  
  # Controlla disponibilità APIs
  cat("Checking API availability...\n")
  
  # Check R API
  r_available <- tryCatch({
    response <- GET(paste0(TEST_CONFIG$r_url, "/health"), timeout(10))
    if (status_code(response) == 200) {
      health_data <- content(response, "parsed")
      cat("R API: ✅ Available -", health_data$backend %||% "R API", "\n")
      TRUE
    } else {
      cat("R API: ❌ HTTP", status_code(response), "\n")
      FALSE
    }
  }, error = function(e) {
    cat("R API: ❌ Not available -", e$message, "\n")
    FALSE
  })
  
  # Check Python API
  python_available <- tryCatch({
    response <- GET(paste0(TEST_CONFIG$python_url, "/health"), timeout(10))
    if (status_code(response) == 200) {
      cat("Python API: ✅ Available - FastAPI\n")
      True
    } else {
      cat("Python API: ❌ HTTP", status_code(response), "\n")
      FALSE
    }
  }, error = function(e) {
    cat("Python API: ❌ Not available -", e$message, "\n")
    FALSE
  })
  
  if (!r_available || !python_available) {
    stop("Required APIs are not available")
  }
  
  cat("\n")
  
  # Warm up caches
  cat("Warming up caches...\n")
  tryCatch({
    POST(paste0(TEST_CONFIG$r_url, "/api/warm-cache"),
         body = list(sizes = TEST_CONFIG$test_sizes),
         encode = "json", timeout(60))
    cat("R API cache warmed\n")
  }, error = function(e) {
    cat("Warning: R cache warming failed:", e$message, "\n")
  })
  
  tryCatch({
    POST(paste0(TEST_CONFIG$python_url, "/api/warm-cache"),
         body = TEST_CONFIG$test_sizes,
         encode = "json", timeout(60))
    cat("Python API cache warmed\n")
  }, error = function(e) {
    cat("Warning: Python cache warming failed:", e$message, "\n")
  })
  
  cat("\n")
  
  # Test per ogni dimensione dataset
  all_results <- list()
  
  for (size in TEST_CONFIG$test_sizes) {
    cat("=" %R% 50, "\n")
    cat(sprintf("TESTING DATASET SIZE: %s\n", format(size, big.mark = ",")))
    cat("=" %R% 50, "\n")
    
    # Parametri test
    test_params <- list(
      dataset_size = size,
      max_points = min(50000, size),
      p_value_threshold = 0.05,
      log_fc_min = -0.5,
      log_fc_max = 0.5
    )
    
    # Test Python API
    python_result <- test_api_performance(
      TEST_CONFIG$python_url, "/api/volcano-data", test_params, "Python FastAPI"
    )
    
    cat("\n")
    
    # Test R API (ottimizzato)
    r_result <- test_api_performance(
      TEST_CONFIG$r_url, "/api/volcano-data", test_params, "Optimized R API"
    )
    
    # Analisi confronto per questa dimensione
    if (python_result$mean_ms < Inf && r_result$mean_ms < Inf) {
      speedup_factor <- python_result$mean_ms / r_result$mean_ms
      overhead_percent <- ((r_result$mean_ms - python_result$mean_ms) / python_result$mean_ms) * 100
      
      cat(sprintf("\n--- COMPARISON FOR SIZE %s ---\n", format(size, big.mark = ",")))
      cat(sprintf("Python: %.1f ms\n", python_result$mean_ms))
      cat(sprintf("R: %.1f ms\n", r_result$mean_ms))
      
      if (speedup_factor > 1) {
        cat(sprintf("🎉 R is %.1fx FASTER than Python!\n", speedup_factor))
      } else {
        cat(sprintf("R is %.1fx slower than Python (%.1f%% overhead)\n", 1/speedup_factor, overhead_percent))
      }
      
      # Performance assessment
      if (overhead_percent <= 50) {
        cat("✅ EXCELLENT: Performance target met!\n")
      } else if (overhead_percent <= 100) {
        cat("✅ GOOD: Acceptable performance\n")
      } else {
        cat("⚠️  NEEDS IMPROVEMENT: Performance target not met\n")
      }
    }
    
    # Store results
    all_results[[as.character(size)]] <- list(
      size = size,
      python = python_result,
      r = r_result
    )
    
    cat("\n")
  }
  
  # Analisi finale
  analyze_final_results(all_results)
  
  return(all_results)
}

#' Analizza risultati finali
#' @param results Lista con tutti i risultati
analyze_final_results <- function(results) {
  
  cat("=" %R% 60, "\n")
  cat("=== FINAL PERFORMANCE ANALYSIS ===\n")
  cat("=" %R% 60, "\n")
  
  # Tabella riassuntiva
  cat("PERFORMANCE SUMMARY:\n")
  cat(sprintf("%-12s | %-12s | %-12s | %-12s | %-10s\n", 
             "Dataset Size", "Python (ms)", "R (ms)", "Speedup", "Status"))
  cat("-" %R% 70, "\n")
  
  targets_met <- 0
  total_tests <- 0
  
  for (size_key in names(results)) {
    result <- results[[size_key]]
    python_ms <- result$python$mean_ms
    r_ms <- result$r$mean_ms
    
    if (python_ms < Inf && r_ms < Inf) {
      speedup <- python_ms / r_ms
      overhead_pct <- ((r_ms - python_ms) / python_ms) * 100
      
      status <- if (overhead_pct <= 50) {
        targets_met <- targets_met + 1
        "✅ PASS"
      } else {
        "❌ FAIL"
      }
      
      speedup_text <- if (speedup > 1) {
        sprintf("%.1fx faster", speedup)
      } else {
        sprintf("%.1fx slower", 1/speedup)
      }
      
      cat(sprintf("%-12s | %-12.1f | %-12.1f | %-12s | %-10s\n",
                 format(result$size, big.mark = ","),
                 python_ms, r_ms, speedup_text, status))
      
      total_tests <- total_tests + 1
    }
  }
  
  cat("-" %R% 70, "\n")
  
  # Statistiche finali
  success_rate <- if (total_tests > 0) (targets_met / total_tests) * 100 else 0
  
  cat(sprintf("\nFINAL RESULTS:\n"))
  cat(sprintf("Tests Passed: %d/%d (%.1f%%)\n", targets_met, total_tests, success_rate))
  
  if (success_rate >= 75) {
    cat("\n🎉 OPTIMIZATION SUCCESS!\n")
    cat("   ✓ R performance optimization achieved\n")
    cat("   ✓ Performance targets met\n")
    cat("   ✓ Ready for production deployment\n")
  } else if (success_rate >= 50) {
    cat("\n✅ PARTIAL SUCCESS\n")
    cat("   ✓ Significant performance improvements achieved\n")
    cat("   ⚠️  Some targets not met - consider further optimization\n")
  } else {
    cat("\n⚠️  OPTIMIZATION INCOMPLETE\n")
    cat("   ❌ Performance targets not consistently met\n")
    cat("   📋 Further optimization required\n")
  }
  
  cat("=" %R% 60, "\n")
}

# Helper function
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution
main <- function() {
  tryCatch({
    results <- execute_final_performance_test()
    
    # Salva risultati
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    saveRDS(results, sprintf("final_performance_results_%s.rds", timestamp))
    cat(sprintf("\nResults saved to: final_performance_results_%s.rds\n", timestamp))
    
    # Determina exit code basato sui risultati
    targets_met <- 0
    total_tests <- 0
    
    for (size_key in names(results)) {
      result <- results[[size_key]]
      if (result$python$mean_ms < Inf && result$r$mean_ms < Inf) {
        overhead_pct <- ((result$r$mean_ms - result$python$mean_ms) / result$python$mean_ms) * 100
        if (overhead_pct <= 50) targets_met <- targets_met + 1
        total_tests <- total_tests + 1
      }
    }
    
    success_rate <- if (total_tests > 0) (targets_met / total_tests) * 100 else 0
    exit_code <- if (success_rate >= 75) 0 else 1
    
    quit(save = "no", status = exit_code)
    
  }, error = function(e) {
    cat("Error during final performance test:", e$message, "\n")
    quit(save = "no", status = 1)
  })
}

# Execute if run directly
if (!interactive()) {
  main()
}