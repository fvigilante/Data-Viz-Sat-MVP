#!/usr/bin/env Rscript

# R Volcano Plot API Server using Plumber
# This server provides R-based volcano plot data processing endpoints

library(plumber)
library(data.table)
library(jsonlite)

# Enhanced logging and error handling system
LOG_LEVEL <- Sys.getenv("R_LOG_LEVEL", "INFO")  # DEBUG, INFO, WARN, ERROR
LOG_FILE <- Sys.getenv("R_LOG_FILE", "")  # Empty means console only

# Log levels hierarchy
LOG_LEVELS <- list(DEBUG = 1, INFO = 2, WARN = 3, ERROR = 4)

#' Enhanced logging function with multiple levels and optional file output
#' @param message Character message to log
#' @param level Character log level (DEBUG, INFO, WARN, ERROR)
#' @param context Character optional context information
log_message <- function(message, level = "INFO", context = NULL) {
  # Check if this level should be logged
  current_level <- LOG_LEVELS[[LOG_LEVEL]]
  message_level <- LOG_LEVELS[[level]]
  
  if (is.null(current_level)) current_level <- LOG_LEVELS[["INFO"]]
  if (is.null(message_level)) message_level <- LOG_LEVELS[["INFO"]]
  
  if (message_level < current_level) {
    return(invisible())
  }
  
  # Format timestamp
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  
  # Format context if provided
  context_str <- if (!is.null(context)) paste0(" [", context, "]") else ""
  
  # Create formatted log message
  log_entry <- sprintf("[%s] %s%s: %s", timestamp, level, context_str, message)
  
  # Output to console
  cat(log_entry, "\n")
  
  # Output to file if specified
  if (nchar(LOG_FILE) > 0) {
    tryCatch({
      cat(log_entry, "\n", file = LOG_FILE, append = TRUE)
    }, error = function(e) {
      cat("Failed to write to log file:", e$message, "\n")
    })
  }
}

#' Create standardized error response matching FastAPI format
#' @param message Character error message
#' @param status_code Integer HTTP status code
#' @param error_type Character type of error
#' @param details List additional error details
#' @return List formatted error response
create_error_response <- function(message, status_code = 500, error_type = "internal_error", details = NULL) {
  error_response <- list(
    error = TRUE,
    message = message,
    error_type = error_type,
    status_code = status_code,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    backend = "R + data.table"
  )
  
  if (!is.null(details)) {
    error_response$details <- details
  }
  
  return(error_response)
}

#' Validate and sanitize input parameters with detailed error messages
#' @param params List of parameters to validate
#' @return List with validation results and sanitized parameters
validate_parameters <- function(params) {
  errors <- list()
  sanitized <- list()
  
  # Validate p_value_threshold
  if (!is.null(params$p_value_threshold)) {
    tryCatch({
      val <- as.numeric(params$p_value_threshold)
      if (is.na(val) || val < 0 || val > 1) {
        errors <- append(errors, "p_value_threshold must be a number between 0 and 1")
      } else {
        sanitized$p_value_threshold <- val
      }
    }, error = function(e) {
      errors <- append(errors, paste("p_value_threshold conversion error:", e$message))
    })
  } else {
    sanitized$p_value_threshold <- 0.05
  }
  
  # Validate log_fc_min
  if (!is.null(params$log_fc_min)) {
    tryCatch({
      val <- as.numeric(params$log_fc_min)
      if (is.na(val) || val < -10 || val > 10) {
        errors <- append(errors, "log_fc_min must be a number between -10 and 10")
      } else {
        sanitized$log_fc_min <- val
      }
    }, error = function(e) {
      errors <- append(errors, paste("log_fc_min conversion error:", e$message))
    })
  } else {
    sanitized$log_fc_min <- -0.5
  }
  
  # Validate log_fc_max
  if (!is.null(params$log_fc_max)) {
    tryCatch({
      val <- as.numeric(params$log_fc_max)
      if (is.na(val) || val < -10 || val > 10) {
        errors <- append(errors, "log_fc_max must be a number between -10 and 10")
      } else {
        sanitized$log_fc_max <- val
      }
    }, error = function(e) {
      errors <- append(errors, paste("log_fc_max conversion error:", e$message))
    })
  } else {
    sanitized$log_fc_max <- 0.5
  }
  
  # Validate dataset_size
  if (!is.null(params$dataset_size)) {
    tryCatch({
      val <- as.integer(params$dataset_size)
      if (is.na(val) || val < MIN_DATASET_SIZE || val > MAX_DATASET_SIZE) {
        errors <- append(errors, sprintf("dataset_size must be an integer between %d and %d", MIN_DATASET_SIZE, MAX_DATASET_SIZE))
      } else {
        sanitized$dataset_size <- val
      }
    }, error = function(e) {
      errors <- append(errors, paste("dataset_size conversion error:", e$message))
    })
  } else {
    sanitized$dataset_size <- 10000L
  }
  
  # Validate max_points
  if (!is.null(params$max_points)) {
    tryCatch({
      val <- as.integer(params$max_points)
      if (is.na(val) || val < 1000 || val > 200000) {
        errors <- append(errors, "max_points must be an integer between 1,000 and 200,000")
      } else {
        sanitized$max_points <- val
      }
    }, error = function(e) {
      errors <- append(errors, paste("max_points conversion error:", e$message))
    })
  } else {
    sanitized$max_points <- 50000L
  }
  
  # Validate zoom_level
  if (!is.null(params$zoom_level)) {
    tryCatch({
      val <- as.numeric(params$zoom_level)
      if (is.na(val) || val < 0.1 || val > 100) {
        errors <- append(errors, "zoom_level must be a number between 0.1 and 100")
      } else {
        sanitized$zoom_level <- val
      }
    }, error = function(e) {
      errors <- append(errors, paste("zoom_level conversion error:", e$message))
    })
  } else {
    sanitized$zoom_level <- 1.0
  }
  
  # Validate search_term (optional string)
  if (!is.null(params$search_term)) {
    if (is.character(params$search_term) && nchar(params$search_term) > 0) {
      # Sanitize search term to prevent injection
      sanitized$search_term <- gsub("[^a-zA-Z0-9\\s\\-_]", "", params$search_term)
      if (nchar(sanitized$search_term) > 100) {
        sanitized$search_term <- substr(sanitized$search_term, 1, 100)
      }
    } else {
      sanitized$search_term <- NULL
    }
  } else {
    sanitized$search_term <- NULL
  }
  
  # Validate lod_mode
  if (!is.null(params$lod_mode)) {
    tryCatch({
      sanitized$lod_mode <- as.logical(params$lod_mode)
    }, error = function(e) {
      sanitized$lod_mode <- TRUE
    })
  } else {
    sanitized$lod_mode <- TRUE
  }
  
  return(list(
    valid = length(errors) == 0,
    errors = errors,
    parameters = sanitized
  ))
}

#' Performance monitoring wrapper for functions
#' @param func Function to monitor
#' @param func_name Character name of the function for logging
#' @param ... Arguments to pass to the function
#' @return Function result with performance logging
monitor_performance <- function(func, func_name, ...) {
  start_time <- Sys.time()
  start_memory <- gc(verbose = FALSE)
  
  log_message(sprintf("Starting %s", func_name), "DEBUG", "PERFORMANCE")
  
  tryCatch({
    result <- func(...)
    
    end_time <- Sys.time()
    end_memory <- gc(verbose = FALSE)
    
    duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
    memory_used <- sum(end_memory[, 2]) - sum(start_memory[, 2])
    
    log_message(sprintf("%s completed in %.3f seconds, memory change: %.2f MB", 
                       func_name, duration, memory_used), "INFO", "PERFORMANCE")
    
    return(result)
  }, error = function(e) {
    end_time <- Sys.time()
    duration <- as.numeric(difftime(end_time, start_time, units = "secs"))
    
    log_message(sprintf("%s failed after %.3f seconds: %s", 
                       func_name, duration, e$message), "ERROR", "PERFORMANCE")
    
    stop(e)
  })
}

