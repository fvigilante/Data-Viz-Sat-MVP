from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import polars as pl
import json
import os
import numpy as np
from pathlib import Path
from functools import lru_cache
from sklearn.decomposition import PCA
from sklearn.preprocessing import StandardScaler
import subprocess
import tempfile

app = FastAPI(title="Data Viz Satellite API", version="1.0.0")

# CORS middleware - allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins for development
    allow_credentials=False,  # Set to False when using allow_origins=["*"]
    allow_methods=["*"],
    allow_headers=["*"],
)

class FilterParams(BaseModel):
    p_value_threshold: float = 0.05
    log_fc_min: float = -0.5
    log_fc_max: float = 0.5
    search_term: Optional[str] = None
    dataset_size: int = 10000
    max_points: int = 50000  # Limit response size for performance
    # Zoom-based LOD parameters
    zoom_level: float = 1.0
    x_range: Optional[List[float]] = None  # [min, max] for visible X range
    y_range: Optional[List[float]] = None  # [min, max] for visible Y range
    lod_mode: bool = True  # Enable level-of-detail loading

class VolcanoDataPoint(BaseModel):
    gene: str
    logFC: float
    padj: float
    classyfireSuperclass: Optional[str] = None
    classyfireClass: Optional[str] = None
    category: str  # "up", "down", "non_significant"

class VolcanoResponse(BaseModel):
    data: List[VolcanoDataPoint]
    stats: dict
    total_rows: int
    filtered_rows: int
    points_before_sampling: int
    is_downsampled: bool

class PCADataPoint(BaseModel):
    sample_id: str
    pc1: float
    pc2: float
    pc3: float
    group: str
    batch: Optional[str] = None
    metadata: Optional[dict] = None

class PCAResponse(BaseModel):
    data: List[PCADataPoint]
    explained_variance: dict
    stats: dict
    is_downsampled: bool
    points_before_sampling: int

class PCAParams(BaseModel):
    dataset_size: int = 1000
    n_features: int = 100
    n_groups: int = 3
    max_points: int = 10000
    add_batch_effect: bool = False
    noise_level: float = 0.1

# Global cache for generated datasets
_data_cache = {}
_pca_cache = {}

