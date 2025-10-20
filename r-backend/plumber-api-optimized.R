#!/usr/bin/env Rscript

# R Volcano Plot API Server - OPTIMIZED VERSION (No Monitoring Overhead)
# Versione ottimizzata senza overhead di monitoring per test performance

library(plumber)
library(data.table)
library(jsonlite)

# Configurazione semplificata
LOG_LEVEL <- "ERROR"  # Solo errori critici

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

# Null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Genera dati volcano sintetici (OTTIMIZZATO - no monitoring)
#' @param size Numero di metaboliti da generare
#' @return data.table con dati volcano sintetici
generate_volcano_data_optimized <- function(size) {
  
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

#' Ottieni dataset cached o genera nuovo (OTTIMIZZATO)
#' @param size Dimensione dataset
#' @return data.table con dati volcano
get_cached_dataset_optimized <- function(size) {
  
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
  dt <- generate_volcano_data_optimized(size)
  
  # Cache il risultato
  tryCatch({
    assign(cache_key, dt, envir = .volcano_cache)
  }, error = function(e) {
    # Continua senza cache se fallisce
  })
  
  return(dt)
}

#' Categorizza punti basato su soglie significatività (OTTIMIZZATO)
#' @param dt data.table con colonne logFC e padj
#' @param p_threshold Soglia p-value per significatività
#' @param log_fc_min Log fold change minimo per up-regulation
#' @param log_fc_max Log fold change massimo per down-regulation
#' @return data.table con colonna category aggiunta
categorize_points_optimized <- function(dt, p_threshold, log_fc_min, log_fc_max) {
  
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
intelligent_sampling_optimized <- function(dt, max_points, zoom_level = 1.0) {
  
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

#' Converti data.table in formato JSON (OTTIMIZZATO)
#' @param dt data.table con dati volcano
#' @return Lista di punti dati per serializzazione JSON
convert_to_data_points_optimized <- function(dt) {
  
  if (nrow(dt) == 0) {
    return(list())
  }
  
  # Usa conversione diretta jsonlite per performance massima
  json_string <- jsonlite::toJSON(dt, dataframe = "rows", auto_unbox = TRUE)
  result <- jsonlite::fromJSON(json_string, simplifyVector = FALSE)
  
  return(result)
}

#' Valida parametri input (SEMPLIFICATO)
#' @param params Lista parametri da validare
#' @return Lista con risultati validazione
validate_parameters_simple <- function(params) {
  
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

#* @apiTitle R Volcano Plot API - OPTIMIZED
#* @apiDescription R-based volcano plot server - versione ottimizzata senza monitoring overhead

#* Health check endpoint
#* @get /health
function() {
  list(
    status = "healthy",
    backend = "R + data.table (OPTIMIZED)",
    version = R.version.string,
    timestamp = Sys.time()
  )
}

#* Get volcano plot data (OTTIMIZZATO)
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
    # Valida parametri (versione semplificata)
    params <- list(
      p_value_threshold = p_value_threshold,
      log_fc_min = log_fc_min,
      log_fc_max = log_fc_max,
      search_term = search_term,
      dataset_size = dataset_size,
      max_points = max_points,
      zoom_level = zoom_level
    )
    
    validation_result <- validate_parameters_simple(params)
    
    if (!validation_result$valid) {
      return(list(
        error = TRUE,
        message = "Invalid parameters",
        errors = validation_result$errors
      ))
    }
    
    validated_params <- validation_result$parameters
    
    # Ottieni dati cached (SENZA monitoring)
    dt <- get_cached_dataset_optimized(validated_params$dataset_size)
    total_rows <- nrow(dt)
    
    # Applica filtro ricerca se fornito (SENZA monitoring)
    if (!is.null(validated_params$search_term) && nchar(validated_params$search_term) > 0) {
      search_lower <- tolower(validated_params$search_term)
      dt <- dt[grepl(search_lower, tolower(gene))]
    }
    
    # Categorizza punti (SENZA monitoring)
    dt <- categorize_points_optimized(dt, validated_params$p_value_threshold, 
                                    validated_params$log_fc_min, validated_params$log_fc_max)
    
    # Calcola statistiche usando aggregazione data.table
    stats_dt <- dt[, .N, by = category]
    stats_list <- setNames(stats_dt$N, stats_dt$category)
    
    stats <- list(
      up_regulated = as.integer(stats_list[["up"]] %||% 0),
      down_regulated = as.integer(stats_list[["down"]] %||% 0),
      non_significant = as.integer(stats_list[["non_significant"]] %||% 0)
    )
    
    # Sampling intelligente (SENZA monitoring)
    points_before_sampling <- nrow(dt)
    is_downsampled <- points_before_sampling > validated_params$max_points
    
    if (is_downsampled) {
      dt <- intelligent_sampling_optimized(dt, validated_params$max_points, validated_params$zoom_level)
    }
    
    # Converti in formato lista per risposta JSON (SENZA monitoring)
    data_points <- convert_to_data_points_optimized(dt)
    
    # Restituisci risposta matching struttura Python FastAPI
    return(list(
      data = data_points,
      stats = stats,
      total_rows = as.integer(total_rows),
      filtered_rows = as.integer(nrow(dt)),
      points_before_sampling = as.integer(points_before_sampling),
      is_downsampled = is_downsampled
    ))
    
  }, error = function(e) {
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
  gc()
  
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
        get_cached_dataset_optimized(size)
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

# Avvia server se eseguito direttamente
if (!interactive()) {
  port <- as.numeric(Sys.getenv("PORT", "8002"))  # Porta diversa per test
  cat(sprintf("Starting OPTIMIZED R API server on port %d...\n", port))
  cat("This version has NO monitoring overhead for performance testing\n")
  
  pr() %>%
    pr_run(port = port, host = "127.0.0.1")
}