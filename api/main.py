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
from sklearn.datasets import make_blobs

app = FastAPI(title="Data Viz Satellite API", version="1.0.0")

# CORS middleware - read allowed origins from environment variable
frontend_url = os.getenv("FRONTEND_URL", "*")
allowed_origins = [frontend_url] if frontend_url != "*" else ["*"]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
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

# PCA Models
class PCADataPoint(BaseModel):
    sample_id: str
    pc1: float
    pc2: float
    pc3: float
    group: str
    batch: Optional[str] = None

class PCAResponse(BaseModel):
    data: List[PCADataPoint]
    explained_variance: dict  # pc1, pc2, pc3 percentages
    stats: dict
    is_downsampled: bool
    points_before_sampling: int

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
    
    # Generate log fold changes using normal distribution
    log_fc = np.random.normal(0, 1.5, size).round(4)
    
    # Generate p-values based on fold change (more realistic distribution)
    abs_log_fc = np.abs(log_fc)
    p_values = np.where(
        abs_log_fc > 1.5,
        np.random.uniform(0, 0.1, size),
        np.where(
            abs_log_fc > 0.8,
            np.random.uniform(0, 0.3, size),
            np.random.uniform(0.2, 1.0, size)
        )
    ).round(6)
    
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
            effective_max_points = get_lod_max_points(filters.zoom_level)
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

# PCA Functions
@lru_cache(maxsize=20)
def generate_pca_dataset(
    n_samples: int, 
    n_features: int, 
    n_groups: int, 
    add_batch_effect: bool = False, 
    noise_level: float = 0.1
) -> tuple:
    """Generate synthetic multi-omics data and compute PCA"""
    
    cache_key = f"{n_samples}_{n_features}_{n_groups}_{add_batch_effect}_{noise_level}"
    
    if cache_key in _pca_cache:
        return _pca_cache[cache_key]
    
    print(f"Generating PCA dataset: {n_samples} samples, {n_features} features, {n_groups} groups")
    
    # Generate synthetic multi-omics data with realistic group separation
    np.random.seed(42)
    
    # Create well-separated clusters for groups
    centers = np.random.randn(n_groups, n_features) * 3
    X, y = make_blobs(
        n_samples=n_samples,
        centers=centers,
        n_features=n_features,
        cluster_std=1.0 + noise_level,
        random_state=42
    )
    
    # Add batch effect if requested
    if add_batch_effect:
        n_batches = min(4, n_groups)  # Max 4 batches
        batch_labels = np.random.choice(n_batches, n_samples)
        
        # Add systematic batch effects
        for batch in range(n_batches):
            batch_mask = batch_labels == batch
            batch_effect = np.random.randn(n_features) * 0.5
            X[batch_mask] += batch_effect
    else:
        batch_labels = np.zeros(n_samples, dtype=int)
    
    # Standardize features
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)
    
    # Compute PCA
    pca = PCA(n_components=3)
    X_pca = pca.fit_transform(X_scaled)
    
    # Create sample IDs
    sample_ids = [f"Sample_{i+1:04d}" for i in range(n_samples)]
    group_labels = [f"Group_{group+1}" for group in y]
    batch_labels_str = [f"Batch_{batch+1}" if add_batch_effect else None for batch in batch_labels]
    
    # Prepare data
    pca_data = []
    for i in range(n_samples):
        pca_data.append({
            'sample_id': sample_ids[i],
            'pc1': float(X_pca[i, 0]),
            'pc2': float(X_pca[i, 1]),
            'pc3': float(X_pca[i, 2]),
            'group': group_labels[i],
            'batch': batch_labels_str[i]
        })
    
    explained_variance = {
        'pc1': float(pca.explained_variance_ratio_[0]),
        'pc2': float(pca.explained_variance_ratio_[1]),
        'pc3': float(pca.explained_variance_ratio_[2])
    }
    
    stats = {
        'total_samples': n_samples,
        'total_features': n_features,
        'groups': list(set(group_labels))
    }
    
    result = (pca_data, explained_variance, stats)
    _pca_cache[cache_key] = result
    
    print(f"PCA dataset generated and cached. Explained variance: PC1={explained_variance['pc1']:.3f}, PC2={explained_variance['pc2']:.3f}, PC3={explained_variance['pc3']:.3f}")
    
    return result