# Global cache for datasets
.volcano_cache <- new.env()

# Null-coalescing operator for cleaner default value handling
`%||%` <- function(x, y) if (is.null(x)) y else x

# Constants for data generation (matching Python implementation)
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

# Dataset size limits for memory management
MAX_DATASET_SIZE <- 10000000  # 10M rows maximum
MIN_DATASET_SIZE <- 100       # 100 rows minimum

#' Validate dataset size for memory management with enhanced logging
#' @param size Integer dataset size to validate
#' @return Validated size within limits
validate_dataset_size <- function(size) {
  log_message(sprintf("Validating dataset size: %s", size), "DEBUG", "VALIDATION")
  
  if (!is.numeric(size) || length(size) != 1 || is.na(size)) {
    error_msg <- "Dataset size must be a single numeric value"
    log_message(error_msg, "ERROR", "VALIDATION")
    stop(error_msg)
  }
  
  size <- as.integer(size)
  
  if (size < MIN_DATASET_SIZE) {
    warning_msg <- sprintf("Dataset size %d is below minimum %d, using minimum", size, MIN_DATASET_SIZE)
    log_message(warning_msg, "WARN", "VALIDATION")
    return(MIN_DATASET_SIZE)
  }
  
  if (size > MAX_DATASET_SIZE) {
    warning_msg <- sprintf("Dataset size %d exceeds maximum %d, using maximum", size, MAX_DATASET_SIZE)
    log_message(warning_msg, "WARN", "VALIDATION")
    return(MAX_DATASET_SIZE)
  }
  
  log_message(sprintf("Dataset size %d validated successfully", size), "DEBUG", "VALIDATION")
  return(size)
}

#' Generate synthetic volcano plot data using vectorized operations
#' Matches the Python implementation logic for consistency
#' @param size Integer number of metabolites to generate
#' @return data.table with synthetic volcano plot data
generate_volcano_data <- function(size) {
  log_message(sprintf("Starting data generation for size %d", size), "INFO", "DATA_GEN")
  
  tryCatch({
    # Validate input size
    size <- validate_dataset_size(size)
    
    log_message(sprintf("Generating new dataset of size %d...", size), "INFO", "DATA_GEN")
  
  # Set seed for reproducible results (matching Python)
  set.seed(42)
  
  # Define proportions for realistic volcano plot (matching Python)
  non_sig_proportion <- 0.85   # 85% non-significant
  up_reg_proportion <- 0.075   # 7.5% up-regulated
  down_reg_proportion <- 0.075 # 7.5% down-regulated
  
  # Calculate counts for each category
  n_non_sig <- as.integer(size * non_sig_proportion)
  n_up_reg <- as.integer(size * up_reg_proportion)
  n_down_reg <- size - n_non_sig - n_up_reg  # Remaining
  
  # Generate log fold changes for each category using vectorized operations
  # Non-significant: centered around 0, small fold changes
  log_fc_non_sig <- rnorm(n_non_sig, mean = 0, sd = 0.6)
  
  # Up-regulated: positive fold changes, concentrated but significant
  log_fc_up <- rnorm(n_up_reg, mean = 1.5, sd = 0.8)
  
  # Down-regulated: negative fold changes, concentrated but significant
  log_fc_down <- rnorm(n_down_reg, mean = -1.5, sd = 0.8)
  
  # Combine all fold changes
  log_fc <- c(log_fc_non_sig, log_fc_up, log_fc_down)
  
  # Generate realistic p-values based on fold change magnitude
  p_values <- numeric(size)
  
  # Non-significant points: high p-values (0.1 to 1.0)
  p_values[1:n_non_sig] <- runif(n_non_sig, min = 0.1, max = 1.0)
  
  # Significant points: low p-values
  # Up-regulated: low p-values
  p_values[(n_non_sig + 1):(n_non_sig + n_up_reg)] <- runif(n_up_reg, min = 0.0001, max = 0.05)
  
  # Down-regulated: low p-values
  p_values[(n_non_sig + n_up_reg + 1):size] <- runif(n_down_reg, min = 0.0001, max = 0.05)
  
  # Add noise to make it more realistic (matching Python)
  noise_factor <- 0.1
  log_fc <- log_fc + rnorm(size, mean = 0, sd = noise_factor)
  
  # Ensure p-values are within valid range
  p_values <- pmax(0.0001, pmin(1.0, p_values))
  
  # Round for cleaner display (matching Python)
  log_fc <- round(log_fc, 4)
  p_values <- round(p_values, 6)
  
  # Shuffle to mix the categories (matching Python)
  indices <- sample(size)
  log_fc <- log_fc[indices]
  p_values <- p_values[indices]
  
  # Generate gene names efficiently
  gene_names <- character(size)
  for (i in 1:size) {
    if (i <= length(METABOLITE_NAMES)) {
      gene_names[i] <- METABOLITE_NAMES[((i - 1) %% length(METABOLITE_NAMES)) + 1]
    } else {
      gene_names[i] <- sprintf("Metabolite_%d", i)
    }
  }
  
  # Generate classifications using vectorized sampling
  superclass_indices <- sample(length(SUPERCLASSES), size, replace = TRUE)
  class_indices <- sample(length(CLASSES), size, replace = TRUE)
  
  # Create data.table directly with all data for optimal performance
  dt <- data.table(
    gene = gene_names,
    logFC = log_fc,
    padj = p_values,
    classyfireSuperclass = SUPERCLASSES[superclass_indices],
    classyfireClass = CLASSES[class_indices]
  )
  
    log_message(sprintf("Dataset of size %d generated successfully", size), "INFO", "DATA_GEN")
    
    return(dt)
  }, error = function(e) {
    error_msg <- sprintf("Failed to generate dataset of size %d: %s", size, e$message)
    log_message(error_msg, "ERROR", "DATA_GEN")
    stop(error_msg)
  })
}

#' Get cached dataset or generate new one if not cached
#' Implements caching mechanism using R environments with enhanced error handling
#' @param size Integer dataset size
#' @return data.table with volcano plot data
get_cached_dataset <- function(size) {
  log_message(sprintf("Requesting dataset of size %d", size), "DEBUG", "CACHE")
  
  tryCatch({
    # Validate size
    size <- validate_dataset_size(size)
    
    # Convert size to character for environment key
    cache_key <- as.character(size)
    
    # Check if dataset exists in cache
    if (exists(cache_key, envir = .volcano_cache)) {
      log_message(sprintf("Returning cached dataset of size %d", size), "INFO", "CACHE")
      cached_data <- get(cache_key, envir = .volcano_cache)
      
      # Validate cached data integrity
      if (!is.data.table(cached_data) || nrow(cached_data) == 0) {
        log_message(sprintf("Cached dataset of size %d is corrupted, regenerating", size), "WARN", "CACHE")
        rm(list = cache_key, envir = .volcano_cache)
      } else {
        return(cached_data)
      }
    }
    
    # Generate new dataset with performance monitoring
    dt <- monitor_performance(generate_volcano_data, "generate_volcano_data", size)
    
    # Cache the result with error handling
    tryCatch({
      assign(cache_key, dt, envir = .volcano_cache)
      log_message(sprintf("Dataset of size %d cached successfully", size), "INFO", "CACHE")
    }, error = function(cache_error) {
      log_message(sprintf("Failed to cache dataset of size %d: %s", size, cache_error$message), "WARN", "CACHE")
      # Continue without caching - return the generated data
    })
    
    return(dt)
  }, error = function(e) {
    error_msg <- sprintf("Failed to get dataset of size %d: %s", size, e$message)
    log_message(error_msg, "ERROR", "CACHE")
    stop(error_msg)
  })
}

