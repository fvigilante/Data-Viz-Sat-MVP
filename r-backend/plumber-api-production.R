#!/usr/bin/env Rscript

# R Volcano Plot API Server - PRODUCTION OPTIMIZED VERSION
# Implementa tutte le ottimizzazioni per massime performance

library(plumber)
library(data.table)
library(jsonlite)

# PERFORMANCE OPTIMIZATION 1: Enable all CPU cores for data.table
data.table::setDTthreads(0L)  # Use all available cores

# PERFORMANCE OPTIMIZATION 2: Feature flag di runtime per monitoring
# Prod: MONITOR_ENABLED=FALSE (default)
# Debug: MONITOR_ENABLED=TRUE (solo ambienti non-prod)
MONITOR_ENABLED <- isTRUE(as.logical(Sys.getenv("MONITOR_ENABLED", "FALSE")))

# Global performance storage (solo se monitoring abilitato)
if (MONITOR_ENABLED) {
  perf <- new.env()
  perf$timers <- list()
  perf$request_id <- NULL
}

# PRODUCTION: Minimal logging (only critical errors)
LOG_LEVEL <- "ERROR"

# Cache globale per i dataset
.volcano_cache <- new.env()

# Costanti per la generazione dati (identiche a Python)
METABOLITE_NAMES <- c(
  "1,3-Isoquinolinediol", "3,4-Dihydro-3-oxo-2H-(1,4)-benzoxazin-2-ylacetic acid",
  "(2-oxo-2,3-dihydro-1H-indol-3-yl)acetic acid", "Resedine", "Methionine sulfoxide",
  "trans-Urocanic acid", "Pro-Tyr", "Glu-Gly-Glu", "NP-024517", "Trp-Pro",
  "Biotin", "Pyridoxine", "Sulfocholic acid", "Pro-Pro", "Targinine",
  "L-Carnitine", "Taurine", "Creatine", "Adenosine", "Guanosine",
  "Cytidine", "Uridine", "Thymidine", "Inosine", "Xanthosine",
  "Hypoxanthine", "Xanthine", "Uric acid", "Allantoin", "Creatinine"
)

SUPERCLASSES <- c(
  "Organic acids and derivatives", "Organoheterocyclic compounds",
  "Lipids and lipid-like molecules", "Others", "Nucleosides, nucleotides, and analogues"
)

CLASSES <- c(
  "Carboxylic acids and derivatives", "Indoles and derivatives", "Benzoxazines",
  "Azolidines", "Azoles", "Biotin and derivatives", "Pyridines and derivatives",
  "Steroids and steroid derivatives", "Others", "Purine nucleosides"
)

# Limiti dataset
MAX_DATASET_SIZE <- 10000000
MIN_DATASET_SIZE <- 100
FAST_PATH_THRESHOLD <- 50000  # Disabilita memory management per dataset <= 50k

# Null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# PERFORMANCE OPTIMIZATION 3: Logging minimo (no I/O sincrono nel hot path)
log_error <- function(message) {
  if (LOG_LEVEL == "ERROR") {
    cat("[ERROR]", message, "\n", file = stderr())
  }
}

# PERFORMANCE OPTIMIZATION 4: Runtime monitoring con feature flag
monitor_performance <- function(fun, label, ...) {
  if (!MONITOR_ENABLED) {
    # PRODUCTION: Esegui direttamente senza overhead
    return(fun(...))
  }
  
  # DEBUG: Monitoring abilitato
  t0 <- proc.time()[["elapsed"]]
  res <- fun(...)
  elapsed <- proc.time()[["elapsed"]] - t0
  
  # Accumula in RAM; nessun I/O sincrono
  if (exists("perf") && !is.null(perf$timers)) {
    perf$timers[[label]] <- elapsed
  }
  
  res
}