@lru_cache(maxsize=10)
def get_cached_dataset(size: int) -> pl.DataFrame:
    """Generate and cache synthetic metabolomics data using vectorized operations"""
    
    if size in _data_cache:
        return _data_cache[size]
    
    print(f"Generating new dataset of size {size}...")
    
    metabolite_names = [
        "1,3-Isoquinolinediol", "3,4-Dihydro-3-oxo-2H-(1,4)-benzoxazin-2-ylacetic acid",
        "(2-oxo-2,3-dihydro-1H-indol-3-yl)acetic acid", "Resedine", "Methionine sulfoxide",
        "trans-Urocanic acid", "Pro-Tyr", "Glu-Gly-Glu", "NP-024517", "Trp-Pro",
        "Biotin", "Pyridoxine", "Sulfocholic acid", "Pro-Pro", "Targinine",
        "L-Carnitine", "Taurine", "Creatine", "Adenosine", "Guanosine",
        "Cytidine", "Uridine", "Thymidine", "Inosine", "Xanthosine",
        "Hypoxanthine", "Xanthine", "Uric acid", "Allantoin", "Creatinine"
    ]
    
    superclasses = [
        "Organic acids and derivatives", "Organoheterocyclic compounds",
        "Lipids and lipid-like molecules", "Others", "Nucleosides, nucleotides, and analogues"
    ]
    
    classes = [
        "Carboxylic acids and derivatives", "Indoles and derivatives", "Benzoxazines",
        "Azolidines", "Azoles", "Biotin and derivatives", "Pyridines and derivatives",
        "Steroids and steroid derivatives", "Others", "Purine nucleosides"
    ]
    
    # Use numpy for vectorized operations - much faster than Python loops
    np.random.seed(42)  # For reproducible results
    
    # Create realistic volcano plot distribution
    # Most metabolites should be non-significant (centered around 0, high p-values)
    # Some should be significantly up/down-regulated
    
    # Define proportions for realistic volcano plot
    non_sig_proportion = 0.85  # 85% non-significant
    up_reg_proportion = 0.075  # 7.5% up-regulated
    down_reg_proportion = 0.075  # 7.5% down-regulated
    
    n_non_sig = int(size * non_sig_proportion)
    n_up_reg = int(size * up_reg_proportion)
    n_down_reg = size - n_non_sig - n_up_reg  # Remaining
    
    # Generate log fold changes for each category
    # Non-significant: centered around 0, small fold changes (più compatti)
    log_fc_non_sig = np.random.normal(0, 0.6, n_non_sig)
    
    # Up-regulated: positive fold changes, più concentrati ma significativi
    log_fc_up = np.random.normal(1.5, 0.8, n_up_reg)  # Normale centrata su 1.5
    
    # Down-regulated: negative fold changes, più concentrati ma significativi
    log_fc_down = np.random.normal(-1.5, 0.8, n_down_reg)  # Normale centrata su -1.5
    
    # Combine all fold changes
    log_fc = np.concatenate([log_fc_non_sig, log_fc_up, log_fc_down])
    
    # Generate realistic p-values based on fold change magnitude
    # Higher fold change = lower p-value (more significant)
    abs_log_fc = np.abs(log_fc)
    
    # Create p-values with realistic volcano shape
    p_values = np.zeros(size)
    
    # Non-significant points: high p-values (0.1 to 1.0) - più concentrati in alto
    p_values[:n_non_sig] = np.random.uniform(0.1, 1.0, n_non_sig)
    
    # Significant points: p-values bassi correlati con fold change
    # Up-regulated: p-values bassi
    p_values[n_non_sig:n_non_sig + n_up_reg] = np.random.uniform(0.0001, 0.05, n_up_reg)
    
    # Down-regulated: p-values bassi
    p_values[n_non_sig + n_up_reg:] = np.random.uniform(0.0001, 0.05, n_down_reg)
    
    # Add some noise to make it more realistic
    noise_factor = 0.1
    log_fc += np.random.normal(0, noise_factor, size)
    
    # Ensure p-values are within valid range
    p_values = np.clip(p_values, 0.0001, 1.0)
    
    # Round for cleaner display
    log_fc = np.round(log_fc, 4)
    p_values = np.round(p_values, 6)
    
    # Shuffle to mix the categories
    indices = np.arange(size)
    np.random.shuffle(indices)
    log_fc = log_fc[indices]
    p_values = p_values[indices]
    
    # Generate gene names efficiently
    gene_names = [
        metabolite_names[i % len(metabolite_names)] if i < len(metabolite_names) 
        else f"Metabolite_{i + 1}" 
        for i in range(size)
    ]
    
    # Generate classifications using numpy choice for efficiency
    superclass_indices = np.random.choice(len(superclasses), size)
    class_indices = np.random.choice(len(classes), size)
    
    # Create DataFrame directly with all data
    df = pl.DataFrame({
        "gene": gene_names,
        "logFC": log_fc,
        "padj": p_values,
        "classyfireSuperclass": [superclasses[i] for i in superclass_indices],
        "classyfireClass": [classes[i] for i in class_indices]
    })
    
    # Cache the result
    _data_cache[size] = df
    print(f"Dataset of size {size} generated and cached")
    
    return df