#' Get cache status information with enhanced error handling
#' @return List with cache statistics
get_cache_status <- function() {
  log_message("Getting cache status", "DEBUG", "CACHE")
  
  tryCatch({
    cached_sizes <- ls(.volcano_cache)
    
    # Convert cached sizes back to integers and sort
    if (length(cached_sizes) > 0) {
      cached_sizes_int <- tryCatch({
        as.integer(cached_sizes)
      }, error = function(e) {
        log_message(sprintf("Error converting cached sizes: %s", e$message), "WARN", "CACHE")
        integer(0)
      })
      cached_sizes_int <- sort(cached_sizes_int[!is.na(cached_sizes_int)])
    } else {
      cached_sizes_int <- integer(0)
    }
    
    # Calculate memory usage (approximate) with error handling
    total_memory_mb <- 0
    corrupted_keys <- character(0)
    
    if (length(cached_sizes) > 0) {
      for (key in cached_sizes) {
        tryCatch({
          dt <- get(key, envir = .volcano_cache)
          if (is.data.table(dt) && nrow(dt) > 0) {
            # Approximate memory usage: each row ~200 bytes
            total_memory_mb <- total_memory_mb + (nrow(dt) * 200 / 1024 / 1024)
          } else {
            corrupted_keys <- c(corrupted_keys, key)
          }
        }, error = function(e) {
          log_message(sprintf("Error accessing cached dataset %s: %s", key, e$message), "WARN", "CACHE")
          corrupted_keys <- c(corrupted_keys, key)
        })
      }
    }
    
    # Clean up corrupted cache entries
    if (length(corrupted_keys) > 0) {
      log_message(sprintf("Removing %d corrupted cache entries", length(corrupted_keys)), "WARN", "CACHE")
      rm(list = corrupted_keys, envir = .volcano_cache)
      # Recalculate after cleanup
      cached_sizes <- ls(.volcano_cache)
      if (length(cached_sizes) > 0) {
        cached_sizes_int <- sort(as.integer(cached_sizes))
      } else {
        cached_sizes_int <- integer(0)
      }
    }
    
    result <- list(
      cached_datasets = I(cached_sizes_int),
      total_cached = length(cached_sizes),
      approximate_memory_mb = round(total_memory_mb, 2),
      corrupted_entries_removed = length(corrupted_keys)
    )
    
    log_message(sprintf("Cache status: %d datasets, %.2f MB", result$total_cached, result$approximate_memory_mb), "INFO", "CACHE")
    
    return(result)
  }, error = function(e) {
    error_msg <- sprintf("Failed to get cache status: %s", e$message)
    log_message(error_msg, "ERROR", "CACHE")
    stop(error_msg)
  })
}

#' Clear all cached datasets with enhanced error handling
#' @return List with operation result
clear_cache <- function() {
  log_message("Clearing cache", "INFO", "CACHE")
  
  tryCatch({
    cached_count <- length(ls(.volcano_cache))
    
    if (cached_count > 0) {
      rm(list = ls(.volcano_cache), envir = .volcano_cache)
      log_message(sprintf("Removed %d cached datasets", cached_count), "INFO", "CACHE")
    } else {
      log_message("Cache was already empty", "INFO", "CACHE")
    }
    
    # Force garbage collection to free memory
    gc_result <- gc()
    memory_freed <- sum(gc_result[, 2])
    
    log_message(sprintf("Garbage collection completed, memory freed: %.2f MB", memory_freed), "DEBUG", "CACHE")
    
    return(list(
      message = "Cache cleared successfully",
      datasets_removed = cached_count,
      memory_freed_mb = round(memory_freed, 2)
    ))
  }, error = function(e) {
    error_msg <- sprintf("Failed to clear cache: %s", e$message)
    log_message(error_msg, "ERROR", "CACHE")
    stop(error_msg)
  })
}

#' Warm cache with common dataset sizes and enhanced error handling
#' @param sizes Vector of dataset sizes to pre-generate
#' @return List with operation result
warm_cache <- function(sizes = c(10000, 50000, 100000, 500000, 1000000)) {
  log_message(sprintf("Starting cache warming for %d sizes", length(sizes)), "INFO", "CACHE")
  
  cached_sizes <- c()
  failed_sizes <- c()
  
  for (size in sizes) {
    tryCatch({
      log_message(sprintf("Warming cache for size %d", size), "DEBUG", "CACHE")
      
      # Validate size before caching
      validated_size <- validate_dataset_size(size)
      
      # Use performance monitoring for cache warming
      monitor_performance(get_cached_dataset, sprintf("cache_warm_%d", validated_size), validated_size)
      
      cached_sizes <- c(cached_sizes, validated_size)
      log_message(sprintf("Successfully cached dataset of size %d", validated_size), "INFO", "CACHE")
      
    }, error = function(e) {
      error_msg <- sprintf("Failed to cache dataset of size %d: %s", size, e$message)
      log_message(error_msg, "WARN", "CACHE")
      failed_sizes <- c(failed_sizes, size)
    })
  }
  
  result <- list(
    message = "Cache warming completed",
    cached_sizes = cached_sizes,
    failed_sizes = failed_sizes,
    total_cached = length(ls(.volcano_cache)),
    success_rate = round(length(cached_sizes) / length(sizes) * 100, 1)
  )
  
  log_message(sprintf("Cache warming completed: %d/%d successful (%.1f%%)", 
                     length(cached_sizes), length(sizes), result$success_rate), "INFO", "CACHE")
  
  return(result)
}

#' Categorize data points based on significance thresholds
#' Matches Python implementation logic using data.table operations
#' @param dt data.table with logFC and padj columns
#' @param p_threshold Numeric p-value threshold for significance
#' @param log_fc_min Numeric minimum log fold change for up-regulation
#' @param log_fc_max Numeric maximum log fold change for down-regulation
#' @return data.table with added category column
categorize_points <- function(dt, p_threshold, log_fc_min, log_fc_max) {
  # Use data.table's efficient conditional assignment
  dt[, category := fifelse(
    padj <= p_threshold & logFC < log_fc_min, "down",
    fifelse(
      padj <= p_threshold & logFC > log_fc_max, "up",
      "non_significant"
    )
  )]
  
  return(dt)
}

#' Convert data.table to JSON-friendly list format
#' Ensures proper scalar values for JSON serialization
#' @param dt data.table with volcano plot data
#' @return List of data points ready for JSON serialization
convert_to_data_points <- function(dt) {
  data_points <- list()
  if (nrow(dt) > 0) {
    for (i in 1:nrow(dt)) {
      data_points[[i]] <- list(
        gene = dt$gene[i][[1]],
        logFC = dt$logFC[i][[1]],
        padj = dt$padj[i][[1]],
        classyfireSuperclass = dt$classyfireSuperclass[i][[1]],
        classyfireClass = dt$classyfireClass[i][[1]],
        category = dt$category[i][[1]]
      )
    }
  }
  return(data_points)
}