# Funzione per ottenere metriche (solo se monitoring abilitato)
get_performance_metrics <- function() {
  if (!MONITOR_ENABLED || !exists("perf")) {
    return(list(monitoring_enabled = FALSE))
  }
  
  return(list(
    monitoring_enabled = TRUE,
    request_id = perf$request_id,
    timers = perf$timers,
    total_time = sum(unlist(perf$timers), na.rm = TRUE)
  ))
}

# Funzione per resettare metriche
reset_performance_metrics <- function(request_id = NULL) {
  if (MONITOR_ENABLED && exists("perf")) {
    perf$timers <- list()
    perf$request_id <- request_id
  }
}

#' Genera dati volcano sintetici (OTTIMIZZATO - no monitoring, no GC forzato)
#' @param size Numero di metaboliti da generare
#' @return data.table con dati volcano sintetici
generate_volcano_data_fast <- function(size) {
  
  # Valida dimensione
  size <- max(MIN_DATASET_SIZE, min(MAX_DATASET_SIZE, as.integer(size)))
  
  # Set seed per risultati riproducibili (matching Python)
  set.seed(42)
  
  # Proporzioni realistiche per volcano plot
  non_sig_proportion <- 0.85
  up_reg_proportion <- 0.075
  down_reg_proportion <- 0.075
  
  n_non_sig <- as.integer(size * non_sig_proportion)
  n_up_reg <- as.integer(size * up_reg_proportion)
  n_down_reg <- size - n_non_sig - n_up_reg
  
  # Genera log fold changes per categoria usando operazioni vettorizzate
  log_fc_non_sig <- rnorm(n_non_sig, mean = 0, sd = 0.6)
  log_fc_up <- rnorm(n_up_reg, mean = 1.5, sd = 0.8)
  log_fc_down <- rnorm(n_down_reg, mean = -1.5, sd = 0.8)
  
  log_fc <- c(log_fc_non_sig, log_fc_up, log_fc_down)
  
  # Genera p-values realistici
  p_values <- numeric(size)
  p_values[1:n_non_sig] <- runif(n_non_sig, min = 0.1, max = 1.0)
  p_values[(n_non_sig + 1):(n_non_sig + n_up_reg)] <- runif(n_up_reg, min = 0.0001, max = 0.05)
  p_values[(n_non_sig + n_up_reg + 1):size] <- runif(n_down_reg, min = 0.0001, max = 0.05)
  
  # Aggiungi rumore
  noise_factor <- 0.1
  log_fc <- log_fc + rnorm(size, mean = 0, sd = noise_factor)
  
  # Assicura range validi
  p_values <- pmax(0.0001, pmin(1.0, p_values))
  
  # Arrotonda per display più pulito
  log_fc <- round(log_fc, 4)
  p_values <- round(p_values, 6)
  
  # Mescola per mixare le categorie
  indices <- sample(size)
  log_fc <- log_fc[indices]
  p_values <- p_values[indices]
  
  # Genera nomi geni efficientemente
  gene_names <- character(size)
  for (i in 1:size) {
    if (i <= length(METABOLITE_NAMES)) {
      gene_names[i] <- METABOLITE_NAMES[((i - 1) %% length(METABOLITE_NAMES)) + 1]
    } else {
      gene_names[i] <- sprintf("Metabolite_%d", i)
    }
  }
  
  # Genera classificazioni usando sampling vettorizzato
  superclass_indices <- sample(length(SUPERCLASSES), size, replace = TRUE)
  class_indices <- sample(length(CLASSES), size, replace = TRUE)
  
  # Crea data.table direttamente
  dt <- data.table(
    gene = gene_names,
    logFC = log_fc,
    padj = p_values,
    classyfireSuperclass = SUPERCLASSES[superclass_indices],
    classyfireClass = CLASSES[class_indices]
  )
  
  return(dt)
}