@lru_cache(maxsize=20)
def get_cached_pca_dataset(dataset_size: int, n_features: int, n_groups: int, add_batch_effect: bool, noise_level: float):
    """Generate and cache synthetic PCA data"""
    
    cache_key = f"{dataset_size}_{n_features}_{n_groups}_{add_batch_effect}_{noise_level}"
    
    if cache_key in _pca_cache:
        return _pca_cache[cache_key]
    
    print(f"Generating new PCA dataset: {dataset_size} samples, {n_features} features, {n_groups} groups...")
    
    np.random.seed(42)  # For reproducible results
    
    # Generate group labels
    group_names = [f"Group_{i+1}" for i in range(n_groups)]
    samples_per_group = dataset_size // n_groups
    remainder = dataset_size % n_groups
    
    # Create sample IDs and group assignments
    sample_ids = []
    groups = []
    
    for i, group_name in enumerate(group_names):
        n_samples = samples_per_group + (1 if i < remainder else 0)
        sample_ids.extend([f"Sample_{group_name}_{j+1}" for j in range(n_samples)])
        groups.extend([group_name] * n_samples)
    
    # Generate synthetic feature matrix with group separation
    X = np.zeros((dataset_size, n_features))
    
    for i, group in enumerate(group_names):
        group_mask = np.array(groups) == group
        group_size = np.sum(group_mask)
        
        # Create group-specific signal in first few components
        base_signal = np.zeros(n_features)
        
        # Add group separation in first 10 features
        if i < 10:  # Ensure we don't exceed n_features
            separation_features = min(10, n_features)
            base_signal[:separation_features] = np.random.normal(i * 2, 0.5, separation_features)
        
        # Generate data for this group
        group_data = np.random.multivariate_normal(
            base_signal, 
            np.eye(n_features) * noise_level,
            size=group_size
        )
        
        X[group_mask] = group_data
    
    # Add batch effect if requested
    batch_labels = None
    if add_batch_effect:
        n_batches = min(3, n_groups)  # Max 3 batches
        batch_labels = [f"Batch_{(i % n_batches) + 1}" for i in range(dataset_size)]
        
        # Add batch effect to random features
        batch_effect_features = np.random.choice(n_features, size=min(20, n_features), replace=False)
        for i, batch in enumerate(set(batch_labels)):
            batch_mask = np.array(batch_labels) == batch
            X[batch_mask, batch_effect_features] += np.random.normal(i * 0.5, 0.2, len(batch_effect_features))
    
    # Perform PCA
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    pca = PCA(n_components=min(3, n_features, dataset_size))
    X_pca = pca.fit_transform(X_scaled)
    
    # Ensure we have at least 3 components (pad with zeros if necessary)
    if X_pca.shape[1] < 3:
        padding = np.zeros((X_pca.shape[0], 3 - X_pca.shape[1]))
        X_pca = np.hstack([X_pca, padding])
        
        # Pad explained variance
        explained_var = list(pca.explained_variance_ratio_)
        while len(explained_var) < 3:
            explained_var.append(0.0)
    else:
        explained_var = pca.explained_variance_ratio_[:3]
    
    # Create result dictionary
    result = {
        'sample_ids': sample_ids,
        'groups': groups,
        'batch_labels': batch_labels,
        'pca_coords': X_pca[:, :3],  # First 3 components
        'explained_variance': {
            'pc1': float(explained_var[0]),
            'pc2': float(explained_var[1]),
            'pc3': float(explained_var[2])
        },
        'stats': {
            'total_samples': dataset_size,
            'total_features': n_features,
            'groups': group_names
        }
    }
    
    # Cache the result
    _pca_cache[cache_key] = result
    print(f"PCA dataset generated and cached: {cache_key}")
    
    return result

def categorize_points(df: pl.DataFrame, p_threshold: float, log_fc_min: float, log_fc_max: float) -> pl.DataFrame:
    """Categorize data points using Polars expressions for optimal performance"""
    
    return df.with_columns([
        pl.when(
            (pl.col("padj") <= p_threshold) & (pl.col("logFC") < log_fc_min)
        ).then(pl.lit("down"))
        .when(
            (pl.col("padj") <= p_threshold) & (pl.col("logFC") > log_fc_max)
        ).then(pl.lit("up"))
        .otherwise(pl.lit("non_significant"))
        .alias("category")
    ])

