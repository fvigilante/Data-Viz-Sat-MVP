#!/usr/bin/env Rscript

# Test rapido per verificare l'impatto del monitoring overhead
# Testa direttamente le funzioni core senza API

library(data.table)
library(jsonlite)
library(httr)

# Carica le funzioni dall'API originale
source("r-backend/plumber-api.R")

#' Test performance delle funzioni core R
test_core_functions_performance <- function() {
  
  cat("=== TEST PERFORMANCE FUNZIONI CORE R ===\n")
  cat("Confronto con/senza monitoring overhead\n\n")
  
  test_size <- 10000
  
  # 1. Test generazione dati CON monitoring
  cat("1. Test generazione dati CON monitoring...\n")
  start_time <- Sys.time()
  dt_with_monitoring <- monitor_performance(get_cached_dataset, "test_with_monitoring", "data_generation", "test_id", test_size)
  time_with_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  cat(sprintf("   Tempo CON monitoring: %.1f ms\n", time_with_monitoring))
  
  # 2. Test generazione dati SENZA monitoring
  cat("2. Test generazione dati SENZA monitoring...\n")
  start_time <- Sys.time()
  dt_without_monitoring <- get_cached_dataset(test_size)
  time_without_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  cat(sprintf("   Tempo SENZA monitoring: %.1f ms\n", time_without_monitoring))
  
  # 3. Test categorizzazione CON monitoring
  cat("3. Test categorizzazione CON monitoring...\n")
  start_time <- Sys.time()
  dt_cat_with <- monitor_performance(categorize_points, "test_categorize", "categorization", "test_id", dt_with_monitoring, 0.05, -0.5, 0.5)
  time_cat_with <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  cat(sprintf("   Tempo CON monitoring: %.1f ms\n", time_cat_with))
  
  # 4. Test categorizzazione SENZA monitoring
  cat("4. Test categorizzazione SENZA monitoring...\n")
  start_time <- Sys.time()
  dt_cat_without <- categorize_points(dt_without_monitoring, 0.05, -0.5, 0.5)
  time_cat_without <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  cat(sprintf("   Tempo SENZA monitoring: %.1f ms\n", time_cat_without))
  
  # 5. Test conversione JSON CON monitoring
  cat("5. Test JSON conversion CON monitoring...\n")
  # Riduci dataset per test JSON
  dt_sample <- dt_cat_with[1:min(5000, nrow(dt_cat_with))]
  start_time <- Sys.time()
  json_with <- monitor_performance(convert_to_data_points_optimized, "test_json", "json_conversion", "test_id", dt_sample)
  time_json_with <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  cat(sprintf("   Tempo CON monitoring: %.1f ms\n", time_json_with))
  
  # 6. Test conversione JSON SENZA monitoring
  cat("6. Test JSON conversion SENZA monitoring...\n")
  dt_sample2 <- dt_cat_without[1:min(5000, nrow(dt_cat_without))]
  start_time <- Sys.time()
  json_without <- convert_to_data_points_optimized(dt_sample2)
  time_json_without <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
  cat(sprintf("   Tempo SENZA monitoring: %.1f ms\n", time_json_without))
  
  # Analisi risultati
  cat("\n=== ANALISI OVERHEAD MONITORING ===\n")
  
  data_overhead <- time_with_monitoring - time_without_monitoring
  data_overhead_pct <- (data_overhead / time_with_monitoring) * 100
  cat(sprintf("Generazione dati - Overhead: %.1f ms (%.1f%%)\n", data_overhead, data_overhead_pct))
  
  cat_overhead <- time_cat_with - time_cat_without
  cat_overhead_pct <- (cat_overhead / time_cat_with) * 100
  cat(sprintf("Categorizzazione - Overhead: %.1f ms (%.1f%%)\n", cat_overhead, cat_overhead_pct))
  
  json_overhead <- time_json_with - time_json_without
  json_overhead_pct <- (json_overhead / time_json_with) * 1000
  cat(sprintf("JSON conversion - Overhead: %.1f ms (%.1f%%)\n", json_overhead, json_overhead_pct))
  
  total_overhead <- data_overhead + cat_overhead + json_overhead
  cat(sprintf("\nTOTALE OVERHEAD MONITORING: %.1f ms\n", total_overhead))
  
  # Test API Python per confronto
  cat("\n=== CONFRONTO CON PYTHON API ===\n")
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
        cat(sprintf("Python API iterazione %d: %.1f ms\n", i, python_time))
      }
    }, error = function(e) {
      cat(sprintf("Python API iterazione %d: ERROR\n", i))
    })
  }
  
  if (length(python_times) > 0) {
    python_avg <- mean(python_times)
    cat(sprintf("Python API media: %.1f ms\n", python_avg))
    
    # Stima tempo R senza monitoring
    estimated_r_time <- time_without_monitoring + time_cat_without + time_json_without
    cat(sprintf("R stimato SENZA monitoring: %.1f ms\n", estimated_r_time))
    
    if (estimated_r_time < Inf && python_avg < Inf) {
      ratio <- estimated_r_time / python_avg
      cat(sprintf("R vs Python (senza monitoring): %.1fx\n", ratio))
      
      if (ratio <= 1.5) {
        cat("🎉 SUCCESS: R sarebbe competitivo senza monitoring!\n")
      } else if (ratio <= 2.0) {
        cat("✅ GOOD: R sarebbe accettabile senza monitoring\n")
      } else {
        cat("⚠️  NEEDS WORK: R ancora lento anche senza monitoring\n")
      }
    }
  }
  
  return(list(
    data_overhead_ms = data_overhead,
    categorization_overhead_ms = cat_overhead,
    json_overhead_ms = json_overhead,
    total_overhead_ms = total_overhead,
    python_avg_ms = if (length(python_times) > 0) mean(python_times) else NA
  ))
}

# Esegui test
tryCatch({
  results <- test_core_functions_performance()
  
  # Salva risultati
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  saveRDS(results, sprintf("monitoring_overhead_analysis_%s.rds", timestamp))
  cat(sprintf("\nRisultati salvati: monitoring_overhead_analysis_%s.rds\n", timestamp))
  
}, error = function(e) {
  cat("Errore durante il test:", e$message, "\n")
})