#!/usr/bin/env Rscript

# Performance Profiling Tests - Identify R Performance Bottlenecks
# Analizza dove sono i colli di bottiglia nell'implementazione R

library(httr)
library(jsonlite)
library(data.table)

# Configurazione per il profiling
PROFILING_CONFIG <- list(
  r_api_url = Sys.getenv("R_API_URL", "http://localhost:8001"),
  python_api_url = Sys.getenv("PYTHON_API_URL", "http://localhost:8000"),
  test_size = 10000,  # Dimensione test per analisi dettagliata
  iterations = 3
)

#' Esegui profiling dettagliato delle performance R
#' @return Lista con risultati del profiling
execute_performance_profiling <- function() {
  
  cat("=== PROFILING PERFORMANCE R vs PYTHON ===\n")
  cat("Identificazione dei colli di bottiglia nell'implementazione R\n\n")
  
  # Test parametri standard
  test_params <- list(
    dataset_size = PROFILING_CONFIG$test_size,
    max_points = 5000,
    p_value_threshold = 0.05,
    log_fc_min = -0.5,
    log_fc_max = 0.5
  )
  
  results <- list()
  
  # 1. Test baseline - confronto diretto
  cat("1. BASELINE COMPARISON\n")
  cat("=" %R% 30, "\n")
  baseline_results <- compare_baseline_performance(test_params)
  results$baseline <- baseline_results
  
  # 2. Test cache warming
  cat("\n2. CACHE WARMING ANALYSIS\n")
  cat("=" %R% 30, "\n")
  cache_results <- analyze_cache_performance(test_params)
  results$cache <- cache_results
  
  # 3. Test componenti individuali R
  cat("\n3. R COMPONENT ANALYSIS\n")
  cat("=" %R% 30, "\n")
  component_results <- analyze_r_components(test_params)
  results$components <- component_results
  
  # 4. Test JSON conversion
  cat("\n4. JSON CONVERSION ANALYSIS\n")
  cat("=" %R% 30, "\n")
  json_results <- analyze_json_conversion()
  results$json <- json_results
  
  # 5. Test memory management
  cat("\n5. MEMORY MANAGEMENT ANALYSIS\n")
  cat("=" %R% 30, "\n")
  memory_results <- analyze_memory_usage(test_params)
  results$memory <- memory_results
  
  # Genera report finale
  generate_profiling_report(results)
  
  return(results)
}