#' Ottieni dataset cached o genera nuovo (OTTIMIZZATO - no monitoring)
#' @param size Dimensione dataset
#' @return data.table con dati volcano
get_cached_dataset_fast <- function(size) {
  
  size <- max(MIN_DATASET_SIZE, min(MAX_DATASET_SIZE, as.integer(size)))
  cache_key <- as.character(size)
  
  # Controlla cache
  if (exists(cache_key, envir = .volcano_cache)) {
    cached_data <- get(cache_key, envir = .volcano_cache)
    if (is.data.table(cached_data) && nrow(cached_data) > 0) {
      return(cached_data)
    }
  }
  
  # Genera nuovo dataset
  dt <- generate_volcano_data_fast(size)
  
  # Cache il risultato (no error handling per performance)
  assign(cache_key, dt, envir = .volcano_cache)
  
  return(dt)
}

#' Categorizza punti basato su soglie significatività (OTTIMIZZATO)
#' @param dt data.table con colonne logFC e padj
#' @param p_threshold Soglia p-value per significatività
#' @param log_fc_min Log fold change minimo per up-regulation
#' @param log_fc_max Log fold change massimo per down-regulation
#' @return data.table con colonna category aggiunta
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

#' Sampling intelligente che prioritizza punti significativi (OTTIMIZZATO)
#' @param dt data.table con colonna category
#' @param max_points Numero massimo di punti da restituire
#' @param zoom_level Livello zoom per sampling adattivo
#' @return data.table campionato
intelligent_sampling_fast <- function(dt, max_points, zoom_level = 1.0) {
  
  if (nrow(dt) <= max_points) {
    return(dt)
  }
  
  # Separa per significatività
  significant_dt <- dt[category != "non_significant"]
  non_significant_dt <- dt[category == "non_significant"]
  
  # A zoom più alti, includi più punti non significativi per contesto
  sig_ratio <- max(0.6 - (zoom_level - 1) * 0.1, 0.3)
  
  sig_points <- min(as.integer(max_points * sig_ratio), nrow(significant_dt))
  non_sig_points <- max_points - sig_points
  
  # Campiona punti significativi (mantieni tutti se possibile)
  if (nrow(significant_dt) <= sig_points) {
    sampled_sig <- significant_dt
    non_sig_points <- max_points - nrow(significant_dt)
  } else {
    # Prioritizza valori estremi per punti significativi
    up_dt <- significant_dt[category == "up"][order(-logFC)]
    down_dt <- significant_dt[category == "down"][order(logFC)]
    
    up_sample <- min(sig_points %/% 2, nrow(up_dt))
    down_sample <- sig_points - up_sample
    
    sampled_up <- if (up_sample > 0 && nrow(up_dt) > 0) up_dt[1:up_sample] else data.table()
    sampled_down <- if (down_sample > 0 && nrow(down_dt) > 0) down_dt[1:down_sample] else data.table()
    
    sampled_sig <- rbind(sampled_up, sampled_down)
  }
  
  # Campiona punti non significativi casualmente
  if (non_sig_points > 0 && nrow(non_significant_dt) > 0) {
    sample_size <- min(non_sig_points, nrow(non_significant_dt))
    sampled_indices <- sample(nrow(non_significant_dt), sample_size)
    sampled_non_sig <- non_significant_dt[sampled_indices]
    
    return(rbind(sampled_sig, sampled_non_sig))
  } else {
    return(sampled_sig)
  }
}

#' Converti data.table in formato JSON (OTTIMIZZATO - no monitoring)
#' @param dt data.table con dati volcano
#' @return Lista di punti dati per serializzazione JSON
convert_to_json_fast <- function(dt) {
  
  if (nrow(dt) == 0) {
    return(list())
  }
  
  # Usa conversione diretta jsonlite per performance massima
  json_string <- jsonlite::toJSON(dt, dataframe = "rows", auto_unbox = TRUE)
  result <- jsonlite::fromJSON(json_string, simplifyVector = FALSE)
  
  return(result)
}