def apply_spatial_filter(df: pl.DataFrame, x_range: Optional[List[float]], y_range: Optional[List[float]]) -> pl.DataFrame:
    """Apply spatial filtering based on visible plot area"""
    if not x_range or not y_range:
        return df
    
    # Convert p-values to -log10 for Y filtering
    df_with_y = df.with_columns([
        (-pl.col("padj").log10()).alias("neg_log_padj")
    ])
    
    # Add buffer around visible area (20% on each side)
    x_buffer = (x_range[1] - x_range[0]) * 0.2
    y_buffer = (y_range[1] - y_range[0]) * 0.2
    
    return df_with_y.filter(
        (pl.col("logFC") >= (x_range[0] - x_buffer)) &
        (pl.col("logFC") <= (x_range[1] + x_buffer)) &
        (pl.col("neg_log_padj") >= (y_range[0] - y_buffer)) &
        (pl.col("neg_log_padj") <= (y_range[1] + y_buffer))
    ).drop("neg_log_padj")

def get_lod_max_points(zoom_level: float, base_points: int = 2000) -> int:
    """Calculate adaptive max points based on zoom level"""
    # Exponential scaling: 2K at zoom 1x, up to 200K at high zoom
    max_adaptive_points = 200000
    zoom_multiplier = min(zoom_level ** 1.5, 100)  # Cap at 100x multiplier
    
    return min(int(base_points * zoom_multiplier), max_adaptive_points)