#' Confronto baseline tra R e Python
compare_baseline_performance <- function(params) {
  
  cat("Confronto diretto R vs Python...\n")
  
  # Test Python
  python_times <- c()
  for (i in 1:PROFILING_CONFIG$iterations) {
    start_time <- Sys.time()
    response <- GET(paste0(PROFILING_CONFIG$python_api_url, "/api/volcano-data"), 
                   query = params, timeout(30))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      python_times <- c(python_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
  }
  
  # Test R
  r_times <- c()
  for (i in 1:PROFILING_CONFIG$iterations) {
    start_time <- Sys.time()
    response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/volcano-data"), 
                   query = params, timeout(30))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      r_times <- c(r_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
  }
  
  python_mean <- mean(python_times)
  r_mean <- mean(r_times)
  slowdown_factor <- r_mean / python_mean
  
  cat(sprintf("Python medio: %.1f ms\n", python_mean))
  cat(sprintf("R medio: %.1f ms\n", r_mean))
  cat(sprintf("R è %.1fx più lento\n", slowdown_factor))
  
  return(list(
    python_mean_ms = python_mean,
    r_mean_ms = r_mean,
    slowdown_factor = slowdown_factor,
    python_times = python_times,
    r_times = r_times
  ))
}

#' Analizza l'impatto del cache warming
analyze_cache_performance <- function(params) {
  
  cat("Analisi impatto cache warming...\n")
  
  # Test R senza cache warming (cold start)
  cat("  Test R cold start...\n")
  cold_times <- c()
  for (i in 1:PROFILING_CONFIG$iterations) {
    # Clear cache prima di ogni test
    tryCatch({
      POST(paste0(PROFILING_CONFIG$r_api_url, "/api/clear-cache"), timeout(10))
    }, error = function(e) {})
    
    start_time <- Sys.time()
    response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/volcano-data"), 
                   query = params, timeout(60))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      cold_times <- c(cold_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
  }
  
  # Test R con cache warming (warm start)
  cat("  Test R warm start...\n")
  # Warm cache
  tryCatch({
    POST(paste0(PROFILING_CONFIG$r_api_url, "/api/warm-cache"),
         body = list(sizes = list(params$dataset_size)),
         encode = "json", timeout(30))
  }, error = function(e) {})
  
  warm_times <- c()
  for (i in 1:PROFILING_CONFIG$iterations) {
    start_time <- Sys.time()
    response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/volcano-data"), 
                   query = params, timeout(30))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      warm_times <- c(warm_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
  }
  
  cold_mean <- mean(cold_times)
  warm_mean <- mean(warm_times)
  cache_improvement <- (cold_mean - warm_mean) / cold_mean * 100
  
  cat(sprintf("R cold start: %.1f ms\n", cold_mean))
  cat(sprintf("R warm start: %.1f ms\n", warm_mean))
  cat(sprintf("Cache improvement: %.1f%%\n", cache_improvement))
  
  return(list(
    cold_mean_ms = cold_mean,
    warm_mean_ms = warm_mean,
    cache_improvement_percent = cache_improvement,
    cold_times = cold_times,
    warm_times = warm_times
  ))
}

#' Analizza i componenti individuali dell'API R
analyze_r_components <- function(params) {
  
  cat("Analisi componenti R API...\n")
  
  # Test endpoint specifici per misurare componenti
  components <- list()
  
  # 1. Cache status (overhead API)
  cat("  Test cache status...\n")
  cache_times <- c()
  for (i in 1:PROFILING_CONFIG$iterations) {
    start_time <- Sys.time()
    response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/cache-status"), timeout(10))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      cache_times <- c(cache_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
  }
  components$cache_status_ms <- mean(cache_times)
  
  # 2. Performance stats (overhead API)
  cat("  Test performance stats...\n")
  perf_times <- c()
  for (i in 1:PROFILING_CONFIG$iterations) {
    start_time <- Sys.time()
    response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/performance-stats"), timeout(10))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      perf_times <- c(perf_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
  }
  components$perf_stats_ms <- mean(perf_times)
  
  # 3. Memory status (overhead API)
  cat("  Test memory status...\n")
  mem_times <- c()
  for (i in 1:PROFILING_CONFIG$iterations) {
    start_time <- Sys.time()
    response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/memory-status"), timeout(10))
    end_time <- Sys.time()
    
    if (status_code(response) == 200) {
      mem_times <- c(mem_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
  }
  components$memory_status_ms <- mean(mem_times)
  
  # Calcola overhead totale
  total_overhead <- components$cache_status_ms + components$perf_stats_ms + components$memory_status_ms
  
  cat(sprintf("Cache status: %.1f ms\n", components$cache_status_ms))
  cat(sprintf("Performance stats: %.1f ms\n", components$perf_stats_ms))
  cat(sprintf("Memory status: %.1f ms\n", components$memory_status_ms))
  cat(sprintf("Overhead totale: %.1f ms\n", total_overhead))
  
  components$total_overhead_ms <- total_overhead
  
  return(components)
}

#' Analizza le performance della conversione JSON
analyze_json_conversion <- function() {
  
  cat("Analisi conversione JSON...\n")
  
  # Test conversione JSON con dati di diverse dimensioni
  sizes <- c(1000, 5000, 10000)
  json_results <- list()
  
  for (size in sizes) {
    cat(sprintf("  Test JSON conversion %d punti...\n", size))
    
    # Genera dati test
    test_data <- data.table(
      gene = paste0("Gene_", 1:size),
      logFC = rnorm(size),
      padj = runif(size),
      classyfireSuperclass = sample(c("Class1", "Class2", "Class3"), size, replace = TRUE),
      classyfireClass = sample(c("SubClass1", "SubClass2"), size, replace = TRUE),
      category = sample(c("up", "down", "non_significant"), size, replace = TRUE)
    )
    
    # Test metodo ottimizzato
    optimized_times <- c()
    for (i in 1:3) {
      start_time <- Sys.time()
      json_string <- jsonlite::toJSON(test_data, dataframe = "rows", auto_unbox = TRUE)
      result <- jsonlite::fromJSON(json_string, simplifyVector = FALSE)
      end_time <- Sys.time()
      optimized_times <- c(optimized_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
    
    # Test metodo tradizionale (loop)
    traditional_times <- c()
    for (i in 1:3) {
      start_time <- Sys.time()
      result_list <- vector("list", nrow(test_data))
      for (j in seq_len(nrow(test_data))) {
        result_list[[j]] <- list(
          gene = as.character(test_data$gene[j]),
          logFC = as.numeric(test_data$logFC[j]),
          padj = as.numeric(test_data$padj[j]),
          classyfireSuperclass = as.character(test_data$classyfireSuperclass[j]),
          classyfireClass = as.character(test_data$classyfireClass[j]),
          category = as.character(test_data$category[j])
        )
      }
      end_time <- Sys.time()
      traditional_times <- c(traditional_times, as.numeric(difftime(end_time, start_time, units = "secs")) * 1000)
    }
    
    optimized_mean <- mean(optimized_times)
    traditional_mean <- mean(traditional_times)
    speedup <- traditional_mean / optimized_mean
    
    cat(sprintf("    Ottimizzato: %.1f ms\n", optimized_mean))
    cat(sprintf("    Tradizionale: %.1f ms\n", traditional_mean))
    cat(sprintf("    Speedup: %.1fx\n", speedup))
    
    json_results[[as.character(size)]] <- list(
      size = size,
      optimized_ms = optimized_mean,
      traditional_ms = traditional_mean,
      speedup = speedup
    )
  }
  
  return(json_results)
}

#' Analizza l'uso della memoria
analyze_memory_usage <- function(params) {
  
  cat("Analisi uso memoria...\n")
  
  # Memoria prima del test
  gc()
  mem_before <- sum(gc(verbose = FALSE)[, 2])
  
  # Esegui richiesta R
  response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/volcano-data"), 
                 query = params, timeout(30))
  
  # Memoria dopo il test
  mem_after <- sum(gc(verbose = FALSE)[, 2])
  mem_used <- mem_after - mem_before
  
  cat(sprintf("Memoria prima: %.2f MB\n", mem_before))
  cat(sprintf("Memoria dopo: %.2f MB\n", mem_after))
  cat(sprintf("Memoria utilizzata: %.2f MB\n", mem_used))
  
  # Test memory status endpoint
  mem_status_response <- GET(paste0(PROFILING_CONFIG$r_api_url, "/api/memory-status"), timeout(10))
  if (status_code(mem_status_response) == 200) {
    mem_status <- content(mem_status_response, "parsed")
    cat(sprintf("Memoria totale API: %.2f MB\n", mem_status$total_memory_mb))
    cat(sprintf("Pressione memoria: %s\n", mem_status$memory_pressure))
  }
  
  return(list(
    memory_before_mb = mem_before,
    memory_after_mb = mem_after,
    memory_used_mb = mem_used,
    memory_status = if (exists("mem_status")) mem_status else NULL
  ))
}

#' Genera report di profiling
generate_profiling_report <- function(results) {
  
  cat("\n" %R% 60, "\n")
  cat("=== PROFILING REPORT ===\n")
  cat("=" %R% 60, "\n")
  
  # Baseline comparison
  if (!is.null(results$baseline)) {
    baseline <- results$baseline
    cat(sprintf("BASELINE: R è %.1fx più lento di Python\n", baseline$slowdown_factor))
    cat(sprintf("  Python: %.1f ms\n", baseline$python_mean_ms))
    cat(sprintf("  R: %.1f ms\n", baseline$r_mean_ms))
  }
  
  # Cache analysis
  if (!is.null(results$cache)) {
    cache <- results$cache
    cat(sprintf("\nCACHE: Miglioramento %.1f%% con warm cache\n", cache$cache_improvement_percent))
    cat(sprintf("  Cold start: %.1f ms\n", cache$cold_mean_ms))
    cat(sprintf("  Warm start: %.1f ms\n", cache$warm_mean_ms))
  }
  
  # Component overhead
  if (!is.null(results$components)) {
    comp <- results$components
    cat(sprintf("\nOVERHEAD API: %.1f ms totale\n", comp$total_overhead_ms))
    cat(sprintf("  Cache status: %.1f ms\n", comp$cache_status_ms))
    cat(sprintf("  Performance stats: %.1f ms\n", comp$perf_stats_ms))
    cat(sprintf("  Memory status: %.1f ms\n", comp$memory_status_ms))
  }
  
  # JSON conversion
  if (!is.null(results$json)) {
    cat("\nJSON CONVERSION:\n")
    for (size_key in names(results$json)) {
      json_data <- results$json[[size_key]]
      cat(sprintf("  %s punti: %.1fx speedup (%.1f ms vs %.1f ms)\n", 
                 size_key, json_data$speedup, json_data$optimized_ms, json_data$traditional_ms))
    }
  }
  
  # Memory usage
  if (!is.null(results$memory)) {
    mem <- results$memory
    cat(sprintf("\nMEMORIA: %.2f MB utilizzata per richiesta\n", mem$memory_used_mb))
  }
  
  # Raccomandazioni
  cat("\n--- RACCOMANDAZIONI ---\n")
  
  if (!is.null(results$baseline) && results$baseline$slowdown_factor > 5) {
    cat("🔴 CRITICO: R è molto più lento di Python\n")
  }
  
  if (!is.null(results$cache) && results$cache$cache_improvement_percent < 20) {
    cat("⚠️  Cache warming ha poco impatto\n")
  }
  
  if (!is.null(results$components) && results$components$total_overhead_ms > 100) {
    cat("⚠️  Overhead API significativo - considerare semplificazione\n")
  }
  
  cat("=" %R% 60, "\n")
}

# Helper function
`%R%` <- function(x, n) paste(rep(x, n), collapse = "")

# Main execution
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) > 0 && (args[1] == "--help" || args[1] == "-h")) {
    cat("Usage: Rscript performance-profiling-tests.R\n")
    cat("Analizza i colli di bottiglia nell'implementazione R\n")
    return()
  }
  
  tryCatch({
    results <- execute_performance_profiling()
    
    # Salva risultati
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    saveRDS(results, sprintf("profiling_results_%s.rds", timestamp))
    cat(sprintf("\nRisultati salvati in: profiling_results_%s.rds\n", timestamp))
    
  }, error = function(e) {
    cat("Errore durante il profiling:", e$message, "\n")
    quit(save = "no", status = 1)
  })
}

# Execute if run directly
if (!interactive()) {
  main()
}