#' Apply spatial filtering based on visible plot area
#' Matches Python implementation for level-of-detail loading
#' @param dt data.table with logFC and padj columns
#' @param x_range Numeric vector with min/max X range (optional)
#' @param y_range Numeric vector with min/max Y range (optional)
#' @return Filtered data.table
apply_spatial_filter <- function(dt, x_range = NULL, y_range = NULL) {
  if (is.null(x_range) || is.null(y_range)) {
    return(dt)
  }
  
  # Convert p-values to -log10 for Y filtering
  dt[, neg_log_padj := -log10(padj)]
  
  # Add buffer around visible area (20% on each side)
  x_buffer <- (x_range[2] - x_range[1]) * 0.2
  y_buffer <- (y_range[2] - y_range[1]) * 0.2
  
  # Apply spatial filter
  filtered_dt <- dt[
    logFC >= (x_range[1] - x_buffer) & 
    logFC <= (x_range[2] + x_buffer) &
    neg_log_padj >= (y_range[1] - y_buffer) & 
    neg_log_padj <= (y_range[2] + y_buffer)
  ]
  
  # Remove temporary column
  filtered_dt[, neg_log_padj := NULL]
  
  return(filtered_dt)
}

#' Calculate adaptive max points based on zoom level
#' Matches Python implementation for level-of-detail loading
#' @param zoom_level Numeric zoom level
#' @param base_points Integer base number of points
#' @return Integer maximum points for this zoom level
get_lod_max_points <- function(zoom_level, base_points = 2000) {
  # Exponential scaling: 2K at zoom 1x, up to 200K at high zoom
  max_adaptive_points <- 200000
  zoom_multiplier <- min(zoom_level^1.5, 100)  # Cap at 100x multiplier
  
  return(as.integer(min(base_points * zoom_multiplier, max_adaptive_points)))
}

#' Intelligent sampling that prioritizes significant points
#' Matches Python implementation logic using data.table operations
#' @param dt data.table with category column
#' @param max_points Integer maximum points to return
#' @param zoom_level Numeric zoom level for adaptive sampling
#' @return Sampled data.table
intelligent_sampling <- function(dt, max_points, zoom_level = 1.0) {
  if (nrow(dt) <= max_points) {
    return(dt)
  }
  
  # Separate by significance
  significant_dt <- dt[category != "non_significant"]
  non_significant_dt <- dt[category == "non_significant"]
  
  # At higher zoom levels, include more non-significant points for context
  sig_ratio <- max(0.6 - (zoom_level - 1) * 0.1, 0.3)  # 60% significant at 1x, 30% at 4x+
  
  sig_points <- min(as.integer(max_points * sig_ratio), nrow(significant_dt))
  non_sig_points <- max_points - sig_points
  
  # Sample significant points (keep all if possible)
  if (nrow(significant_dt) <= sig_points) {
    sampled_sig <- significant_dt
    non_sig_points <- max_points - nrow(significant_dt)
  } else {
    # Prioritize extreme values for significant points
    up_dt <- significant_dt[category == "up"][order(-logFC)]  # Sort descending
    down_dt <- significant_dt[category == "down"][order(logFC)]  # Sort ascending
    
    up_sample <- min(sig_points %/% 2, nrow(up_dt))
    down_sample <- sig_points - up_sample
    
    # Take top samples from each category
    sampled_up <- if (up_sample > 0 && nrow(up_dt) > 0) up_dt[1:up_sample] else data.table()
    sampled_down <- if (down_sample > 0 && nrow(down_dt) > 0) down_dt[1:down_sample] else data.table()
    
    sampled_sig <- rbind(sampled_up, sampled_down)
  }
  
  # Sample non-significant points randomly
  if (non_sig_points > 0 && nrow(non_significant_dt) > 0) {
    sample_size <- min(non_sig_points, nrow(non_significant_dt))
    sampled_indices <- sample(nrow(non_significant_dt), sample_size)
    sampled_non_sig <- non_significant_dt[sampled_indices]
    
    return(rbind(sampled_sig, sampled_non_sig))
  } else {
    return(sampled_sig)
  }
}

#* @apiTitle R Volcano Plot API
#* @apiDescription R-based volcano plot data processing server

#* Get cache status
#* @get /api/cache-status
function(res) {
  log_message("Cache status endpoint called", "INFO", "API")
  
  tryCatch({
    result <- get_cache_status()
    log_message("Cache status retrieved successfully", "DEBUG", "API")
    return(result)
  }, error = function(e) {
    log_message(sprintf("Cache status endpoint error: %s", e$message), "ERROR", "API")
    res$status <- 500
    return(create_error_response(
      message = "Failed to retrieve cache status",
      status_code = 500,
      error_type = "cache_error",
      details = list(original_error = e$message)
    ))
  })
}

#* Warm cache with common dataset sizes
#* @post /api/warm-cache
#* @param sizes:list List of dataset sizes to cache (optional)
function(req, res, sizes = NULL) {
  log_message("Cache warming endpoint called", "INFO", "API")
  
  tryCatch({
    # Parse request body if present
    if (!is.null(req$postBody) && nchar(req$postBody) > 0) {
      body <- tryCatch({
        jsonlite::fromJSON(req$postBody, simplifyVector = FALSE)
      }, error = function(e) {
        log_message(sprintf("Failed to parse request body: %s", e$message), "WARN", "API")
        list()
      })
      
      if (!is.null(body$sizes)) {
        sizes <- body$sizes
      }
    }
    
    if (is.null(sizes)) {
      # Default sizes matching Python implementation
      sizes <- c(10000, 50000, 100000, 500000, 1000000)
      log_message("Using default cache warming sizes", "DEBUG", "API")
    } else {
      log_message(sprintf("Using custom cache warming sizes: %s", paste(sizes, collapse = ", ")), "DEBUG", "API")
    }
    
    result <- warm_cache(sizes)
    log_message("Cache warming completed successfully", "INFO", "API")
    return(result)
  }, error = function(e) {
    log_message(sprintf("Cache warming endpoint error: %s", e$message), "ERROR", "API")
    res$status <- 500
    return(create_error_response(
      message = "Failed to warm cache",
      status_code = 500,
      error_type = "cache_error",
      details = list(original_error = e$message)
    ))
  })
}

#* Clear all cached datasets
#* @post /api/clear-cache
function(res) {
  log_message("Cache clearing endpoint called", "INFO", "API")
  
  tryCatch({
    result <- clear_cache()
    log_message("Cache cleared successfully", "INFO", "API")
    return(result)
  }, error = function(e) {
    log_message(sprintf("Cache clearing endpoint error: %s", e$message), "ERROR", "API")
    res$status <- 500
    return(create_error_response(
      message = "Failed to clear cache",
      status_code = 500,
      error_type = "cache_error",
      details = list(original_error = e$message)
    ))
  })
}