def intelligent_pca_sampling(data: List[dict], max_points: int) -> List[dict]:
    """Intelligent sampling for PCA data that preserves group distribution"""
    if len(data) <= max_points:
        return data
    
    # Group by group label
    groups = {}
    for point in data:
        group = point['group']
        if group not in groups:
            groups[group] = []
        groups[group].append(point)
    
    # Sample proportionally from each group
    sampled_data = []
    n_groups = len(groups)
    points_per_group = max_points // n_groups
    remaining_points = max_points % n_groups
    
    for i, (group, points) in enumerate(groups.items()):
        # Give extra points to first few groups if there's a remainder
        group_points = points_per_group + (1 if i < remaining_points else 0)
        
        if len(points) <= group_points:
            sampled_data.extend(points)
        else:
            # Random sampling within group
            indices = np.random.choice(len(points), group_points, replace=False)
            sampled_data.extend([points[idx] for idx in indices])
    
    return sampled_data

@app.get("/api/pca-cache-status")
async def pca_cache_status():
    """Get current PCA cache status"""
    return {
        "cached_datasets": list(_pca_cache.keys()),
        "total_cached": len(_pca_cache)
    }

@app.post("/api/clear-cache")
async def clear_cache():
    """Clear all cached data to free memory"""
    global _data_cache, _pca_cache
    
    # Store counts before clearing
    volcano_cache_count = len(_data_cache)
    pca_cache_count = len(_pca_cache)
    
    # Clear all caches
    _data_cache.clear()
    _pca_cache.clear()
    
    # Also clear the LRU caches
    get_cached_dataset.cache_clear()
    generate_pca_dataset.cache_clear()
    
    return {
        "message": "Cache cleared successfully",
        "cleared": {
            "volcano_datasets": volcano_cache_count,
            "pca_datasets": pca_cache_count,
            "total_cleared": volcano_cache_count + pca_cache_count
        }
    }

@app.get("/api/pca-data", response_model=PCAResponse)
async def get_pca_data(
    dataset_size: int = Query(1000, ge=100, le=100000),
    n_features: int = Query(100, ge=10, le=2000),  # Reduced max features to prevent crashes
    n_groups: int = Query(3, ge=2, le=8),
    max_points: int = Query(10000, ge=100, le=50000),
    add_batch_effect: bool = Query(False),
    noise_level: float = Query(0.1, ge=0.01, le=1.0)
):
    """
    Generate and return PCA data with 3D coordinates
    """
    try:
        # Safety check for performance-critical combinations
        if dataset_size > 10000 and n_features > 1000:
            raise HTTPException(
                status_code=400, 
                detail="High dataset size with high feature count may cause performance issues. Please reduce either dataset size (<10K) or features (<1K)."
            )
        
        if n_features > 2000:
            raise HTTPException(
                status_code=400,
                detail="Feature count exceeds safe limit (2000). Please reduce to prevent system overload."
            )
        # Generate PCA dataset
        pca_data, explained_variance, stats = generate_pca_dataset(
            dataset_size, n_features, n_groups, add_batch_effect, noise_level
        )
        
        # Apply intelligent sampling if needed
        points_before_sampling = len(pca_data)
        is_downsampled = len(pca_data) > max_points
        
        if is_downsampled:
            pca_data = intelligent_pca_sampling(pca_data, max_points)
        
        # Convert to Pydantic models
        data_points = [PCADataPoint(**point) for point in pca_data]
        
        return PCAResponse(
            data=data_points,
            explained_variance=explained_variance,
            stats=stats,
            is_downsampled=is_downsampled,
            points_before_sampling=points_before_sampling
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error generating PCA data: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)