def intelligent_sampling(df: pl.DataFrame, max_points: int, zoom_level: float) -> pl.DataFrame:
    """Intelligent sampling that prioritizes significant points and adapts to zoom level"""
    if len(df) <= max_points:
        return df
    
    # Separate by significance
    significant_df = df.filter(pl.col("category") != "non_significant")
    non_significant_df = df.filter(pl.col("category") == "non_significant")
    
    # At higher zoom levels, include more non-significant points for context
    sig_ratio = max(0.6 - (zoom_level - 1) * 0.1, 0.3)  # 60% significant at 1x, 30% at 4x+
    
    sig_points = min(int(max_points * sig_ratio), len(significant_df))
    non_sig_points = max_points - sig_points
    
    # Sample significant points (keep all if possible)
    if len(significant_df) <= sig_points:
        sampled_sig = significant_df
        non_sig_points = max_points - len(significant_df)
    else:
        # Prioritize extreme values for significant points
        up_df = significant_df.filter(pl.col("category") == "up").sort("logFC", descending=True)
        down_df = significant_df.filter(pl.col("category") == "down").sort("logFC")
        
        up_sample = min(sig_points // 2, len(up_df))
        down_sample = sig_points - up_sample
        
        sampled_sig = pl.concat([
            up_df.head(up_sample),
            down_df.head(down_sample)
        ])
    
    # Sample non-significant points randomly
    if non_sig_points > 0 and len(non_significant_df) > 0:
        sampled_non_sig = non_significant_df.sample(min(non_sig_points, len(non_significant_df)))
        return pl.concat([sampled_sig, sampled_non_sig])
    else:
        return sampled_sig

@app.get("/")
async def root():
    return {"message": "Data Viz Satellite API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.get("/ready")
async def readiness_check():
    return {"status": "ready"}

@app.post("/api/warm-cache")
async def warm_cache(sizes: List[int] = [10000, 50000, 100000, 500000, 1000000]):
    """
    Pre-generate and cache datasets for faster subsequent requests
    """
    try:
        cached_sizes = []
        for size in sizes:
            if size <= 10000000:  # Safety limit
                get_cached_dataset(size)
                cached_sizes.append(size)
        
        return {
            "message": "Cache warmed successfully",
            "cached_sizes": cached_sizes,
            "total_cached": len(_data_cache)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error warming cache: {str(e)}")

@app.get("/api/cache-status")
async def cache_status():
    """
    Get current cache status
    """
    return {
        "cached_datasets": list(_data_cache.keys()),
        "total_cached": len(_data_cache)
    }

@app.post("/api/volcano-data", response_model=VolcanoResponse)
async def get_volcano_data(filters: FilterParams):
    """
    Get filtered volcano plot data with server-side processing using Polars
    """
    try:
        # Get cached synthetic data
        df = get_cached_dataset(filters.dataset_size)
        total_rows = len(df)
        
        # Apply search filter if provided
        if filters.search_term:
            df = df.filter(
                pl.col("gene").str.to_lowercase().str.contains(
                    filters.search_term.lower()
                )
            )
        
        # Categorize points
        df = categorize_points(
            df, 
            filters.p_value_threshold, 
            filters.log_fc_min, 
            filters.log_fc_max
        )
        
        # Calculate statistics using Polars aggregation
        stats_df = df.group_by("category").agg([
            pl.count().alias("count")
        ])
        
        # Convert to dictionary for easy access
        stats_dict = {
            row["category"]: row["count"] 
            for row in stats_df.to_dicts()
        }
        
        stats = {
            "up_regulated": stats_dict.get("up", 0),
            "down_regulated": stats_dict.get("down", 0),
            "non_significant": stats_dict.get("non_significant", 0)
        }
        
        # Apply spatial filtering if LOD mode is enabled and ranges are provided
        if filters.lod_mode and filters.x_range and filters.y_range:
            df = apply_spatial_filter(df, filters.x_range, filters.y_range)
        
        # Determine max points based on LOD mode
        if filters.lod_mode:
            effective_max_points = get_lod_max_points(filters.zoom_level, filters.max_points)
        else:
            effective_max_points = filters.max_points
        
        # Intelligent sampling with LOD considerations
        points_before_sampling = len(df)
        is_downsampled = len(df) > effective_max_points
        
        if is_downsampled:
            df = intelligent_sampling(df, effective_max_points, filters.zoom_level)
        
        # Convert to list of dictionaries for JSON response - optimized
        data_points = []
        if len(df) > 0:
            data_dicts = df.to_dicts()
            for row in data_dicts:
                data_points.append(VolcanoDataPoint(
                    gene=row["gene"],
                    logFC=row["logFC"],
                    padj=row["padj"],
                    classyfireSuperclass=row["classyfireSuperclass"],
                    classyfireClass=row["classyfireClass"],
                    category=row["category"]
                ))
        
        return VolcanoResponse(
            data=data_points,
            stats=stats,
            total_rows=total_rows,
            filtered_rows=len(data_points),  # Actual number of points returned (after downsampling)
            points_before_sampling=points_before_sampling,
            is_downsampled=is_downsampled
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing data: {str(e)}")

@app.get("/api/volcano-data", response_model=VolcanoResponse)
async def get_volcano_data_get(
    p_value_threshold: float = Query(0.05, ge=0.0, le=1.0),
    log_fc_min: float = Query(-0.5, ge=-10.0, le=10.0),
    log_fc_max: float = Query(0.5, ge=-10.0, le=10.0),
    search_term: Optional[str] = Query(None),
    dataset_size: int = Query(10000, ge=100, le=10000000),
    max_points: int = Query(50000, ge=1000, le=200000),
    # LOD parameters
    zoom_level: float = Query(1.0, ge=0.1, le=100.0),
    x_min: Optional[float] = Query(None),
    x_max: Optional[float] = Query(None),
    y_min: Optional[float] = Query(None),
    y_max: Optional[float] = Query(None),
    lod_mode: bool = Query(True)
):
    """
    GET endpoint for volcano data with query parameters
    """
    # Construct ranges if provided
    x_range = [x_min, x_max] if x_min is not None and x_max is not None else None
    y_range = [y_min, y_max] if y_min is not None and y_max is not None else None
    
    filters = FilterParams(
        p_value_threshold=p_value_threshold,
        log_fc_min=log_fc_min,
        log_fc_max=log_fc_max,
        search_term=search_term,
        dataset_size=dataset_size,
        max_points=max_points,
        zoom_level=zoom_level,
        x_range=x_range,
        y_range=y_range,
        lod_mode=lod_mode
    )
    
    return await get_volcano_data(filters)

@app.get("/api/pca-cache-status")
async def pca_cache_status():
    """Get current PCA cache status"""
    return {
        "cached_datasets": list(_pca_cache.keys()),
        "total_cached": len(_pca_cache)
    }

@app.post("/api/clear-cache")
async def clear_cache():
    """Clear all caches"""
    global _data_cache, _pca_cache
    _data_cache.clear()
    _pca_cache.clear()
    return {
        "message": "All caches cleared successfully",
        "volcano_cache_size": len(_data_cache),
        "pca_cache_size": len(_pca_cache)
    }

@app.get("/api/pca-data", response_model=PCAResponse)
async def get_pca_data(
    dataset_size: int = Query(1000, ge=10, le=100000),
    n_features: int = Query(100, ge=10, le=10000),
    n_groups: int = Query(3, ge=2, le=10),
    max_points: int = Query(10000, ge=100, le=50000),
    add_batch_effect: bool = Query(False),
    noise_level: float = Query(0.1, ge=0.01, le=2.0)
):
    """
    GET endpoint for PCA data with query parameters
    """
    try:
        # Get cached PCA data
        pca_result = get_cached_pca_dataset(
            dataset_size, n_features, n_groups, add_batch_effect, noise_level
        )
        
        # Convert to list of PCADataPoint objects
        data_points = []
        points_before_sampling = len(pca_result['sample_ids'])
        is_downsampled = points_before_sampling > max_points
        
        # Apply downsampling if necessary
        if is_downsampled:
            # Simple random sampling for PCA data
            indices = np.random.choice(points_before_sampling, size=max_points, replace=False)
            indices = sorted(indices)  # Keep order for consistency
        else:
            indices = range(points_before_sampling)
        
        for i in indices:
            data_points.append(PCADataPoint(
                sample_id=pca_result['sample_ids'][i],
                pc1=float(pca_result['pca_coords'][i, 0]),
                pc2=float(pca_result['pca_coords'][i, 1]),
                pc3=float(pca_result['pca_coords'][i, 2]),
                group=pca_result['groups'][i],
                batch=pca_result['batch_labels'][i] if pca_result['batch_labels'] else None,
                metadata={}
            ))
        
        return PCAResponse(
            data=data_points,
            explained_variance=pca_result['explained_variance'],
            stats=pca_result['stats'],
            is_downsampled=is_downsampled,
            points_before_sampling=points_before_sampling
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing PCA data: {str(e)}")

@app.get("/api/r/volcano-data", response_model=VolcanoResponse)
async def get_r_volcano_data(
    p_value_threshold: float = Query(0.05, ge=0.0, le=1.0),
    log_fc_min: float = Query(-0.5, ge=-10.0, le=10.0),
    log_fc_max: float = Query(0.5, ge=-10.0, le=10.0),
    search_term: Optional[str] = Query(None),
    dataset_size: int = Query(10000, ge=100, le=10000000),
    max_points: int = Query(50000, ge=1000, le=200000),
    zoom_level: float = Query(1.0, ge=0.1, le=100.0)
):
    """
    R-based volcano plot data generation using direct R script execution
    """
    try:
        # Create R script for data generation
        r_script = f"""
library(data.table)
library(jsonlite)

# Set parameters
dataset_size <- {dataset_size}
p_threshold <- {p_value_threshold}
log_fc_min <- {log_fc_min}
log_fc_max <- {log_fc_max}
max_points <- {max_points}
search_term <- {'NULL' if not search_term else f'"{search_term}"'}

# Generate data
set.seed(42)
size <- max(100, min(10000000, as.integer(dataset_size)))

# Create realistic volcano plot distribution
log_fc <- rnorm(size, mean = 0, sd = 1.2)
p_values <- runif(size, min = 0.0001, max = 1.0)

# Create significant points (15% of data)
sig_indices <- sample(size, size * 0.15)
p_values[sig_indices] <- runif(length(sig_indices), min = 0.0001, max = 0.05)

# Generate gene names
gene_names <- paste0("R_Gene_", 1:size)

# Create data.table
dt <- data.table(
  gene = gene_names,
  logFC = round(log_fc, 4),
  padj = round(p_values, 6),
  classyfireSuperclass = sample(c("Organic acids", "Lipids", "Others"), size, replace = TRUE),
  classyfireClass = sample(c("Carboxylic acids", "Steroids", "Others"), size, replace = TRUE)
)

# Apply search filter if provided
if (!is.null(search_term) && nchar(search_term) > 0) {{
  search_lower <- tolower(search_term)
  dt <- dt[grepl(search_lower, tolower(gene))]
}}

# Categorize points
dt[, category := fifelse(
  padj <= p_threshold & logFC < log_fc_min, "down",
  fifelse(
    padj <= p_threshold & logFC > log_fc_max, "up",
    "non_significant"
  )
)]

# Calculate stats
stats_dt <- dt[, .N, by = category]
stats_list <- setNames(stats_dt$N, stats_dt$category)

stats <- list(
  up_regulated = as.integer(ifelse(is.na(stats_list[["up"]]), 0, stats_list[["up"]])),
  down_regulated = as.integer(ifelse(is.na(stats_list[["down"]]), 0, stats_list[["down"]])),
  non_significant = as.integer(ifelse(is.na(stats_list[["non_significant"]]), 0, stats_list[["non_significant"]]))
)

# Apply sampling if needed
total_rows <- {dataset_size}
points_before_sampling <- nrow(dt)
is_downsampled <- points_before_sampling > max_points

if (is_downsampled) {{
  sample_indices <- sample(nrow(dt), max_points)
  dt <- dt[sample_indices]
}}

# Prepare result
result <- list(
  data = dt,
  stats = stats,
  total_rows = as.integer(total_rows),
  filtered_rows = as.integer(nrow(dt)),
  points_before_sampling = as.integer(points_before_sampling),
  is_downsampled = is_downsampled
)

# Output as JSON
cat(toJSON(result, auto_unbox = TRUE, digits = 6))
"""
        
        # Execute R script
        with tempfile.NamedTemporaryFile(mode='w', suffix='.R', delete=False) as f:
            f.write(r_script)
            r_script_path = f.name
        
        try:
            # Run R script
            result = subprocess.run(
                ['Rscript', r_script_path],
                capture_output=True,
                text=True,
                timeout=30,
                cwd='/app'
            )
            
            if result.returncode != 0:
                raise Exception(f"R script failed: {result.stderr}")
            
            # Parse JSON result
            r_data = json.loads(result.stdout)
            
            # Convert R data to Python objects
            data_points = []
            if r_data.get('data') and len(r_data['data']) > 0:
                for row in r_data['data']:
                    data_points.append(VolcanoDataPoint(
                        gene=row['gene'],
                        logFC=row['logFC'],
                        padj=row['padj'],
                        classyfireSuperclass=row['classyfireSuperclass'],
                        classyfireClass=row['classyfireClass'],
                        category=row['category']
                    ))
            
            return VolcanoResponse(
                data=data_points,
                stats=r_data['stats'],
                total_rows=r_data['total_rows'],
                filtered_rows=r_data['filtered_rows'],
                points_before_sampling=r_data['points_before_sampling'],
                is_downsampled=r_data['is_downsampled']
            )
            
        finally:
            # Clean up temp file
            os.unlink(r_script_path)
            
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="R computation timed out")
    except json.JSONDecodeError as e:
        raise HTTPException(status_code=500, detail=f"Failed to parse R output: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"R computation failed: {str(e)}")

@app.get("/api/r/health")
async def r_health_check():
    """Check if R is available and working"""
    try:
        result = subprocess.run(
            ['Rscript', '-e', 'cat("R is working")'],
            capture_output=True,
            text=True,
            timeout=10,
            cwd='/app'
        )
        
        if result.returncode == 0:
            return {
                "status": "healthy",
                "backend": "R via subprocess",
                "r_output": result.stdout.strip()
            }
        else:
            return {
                "status": "error",
                "backend": "R via subprocess",
                "error": result.stderr
            }
    except Exception as e:
        return {
            "status": "error",
            "backend": "R via subprocess",
            "error": str(e)
        }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)