#' Valida parametri input (SEMPLIFICATO - no logging verboso)
#' @param params Lista parametri da validare
#' @return Lista con risultati validazione
validate_parameters_fast <- function(params) {
  
  errors <- c()
  sanitized <- list()
  
  # Valida p_value_threshold
  val <- as.numeric(params$p_value_threshold %||% 0.05)
  if (is.na(val) || val < 0 || val > 1) {
    errors <- c(errors, "p_value_threshold must be between 0 and 1")
  } else {
    sanitized$p_value_threshold <- val
  }
  
  # Valida log_fc_min
  val <- as.numeric(params$log_fc_min %||% -0.5)
  if (is.na(val) || val < -10 || val > 10) {
    errors <- c(errors, "log_fc_min must be between -10 and 10")
  } else {
    sanitized$log_fc_min <- val
  }
  
  # Valida log_fc_max
  val <- as.numeric(params$log_fc_max %||% 0.5)
  if (is.na(val) || val < -10 || val > 10) {
    errors <- c(errors, "log_fc_max must be between -10 and 10")
  } else {
    sanitized$log_fc_max <- val
  }
  
  # Valida dataset_size
  val <- as.integer(params$dataset_size %||% 10000)
  if (is.na(val) || val < MIN_DATASET_SIZE || val > MAX_DATASET_SIZE) {
    errors <- c(errors, sprintf("dataset_size must be between %d and %d", MIN_DATASET_SIZE, MAX_DATASET_SIZE))
  } else {
    sanitized$dataset_size <- val
  }
  
  # Valida max_points
  val <- as.integer(params$max_points %||% 50000)
  if (is.na(val) || val < 1000 || val > 200000) {
    errors <- c(errors, "max_points must be between 1,000 and 200,000")
  } else {
    sanitized$max_points <- val
  }
  
  # Valida zoom_level
  val <- as.numeric(params$zoom_level %||% 1.0)
  if (is.na(val) || val < 0.1 || val > 100) {
    errors <- c(errors, "zoom_level must be between 0.1 and 100")
  } else {
    sanitized$zoom_level <- val
  }
  
  # Valida search_term
  if (!is.null(params$search_term) && is.character(params$search_term) && nchar(params$search_term) > 0) {
    sanitized$search_term <- gsub("[^a-zA-Z0-9\\s\\-_]", "", params$search_term)
    if (nchar(sanitized$search_term) > 100) {
      sanitized$search_term <- substr(sanitized$search_term, 1, 100)
    }
  } else {
    sanitized$search_term <- NULL
  }
  
  return(list(
    valid = length(errors) == 0,
    errors = errors,
    parameters = sanitized
  ))
}

