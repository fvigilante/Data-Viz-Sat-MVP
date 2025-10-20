#!/usr/bin/env Rscript

# Test semplice per misurare l'overhead del monitoring
# Senza dipendenze dal file API principale

library(data.table)
library(jsonlite)
library(httr)

# Simula la funzione monitor_performance
monitor_performance_test <- function(func, func_name, phase = "unknown", request_id = NULL, ...) {
  start_time <- Sys.time()
  start_memory <- gc(verbose = FALSE)
  
  # Simula logging
  cat(sprintf("Starting %s [%s]\n", func_name, phase))
  
  tryCatch({
    result <- func(...)
    
    end_time <- Sys.time()
    end_memory <- gc(verbose = FALSE)
    
    duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
    memory_used <- sum(end_memory[, 2]) - sum(start_memory[, 2])
    
    # Simula storage metriche (overhead aggiuntivo)
    metrics <- list(
      phase = phase,
      function_name = func_name,
      duration_sec = duration,
      memory_change_mb = memory_used,
      start_time = start_time,
      end_time = end_time,
      request_id = request_id,
      status = "success"
    )
    
    cat(sprintf("%s [%s] completed in %.4f seconds, memory change: %.3f MB\n", 
               func_name, phase, duration, memory_used))
    
    return(result)
  }, error = function(e) {
    cat(sprintf("%s [%s] failed: %s\n", func_name, phase, e$message))
    stop(e)
  })
}

# Funzione semplice per generare dati test
generate_test_data <- function(size) {
  set.seed(42)
  data.table(
    gene = paste0("Gene_", 1:size),
    logFC = rnorm(size),
    padj = runif(size),
    classyfireSuperclass = sample(c("Class1", "Class2", "Class3"), size, replace = TRUE),
    classyfireClass = sample(c("SubClass1", "SubClass2"), size, replace = TRUE)
  )
}

# Funzione per categorizzare
categorize_simple <- function(dt, p_threshold = 0.05, log_fc_min = -0.5, log_fc_max = 0.5) {
  dt[, category := fifelse(
    padj <= p_threshold & logFC < log_fc_min, "down",
    fifelse(
      padj <= p_threshold & logFC > log_fc_max, "up",
      "non_significant"
    )
  )]
  return(dt)
}

# Funzione per conversione JSON
convert_to_json_simple <- function(dt) {
  if (nrow(dt) == 0) return(list())
  json_string <- jsonlite::toJSON(dt, dataframe = "rows", auto_unbox = TRUE)
  result <- jsonlite::fromJSON(json_string, simplifyVector = FALSE)
  return(result)
}

# Test principale
cat("=== TEST OVERHEAD MONITORING ===\n")
test_size <- 10000

# Test 1: Generazione dati CON monitoring
cat("\n1. Generazione dati CON monitoring:\n")
start_time <- Sys.time()
dt_with <- monitor_performance_test(generate_test_data, "generate_data", "data_generation", "test1", test_size)
time_with_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

# Test 2: Generazione dati SENZA monitoring
cat("\n2. Generazione dati SENZA monitoring:\n")
start_time <- Sys.time()
dt_without <- generate_test_data(test_size)
time_without_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
cat(sprintf("Direct call completed in %.4f seconds\n", (time_without_monitoring/1000)))

# Test 3: Categorizzazione CON monitoring
cat("\n3. Categorizzazione CON monitoring:\n")
start_time <- Sys.time()
dt_cat_with <- monitor_performance_test(categorize_simple, "categorize", "categorization", "test2", dt_with)
time_cat_with_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

# Test 4: Categorizzazione SENZA monitoring
cat("\n4. Categorizzazione SENZA monitoring:\n")
start_time <- Sys.time()
dt_cat_without <- categorize_simple(dt_without)
time_cat_without_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
cat(sprintf("Direct call completed in %.4f seconds\n", (time_cat_without_monitoring/1000)))

# Test 5: JSON CON monitoring (sample ridotto)
sample_size <- min(5000, nrow(dt_cat_with))
dt_sample_with <- dt_cat_with[1:sample_size]
dt_sample_without <- dt_cat_without[1:sample_size]

cat("\n5. JSON conversion CON monitoring:\n")
start_time <- Sys.time()
json_with <- monitor_performance_test(convert_to_json_simple, "json_convert", "json_conversion", "test3", dt_sample_with)
time_json_with_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

