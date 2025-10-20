#!/usr/bin/env Rscript

# Test semplice delle ottimizzazioni implementate

library(data.table)
library(jsonlite)

# Abilita multi-threading
data.table::setDTthreads(0L)

cat("=== TEST OTTIMIZZAZIONI R ===\n")
cat("Multi-threading data.table:", data.table::getDTthreads(), "cores\n\n")

# Funzioni ottimizzate (copiate dal file production)
generate_volcano_data_fast <- function(size) {
  size <- max(100, min(10000000, as.integer(size)))
  set.seed(42)
  
  non_sig_proportion <- 0.85
  up_reg_proportion <- 0.075
  down_reg_proportion <- 0.075
  
  n_non_sig <- as.integer(size * non_sig_proportion)
  n_up_reg <- as.integer(size * up_reg_proportion)
  n_down_reg <- size - n_non_sig - n_up_reg
  
  log_fc_non_sig <- rnorm(n_non_sig, mean = 0, sd = 0.6)
  log_fc_up <- rnorm(n_up_reg, mean = 1.5, sd = 0.8)
  log_fc_down <- rnorm(n_down_reg, mean = -1.5, sd = 0.8)
  
  log_fc <- c(log_fc_non_sig, log_fc_up, log_fc_down)
  
  p_values <- numeric(size)
  p_values[1:n_non_sig] <- runif(n_non_sig, min = 0.1, max = 1.0)
  p_values[(n_non_sig + 1):(n_non_sig + n_up_reg)] <- runif(n_up_reg, min = 0.0001, max = 0.05)
  p_values[(n_non_sig + n_up_reg + 1):size] <- runif(n_down_reg, min = 0.0001, max = 0.05)
  
  noise_factor <- 0.1
  log_fc <- log_fc + rnorm(size, mean = 0, sd = noise_factor)
  p_values <- pmax(0.0001, pmin(1.0, p_values))
  log_fc <- round(log_fc, 4)
  p_values <- round(p_values, 6)
  
  indices <- sample(size)
  log_fc <- log_fc[indices]
  p_values <- p_values[indices]
  
  gene_names <- paste0("Gene_", 1:size)
  
  dt <- data.table(
    gene = gene_names,
    logFC = log_fc,
    padj = p_values,
    classyfireSuperclass = sample(c("Class1", "Class2", "Class3"), size, replace = TRUE),
    classyfireClass = sample(c("SubClass1", "SubClass2"), size, replace = TRUE)
  )
  
  return(dt)
}

categorize_points_fast <- function(dt, p_threshold, log_fc_min, log_fc_max) {
  dt[, category := fifelse(
    padj <= p_threshold & logFC < log_fc_min, "down",
    fifelse(
      padj <= p_threshold & logFC > log_fc_max, "up",
      "non_significant"
    )
  )]
  return(dt)
}

convert_to_json_fast <- function(dt) {
  if (nrow(dt) == 0) return(list())
  json_string <- jsonlite::toJSON(dt, dataframe = "rows", auto_unbox = TRUE)
  result <- jsonlite::fromJSON(json_string, simplifyVector = FALSE)
  return(result)
}

# Test con diverse dimensioni
test_sizes <- c(10000, 50000, 100000)

for (size in test_sizes) {
  cat(sprintf("Testing size: %s\n", format(size, big.mark = ",")))
  
  times <- c()
  for (i in 1:3) {
    start_time <- Sys.time()
    
    # Pipeline completa ottimizzata
    dt <- generate_volcano_data_fast(size)
    dt <- categorize_points_fast(dt, 0.05, -0.5, 0.5)
    
    # Sample per JSON conversion
    sample_size <- min(5000, nrow(dt))
    dt_sample <- dt[1:sample_size]
    data_points <- convert_to_json_fast(dt_sample)
    
    end_time <- Sys.time()
    duration_ms <- as.numeric(difftime(end_time, start_time, units = "secs")) * 1000
    times <- c(times, duration_ms)
    
    cat(sprintf("  Iterazione %d: %.1f ms (%d punti generati, %d convertiti)\n", 
               i, duration_ms, nrow(dt), length(data_points)))
  }
  
  mean_time <- mean(times)
  cat(sprintf("  MEDIA: %.1f ms\n", mean_time))
  
  # Stima throughput
  throughput <- size / (mean_time / 1000)
  cat(sprintf("  THROUGHPUT: %.0f punti/secondo\n", throughput))
  cat("\n")
}

cat("=== OTTIMIZZAZIONI IMPLEMENTATE ===\n")
cat("✅ Multi-threading data.table abilitato\n")
cat("✅ Operazioni vettorizzate per generazione dati\n")
cat("✅ Conversione JSON ottimizzata\n")
cat("✅ Nessun overhead di monitoring/logging\n")
cat("✅ Nessun GC forzato nel hot path\n")
cat("✅ Pipeline consolidata senza micro-misurazioni\n")

cat("\nTest completato con successo!\n")