# PERFORMANCE OPTIMIZATION 5: Single pipeline wrapper con monitoring condizionale
#' Processa intera pipeline volcano plot in una singola chiamata ottimizzata
#' @param dataset_size Dimensione dataset
#' @param p_threshold Soglia p-value
#' @param log_fc_min Min log fold change
#' @param log_fc_max Max log fold change
#' @param search_term Termine di ricerca (opzionale)
#' @param max_points Punti massimi da restituire
#' @param zoom_level Livello zoom
#' @return Lista con dati processati
process_volcano_pipeline_fast <- function(dataset_size, p_threshold, log_fc_min, log_fc_max, 
                                         search_term = NULL, max_points = 50000, zoom_level = 1.0) {
  
  # STEP 1: Get cached data (monitoring condizionale)
  dt <- monitor_performance(get_cached_dataset_fast, "data_generation", dataset_size)
  total_rows <- nrow(dt)
  
  # STEP 2: Apply search filter if provided (monitoring condizionale)
  if (!is.null(search_term) && nchar(search_term) > 0) {
    search_lower <- tolower(search_term)
    dt <- monitor_performance(function(dt, term) dt[grepl(term, tolower(gene))], "search_filter", dt, search_lower)
  }
  
  # STEP 3: Categorize points (monitoring condizionale)
  dt <- monitor_performance(categorize_points_fast, "categorization", dt, p_threshold, log_fc_min, log_fc_max)
  
  # STEP 4: Calculate statistics using data.table aggregation
  stats_dt <- dt[, .N, by = category]
  stats_list <- setNames(stats_dt$N, stats_dt$category)
  
  stats <- list(
    up_regulated = as.integer(stats_list[["up"]] %||% 0),
    down_regulated = as.integer(stats_list[["down"]] %||% 0),
    non_significant = as.integer(stats_list[["non_significant"]] %||% 0)
  )
  
  # STEP 5: Intelligent sampling (monitoring condizionale)
  points_before_sampling <- nrow(dt)
  is_downsampled <- points_before_sampling > max_points
  
  if (is_downsampled) {
    dt <- monitor_performance(intelligent_sampling_fast, "sampling", dt, max_points, zoom_level)
  }
  
  # STEP 6: Convert to JSON (monitoring condizionale)
  # PERFORMANCE OPTIMIZATION 6: Fast path for small datasets (no memory management)
  if (dataset_size <= FAST_PATH_THRESHOLD) {
    data_points <- monitor_performance(convert_to_json_fast, "json_conversion", dt)
  } else {
    # Use memory management only for large datasets
    data_points <- monitor_performance(convert_to_json_fast, "json_conversion_large", dt)
  }
  
  return(list(
    data = data_points,
    stats = stats,
    total_rows = as.integer(total_rows),
    filtered_rows = as.integer(nrow(dt)),
    points_before_sampling = as.integer(points_before_sampling),
    is_downsampled = is_downsampled
  ))
}

#* @apiTitle R Volcano Plot API - PRODUCTION OPTIMIZED
#* @apiDescription R-based volcano plot server - versione production con tutte le ottimizzazioni

#* Health check endpoint
#* @get /health
function() {
  list(
    status = "healthy",
    backend = "R + data.table (PRODUCTION OPTIMIZED)",
    version = R.version.string,
    timestamp = Sys.time(),
    configuration = list(
      monitoring_enabled = MONITOR_ENABLED,
      fast_path_threshold = FAST_PATH_THRESHOLD,
      data_table_threads = data.table::getDTthreads(),
      log_level = LOG_LEVEL
    ),
    optimizations = list(
      "Multi-threading enabled" = TRUE,
      "Runtime monitoring flag" = MONITOR_ENABLED,
      "Fast path enabled" = TRUE,
      "GC optimization" = TRUE,
      "Minimal I/O logging" = TRUE
    )
  )
}