#* Get volcano plot data with filtering and intelligent sampling
#* @param p_value_threshold:numeric P-value threshold for significance (default: 0.05)
#* @param log_fc_min:numeric Minimum log fold change for up-regulation (default: -0.5)
#* @param log_fc_max:numeric Maximum log fold change for down-regulation (default: 0.5)
#* @param search_term:character Search term for metabolite names (optional)
#* @param dataset_size:int Dataset size to generate (default: 10000)
#* @param max_points:int Maximum points to return (default: 50000)
#* @param zoom_level:numeric Zoom level for adaptive sampling (default: 1.0)
#* @param x_min:numeric Minimum X range for spatial filtering (optional)
#* @param x_max:numeric Maximum X range for spatial filtering (optional)
#* @param y_min:numeric Minimum Y range for spatial filtering (optional)
#* @param y_max:numeric Maximum Y range for spatial filtering (optional)
#* @param lod_mode:logical Enable level-of-detail loading (default: TRUE)
#* @get /api/volcano-data
function(req, res, p_value_threshold = 0.05, log_fc_min = -0.5, log_fc_max = 0.5, 
         search_term = NULL, dataset_size = 10000, max_points = 50000,
         zoom_level = 1.0, x_min = NULL, x_max = NULL, y_min = NULL, y_max = NULL,
         lod_mode = TRUE) {
  
  request_id <- sprintf("req_%d", as.integer(Sys.time()))
  log_message(sprintf("Volcano data GET endpoint called [%s]", request_id), "INFO", "API")
  
  tryCatch({
    # Validate parameters
    params <- list(
      p_value_threshold = p_value_threshold,
      log_fc_min = log_fc_min,
      log_fc_max = log_fc_max,
      search_term = search_term,
      dataset_size = dataset_size,
      max_points = max_points,
      zoom_level = zoom_level,
      lod_mode = lod_mode
    )
    
    validation_result <- validate_parameters(params)
    
    if (!validation_result$valid) {
      log_message(sprintf("Parameter validation failed [%s]: %s", request_id, paste(validation_result$errors, collapse = "; ")), "WARN", "API")
      res$status <- 400
      return(create_error_response(
        message = "Invalid parameters",
        status_code = 400,
        error_type = "validation_error",
        details = list(errors = validation_result$errors)
      ))
    }
    
    # Use validated parameters
    validated_params <- validation_result$parameters
    log_message(sprintf("Parameters validated successfully [%s]", request_id), "DEBUG", "API")
    # Get cached synthetic data with performance monitoring
    dt <- monitor_performance(get_cached_dataset, sprintf("get_dataset_%s", request_id), validated_params$dataset_size)
    total_rows <- nrow(dt)
    
    # Apply search filter if provided
    if (!is.null(validated_params$search_term) && nchar(validated_params$search_term) > 0) {
      log_message(sprintf("Applying search filter: '%s' [%s]", validated_params$search_term, request_id), "DEBUG", "API")
      # Convert search term to lowercase for case-insensitive search
      search_lower <- tolower(validated_params$search_term)
      original_rows <- nrow(dt)
      dt <- dt[grepl(search_lower, tolower(gene))]
      log_message(sprintf("Search filter applied: %d -> %d rows [%s]", original_rows, nrow(dt), request_id), "DEBUG", "API")
    }
    
    # Categorize points based on significance thresholds
    dt <- monitor_performance(categorize_points, sprintf("categorize_%s", request_id), dt, validated_params$p_value_threshold, validated_params$log_fc_min, validated_params$log_fc_max)
    
    # Calculate statistics using data.table aggregation
    stats_dt <- dt[, .N, by = category]
    
    # Convert to named list for easy access
    stats_list <- setNames(stats_dt$N, stats_dt$category)
    
    stats <- list(
      up_regulated = as.integer(stats_list[["up"]] %||% 0),
      down_regulated = as.integer(stats_list[["down"]] %||% 0),
      non_significant = as.integer(stats_list[["non_significant"]] %||% 0)
    )
    
    # Apply spatial filtering if LOD mode is enabled and ranges are provided
    x_range <- NULL
    y_range <- NULL
    
    if (lod_mode && !is.null(x_min) && !is.null(x_max) && !is.null(y_min) && !is.null(y_max)) {
      x_range <- c(as.numeric(x_min), as.numeric(x_max))
      y_range <- c(as.numeric(y_min), as.numeric(y_max))
      dt <- apply_spatial_filter(dt, x_range, y_range)
    }
    
    # Determine max points based on LOD mode
    if (validated_params$lod_mode) {
      effective_max_points <- get_lod_max_points(validated_params$zoom_level, validated_params$max_points)
      log_message(sprintf("LOD mode enabled: effective_max_points = %d [%s]", effective_max_points, request_id), "DEBUG", "API")
    } else {
      effective_max_points <- validated_params$max_points
      log_message(sprintf("LOD mode disabled: using max_points = %d [%s]", effective_max_points, request_id), "DEBUG", "API")
    }
    
    # Intelligent sampling with LOD considerations
    points_before_sampling <- nrow(dt)
    is_downsampled <- points_before_sampling > effective_max_points
    
    if (is_downsampled) {
      log_message(sprintf("Downsampling required: %d -> %d points [%s]", points_before_sampling, effective_max_points, request_id), "DEBUG", "API")
      dt <- monitor_performance(intelligent_sampling, sprintf("sampling_%s", request_id), dt, effective_max_points, validated_params$zoom_level)
    } else {
      log_message(sprintf("No downsampling needed: %d points [%s]", points_before_sampling, request_id), "DEBUG", "API")
    }
    
    # Convert to list format for JSON response
    data_points <- convert_to_data_points(dt)
    
    # Return response matching Python FastAPI structure
    result <- list(
      data = data_points,
      stats = stats,
      total_rows = as.integer(total_rows),
      filtered_rows = as.integer(nrow(dt)),
      points_before_sampling = as.integer(points_before_sampling),
      is_downsampled = is_downsampled
    )
    
    log_message(sprintf("Volcano data GET request completed successfully [%s]: %d points returned", request_id, length(data_points)), "INFO", "API")
    
    return(result)
    
  }, error = function(e) {
    log_message(sprintf("Volcano data GET endpoint error [%s]: %s", request_id, e$message), "ERROR", "API")
    res$status <- 500
    return(create_error_response(
      message = "Failed to process volcano data request",
      status_code = 500,
      error_type = "processing_error",
      details = list(
        original_error = e$message,
        request_id = request_id
      )
    ))
  })
}