cat("\n6. JSON conversion SENZA monitoring:\n")
start_time <- Sys.time()
json_without <- convert_to_json_simple(dt_sample_without)
time_json_without_monitoring <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000
cat(sprintf("Direct call completed in %.4f seconds\n", (time_json_without_monitoring/1000)))

# Analisi risultati
cat("\n=== ANALISI OVERHEAD ===\n")

data_overhead <- time_with_monitoring - time_without_monitoring
cat(sprintf("Generazione dati - CON monitoring: %.1f ms\n", time_with_monitoring))
cat(sprintf("Generazione dati - SENZA monitoring: %.1f ms\n", time_without_monitoring))
cat(sprintf("Overhead generazione: %.1f ms (%.1f%%)\n", data_overhead, (data_overhead/time_with_monitoring)*100))

cat_overhead <- time_cat_with_monitoring - time_cat_without_monitoring
cat(sprintf("\nCategorizzazione - CON monitoring: %.1f ms\n", time_cat_with_monitoring))
cat(sprintf("Categorizzazione - SENZA monitoring: %.1f ms\n", time_cat_without_monitoring))
cat(sprintf("Overhead categorizzazione: %.1f ms (%.1f%%)\n", cat_overhead, (cat_overhead/time_cat_with_monitoring)*100))

json_overhead <- time_json_with_monitoring - time_json_without_monitoring
cat(sprintf("\nJSON conversion - CON monitoring: %.1f ms\n", time_json_with_monitoring))
cat(sprintf("JSON conversion - SENZA monitoring: %.1f ms\n", time_json_without_monitoring))
cat(sprintf("Overhead JSON: %.1f ms (%.1f%%)\n", json_overhead, (json_overhead/time_json_with_monitoring)*100))

total_overhead <- data_overhead + cat_overhead + json_overhead
cat(sprintf("\n🔍 TOTALE OVERHEAD MONITORING: %.1f ms\n", total_overhead))

# Stima tempo totale pipeline
total_with_monitoring <- time_with_monitoring + time_cat_with_monitoring + time_json_with_monitoring
total_without_monitoring <- time_without_monitoring + time_cat_without_monitoring + time_json_without_monitoring

cat(sprintf("\nPipeline completa CON monitoring: %.1f ms\n", total_with_monitoring))
cat(sprintf("Pipeline completa SENZA monitoring: %.1f ms\n", total_without_monitoring))
cat(sprintf("Miglioramento rimuovendo monitoring: %.1fx (%.1f%% più veloce)\n", 
           total_with_monitoring/total_without_monitoring, 
           ((total_with_monitoring-total_without_monitoring)/total_with_monitoring)*100))

# Test Python per confronto
cat("\n=== CONFRONTO CON PYTHON ===\n")
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
      cat(sprintf("Python iterazione %d: %.1f ms\n", i, python_time))
    }
  }, error = function(e) {
    cat(sprintf("Python iterazione %d: ERROR - %s\n", i, e$message))
  })
}

if (length(python_times) > 0) {
  python_avg <- mean(python_times)
  cat(sprintf("Python media: %.1f ms\n", python_avg))
  
  cat(sprintf("\nCONFRONTO FINALE:\n"))
  cat(sprintf("Python: %.1f ms\n", python_avg))
  cat(sprintf("R CON monitoring: %.1f ms (%.1fx più lento)\n", total_with_monitoring, total_with_monitoring/python_avg))
  cat(sprintf("R SENZA monitoring: %.1f ms (%.1fx più lento)\n", total_without_monitoring, total_without_monitoring/python_avg))
  
  if (total_without_monitoring <= python_avg * 1.5) {
    cat("\n🎉 CONCLUSIONE: R senza monitoring sarebbe competitivo!\n")
    cat("   Raccomandazione: Rimuovere overhead monitoring dalla produzione\n")
  } else if (total_without_monitoring <= python_avg * 2.0) {
    cat("\n✅ CONCLUSIONE: R senza monitoring sarebbe accettabile\n")
    cat("   Raccomandazione: Considerare rimozione monitoring per performance\n")
  } else {
    cat("\n⚠️  CONCLUSIONE: R ha altri problemi oltre al monitoring\n")
    cat("   Raccomandazione: Ulteriori ottimizzazioni necessarie\n")
  }
}

cat("\n=== FINE TEST ===\n")