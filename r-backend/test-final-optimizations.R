#!/usr/bin/env Rscript

# Test finale delle ottimizzazioni implementate
# Confronta performance con e senza monitoring

library(data.table)
library(jsonlite)
library(httr)

# Carica le funzioni ottimizzate
source("r-backend/plumber-api-production.R")

cat("=== TEST FINALE OTTIMIZZAZIONI R ===\n")
cat("Confronto performance con feature flag di monitoring\n\n")

test_size <- 10000

# Test 1: PRODUCTION MODE (MONITOR_ENABLED = FALSE)
cat("1. PRODUCTION MODE (MONITOR_ENABLED = FALSE)\n")
cat("=" %R% 40, "\n")

# Simula ambiente production
assign("MONITOR_ENABLED", FALSE, envir = .GlobalEnv)

times_production <- c()
for (i in 1:3) {
  start_time <- Sys.time()
  
  result <- process_volcano_pipeline_fast(
    dataset_size = test_size,
    p_threshold = 0.05,
    log_fc_min = -0.5,
    log_fc_max = 0.5,
    search_term = NULL,
    max_points = 5000,
    zoom_level = 1.0
  )
  
  end_time <- Sys.time()
  duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
  times_production <- c(times_production, duration_ms)
  
  cat(sprintf("  Iterazione %d: %.1f ms (%d punti)\n", i, duration_ms, length(result$data)))
}

production_mean <- mean(times_production)
cat(sprintf("PRODUCTION MEAN: %.1f ms\n", production_mean))

# Test 2: DEBUG MODE (MONITOR_ENABLED = TRUE)
cat("\n2. DEBUG MODE (MONITOR_ENABLED = TRUE)\n")
cat("=" %R% 40, "\n")

# Simula ambiente debug
assign("MONITOR_ENABLED", TRUE, envir = .GlobalEnv)

# Inizializza ambiente performance
perf <- new.env()
perf$timers <- list()
perf$request_id <- NULL
assign("perf", perf, envir = .GlobalEnv)

times_debug <- c()
for (i in 1:3) {
  # Reset metriche
  perf$timers <- list()
  perf$request_id <- sprintf("debug_req_%d", i)
  
  start_time <- Sys.time()
  
  result <- process_volcano_pipeline_fast(
    dataset_size = test_size,
    p_threshold = 0.05,
    log_fc_min = -0.5,
    log_fc_max = 0.5,
    search_term = NULL,
    max_points = 5000,
    zoom_level = 1.0
  )
  
  end_time <- Sys.time()
  duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
  times_debug <- c(times_debug, duration_ms)
  
  # Mostra metriche dettagliate
  metrics <- get_performance_metrics()
  cat(sprintf("  Iterazione %d: %.1f ms (%d punti)\n", i, duration_ms, length(result$data)))
  if (metrics$monitoring_enabled && length(metrics$timers) > 0) {
    cat("    Breakdown:\n")
    for (timer_name in names(metrics$timers)) {
      cat(sprintf("      %s: %.1f ms\n", timer_name, metrics$timers[[timer_name]] * 1000))
    }
  }
}

debug_mean <- mean(times_debug)
cat(sprintf("DEBUG MEAN: %.1f ms\n", debug_mean))

# Test 3: Confronto con Python API
cat("\n3. CONFRONTO CON PYTHON API\n")
cat("=" %R% 40, "\n")

python_times <- c()
for (i in 1:3) {
  tryCatch({
    start_time <- Sys.time()
    response <- GET("http://localhost:8000/api/volcano-data", 
                   query = list(dataset_size = test_size, max_points = 5000), 
                   timeout(30))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      python_time <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
      python_times <- c(python_times, python_time)
      cat(sprintf("  Python iterazione %d: %.1f ms\n", i, python_time))
    } else {
      cat(sprintf("  Python iterazione %d: ERROR HTTP %d\n", i, status_code(response)))
    }
  }, error = function(e) {
    cat(sprintf("  Python iterazione %d: ERROR - %s\n", i, e$message))
  })
}

# Analisi finale
cat("\n" %R% 60, "\n")
cat("=== ANALISI FINALE OTTIMIZZAZIONI ===\n")
cat("=" %R% 60, "\n")

if (length(python_times) > 0) {
  python_mean <- mean(python_times)
  cat(sprintf("Python FastAPI:           %.1f ms\n", python_mean))
} else {
  python_mean <- NA
  cat("Python FastAPI:           Non disponibile\n")
}

cat(sprintf("R PRODUCTION (no monitor): %.1f ms\n", production_mean))
cat(sprintf("R DEBUG (con monitor):     %.1f ms\n", debug_mean))

# Calcola miglioramenti
if (!is.na(python_mean)) {
  production_vs_python <- production_mean / python_mean
  if (production_vs_python < 1) {
    cat(sprintf("\n🎉 R PRODUCTION è %.1fx PIÙ VELOCE di Python!\n", 1/production_vs_python))
  } else {
    cat(sprintf("\nR PRODUCTION è %.1fx più lento di Python (%.1f%% overhead)\n", 
               production_vs_python, (production_vs_python - 1) * 100))
  }
}

monitoring_overhead <- debug_mean - production_mean
monitoring_overhead_pct <- (monitoring_overhead / debug_mean) * 100
cat(sprintf("\nOVERHEAD MONITORING: %.1f ms (%.1f%%)\n", monitoring_overhead, monitoring_overhead_pct))

cat("\n--- CONCLUSIONI ---\n")
if (!is.na(python_mean) && production_mean <= python_mean * 1.5) {
  cat("✅ SUCCESSO: Ottimizzazioni R completate con successo!\n")
  cat("   - Performance competitive con Python\n")
  cat("   - Feature flag monitoring implementato\n")
  cat("   - Multi-threading abilitato\n")
  cat("   - Fast path per dataset piccoli\n")
} else {
  cat("⚠️  PARZIALE: Ottimizzazioni implementate ma performance ancora da migliorare\n")
}

cat("=" %R% 60, "\n")

# Helper function
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")