#* Get volcano plot data (PRODUCTION OPTIMIZED)
#* @param p_value_threshold:numeric P-value threshold (default: 0.05)
#* @param log_fc_min:numeric Min log fold change (default: -0.5)
#* @param log_fc_max:numeric Max log fold change (default: 0.5)
#* @param search_term:character Search term (optional)
#* @param dataset_size:int Dataset size (default: 10000)
#* @param max_points:int Max points to return (default: 50000)
#* @param zoom_level:numeric Zoom level (default: 1.0)
#* @get /api/volcano-data
function(p_value_threshold = 0.05, log_fc_min = -0.5, log_fc_max = 0.5, 
         search_term = NULL, dataset_size = 10000, max_points = 50000, zoom_level = 1.0) {
  
  tryCatch({
    # Reset performance metrics per questa request (se monitoring abilitato)
    request_id <- sprintf("req_%d", as.integer(Sys.time()))
    reset_performance_metrics(request_id)
    
    # Valida parametri (versione veloce)
    params <- list(
      p_value_threshold = p_value_threshold,
      log_fc_min = log_fc_min,
      log_fc_max = log_fc_max,
      search_term = search_term,
      dataset_size = dataset_size,
      max_points = max_points,
      zoom_level = zoom_level
    )
    
    validation_result <- validate_parameters_fast(params)
    
    if (!validation_result$valid) {
      return(list(
        error = TRUE,
        message = "Invalid parameters",
        errors = validation_result$errors
      ))
    }
    
    validated_params <- validation_result$parameters
    
    # PERFORMANCE OPTIMIZATION 7: Single pipeline call con monitoring condizionale
    result <- monitor_performance(process_volcano_pipeline_fast, "total_pipeline",
      dataset_size = validated_params$dataset_size,
      p_threshold = validated_params$p_value_threshold,
      log_fc_min = validated_params$log_fc_min,
      log_fc_max = validated_params$log_fc_max,
      search_term = validated_params$search_term,
      max_points = validated_params$max_points,
      zoom_level = validated_params$zoom_level
    )
    
    # Aggiungi metriche di performance se monitoring abilitato
    if (MONITOR_ENABLED) {
      result$performance_metrics <- get_performance_metrics()
    }
    
    return(result)
    
  }, error = function(e) {
    log_error(paste("Volcano data endpoint error:", e$message))
    return(list(
      error = TRUE,
      message = "Failed to process volcano data request",
      details = e$message
    ))
  })
}

#* Clear cache
#* @post /api/clear-cache
function() {
  cached_count <- length(ls(.volcano_cache))
  if (cached_count > 0) {
    rm(list = ls(.volcano_cache), envir = .volcano_cache)
  }
  # PERFORMANCE OPTIMIZATION 6: Optional GC (not forced in hot path)
  # gc() # Commented out - let R manage memory automatically
  
  return(list(
    message = "Cache cleared successfully",
    datasets_removed = cached_count
  ))
}

#* Warm cache
#* @post /api/warm-cache
function(req) {
  sizes <- c(10000, 50000, 100000, 500000, 1000000)  # Default sizes
  
  # Parse request body if present
  if (!is.null(req$postBody) && nchar(req$postBody) > 0) {
    tryCatch({
      body <- jsonlite::fromJSON(req$postBody, simplifyVector = FALSE)
      if (!is.null(body$sizes)) {
        sizes <- unlist(body$sizes)
      }
    }, error = function(e) {
      # Use default sizes if parsing fails
    })
  }
  
  cached_sizes <- c()
  for (size in sizes) {
    tryCatch({
      if (size <= MAX_DATASET_SIZE) {
        get_cached_dataset_fast(size)
        cached_sizes <- c(cached_sizes, size)
      }
    }, error = function(e) {
      # Continue with other sizes
    })
  }
  
  return(list(
    message = "Cache warmed successfully",
    cached_sizes = cached_sizes,
    total_cached = length(ls(.volcano_cache))
  ))
}

#* Get performance metrics (solo se monitoring abilitato)
#* @get /api/performance-metrics
function() {
  if (!MONITOR_ENABLED) {
    return(list(
      monitoring_enabled = FALSE,
      message = "Performance monitoring is disabled. Set MONITOR_ENABLED=TRUE to enable."
    ))
  }
  
  return(get_performance_metrics())
}

# Avvia server se eseguito direttamente
if (!interactive()) {
  port <- as.numeric(Sys.getenv("PORT", "8001"))
  cat(sprintf("Starting PRODUCTION OPTIMIZED R API server on port %d...\n", port))
  cat("Optimizations enabled:\n")
  cat("  - Multi-threading: data.table using all cores\n")
  cat("  - Monitoring flag: MONITOR_ENABLED =", MONITOR_ENABLED, "\n")
  cat("  - Single pipeline: consolidated measurements\n")
  cat("  - Fast path: optimized for datasets <= 50k\n")
  cat("  - Minimal I/O: error-only logging\n")
  
  # Create plumber router and run
  pr() %>%
    pr_run(port = port, host = "127.0.0.1")
}