#* POST endpoint for volcano data (matches Python FastAPI)
#* @param p_value_threshold:numeric P-value threshold for significance
#* @param log_fc_min:numeric Minimum log fold change for up-regulation
#* @param log_fc_max:numeric Maximum log fold change for down-regulation
#* @param search_term:character Search term for metabolite names (optional)
#* @param dataset_size:int Dataset size to generate
#* @param max_points:int Maximum points to return
#* @param zoom_level:numeric Zoom level for adaptive sampling
#* @param x_range:list X range for spatial filtering [min, max] (optional)
#* @param y_range:list Y range for spatial filtering [min, max] (optional)
#* @param lod_mode:logical Enable level-of-detail loading
#* @post /api/volcano-data
function(req, res) {
  request_id <- sprintf("post_req_%d", as.integer(Sys.time()))
  log_message(sprintf("Volcano data POST endpoint called [%s]", request_id), "INFO", "API")
  
  tryCatch({
    # Parse JSON body with error handling
    if (is.null(req$postBody) || nchar(req$postBody) == 0) {
      log_message(sprintf("Empty request body [%s]", request_id), "WARN", "API")
      res$status <- 400
      return(create_error_response(
        message = "Request body is required for POST requests",
        status_code = 400,
        error_type = "missing_body"
      ))
    }
    
    body <- tryCatch({
      jsonlite::fromJSON(req$postBody, simplifyVector = FALSE)
    }, error = function(e) {
      log_message(sprintf("Failed to parse JSON body [%s]: %s", request_id, e$message), "ERROR", "API")
      stop(sprintf("Invalid JSON in request body: %s", e$message))
    })
    
    # Extract and validate parameters
    params <- list(
      p_value_threshold = body$p_value_threshold %||% 0.05,
      log_fc_min = body$log_fc_min %||% -0.5,
      log_fc_max = body$log_fc_max %||% 0.5,
      search_term = body$search_term,
      dataset_size = body$dataset_size %||% 10000,
      max_points = body$max_points %||% 50000,
      zoom_level = body$zoom_level %||% 1.0,
      lod_mode = body$lod_mode %||% TRUE
    )
    
    validation_result <- validate_parameters(params)
    
    if (!validation_result$valid) {
      log_message(sprintf("Parameter validation failed [%s]: %s", request_id, paste(validation_result$errors, collapse = "; ")), "WARN", "API")
      res$status <- 400
      return(create_error_response(
        message = "Invalid parameters",
        status_code = 400,
        error_type = "validation_error",
        details = list(errors = validation_result$errors)
      ))
    }
    
    # Use validated parameters
    validated_params <- validation_result$parameters
    x_range <- body$x_range
    y_range <- body$y_range
    
    log_message(sprintf("Parameters validated successfully [%s]", request_id), "DEBUG", "API")
    
    # Get cached synthetic data with performance monitoring
    dt <- monitor_performance(get_cached_dataset, sprintf("get_dataset_%s", request_id), validated_params$dataset_size)
    total_rows <- nrow(dt)
    
    # Apply search filter if provided
    if (!is.null(validated_params$search_term) && nchar(validated_params$search_term) > 0) {
      log_message(sprintf("Applying search filter: '%s' [%s]", validated_params$search_term, request_id), "DEBUG", "API")
      search_lower <- tolower(validated_params$search_term)
      original_rows <- nrow(dt)
      dt <- dt[grepl(search_lower, tolower(gene))]
      log_message(sprintf("Search filter applied: %d -> %d rows [%s]", original_rows, nrow(dt), request_id), "DEBUG", "API")
    }
    
    # Categorize points
    dt <- monitor_performance(categorize_points, sprintf("categorize_%s", request_id), dt, validated_params$p_value_threshold, validated_params$log_fc_min, validated_params$log_fc_max)
    
    # Calculate statistics
    stats_dt <- dt[, .N, by = category]
    stats_list <- setNames(stats_dt$N, stats_dt$category)
    
    stats <- list(
      up_regulated = as.integer(stats_list[["up"]] %||% 0),
      down_regulated = as.integer(stats_list[["down"]] %||% 0),
      non_significant = as.integer(stats_list[["non_significant"]] %||% 0)
    )
    
    # Apply spatial filtering if enabled
    if (validated_params$lod_mode && !is.null(x_range) && !is.null(y_range)) {
      log_message(sprintf("Applying spatial filtering [%s]", request_id), "DEBUG", "API")
      dt <- monitor_performance(apply_spatial_filter, sprintf("spatial_filter_%s", request_id), dt, x_range, y_range)
    }
    
    # Determine effective max points
    if (validated_params$lod_mode) {
      effective_max_points <- get_lod_max_points(validated_params$zoom_level, validated_params$max_points)
      log_message(sprintf("LOD mode enabled: effective_max_points = %d [%s]", effective_max_points, request_id), "DEBUG", "API")
    } else {
      effective_max_points <- validated_params$max_points
      log_message(sprintf("LOD mode disabled: using max_points = %d [%s]", effective_max_points, request_id), "DEBUG", "API")
    }
    
    # Apply intelligent sampling
    points_before_sampling <- nrow(dt)
    is_downsampled <- points_before_sampling > effective_max_points
    
    if (is_downsampled) {
      log_message(sprintf("Downsampling required: %d -> %d points [%s]", points_before_sampling, effective_max_points, request_id), "DEBUG", "API")
      dt <- monitor_performance(intelligent_sampling, sprintf("sampling_%s", request_id), dt, effective_max_points, validated_params$zoom_level)
    } else {
      log_message(sprintf("No downsampling needed: %d points [%s]", points_before_sampling, request_id), "DEBUG", "API")
    }
    
    # Convert to response format
    data_points <- convert_to_data_points(dt)
    
    result <- list(
      data = data_points,
      stats = stats,
      total_rows = as.integer(total_rows),
      filtered_rows = as.integer(nrow(dt)),
      points_before_sampling = as.integer(points_before_sampling),
      is_downsampled = is_downsampled
    )
    
    log_message(sprintf("Volcano data POST request completed successfully [%s]: %d points returned", request_id, length(data_points)), "INFO", "API")
    
    return(result)
    
  }, error = function(e) {
    log_message(sprintf("Volcano data POST endpoint error [%s]: %s", request_id, e$message), "ERROR", "API")
    res$status <- 500
    return(create_error_response(
      message = "Failed to process volcano data request",
      status_code = 500,
      error_type = "processing_error",
      details = list(
        original_error = e$message,
        request_id = request_id
      )
    ))
  })
}

#* Health check endpoint
#* @get /health
function(res) {
  log_message("Health check endpoint called", "DEBUG", "API")
  
  tryCatch({
    # Perform basic system checks
    memory_info <- gc(verbose = FALSE)
    cache_status <- get_cache_status()
    
    health_data <- list(
      status = "healthy",
      timestamp = Sys.time(),
      backend = "R + data.table",
      version = R.version.string,
      packages = list(
        plumber = as.character(packageVersion("plumber")),
        data.table = as.character(packageVersion("data.table")),
        jsonlite = as.character(packageVersion("jsonlite"))
      ),
      system = list(
        memory_used_mb = round(sum(memory_info[, 2]), 2),
        cached_datasets = cache_status$total_cached,
        cache_memory_mb = cache_status$approximate_memory_mb,
        log_level = LOG_LEVEL
      )
    )
    
    log_message("Health check completed successfully", "DEBUG", "API")
    return(health_data)
    
  }, error = function(e) {
    log_message(sprintf("Health check endpoint error: %s", e$message), "ERROR", "API")
    res$status <- 503
    return(create_error_response(
      message = "Health check failed",
      status_code = 503,
      error_type = "health_check_error",
      details = list(original_error = e$message)
    ))
  })
}

#* Enable CORS for all routes with logging
#* @filter cors
function(req, res) {
  log_message(sprintf("%s %s", req$REQUEST_METHOD, req$PATH_INFO), "DEBUG", "CORS")
  
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    log_message(sprintf("CORS preflight for %s", req$PATH_INFO), "DEBUG", "CORS")
    res$status <- 200
    return(list())
  } else {
    plumber::forward()
  }
}

#* Global error handler
#* @filter error
function(req, res, err) {
  log_message(sprintf("Unhandled error in %s %s: %s", req$REQUEST_METHOD, req$PATH_INFO, err$message), "ERROR", "GLOBAL")
  
  res$status <- 500
  return(create_error_response(
    message = "Internal server error",
    status_code = 500,
    error_type = "unhandled_error",
    details = list(
      path = req$PATH_INFO,
      method = req$REQUEST_METHOD,
      error = err$message
    )
  ))
}

# Global server instance for graceful shutdown
.server_instance <- NULL

