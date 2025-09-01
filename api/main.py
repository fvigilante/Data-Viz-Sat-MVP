from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
import polars as pl
import json
from pathlib import Path

app = FastAPI(title="Data Viz Satellite API", version="1.0.0")

# CORS middleware for Next.js frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://your-domain.com"],
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

def generate_synthetic_data(size: int) -> pl.DataFrame:
    """Generate synthetic metabolomics data using Polars"""
    
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
    
    # Generate data using Polars expressions for better performance
    import random
    
    data = []
    for i in range(size):
        log_fc = (random.random() - 0.5) * 8  # Range -4 to 4
        
        # Realistic p-value distribution based on fold change
        if abs(log_fc) > 1.5:
            p_value = random.random() * 0.1
        elif abs(log_fc) > 0.8:
            p_value = random.random() * 0.3
        else:
            p_value = random.random() * 0.8 + 0.2
            
        gene_name = metabolite_names[i % len(metabolite_names)] if i < len(metabolite_names) else f"Metabolite_{i + 1}"
        
        data.append({
            "gene": gene_name,
            "logFC": round(log_fc, 4),
            "padj": round(p_value, 6),
            "classyfireSuperclass": random.choice(superclasses),
            "classyfireClass": random.choice(classes)
        })
    
    return pl.DataFrame(data)

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

@app.get("/")
async def root():
    return {"message": "Data Viz Satellite API", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy"}

@app.post("/api/volcano-data", response_model=VolcanoResponse)
async def get_volcano_data(filters: FilterParams):
    """
    Get filtered volcano plot data with server-side processing using Polars
    """
    try:
        # Generate synthetic data
        df = generate_synthetic_data(filters.dataset_size)
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
        
        # Convert to list of dictionaries for JSON response
        data_points = [
            VolcanoDataPoint(**row) for row in df.to_dicts()
        ]
        
        return VolcanoResponse(
            data=data_points,
            stats=stats,
            total_rows=total_rows,
            filtered_rows=len(df)
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing data: {str(e)}")

@app.get("/api/volcano-data", response_model=VolcanoResponse)
async def get_volcano_data_get(
    p_value_threshold: float = Query(0.05, ge=0.0, le=1.0),
    log_fc_min: float = Query(-0.5, ge=-10.0, le=10.0),
    log_fc_max: float = Query(0.5, ge=-10.0, le=10.0),
    search_term: Optional[str] = Query(None),
    dataset_size: int = Query(10000, ge=100, le=1000000)
):
    """
    GET endpoint for volcano data with query parameters
    """
    filters = FilterParams(
        p_value_threshold=p_value_threshold,
        log_fc_min=log_fc_min,
        log_fc_max=log_fc_max,
        search_term=search_term,
        dataset_size=dataset_size
    )
    
    return await get_volcano_data(filters)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)