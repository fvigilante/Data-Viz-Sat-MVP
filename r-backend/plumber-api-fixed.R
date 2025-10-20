#!/usr/bin/env Rscript

library(plumber)
library(data.table)
library(jsonlite)

# Enable all CPU cores
data.table::setDTthreads(0L)

# Feature flag for monitoring (disabled by default)
MONITOR_ENABLED <- isTRUE(as.logical(Sys.getenv("MONITOR_ENABLED", "FALSE")))

# Global cache
.volcano_cache <- new.env()
if (MONITOR_ENABLED) {
  perf <- new.env()
  perf$timers <- list()
}

# Constants
METABOLITE_NAMES <- c(
  "1,3-Isoquinolinediol", "3,4-Dihydro-3-oxo-2H-(1,4)-benzoxazin-2-ylacetic acid",
  "(2-oxo-2,3-dihydro-1H-indol-3-yl)acetic acid", "Resedine", "Methionine sulfoxide",
  "trans-Urocanic acid", "Pro-Tyr", "Glu-Gly-Glu", "NP-024517", "Trp-Pro"
)

SUPERCLASSES <- c(
  "Organic acids and derivatives", "Organoheterocyclic compounds",
  "Lipids and lipid-like molecules", "Others", "Nucleosides, nucleotides, and analogues"
)

CLASSES <- c(
  "Carboxylic acids and derivatives", "Indoles and derivatives", "Benzoxazines",
  "Azolidines", "Azoles", "Biotin and derivatives", "Pyridines and derivatives"
)

# Null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Conditional monitoring wrapper
monitor_performance <- function(fun, label, ...) {
  if (!MONITOR_ENABLED) return(fun(...))
  
  t0 <- proc.time()[["elapsed"]]
  res <- fun(...)
  elapsed <- proc.time()[["elapsed"]] - t0
  perf$timers[[label]] <- elapsed
  res
}

# Data generation
generate_volcano_data <- function(size) {
  size <- max(100, min(10000000, as.integer(size)))
  set.seed(42)
  
  # Generate data
  log_fc <- rnorm(size, mean = 0, sd = 1.2)
  p_values <- runif(size, min = 0.0001, max = 1.0)
  
  # Create significant points
  sig_indices <- sample(size, size * 0.15)
  p_values[sig_indices] <- runif(length(sig_indices), min = 0.0001, max = 0.05)
  
  gene_names <- paste0("Gene_", 1:size)
  
  dt <- data.table(
    gene = gene_names,
    logFC = round(log_fc, 4),
    padj = round(p_values, 6),
    classyfireSuperclass = sample(SUPERCLASSES, size, replace = TRUE),
    classyfireClass = sample(CLASSES, size, replace = TRUE)
  )
  
  return(dt)
}

get_cached_dataset <- function(size) {
  cache_key <- as.character(size)
  
  if (exists(cache_key, envir = .volcano_cache)) {
    return(get(cache_key, envir = .volcano_cache))
  }
  
  dt <- generate_volcano_data(size)
  assign(cache_key, dt, envir = .volcano_cache)
  return(dt)
}

categorize_points <- function(dt, p_threshold, log_fc_min, log_fc_max) {
  dt[, category := fifelse(
    padj <= p_threshold & logFC < log_fc_min, "down",
    fifelse(
      padj <= p_threshold & logFC > log_fc_max, "up",
      "non_significant"
    )
  )]
  return(dt)
}

convert_to_json <- function(dt) {
  if (nrow(dt) == 0) return(list())
  
  # Return data.table directly - let plumber handle JSON serialization
  return(dt)
}

# Main pipeline function
process_volcano_pipeline <- function(dataset_size, p_threshold, log_fc_min, log_fc_max, 
                                   search_term = NULL, max_points = 50000, zoom_level = 1.0) {
  
  dt <- monitor_performance(get_cached_dataset, "data_generation", dataset_size)
  total_rows <- nrow(dt)
  
  if (!is.null(search_term) && nchar(search_term) > 0) {
    search_lower <- tolower(search_term)
    dt <- dt[grepl(search_lower, tolower(gene))]
  }
  
  dt <- monitor_performance(categorize_points, "categorization", dt, p_threshold, log_fc_min, log_fc_max)
  
  stats_dt <- dt[, .N, by = category]
  stats_list <- setNames(stats_dt$N, stats_dt$category)
  
  stats <- list(
    up_regulated = as.integer(stats_list[["up"]] %||% 0),
    down_regulated = as.integer(stats_list[["down"]] %||% 0),
    non_significant = as.integer(stats_list[["non_significant"]] %||% 0)
  )
  
  points_before_sampling <- nrow(dt)
  is_downsampled <- points_before_sampling > max_points
  
  if (is_downsampled) {
    sample_indices <- sample(nrow(dt), max_points)
    dt <- dt[sample_indices]
  }
  
  data_points <- monitor_performance(convert_to_json, "json_conversion", dt)
  
  return(list(
    data = data_points,
    stats = stats,
    total_rows = as.integer(total_rows),
    filtered_rows = as.integer(nrow(dt)),
    points_before_sampling = as.integer(points_before_sampling),
    is_downsampled = is_downsampled
  ))
}

# Create plumber router
pr <- pr() %>%
  pr_get("/health", function() {
    list(
      status = "healthy",
      backend = "R + data.table (UNIFIED OPTIMIZED)",
      timestamp = Sys.time(),
      monitoring_enabled = MONITOR_ENABLED,
      threads = data.table::getDTthreads()
    )
  }) %>%
  pr_get("/api/volcano-data", function(p_value_threshold = 0.05, log_fc_min = -0.5, log_fc_max = 0.5, 
                                      search_term = NULL, dataset_size = 10000, max_points = 50000, zoom_level = 1.0) {
    
    tryCatch({
      if (MONITOR_ENABLED) {
        perf$timers <- list()
      }
      
      dataset_size <- as.integer(dataset_size %||% 10000)
      max_points <- as.integer(max_points %||% 50000)
      p_value_threshold <- as.numeric(p_value_threshold %||% 0.05)
      log_fc_min <- as.numeric(log_fc_min %||% -0.5)
      log_fc_max <- as.numeric(log_fc_max %||% 0.5)
      zoom_level <- as.numeric(zoom_level %||% 1.0)
      
      result <- monitor_performance(process_volcano_pipeline, "total_pipeline",
        dataset_size = dataset_size,
        p_threshold = p_value_threshold,
        log_fc_min = log_fc_min,
        log_fc_max = log_fc_max,
        search_term = search_term,
        max_points = max_points,
        zoom_level = zoom_level
      )
      
      if (MONITOR_ENABLED) {
        result$performance_metrics <- list(
          monitoring_enabled = TRUE,
          timers = perf$timers,
          total_time = sum(unlist(perf$timers), na.rm = TRUE)
        )
      }
      
      return(result)
      
    }, error = function(e) {
      return(list(
        error = TRUE,
        message = "Failed to process volcano data request",
        details = e$message
      ))
    })
  }) %>%
  pr_post("/api/clear-cache", function() {
    cached_count <- length(ls(.volcano_cache))
    if (cached_count > 0) {
      rm(list = ls(.volcano_cache), envir = .volcano_cache)
    }
    return(list(
      message = "Cache cleared successfully",
      datasets_removed = cached_count
    ))
  })

# Start server
if (!interactive()) {
  port <- as.numeric(Sys.getenv("PORT", "8001"))
  cat(sprintf("Starting R API server on port %d...\n", port))
  cat("Monitoring enabled:", MONITOR_ENABLED, "\n")
  
  pr %>% pr_run(port = port, host = "127.0.0.1")
}