# Enhanced graceful shutdown handler with process management
graceful_shutdown <- function() {
  log_message("Received shutdown signal, stopping server gracefully...", "INFO", "SERVER")
  
  # Record shutdown start time
  shutdown_start <- Sys.time()
  
  # Clear cache to free memory
  tryCatch({
    cache_items <- 0
    if (exists(".volcano_cache")) {
      cache_items <- length(ls(.volcano_cache))
    }
    clear_cache()
    log_message(sprintf("Cache cleared during shutdown (%d items)", cache_items), "INFO", "SERVER")
  }, error = function(e) {
    log_message(sprintf("Error clearing cache during shutdown: %s", e$message), "WARN", "SERVER")
  })
  
  # Close any open file connections
  tryCatch({
    open_connections <- showConnections(all = TRUE)
    if (nrow(open_connections) > 0) {
      closeAllConnections()
      log_message(sprintf("Closed %d open connections", nrow(open_connections)), "INFO", "SERVER")
    }
  }, error = function(e) {
    log_message(sprintf("Error closing connections: %s", e$message), "WARN", "SERVER")
  })
  
  # Save shutdown information for process management
  tryCatch({
    shutdown_info <- list(
      shutdown_time = shutdown_start,
      process_id = Sys.getpid(),
      uptime_seconds = if (exists(".server_start_time")) {
        as.numeric(difftime(shutdown_start, .server_start_time, units = "secs"))
      } else {
        NA
      }
    )
    
    # Write shutdown info
    if (!is.na(shutdown_info$uptime_seconds)) {
      log_message(sprintf("Server uptime: %.2f seconds", shutdown_info$uptime_seconds), "INFO", "SERVER")
    }
    
    # Create shutdown marker file for process management scripts
    writeLines(
      c(
        sprintf("SHUTDOWN_TIME=%s", shutdown_info$shutdown_time),
        sprintf("PROCESS_ID=%d", shutdown_info$process_id),
        sprintf("UPTIME_SECONDS=%.2f", shutdown_info$uptime_seconds %||% 0)
      ),
      "server-shutdown.info"
    )
    
  }, error = function(e) {
    log_message(sprintf("Error saving shutdown info: %s", e$message), "WARN", "SERVER")
  })
  
  # Force garbage collection
  gc()
  
  # Calculate shutdown duration
  shutdown_duration <- as.numeric(difftime(Sys.time(), shutdown_start, units = "secs"))
  log_message(sprintf("Server shutdown complete (%.3f seconds)", shutdown_duration), "INFO", "SERVER")
  
  quit(save = "no", status = 0)
}

# Set up signal handlers for graceful shutdown (Unix-like systems)
if (.Platform$OS.type == "unix") {
  # Register signal handlers
  tryCatch({
    # SIGTERM handler
    signal(tools::SIGTERM, graceful_shutdown)
    # SIGINT handler (Ctrl+C)
    signal(tools::SIGINT, graceful_shutdown)
    log_message("Signal handlers registered for graceful shutdown", "DEBUG", "SERVER")
  }, error = function(e) {
    log_message(sprintf("Failed to register signal handlers: %s", e$message), "WARN", "SERVER")
  })
}

# Start the server function with enhanced logging and process management
start_server <- function(port = 8001, host = "127.0.0.1") {
  log_message("Starting R Volcano Plot API server...", "INFO", "SERVER")
  log_message(sprintf("Server will be available at: http://%s:%d", host, port), "INFO", "SERVER")
  log_message(sprintf("Health check endpoint: http://%s:%d/health", host, port), "INFO", "SERVER")
  log_message(sprintf("Log level: %s", LOG_LEVEL), "INFO", "SERVER")
  log_message(sprintf("Process ID: %d", Sys.getpid()), "INFO", "SERVER")
  
  # Record server start time for uptime calculation
  .server_start_time <<- Sys.time()
  
  if (nchar(LOG_FILE) > 0) {
    log_message(sprintf("Logging to file: %s", LOG_FILE), "INFO", "SERVER")
  } else {
    log_message("Logging to console only", "INFO", "SERVER")
  }
  
  # Validate port and host
  if (!is.numeric(port) || port < 1 || port > 65535) {
    stop("Port must be a number between 1 and 65535")
  }
  
  if (!is.character(host) || nchar(host) == 0) {
    stop("Host must be a non-empty string")
  }
  
  # Initialize server with error handling and process management
  tryCatch({
    # Create plumber instance
    server_instance <- pr()
    .server_instance <<- server_instance
    
    # Add startup message
    log_message("Plumber API server initialized successfully", "INFO", "SERVER")
    
    # Start server with enhanced error handling
    server_instance %>%
      pr_run(
        port = port, 
        host = host
      )
      
  }, error = function(e) {
    log_message(sprintf("Failed to start server: %s", e$message), "ERROR", "SERVER")
    
    # Try to provide helpful error messages
    if (grepl("bind", e$message, ignore.case = TRUE)) {
      log_message(sprintf("Port %d may already be in use. Try a different port.", port), "ERROR", "SERVER")
    } else if (grepl("address", e$message, ignore.case = TRUE)) {
      log_message(sprintf("Invalid host address: %s", host), "ERROR", "SERVER")
    }
    
    stop(e)
  }, finally = {
    # Cleanup on exit
    log_message("Server process ending, performing cleanup...", "INFO", "SERVER")
    graceful_shutdown()
  })
}

# Main execution - only run if this is the main script
main <- function() {
  # Parse command line arguments
  args <- commandArgs(trailingOnly = TRUE)
  
  # Parse port (default: 8001)
  port <- if (length(args) > 0 && !is.na(as.numeric(args[1]))) {
    as.numeric(args[1])
  } else {
    8001
  }
  
  # Parse host (default: 127.0.0.1)
  host <- if (length(args) > 1 && nchar(args[2]) > 0) {
    args[2]
  } else {
    "127.0.0.1"
  }
  
  # Log startup parameters
  log_message(sprintf("Starting server with port=%d, host=%s", port, host), "INFO", "STARTUP")
  
  # Validate environment
  log_message("Validating R environment...", "INFO", "STARTUP")
  
  # Check required packages
  required_packages <- c("plumber", "data.table", "jsonlite")
  missing_packages <- character(0)
  
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing_packages <- c(missing_packages, pkg)
    }
  }
  
  if (length(missing_packages) > 0) {
    log_message(sprintf("Missing required packages: %s", paste(missing_packages, collapse = ", ")), "ERROR", "STARTUP")
    log_message("Please run 'Rscript install-packages.R' to install missing packages", "ERROR", "STARTUP")
    quit(save = "no", status = 1)
  }
  
  log_message("All required packages are available", "INFO", "STARTUP")
  
  # Create and start the plumber API directly
  tryCatch({
    # Configure JSON serialization options
    options(plumber.serializer = plumber::serializer_json(auto_unbox = TRUE))
    
    # Create plumber router
    pr <- pr() %>%
      pr_set_serializer(plumber::serializer_json(auto_unbox = TRUE)) %>%
      pr_get("/health", function(res) {
        log_message("Health check endpoint called", "DEBUG", "API")
        
        tryCatch({
          memory_info <- gc(verbose = FALSE)
          cache_status <- get_cache_status()
          
          health_data <- list(
            status = "healthy",
            timestamp = Sys.time(),
            backend = "R + data.table",
            version = R.version.string,
            packages = list(
              plumber = as.character(packageVersion("plumber")),
              data.table = as.character(packageVersion("data.table")),
              jsonlite = as.character(packageVersion("jsonlite"))
            ),
            system = list(
              memory_used_mb = round(sum(memory_info[, 2]), 2),
              cached_datasets = cache_status$total_cached,
              cache_memory_mb = cache_status$approximate_memory_mb,
              log_level = LOG_LEVEL
            )
          )
          
          log_message("Health check completed successfully", "DEBUG", "API")
          return(health_data)
          
        }, error = function(e) {
          log_message(sprintf("Health check endpoint error: %s", e$message), "ERROR", "API")
          res$status <- 503
          return(create_error_response(
            message = "Health check failed",
            status_code = 503,
            error_type = "health_check_error",
            details = list(original_error = e$message)
          ))
        })
      }) %>%
      pr_get("/api/volcano-data", function(req, res, p_value_threshold = 0.05, log_fc_min = -0.5, log_fc_max = 0.5, 
              search_term = NULL, dataset_size = 10000, max_points = 50000, zoom_level = 1.0, 
              x_min = NULL, x_max = NULL, y_min = NULL, y_max = NULL, lod_mode = TRUE) {
        
        request_id <- sprintf("req_%d", as.integer(Sys.time()))
        log_message(sprintf("Volcano data GET endpoint called [%s]", request_id), "INFO", "API")
        
        tryCatch({
          # Validate parameters
          params <- list(
            p_value_threshold = p_value_threshold,
            log_fc_min = log_fc_min,
            log_fc_max = log_fc_max,
            search_term = search_term,
            dataset_size = dataset_size,
            max_points = max_points,
            zoom_level = zoom_level,
            lod_mode = lod_mode
          )
          
          validation_result <- validate_parameters(params)
          
          if (!validation_result$valid) {
            log_message(sprintf("Parameter validation failed [%s]: %s", request_id, paste(validation_result$errors, collapse = "; ")), "WARN", "API")
            res$status <- 400
            return(create_error_response(
              message = "Invalid parameters",
              status_code = 400,
              error_type = "validation_error",
              details = list(errors = validation_result$errors)
            ))
          }
          
          # Use validated parameters
          validated_params <- validation_result$parameters
          log_message(sprintf("Parameters validated successfully [%s]", request_id), "DEBUG", "API")
          
          # Get cached synthetic data with performance monitoring
          dt <- monitor_performance(get_cached_dataset, sprintf("get_dataset_%s", request_id), validated_params$dataset_size)
          total_rows <- nrow(dt)
          
          # Apply search filter if provided
          if (!is.null(validated_params$search_term) && nchar(validated_params$search_term) > 0) {
            log_message(sprintf("Applying search filter: '%s' [%s]", validated_params$search_term, request_id), "DEBUG", "API")
            search_lower <- tolower(validated_params$search_term)
            original_rows <- nrow(dt)
            dt <- dt[grepl(search_lower, tolower(gene))]
            log_message(sprintf("Search filter applied: %d -> %d rows [%s]", original_rows, nrow(dt), request_id), "DEBUG", "API")
          }
          
          # Categorize points based on significance thresholds
          dt <- monitor_performance(categorize_points, sprintf("categorize_%s", request_id), dt, validated_params$p_value_threshold, validated_params$log_fc_min, validated_params$log_fc_max)
          
          # Calculate statistics using data.table aggregation
          stats_dt <- dt[, .N, by = category]
          stats_list <- setNames(stats_dt$N, stats_dt$category)
          
          stats <- list(
            up_regulated = as.integer(stats_list[["up"]] %||% 0),
            down_regulated = as.integer(stats_list[["down"]] %||% 0),
            non_significant = as.integer(stats_list[["non_significant"]] %||% 0)
          )
          
          # Apply spatial filtering if LOD mode is enabled and ranges are provided
          x_range <- NULL
          y_range <- NULL
          
          if (lod_mode && !is.null(x_min) && !is.null(x_max) && !is.null(y_min) && !is.null(y_max)) {
            x_range <- c(as.numeric(x_min), as.numeric(x_max))
            y_range <- c(as.numeric(y_min), as.numeric(y_max))
            dt <- apply_spatial_filter(dt, x_range, y_range)
          }
          
          # Determine max points based on LOD mode
          if (validated_params$lod_mode) {
            effective_max_points <- get_lod_max_points(validated_params$zoom_level, validated_params$max_points)
            log_message(sprintf("LOD mode enabled: effective_max_points = %d [%s]", effective_max_points, request_id), "DEBUG", "API")
          } else {
            effective_max_points <- validated_params$max_points
            log_message(sprintf("LOD mode disabled: using max_points = %d [%s]", effective_max_points, request_id), "DEBUG", "API")
          }
          
          # Intelligent sampling with LOD considerations
          points_before_sampling <- nrow(dt)
          is_downsampled <- points_before_sampling > effective_max_points
          
          if (is_downsampled) {
            log_message(sprintf("Downsampling required: %d -> %d points [%s]", points_before_sampling, effective_max_points, request_id), "DEBUG", "API")
            dt <- monitor_performance(intelligent_sampling, sprintf("sampling_%s", request_id), dt, effective_max_points, validated_params$zoom_level)
          } else {
            log_message(sprintf("No downsampling needed: %d points [%s]", points_before_sampling, request_id), "DEBUG", "API")
          }
          
          # Convert to list format for JSON response
          data_points <- list()
          if (nrow(dt) > 0) {
            for (i in 1:nrow(dt)) {
              data_points[[i]] <- list(
                gene = as.character(dt$gene[i]),
                logFC = as.numeric(dt$logFC[i]),
                padj = as.numeric(dt$padj[i]),
                classyfireSuperclass = as.character(dt$classyfireSuperclass[i]),
                classyfireClass = as.character(dt$classyfireClass[i]),
                category = as.character(dt$category[i])
              )
            }
          }
          
          # Return response matching Python FastAPI structure
          result <- list(
            data = data_points,
            stats = stats,
            total_rows = as.integer(total_rows),
            filtered_rows = as.integer(nrow(dt)),
            points_before_sampling = as.integer(points_before_sampling),
            is_downsampled = is_downsampled
          )
          
          log_message(sprintf("Volcano data GET request completed successfully [%s]: %d points returned", request_id, length(data_points)), "INFO", "API")
          
          return(result)
          
        }, error = function(e) {
          log_message(sprintf("Volcano data GET endpoint error [%s]: %s", request_id, e$message), "ERROR", "API")
          res$status <- 500
          return(create_error_response(
            message = "Failed to process volcano data request",
            status_code = 500,
            error_type = "processing_error",
            details = list(
              original_error = e$message,
              request_id = request_id
            )
          ))
        })
      }) %>%
      pr_get("/api/cache-status", function(res) {
        log_message("Cache status endpoint called", "INFO", "API")
        
        tryCatch({
          result <- get_cache_status()
          log_message("Cache status retrieved successfully", "DEBUG", "API")
          return(result)
        }, error = function(e) {
          log_message(sprintf("Cache status endpoint error: %s", e$message), "ERROR", "API")
          res$status <- 500
          return(create_error_response(
            message = "Failed to retrieve cache status",
            status_code = 500,
            error_type = "cache_error",
            details = list(original_error = e$message)
          ))
        })
      })
    
    log_message("Plumber API created successfully", "INFO", "SERVER")
    log_message(sprintf("Server will be available at: http://%s:%d", host, port), "INFO", "SERVER")
    log_message(sprintf("Health check endpoint: http://%s:%d/health", host, port), "INFO", "SERVER")
    
    # Start the server
    pr$run(host = host, port = port)
    
  }, error = function(e) {
    log_message(sprintf("Failed to start server: %s", e$message), "ERROR", "SERVER")
    quit(save = "no", status = 1)
  })
}

# If script is run directly, start the server
if (!interactive()) {
  main()
}