# Data Viz Satellite - Multi-Omics Visualization Microservice Pilot

A pilot microservice developed by Sequentia Biotech's IT team to evaluate modern web technologies for multi-omics data visualization. Built with Next.js 15, TypeScript, and Plotly.js, this satellite application is designed to integrate with Sequentia Hub as an independent service within our Kubernetes-based microservices architecture.

## 🏢 Project Overview

This pilot project serves as a technology evaluation platform for building scalable data visualization microservices that can be launched from Sequentia Hub's results pages. The application demonstrates how users can explore various omics datasets (genomics, transcriptomics, proteomics, metabolomics) with advanced interactive visualizations, providing enhanced data exploration capabilities beyond the main platform interface.

### Strategic Goals
- **Technology Evaluation**: Assess Next.js 15 + React 19 + Plotly.js stack for enterprise omics visualization
- **Microservice Architecture**: Design patterns for Kubernetes-based satellite applications  
- **Hub Integration**: Seamless data flow from Sequentia Hub results to visualization services
- **Scalability Testing**: Performance evaluation with various omics dataset sizes and types

## ✨ Key Features

### 📊 Interactive Volcano Plots
- **Four-Tier Architecture**: Client-side, Next.js server-side, FastAPI + Polars, and R + data.table high-performance processing
- **Manual Level-of-Detail (LOD) Controls**: User-selectable downsampling levels (10K/20K/50K/100K points)
- **Intelligent Downsampling**: Significance-aware sampling that prioritizes biologically relevant data
- **Real-time Filtering**: Adjustable p-value thresholds and log2(FC) ranges with live updates
- **Server-Side Filtering**: All filtering operations (p-value, log2FC, search) handled by backend APIs
- **Dual High-Performance Backends**: FastAPI + Polars and R + data.table for processing 10M+ data points with intelligent caching
- **Performance Comparison**: Side-by-side R vs Python implementation comparison and benchmarking
- **Interactive Legend**: Toggle visibility of up-regulated, down-regulated, and non-significant metabolites
- **Hover Tooltips**: Detailed metabolite information including ClassyFire annotations
- **Export Capabilities**: Download plots as high-resolution PNG images and filtered CSV data
- **Technology Explainers**: Interactive accordion sections explaining the technical architecture
- **Responsive Design**: Optimized for desktop and tablet viewing

### 🧬 Principal Component Analysis (PCA)
- **3D Interactive Visualization**: Hardware-accelerated 3D scatter plots with Plotly.js WebGL
- **Dynamic Group Management**: Toggle visibility of experimental groups with real-time plot updates
- **Smart Performance Controls**: Safety limits prevent system crashes with large feature sets
- **Dynamic Data Tables**: Automatically generated tables for each visible group
- **Group-Specific Exports**: Individual CSV downloads for each experimental group
- **Intelligent Caching**: Pre-computed PCA results with manual cache management
- **Color Coordination**: Consistent color schemes between 3D plot and data tables
- **Batch Effect Simulation**: Optional batch effect modeling for realistic data scenarios
- **Scalable Architecture**: Handles up to 2K features safely with performance warnings

### 🔍 Multi-Omics Data Analysis Tools
- **Universal Data Support**: Genomics (SNPs, GWAS), Transcriptomics (RNA-seq), Proteomics (abundance), Metabolomics (profiling)
- **Significance Thresholds**: Configurable statistical and biological significance boundaries
- **Search & Filtering**: Real-time search across various omics identifiers and annotations
- **Interactive Tables**: Sortable tables for significant features across different omics types
- **Export Capabilities**: Download filtered results in formats compatible with Sequentia Hub
- **Synthetic Data Generation**: Multi-omics dataset generators for testing various data types and sizes

### 📁 Enterprise Data Integration
- **Hub Integration**: Direct data pipeline from Sequentia Hub results pages
- **Multiple Formats**: Support for various omics data formats (CSV, TSV, JSON, Parquet)
- **API-First Design**: RESTful endpoints for seamless microservice communication
- **Authentication**: Integration with Sequentia's authentication and authorization systems
- **Data Validation**: Enterprise-grade validation for various omics data schemas
- **Error Handling**: Comprehensive error reporting with integration back to Hub interface

### 🎓 Educational Features
- **Interactive Technology Explainers**: Accordion-based sections explaining technical architecture
- **Architecture Comparisons**: Clear explanations of client-side vs server-side vs FastAPI processing
- **Performance Characteristics**: Detailed performance metrics and use case recommendations
- **Technology Stack Details**: Comprehensive breakdown of technologies used in each approach
- **Real-world Use Cases**: Practical examples of when to use each architecture
- **Best Practices**: Guidelines for choosing the right approach for different scenarios

## 🏗️ Project Structure

\`\`\`
├── app/                          # Next.js 15 App Router
│   ├── layout.tsx               # Root layout with navigation and fonts
│   ├── page.tsx                 # Home page (redirects to volcano plot)
│   ├── globals.css              # Global styles, CSS variables, and Tailwind
│   ├── about/                   # About page with project information
│   ├── plots/                   # Data visualization pages
│   │   ├── volcano/             # Client-side volcano plot implementation
│   │   │   └── page.tsx         # Main client-side volcano plot page
│   │   ├── volcano-server/      # Server-side volcano plot implementation
│   │   │   └── page.tsx         # Main server-side volcano plot page
│   │   ├── volcano-fastapi/     # FastAPI + Polars volcano plot implementation
│   │   │   └── page.tsx         # FastAPI-powered volcano plot page
│   │   ├── volcano-r/           # R + data.table volcano plot implementation
│   │   │   └── page.tsx         # R-powered volcano plot page
│   │   ├── heatmap/            # Heatmap visualization (future implementation)
│   │   └── pca/                # PCA visualization (future implementation)
│   └── api/                     # Next.js API routes
│       ├── volcano-data/        # Server-side data processing endpoint
│       │   └── route.ts         # GET endpoint for processed volcano data
│       ├── r-volcano-data/      # R backend proxy endpoint
│       │   └── route.ts         # Proxy to R Plumber API
│       ├── r-cache-status/      # R cache status endpoint
│       │   └── route.ts         # R cache management proxy
│       ├── r-warm-cache/        # R cache warming endpoint
│       │   └── route.ts         # R cache pre-generation proxy
│       └── r-clear-cache/       # R cache clearing endpoint
│           └── route.ts         # R cache clearing proxy
├── api/                         # FastAPI Backend
│   ├── main.py                  # FastAPI application with Polars data processing
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile              # Docker configuration for API
│   └── README.md               # API documentation
├── r-backend/                   # R Backend (Plumber API)
│   ├── plumber-api.R           # R Plumber API server with data.table processing
│   ├── install-packages.R      # R package installation script
│   ├── validate-setup.R        # R environment validation script
│   ├── start-server.sh         # Unix server startup script
│   ├── start-server.bat        # Windows server startup script
│   ├── setup-guide.md          # Comprehensive R setup instructions
│   └── README.md               # R backend documentation
├── components/                   # React components library
│   ├── VolcanoPlot.tsx         # Client-side interactive volcano plot component
│   ├── ServerVolcanoPlot.tsx   # Server-side volcano plot component
│   ├── FastAPIVolcanoPlot.tsx  # FastAPI + Polars volcano plot component
│   ├── RVolcanoPlot.tsx        # R + data.table volcano plot component
│   ├── FastAPIPCAPlot.tsx      # PCA analysis with dynamic tables
│   ├── TechExplainer.tsx       # Interactive technology architecture explainer
│   ├── theme-provider.tsx      # Theme context provider
│   ├── layout/                 # Layout and navigation components
│   │   ├── Header.tsx          # Application header with branding
│   │   ├── SidebarNav.tsx      # Navigation sidebar with routing
│   │   └── Footer.tsx          # Application footer with GitHub link
│   └── ui/                     # Reusable UI components (shadcn/ui)
│       ├── accordion.tsx       # Collapsible content sections
│       ├── badge.tsx           # Status and category badges
│       ├── button.tsx          # Button component variants
│       ├── card.tsx            # Card container components
│       ├── input.tsx           # Form input components
│       ├── label.tsx           # Form label components
│       ├── slider.tsx          # Range slider component
│       ├── table.tsx           # Data table components
│       └── ...                 # Additional UI components
├── lib/                        # Utility libraries and helpers
│   ├── schema.ts               # Zod validation schemas for data types
│   ├── parseCsv.ts            # CSV/TSV parsing with Papa Parse
│   └── utils.ts               # General utility functions and helpers
├── public/                     # Static assets and files
│   ├── metabolomics_example.csv # Example metabolomics dataset
│   └── ...                     # Additional static assets
├── styles/                     # Additional stylesheets
│   └── globals.css            # Global CSS styles
├── scripts/                     # Development and deployment scripts
│   ├── dev.py                  # Python script to run both servers
│   └── dev.sh                 # Shell script for concurrent development
└── Configuration Files
    ├── package.json            # Dependencies and scripts
    ├── tsconfig.json          # TypeScript configuration
    ├── tailwind.config.ts     # Tailwind CSS configuration
    ├── next.config.mjs        # Next.js configuration
    ├── docker-compose.yml     # Multi-service Docker configuration
    ├── .env.example           # Environment variables template
    └── components.json        # shadcn/ui component configuration
\`\`\`

## 🧪 Business Logic & Scientific Background

### Volcano Plot Analysis
Volcano plots are essential tools in metabolomics for visualizing differential expression results:

- **X-axis (Log2 Fold Change)**: Represents the magnitude of change between conditions
- **Y-axis (-log10 p-value)**: Represents statistical significance
- **Color Coding**: 
  - 🔴 **Red**: Up-regulated metabolites (high fold change, low p-value)
  - 🔵 **Blue**: Down-regulated metabolites (low fold change, low p-value)
  - ⚫ **Gray**: Non-significant metabolites

### Four-Tier Data Processing Architecture

#### Tier 1: Client-Side Processing (`/plots/volcano`)
**Best for**: Prototyping, small datasets (<10K rows), offline usage
1. **File Upload**: User uploads CSV/TSV file
2. **CSV Parsing**: Client-side parsing with Papa Parse
3. **Data Validation**: Schema validation using Zod
4. **Visualization**: Real-time interactive plotting with Plotly.js
5. **Filtering**: Dynamic filtering based on user-defined thresholds

**Performance**: ⚡ Fast for small datasets, limited by browser memory

#### Tier 2: Next.js Server-Side Processing (`/plots/volcano-server`)
**Best for**: Medium datasets (10K-50K rows), integrated deployment
1. **Data Pre-processing**: Server processes data via Next.js API endpoint
2. **Normalization**: Column name mapping and data cleaning
3. **Validation**: Server-side data validation
4. **Response**: JSON data sent to client for visualization
5. **Caching**: Optimized for repeated requests

**Performance**: ⚡⚡ Good for medium datasets, Node.js limitations for large data

#### Tier 3: FastAPI + Polars Processing (`/plots/volcano-fastapi`) - HIGH PERFORMANCE
**Best for**: Large datasets (50K+ rows), production environments, performance-critical applications
1. **High-Performance Backend**: FastAPI serves as the dedicated API layer
2. **Polars Data Processing**: Lightning-fast DataFrame operations (10x faster than pandas)
3. **Manual LOD Controls**: User-selectable downsampling levels (10K/20K/50K/100K points)
4. **Intelligent Downsampling**: Significance-aware sampling that preserves biological relevance
5. **Intelligent Caching System**: LRU cache stores generated datasets in memory for instant subsequent access
6. **Vectorized Data Generation**: NumPy-based synthetic data creation for 10x faster generation
7. **Server-Side Filtering**: All filtering (p-value, log2FC, search) handled by optimized API
8. **Adaptive Sampling**: Automatically adjusts sampling strategy based on dataset size
9. **Lazy Evaluation**: Efficient query planning and parallel processing
10. **Cache Warming**: Pre-generate common dataset sizes for instant loading
11. **Memory Optimization**: Efficient handling of 100K+ to 10M+ data points
12. **Scalable Architecture**: Production-ready with horizontal scaling capabilities

**Performance**: ⚡⚡⚡ Optimized for large datasets, scientific computing performance with intelligent caching and user-controlled LOD

#### Tier 4: R + data.table Processing (`/plots/volcano-r`) - RESEARCH & COMPARISON
**Best for**: Statistical computing, R ecosystem integration, performance benchmarking
1. **R Plumber API**: Lightweight R HTTP API server for statistical computing
2. **data.table Processing**: High-performance data manipulation with R's data.table package
3. **Statistical Accuracy**: Native R statistical functions for precise calculations
4. **Vectorized Operations**: Efficient R vectorization for large dataset processing
5. **Environment-Based Caching**: R environment caching system for dataset storage
6. **Identical Functionality**: Matches FastAPI implementation feature-for-feature
7. **Performance Benchmarking**: Direct comparison with Python implementation
8. **Memory Management**: R-specific memory optimization and garbage collection
9. **Cross-Platform Support**: Windows, macOS, and Linux compatibility
10. **Research Integration**: Seamless integration with existing R workflows

**Performance**: ⚡⚡⚡ Comparable to FastAPI for statistical computing, optimized for R ecosystem integration

### ClassyFire Integration
The application integrates metabolite classification data:
- **Superclass**: High-level chemical classification
- **Class**: More specific chemical grouping
- **Biological Context**: Helps researchers understand metabolic pathways

## 🔬 R Integration & Performance Comparison

### R Backend Overview

The R integration provides a complete alternative backend implementation using R + data.table, enabling direct performance and functionality comparison with the Python + Polars implementation. This dual-backend approach allows researchers to leverage the best of both ecosystems.

### Key Features

#### 🚀 High-Performance R Backend
- **Plumber API Server**: Lightweight R HTTP API framework
- **data.table Processing**: Vectorized operations for 10M+ data points
- **Environment Caching**: R-native caching system for optimal memory usage
- **Statistical Accuracy**: Native R statistical functions for precise calculations
- **Cross-Platform**: Windows, macOS, and Linux support

#### 📊 Functional Parity
- **Identical UI**: Same interface, controls, and visualization as FastAPI version
- **Same API Structure**: Compatible JSON request/response format
- **Feature Complete**: All filtering, sampling, and export capabilities
- **Cache Management**: Warming, clearing, and status endpoints
- **Error Handling**: Comprehensive error management matching FastAPI format

#### ⚡ Performance Benchmarking
- **Automated Benchmarking**: Built-in performance comparison framework
- **Multiple Metrics**: Response time, memory usage, CPU utilization
- **Statistical Validation**: Output consistency verification between R and Python
- **Comprehensive Reports**: HTML reports with detailed performance analysis

### R Backend Architecture

```
Frontend (Next.js) → Next.js API Routes → R Plumber Server → data.table Processing
```

#### Components
1. **R Plumber API** (`r-backend/plumber-api.R`) - HTTP API server
2. **Next.js Proxy Routes** (`/app/api/r-*`) - Frontend integration
3. **React Component** (`RVolcanoPlot.tsx`) - R-specific UI component
4. **Process Management** - Startup, monitoring, and health checks

### Quick Start with R Backend

#### Prerequisites
- **R 4.0+** installed and in PATH
- **Required R packages**: plumber, data.table, jsonlite

#### Installation & Setup

1. **Install R dependencies**
   ```bash
   cd r-backend
   Rscript install-packages.R
   ```

2. **Start R backend server**
   ```bash
   # Windows
   start-server.bat
   
   # macOS/Linux
   chmod +x start-server.sh
   ./start-server.sh
   ```

3. **Start development environment**
   ```bash
   # Run both FastAPI and R backends
   npm run dev:full
   
   # Or start R backend separately
   npm run dev:r
   ```

4. **Access R volcano plot**
   - Navigate to [http://localhost:3000/plots/volcano-r](http://localhost:3000/plots/volcano-r)
   - Compare with FastAPI version at [http://localhost:3000/plots/volcano-fastapi](http://localhost:3000/plots/volcano-fastapi)

### Performance Comparison

#### Benchmarking Framework

The application includes a comprehensive benchmarking system:

```bash
# Quick performance comparison
cd r-backend
Rscript quick-benchmark.R

# Comprehensive benchmark suite
Rscript benchmark-framework.R run

# Generate performance report
Rscript benchmark-framework.R report results.rds
```

#### Benchmark Scenarios
- **Dataset Sizes**: 10K, 50K, 100K, 500K, 1M data points
- **Parameter Variations**: Different p-value thresholds, fold-change ranges
- **Resource Monitoring**: CPU, memory, and response time tracking
- **Statistical Validation**: Output consistency verification

#### Expected Performance Characteristics

| Metric | R + data.table | Python + Polars | Notes |
|--------|----------------|-----------------|-------|
| **Small Datasets** (10K) | ~40ms | ~45ms | R slightly faster |
| **Medium Datasets** (100K) | ~140ms | ~155ms | Comparable performance |
| **Large Datasets** (1M+) | ~700ms | ~680ms | Very similar |
| **Memory Usage** | Efficient | Efficient | Both optimized |
| **Statistical Accuracy** | Native R precision | NumPy precision | Functionally identical |

### R-Specific Features

#### Advanced Statistical Computing
- **Native R Functions**: Leverages R's statistical computing strengths
- **Vectorized Operations**: Efficient data.table operations
- **Memory Management**: R-specific garbage collection and optimization
- **Reproducible Results**: Fixed random seeds for consistent output

#### Integration Benefits
- **R Ecosystem**: Easy integration with existing R workflows
- **Statistical Packages**: Access to CRAN's extensive statistical libraries
- **Research Compatibility**: Familiar environment for R users
- **Cross-Validation**: Verify results between R and Python implementations

### Development Workflow

#### Dual Backend Development
```bash
# Start both backends for comparison
npm run dev:full

# Test both implementations
curl http://localhost:8000/api/volcano-data  # FastAPI
curl http://localhost:8001/api/volcano-data  # R backend

# Run comparison tests
cd r-backend
Rscript live-comparison-test.R
```

#### Output Validation
```bash
# Compare outputs between backends
Rscript compare-outputs.R r_response.json python_response.json

# Statistical validation
Rscript statistical-validation.R r_data.json python_data.json

# Generate comparison report
Rscript generate-comparison-report.R r_response.json python_response.json report.html
```

### Troubleshooting R Integration

#### Common Issues

**R Not Found**
```bash
# Verify R installation
Rscript --version
R --version
```

**Package Installation Fails**
```bash
# Manual package installation
R
> install.packages(c("plumber", "data.table", "jsonlite"))
```

**Port Conflicts**
```bash
# Use custom port
./start-server.sh 8002

# Check port usage
netstat -an | grep 8001  # Unix
netstat -an | find ":8001"  # Windows
```

**Performance Issues**
```bash
# Monitor R backend
./server-status.sh

# Check health
curl http://localhost:8001/health
```

### R Backend API Endpoints

#### Core Endpoints
- `GET /health` - Server health and package versions
- `GET /api/volcano-data` - Main volcano plot data processing
- `GET /api/cache-status` - Cache status and memory usage
- `POST /api/warm-cache` - Pre-generate common dataset sizes
- `POST /api/clear-cache` - Clear cached datasets

#### Example Usage
```bash
# Get volcano data with R backend
curl "http://localhost:8001/api/volcano-data?dataset_size=10000&p_value_threshold=0.05"

# Check cache status
curl http://localhost:8001/api/cache-status

# Warm cache for common sizes
curl -X POST http://localhost:8001/api/warm-cache
```

### Production Considerations

#### Deployment Options
1. **Standalone R Server**: Run R backend as separate service
2. **Docker Integration**: Include R backend in multi-container setup
3. **Process Management**: Use systemd (Linux) or Windows services
4. **Load Balancing**: Scale R backend instances for high throughput

#### Monitoring & Maintenance
- **Health Checks**: Automated monitoring with restart capabilities
- **Performance Metrics**: CPU, memory, and response time tracking
- **Log Management**: Comprehensive logging for debugging and monitoring
- **Resource Limits**: Memory and CPU limits for stable operation

This R integration provides a complete alternative backend while maintaining full compatibility with the existing frontend, enabling comprehensive performance comparison and validation between R and Python implementations.

## 📚 R Integration Documentation

### Complete Documentation Suite

The R backend integration includes comprehensive documentation covering all aspects of setup, usage, and maintenance:

#### Setup and Installation
- **[R Backend README](r-backend/README.md)** - Basic setup and API overview
- **[Setup Guide](r-backend/setup-guide.md)** - Detailed installation instructions for all platforms
- **[Troubleshooting Guide](r-backend/TROUBLESHOOTING-GUIDE.md)** - Comprehensive problem-solving guide

#### Performance and Comparison
- **[Benchmarking README](r-backend/BENCHMARKING-README.md)** - Performance testing framework
- **[Comparison Procedures](r-backend/COMPARISON-PROCEDURES.md)** - R vs Python comparison methodology
- **[Output Validation README](r-backend/OUTPUT-VALIDATION-README.md)** - Data consistency verification

#### System Management
- **[Process Management README](r-backend/PROCESS-MANAGEMENT-README.md)** - Server lifecycle management
- **[Error Handling README](r-backend/ERROR-HANDLING-README.md)** - Error handling and logging
- **[Cache Endpoints Summary](r-backend/CACHE-ENDPOINTS-SUMMARY.md)** - Cache management features

#### Technical Implementation
- **[Data Generation README](r-backend/DATA-GENERATION-README.md)** - Data generation and caching system
- **[Demo Validation Usage](r-backend/demo-validation-usage.md)** - Validation examples and usage

### Quick Reference

#### Essential Commands
\`\`\`bash
# Setup
cd r-backend && Rscript install-packages.R

# Start R backend
npm run dev:r-start

# Health check
curl http://localhost:8001/health

# Quick benchmark
npm run benchmark:quick

# Comprehensive testing
npm run test:r
\`\`\`

#### Key Endpoints
- **Health**: `GET /health`
- **Volcano Data**: `GET /api/volcano-data`
- **Cache Status**: `GET /api/cache-status`
- **Cache Management**: `POST /api/warm-cache`, `POST /api/clear-cache`

#### Performance Comparison
\`\`\`bash
# Quick comparison
Rscript r-backend/quick-benchmark.R

# Detailed analysis
Rscript r-backend/benchmark-framework.R run
Rscript r-backend/benchmark-framework.R report results.rds

# Output validation
Rscript r-backend/live-comparison-test.R
\`\`\`

### Documentation Organization

\`\`\`
r-backend/
├── README.md                      # Basic setup and overview
├── setup-guide.md                 # Detailed installation guide
├── TROUBLESHOOTING-GUIDE.md       # Comprehensive troubleshooting
├── COMPARISON-PROCEDURES.md       # R vs Python comparison methods
├── BENCHMARKING-README.md         # Performance testing framework
├── OUTPUT-VALIDATION-README.md    # Data validation procedures
├── PROCESS-MANAGEMENT-README.md   # Server management
├── ERROR-HANDLING-README.md       # Error handling system
├── CACHE-ENDPOINTS-SUMMARY.md     # Cache management
├── DATA-GENERATION-README.md      # Data generation system
└── demo-validation-usage.md       # Usage examples
\`\`\`

This documentation suite provides complete coverage of the R integration, from initial setup through advanced performance optimization and troubleshooting.

## 🛠️ Technical Architecture & Implementation

### Technology Stack

#### Frontend Technologies
- **Next.js 15**: React framework with App Router for modern web development
- **React 19**: Latest React with concurrent features and improved performance
- **TypeScript 5**: Full type safety and enhanced developer experience
- **Tailwind CSS 3.4**: Utility-first CSS framework for rapid UI development
- **shadcn/ui**: High-quality, accessible component library built on Radix UI
- **Geist Font**: Modern typography with sans and mono variants

#### Backend Technologies
- **FastAPI**: Modern, fast web framework for building APIs with Python
- **Polars**: Lightning-fast DataFrame library for high-performance data processing
- **Pydantic**: Data validation and settings management using Python type annotations
- **Uvicorn**: ASGI server for production-ready API deployment

#### Data Visualization & Processing
- **Plotly.js**: Advanced interactive plotting library with WebGL acceleration
- **react-plotly.js**: React wrapper for Plotly.js with proper SSR handling
- **Papa Parse**: High-performance CSV/TSV parsing with streaming support
- **Zod**: Runtime type validation and schema definition

#### Development & Build Tools
- **PostCSS**: CSS processing with autoprefixer
- **ESLint**: Code linting and quality assurance
- **Docker**: Containerization for consistent development and deployment
- **Docker Compose**: Multi-service orchestration for full-stack development

### Architecture Patterns

#### Client-Side Volcano Plot (`/plots/volcano`)
The client-side implementation follows a pure React pattern with local state management:

```typescript
// Data Flow Architecture
User Upload → Papa Parse → Zod Validation → React State → Plotly.js Rendering

// Key Components:
- File Upload Handler: Processes CSV/TSV files with drag-and-drop support
- Data Parser: Normalizes column names and validates data structure
- State Management: React hooks for filtering, caching, and UI state
- Plot Component: Dynamic Plotly.js integration with real-time updates
- Export Functions: PNG download and CSV export capabilities
```

**Performance Characteristics:**
- Optimal for datasets up to 50,000 data points
- Real-time filtering and interaction
- Client-side caching for dataset switching
- Memory-efficient data structures

#### Server-Side Volcano Plot (`/plots/volcano-server`)
The server-side implementation demonstrates API-driven data processing:

```typescript
// Data Flow Architecture
API Request → Server Processing → JSON Response → Client Rendering

// API Endpoint (/api/volcano-data/route.ts):
- File System Access: Reads example CSV from public directory
- Server-Side Parsing: Papa Parse processing on Node.js
- Data Normalization: Column mapping and type conversion
- Response Optimization: Structured JSON with error handling
```

**Performance Characteristics:**
- Scalable for large datasets (100K+ points)
- Server-side data preprocessing
- Reduced client-side memory usage
- Cacheable API responses

### Data Processing Pipeline

#### CSV/TSV Parsing Logic (`lib/parseCsv.ts`)
```typescript
// Intelligent Column Mapping
const columnMappings = {
  gene: ['gene', 'metabolite', 'metabolite name'],
  logFC: ['log2(fc)', 'logfc', 'log2fc', 'fold change'],
  padj: ['p-value', 'pvalue', 'padj', 'fdr', 'adjusted p-value'],
  classyfireSuperclass: ['superclass', 'classyfire superclass'],
  classyfireClass: ['class', 'classyfire class']
}

// Data Validation Pipeline
Raw CSV → Header Normalization → Type Coercion → Zod Validation → Clean Dataset
```

#### Synthetic Data Generation
The application includes a sophisticated synthetic data generator for testing:

```typescript
// Realistic Metabolomics Data Simulation
- Metabolite Names: 30+ real metabolite identifiers
- Statistical Distribution: Biologically realistic p-value and fold-change correlations
- Classification Data: Authentic ClassyFire superclass and class assignments
- Scalable Generation: Supports 1K to 100K+ data points with performance optimization
```

### Plotly.js Integration & Optimization

#### Dynamic Import Strategy
```typescript
// SSR-Safe Plotly.js Loading
const Plot = dynamic(() => import("react-plotly.js"), { 
  ssr: false,
  loading: () => <LoadingSpinner />
})
```

#### Plot Configuration & Performance
```typescript
// Optimized Plot Settings for Multi-Omics Data
{
  type: "scattergl",           // WebGL acceleration for 100K+ features
  mode: "markers",             // Point-based visualization
  hovermode: "closest",        // Efficient hover interactions
  responsive: true,            // Automatic resizing
  displayModeBar: true,        // Export and interaction tools
  modeBarButtonsToRemove: [    // Streamlined toolbar
    "lasso2d", "select2d"
  ]
}

// scattergl Performance Benefits:
// ✅ GPU-accelerated rendering via WebGL
// ✅ Smooth interactions with 100K+ omics features
// ✅ Memory-efficient point management
// ✅ Real-time filtering without performance degradation
// ✅ Ideal for genomics, transcriptomics, proteomics, metabolomics
```

#### Interactive Features Implementation
- **Category Filtering**: Real-time point visibility toggling
- **Threshold Lines**: Dynamic significance and fold-change boundaries  
- **Hover Tooltips**: Rich metabolite information display
- **Export Functions**: High-resolution PNG generation
- **Zoom & Pan**: Native Plotly.js navigation with reset functionality

### State Management Architecture

#### Client-Side State Pattern
```typescript
// Hierarchical State Management
const [data, setData] = useState<DegRow[]>([])           // Raw dataset
const [filteredData, setFilteredData] = useState<DegRow[]>([])  // Processed data
const [logFCRange, setLogFCRange] = useState([-0.5, 0.5])      // Filter parameters
const [pValue, setPValue] = useState(0.05)                      // Significance threshold

// Computed State with useMemo
const { downRegulated, upRegulated, nonSignificant } = useMemo(() => {
  // Efficient categorization logic
}, [filteredData, pValue, logFCRange])
```

#### Caching Strategy
```typescript
// Dataset Caching for Performance
const [datasetCache, setDatasetCache] = useState<Map<number, DegRow[]>>(new Map())

// Cache Management
- Synthetic datasets cached by size (1K, 10K, 50K, 100K)
- Instant switching between cached datasets
- Memory-efficient cache eviction
```

### Component Architecture

#### Modular Design Pattern
```
Layout Components (components/layout/)
├── Header.tsx          # Application branding and navigation
├── SidebarNav.tsx      # Route-aware navigation with active states
└── Footer.tsx          # GitHub integration and branding

Plot Components
├── VolcanoPlot.tsx     # Client-side interactive plot
└── ServerVolcanoPlot.tsx # Server-side optimized plot

UI Components (components/ui/)
├── Atomic Components   # Button, Input, Label, etc.
├── Composite Components # Card, Table, Slider, etc.
└── Layout Components   # Responsive grid and container systems
```

#### Props Interface Design
```typescript
// Type-Safe Component Interfaces
interface VolcanoPlotProps {
  data: DegRow[]                    // Validated dataset
  logFcMin?: number                 // Fold change threshold (lower)
  logFcMax?: number                 # Fold change threshold (upper)
  padjThreshold?: number            # Statistical significance threshold
}

// Zod Schema Validation
export const DegRowSchema = z.object({
  gene: z.string().min(1),                    // Required metabolite identifier
  logFC: z.coerce.number(),                   // Fold change (auto-converted)
  padj: z.coerce.number().min(0).max(1),     // P-value with range validation
  classyfireSuperclass: z.string().optional(), // Optional classification
  classyfireClass: z.string().optional()      // Optional sub-classification
})
```

### Performance Optimization Strategies

#### Client-Side Optimizations
- **Memoization**: Expensive calculations cached with `useMemo`
- **Debounced Inputs**: Smooth real-time filtering without performance impact
- **Virtual Scrolling**: Efficient table rendering for large datasets
- **Code Splitting**: Dynamic imports for Plotly.js and heavy components

#### Server-Side Optimizations  
- **Static Generation**: Pre-built pages for optimal loading
- **API Caching**: Structured responses with appropriate cache headers
- **Memory Management**: Efficient data processing with streaming where applicable

#### Bundle Optimization
- **Tree Shaking**: Unused code elimination
- **Dynamic Imports**: Lazy loading of visualization libraries
- **Asset Optimization**: Optimized fonts, images, and static resources

## 🚀 Getting Started

### Prerequisites
- **Docker & Docker Compose**: Required for the easiest setup (recommended)
- **Alternative**: Node.js 18+, Python 3.11+, and R 4.0+ for manual setup
- **R Installation**: Required for R backend functionality and performance comparison
- **Modern Browser**: Chrome 90+, Firefox 88+, Safari 14+, or Edge 90+

### Installation

#### Option 1: Docker Development (Recommended)

The easiest way to run the full application locally with both frontend and backend.

1. **Clone the repository**
   \`\`\`bash
   git clone https://github.com/fvigilante/Data-Viz-Sat-MVP.git
   cd Data-Viz-Sat-MVP
   \`\`\`

2. **Start the application with Docker**
   \`\`\`bash
   # Build and run both containers in detached mode
   docker-compose up -d
   
   # Or build first, then run
   docker-compose build
   docker-compose up -d
   \`\`\`

3. **Access the applications**
   - **Frontend**: [http://localhost:3000](http://localhost:3000)
   - **API**: [http://localhost:8000](http://localhost:8000)
   - **API Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)

4. **Useful Docker commands**
   \`\`\`bash
   # View logs
   docker-compose logs -f
   
   # Stop the application
   docker-compose down
   
   # Rebuild after code changes
   docker-compose up -d --build
   
   # View container status
   docker-compose ps
   \`\`\`

#### Option 2: Manual Development Setup (Full Stack with R)

If you prefer to run all services manually without Docker.

1. **Clone and install frontend dependencies**
   \`\`\`bash
   git clone https://github.com/fvigilante/Data-Viz-Sat-MVP.git
   cd Data-Viz-Sat-MVP
   npm install
   \`\`\`

2. **Install Python dependencies for FastAPI**
   \`\`\`bash
   cd api
   pip install -r requirements.txt
   cd ..
   \`\`\`

3. **Install R dependencies for R backend**
   \`\`\`bash
   cd r-backend
   Rscript install-packages.R
   cd ..
   \`\`\`

4. **Run all services concurrently**
   \`\`\`bash
   # Option A: All services with one command
   npm run dev:full
   
   # Option B: Run services in separate terminals
   # Terminal 1 - FastAPI backend
   npm run dev:api
   
   # Terminal 2 - R backend
   npm run dev:r
   
   # Terminal 3 - Next.js frontend  
   npm run dev
   \`\`\`

### Available npm Scripts for R Backend

\`\`\`bash
# R Backend Development
npm run dev:r              # Start R backend server
npm run dev:r-start        # Start R backend with process management
npm run dev:r-stop         # Stop R backend server
npm run dev:r-status       # Check R backend status

# Testing
npm run test:r             # Run R backend comprehensive tests
npm run test:integration   # Run integration tests
npm run test:r-validation  # Run output validation tests

# Performance Benchmarking
npm run benchmark:quick    # Quick performance comparison
npm run benchmark:full     # Comprehensive benchmark suite
npm run benchmark:memory   # Memory usage profiling
\`\`\`

5. **Access the applications**
   - **Frontend**: [http://localhost:3000](http://localhost:3000)
   - **FastAPI**: [http://localhost:8000](http://localhost:8000)
   - **FastAPI Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
   - **R Backend**: [http://localhost:8001](http://localhost:8001)
   - **R Health Check**: [http://localhost:8001/health](http://localhost:8001/health)

#### Option 3: Frontend Only

For frontend development without the FastAPI backend.

1. **Install dependencies**
   \`\`\`bash
   npm install
   \`\`\`

2. **Run the development server**
   \`\`\`bash
   npm run dev
   \`\`\`

3. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)
   
   *Note: FastAPI-powered features will not work in this mode.*

### Build for Production

\`\`\`bash
# Build the application
npm run build

# Start the production server
npm run start
\`\`\`

### R Backend Setup

#### Installing R

**Windows:**
1. Download R from [https://cran.r-project.org/bin/windows/base/](https://cran.r-project.org/bin/windows/base/)
2. Run the installer and follow the setup wizard
3. Verify installation: `Rscript --version`

**macOS:**
\`\`\`bash
# Using Homebrew (recommended)
brew install r

# Verify installation
Rscript --version
\`\`\`

**Linux (Ubuntu/Debian):**
\`\`\`bash
sudo apt update
sudo apt install r-base r-base-dev
Rscript --version
\`\`\`

#### R Package Installation

\`\`\`bash
cd r-backend
Rscript install-packages.R
\`\`\`

This installs required packages:
- `plumber` - Web API framework for R
- `data.table` - High-performance data manipulation
- `jsonlite` - JSON parsing and generation

#### Starting R Backend

**Windows:**
\`\`\`cmd
cd r-backend
start-server.bat
\`\`\`

**macOS/Linux:**
\`\`\`bash
cd r-backend
chmod +x start-server.sh
./start-server.sh
\`\`\`

#### Verifying R Backend

\`\`\`bash
# Test health endpoint
curl http://localhost:8001/health

# Expected response:
{
  "status": "healthy",
  "backend": "R + data.table",
  "version": "R version 4.x.x",
  "packages": {
    "plumber": "1.x.x",
    "data.table": "1.x.x",
    "jsonlite": "1.x.x"
  }
}
\`\`\`

### Usage

#### Quick Start
1. Visit the application homepage
2. Navigate to any volcano plot implementation:
   - **Client-side**: `/plots/volcano`
   - **Server-side**: `/plots/volcano-server`
   - **FastAPI**: `/plots/volcano-fastapi`
   - **R Backend**: `/plots/volcano-r`
3. Click "Load Example Dataset" to explore with synthetic data
4. Adjust p-value and Log2(FC) thresholds using the controls
5. Compare performance between different implementations

#### Performance Comparison
1. **Load identical datasets** in FastAPI and R implementations
2. **Compare response times** and visual output
3. **Run benchmarks** using the built-in benchmarking tools:
   \`\`\`bash
   cd r-backend
   Rscript quick-benchmark.R
   \`\`\`

#### Upload Your Data
1. Prepare a CSV/TSV file with columns:
   - **Metabolite name** (or "gene")
   - **log2(FC)** (or "logFC") 
   - **p-Value** (or "padj")
   - **ClassyFire Superclass** (optional)
   - **ClassyFire Class** (optional)

2. Upload via the file input or drag-and-drop
3. Review any parsing errors in the alert panel
4. Analyze your results using the interactive tools
5. Compare results between R and Python backends

## 🔧 Troubleshooting

### R Backend Issues

#### R Not Found
\`\`\`bash
# Check R installation
Rscript --version
R --version

# Add R to PATH (Windows)
# Add R installation directory to system PATH

# Reinstall R if needed
# Windows: Download from CRAN
# macOS: brew install r
# Linux: sudo apt install r-base
\`\`\`

#### Package Installation Fails
\`\`\`bash
# Manual package installation
R
> install.packages(c("plumber", "data.table", "jsonlite"))

# On Linux, install development packages
sudo apt install r-base-dev

# Check package installation
R
> library(plumber)
> library(data.table)
> library(jsonlite)
\`\`\`

#### Port Already in Use
\`\`\`bash
# Check what's using port 8001
lsof -Pi :8001 -sTCP:LISTEN  # macOS/Linux
netstat -an | find ":8001"   # Windows

# Use different port
./start-server.sh 8002  # Unix
start-server.bat 8002   # Windows
\`\`\`

#### R Backend Won't Start
\`\`\`bash
# Check R backend logs
cd r-backend
cat r-server.log

# Test R script directly
Rscript plumber-api.R

# Verify dependencies
Rscript validate-setup.R
\`\`\`

#### Performance Issues
\`\`\`bash
# Monitor R backend status
cd r-backend
./server-status.sh  # Unix
server-status.bat   # Windows

# Check memory usage
curl http://localhost:8001/api/cache-status

# Clear cache if needed
curl -X POST http://localhost:8001/api/clear-cache
\`\`\`

### General Issues

#### Frontend Build Errors
\`\`\`bash
# Clear Next.js cache
rm -rf .next
npm run build

# Check Node.js version
node --version  # Should be 18+
\`\`\`

#### API Connection Issues
\`\`\`bash
# Verify all services are running
curl http://localhost:3000      # Frontend
curl http://localhost:8000/health  # FastAPI
curl http://localhost:8001/health  # R Backend

# Check environment variables
echo $API_INTERNAL_URL
echo $R_API_URL
\`\`\`

#### Docker Issues
\`\`\`bash
# Rebuild containers
docker-compose down -v
docker-compose up -d --build

# Check container logs
docker-compose logs web
docker-compose logs api
\`\`\`

### Performance Benchmarking Issues

#### Benchmark Fails to Run
\`\`\`bash
# Ensure both backends are running
curl http://localhost:8000/health
curl http://localhost:8001/health

# Run health check first
cd r-backend
Rscript quick-benchmark.R health

# Check R dependencies
Rscript -e "library(httr); library(jsonlite)"
\`\`\`

#### Inconsistent Results
\`\`\`bash
# Verify output consistency
cd r-backend
Rscript live-comparison-test.R

# Generate detailed comparison
Rscript compare-outputs.R r_response.json python_response.json

# Check statistical validation
Rscript statistical-validation.R r_data.json python_data.json
\`\`\`

### Getting Help

If you encounter issues not covered here:

1. **Check logs** in `r-backend/` directory
2. **Verify dependencies** with validation scripts
3. **Test individual components** before running full stack
4. **Review error messages** for specific guidance
5. **Check GitHub issues** for known problems

## 🚀 Deployment & Production

This project supports three deployment methods: local Docker development available in "http://localhost:3000/" and automated CI/CD deployment with GCP Cloud Run and Deploy, triggered by GitHub "main" branch new commits,  available in "https://data-viz-sat-mvp-18592493990.europe-west1.run.app/".
Choose the method that best fits your development workflow.

### 🐳 Local Docker Development

Perfect for development and testing the full multi-container setup locally.

#### Quick Start
\`\`\`bash
# Build and start both containers
docker-compose build
docker-compose up -d

# Access the application
# Frontend: http://localhost:3000
# API: http://localhost:8000
\`\`\`

#### Architecture
- **Frontend Container**: Next.js app on port 3000 (mapped from internal 8080)
- **Backend Container**: FastAPI on port 8000 (mapped from internal 9000)
- **Internal Communication**: `API_INTERNAL_URL=http://api:9000`
- **Health Checks**: Automatic container health monitoring
- **Hot Reload**: Code changes reflected immediately

#### Useful Commands
\`\`\`bash
# View logs
docker-compose logs web    # Frontend logs
docker-compose logs api    # Backend logs
docker-compose logs -f     # Follow all logs

# Restart services
docker-compose restart web
docker-compose restart api

# Clean rebuild
docker-compose down -v
docker-compose up -d --build

# Container shell access
docker-compose exec web sh
docker-compose exec api bash
\`\`\`


### ☁️ Google Cloud Run Multi-Container Deployment

The repository includes an automated GitHub trigger that builds and deploys on every push to `main`.

**Setup (One-time)**
1. **Fork/Clone the repository** to your GitHub account
2. **Connect to Google Cloud Build**:
   - Go to [Google Cloud Build Triggers](https://console.cloud.google.com/cloud-build/triggers)
   - Click "Connect Repository" and select your GitHub repo
   - Create trigger with these settings:
     - **Name**: `data-viz-satellite-multi-container`
     - **Event**: Push to branch `^main$`
     - **Configuration**: Autodetected (uses `cloudbuild.yaml`)
     - **Region**: `europe-west1`

3. **Configure project settings** in `cloudbuild.yaml` and `service.yaml`:
   \`\`\`bash
   # Update project ID in service.yaml
   sed -i 's/data-viz-satellite-mvp/YOUR-PROJECT-ID/g' service.yaml
   sed -i 's/data-viz-satellite-mvp/YOUR-PROJECT-ID/g' cloudbuild.yaml
   \`\`\`

**Deployment Process**
\`\`\`bash
# Simply push to main branch
git add .
git commit -m "Deploy to production"
git push origin main

# Monitor build progress
gcloud builds list --limit=5
gcloud builds log BUILD_ID --follow
\`\`\`

**Build Pipeline**
1. **Build API Image**: FastAPI container with Polars optimization
2. **Build Frontend Image**: Next.js production build with multi-stage Docker
3. **Push to Container Registry**: Images stored in Google Container Registry
4. **Deploy Multi-Container Service**: Atomic deployment with zero downtime
5. **Health Checks**: Automatic verification of service health



### 🏗️ Multi-Container Architecture

#### Container Configuration

**Frontend Container (web)**
- **Image**: Next.js 15 production build
- **Port**: 8080 (internal), exposed externally
- **Resources**: 1-2 CPU, 1-2GB RAM
- **Environment**:
  - `API_INTERNAL_URL=http://127.0.0.1:9000`
  - `NODE_ENV=production`
  - `PORT=8080`

**Backend Container (api)**
- **Image**: FastAPI with Polars and scientific libraries
- **Port**: 9000 (internal only)
- **Resources**: 1-2 CPU, 2-4GB RAM (optimized for data processing)
- **Environment**:
  - `FRONTEND_URL=http://127.0.0.1:8080`
  - `PORT=9000`
- **Health Checks**: `/health` endpoint with startup/liveness probes

#### Service Configuration
\`\`\`yaml
# Key service.yaml settings
spec:
  template:
    metadata:
      annotations:
        run.googleapis.com/execution-environment: gen2
        autoscaling.knative.dev/maxScale: "10"
    spec:
      containerConcurrency: 80
      timeoutSeconds: 300
\`\`\`

#### Benefits of This Architecture

✅ **Technology Optimization**: Next.js for UI, FastAPI+Polars for data processing  
✅ **Independent Scaling**: Scale frontend and backend based on different load patterns  
✅ **Resource Efficiency**: Each container gets resources tailored to its workload  
✅ **Fault Isolation**: Issues in one container don't affect the other  
✅ **Development Flexibility**: Teams can work on frontend and backend independently  
✅ **Cost Optimization**: Pay only for resources each component needs  
✅ **Zero Downtime Deployments**: Atomic deployments with automatic rollback  



#### Common Issues & Solutions

**Build Failures**
\`\`\`bash
# Check build logs
gcloud builds list --limit=5
gcloud builds log BUILD_ID

# Common fixes:
# - Verify Dockerfile paths in cloudbuild.yaml
# - Check for syntax errors in service.yaml
# - Ensure all required files are committed to git
\`\`\`

**Deployment Issues**
\`\`\`bash
# Check service deployment status
gcloud run services describe data-viz-satellite --region=europe-west1

# Common fixes:
# - Verify container images exist in registry
# - Check environment variables in service.yaml
# - Ensure proper IAM permissions for Cloud Run
\`\`\`

**Runtime Errors**
\`\`\`bash
# Check container logs
gcloud logging read "resource.type=cloud_run_revision" --limit=50

# Common fixes:
# - Verify API_INTERNAL_URL points to correct internal port
# - Check that both containers are healthy
# - Ensure proper resource limits (memory for data processing)
\`\`\`

### 📋 Deployment Summary

| Method | Use Case | Setup Time | Automation | Best For |
|--------|----------|------------|------------|----------|
| **🐳 Local Docker** | Development & Testing | 5 minutes | Manual | Local development, debugging |
| **🤖 Automated CI/CD** | Production | 10 minutes setup | Full automation | Production deployments, team collaboration |

**Live Application**: https://data-viz-sat-mvp-18592493990.europe-west1.run.app/


### Environment Configuration

#### Environment Variables

For local development:
\`\`\`bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
\`\`\`

For Cloud Run deployment (automatically set in service.yaml):
\`\`\`bash
# Frontend container
NEXT_PUBLIC_API_URL=http://127.0.0.1:9000
PORT=8080

# API container  
FRONTEND_URL=http://127.0.0.1:8080
PORT=9000
\`\`\`

## 📊 Data Format Requirements

### Expected CSV Structure
\`\`\`csv
Metabolite name,log2(FC),p-Value,ClassyFire Superclass,ClassyFire Class
Methionine,2.34,0.001,Organic acids and derivatives,Carboxylic acids and derivatives
Tryptophan,-1.87,0.023,Organoheterocyclic compounds,Indoles and derivatives
\`\`\`

### Supported Column Names
- **Metabolite**: "Metabolite name", "gene", "Gene"
- **Fold Change**: "log2(FC)", "logFC", "Log2FC"
- **P-value**: "p-Value", "pvalue", "padj", "FDR"
- **Classification**: "ClassyFire Superclass", "ClassyFire Class"

## 🚀 FastAPI + Polars Backend

### API Endpoints

#### GET `/api/volcano-data`
High-performance volcano plot data with server-side filtering and intelligent caching.

**Query Parameters:**
- `p_value_threshold` (float): P-value threshold (0.0-1.0, default: 0.05)
- `log_fc_min` (float): Minimum log2FC (-10.0-10.0, default: -0.5)
- `log_fc_max` (float): Maximum log2FC (-10.0-10.0, default: 0.5)
- `search_term` (string, optional): Search term for metabolite names
- `dataset_size` (int): Number of synthetic data points (100-10000000, default: 10000)
- `max_points` (int): Maximum points in response (1000-100000, default: 20000)

#### POST `/api/warm-cache`
Pre-generate and cache multiple dataset sizes for instant loading.

**Request Body:**
```json
[10000, 50000, 100000, 500000, 1000000, 5000000]
```

**Response:**
```json
{
  "message": "Cache warmed successfully",
  "cached_sizes": [10000, 50000, 100000, 500000, 1000000, 5000000],
  "total_cached": 6
}
```

#### GET `/api/cache-status`
Get current cache status and available cached datasets.

**Response:**
```json
{
  "cached_datasets": [10000, 100000, 500000],
  "total_cached": 3
}
```

**Example Request:**
\`\`\`bash
curl "http://localhost:8000/api/volcano-data?p_value_threshold=0.05&log_fc_min=-0.5&log_fc_max=0.5&search_term=methionine&dataset_size=10000"
\`\`\`

**Response Format:**
\`\`\`json
{
  "data": [
    {
      "gene": "Methionine",
      "logFC": 2.34,
      "padj": 0.001,
      "classyfireSuperclass": "Organic acids and derivatives",
      "classyfireClass": "Carboxylic acids and derivatives",
      "category": "up"
    }
  ],
  "stats": {
    "up_regulated": 150,
    "down_regulated": 120,
    "non_significant": 9730
  },
  "total_rows": 10000,
  "filtered_rows": 10000
}
\`\`\`

### Performance Benefits & User Experience

#### Performance Optimizations
- **Polars Processing**: 10x faster than pandas for large datasets
- **Vectorized Data Generation**: NumPy-based operations for 10x faster synthetic data creation
- **Intelligent Caching**: LRU cache system stores datasets in memory for instant subsequent access
- **Smart Response Sampling**: Limits responses to 20K points while prioritizing significant data
- **Memory Efficient**: Optimized for 100K+ to 10M+ data points
- **Lazy Evaluation**: Efficient query planning and execution
- **Parallel Processing**: Multi-threaded operations

#### User Experience Features
- **Loading State Indicators**: Clear distinction between "Generating Dataset" vs "Loading Cached Data"
- **Cache Warming**: Pre-generate common dataset sizes (10K, 50K, 100K, 500K, 1M, 5M) with one click
- **Progress Feedback**: Real-time status updates during data processing
- **Performance Transparency**: Users know when data is being generated vs retrieved from cache
- **Instant Dataset Switching**: Cached datasets load 20-30% faster than first-time generation

### API Documentation
Visit [http://localhost:8000/docs](http://localhost:8000/docs) for interactive API documentation.

## 🔧 Configuration

### Environment Variables

\`\`\`bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:8000
\`\`\`

### Customization
- **Themes**: Modify `app/globals.css` for custom color schemes
- **Data Schema**: Update `lib/schema.ts` for different data formats
- **Plot Settings**: Customize visualization in component files
- **API Configuration**: Modify `api/main.py` for custom data processing logic

## 📈 Performance Comparison & Optimization

### Architecture Performance Matrix

| Feature | Client-Side | Next.js Server | FastAPI + Polars |
|---------|-------------|----------------|------------------|
| **Best Dataset Size** | < 10K rows | 10K - 50K rows | 50K+ rows |
| **Processing Speed** | ⚡ Fast | ⚡⚡ Good | ⚡⚡⚡ Excellent |
| **Memory Efficiency** | 📈 Limited | 📊 Moderate | 📉 Optimized |
| **Server-Side Filtering** | ❌ No | ✅ Basic | ✅✅ Advanced |
| **Scalability** | 🔴 Browser limited | 🟡 Node.js limited | 🟢 Production ready |
| **Setup Complexity** | 🟢 Simple | 🟡 Moderate | 🟠 Advanced |
| **Dependencies** | None | Node.js | Python + FastAPI |

### Performance Benchmarks

| Dataset Size | Client-Side | Next.js Server | FastAPI + Polars (First Load) | FastAPI + Polars (Cached) | Memory Usage |
|--------------|-------------|----------------|-------------------------------|---------------------------|--------------|
| 1K rows      | ~200ms     | ~150ms         | ~300ms                       | ~200ms                    | ~2MB         |
| 10K rows     | ~800ms     | ~300ms         | ~800ms                       | ~400ms                    | ~10MB        |
| 50K rows     | ~3s        | ~800ms         | ~2s                          | ~1.5s                     | ~25MB        |
| 100K rows    | ❌ Crashes  | ~2s           | ~4.5s                        | ~3.2s                     | ~50MB        |
| 500K rows    | ❌ N/A      | ❌ Timeout     | ~3s                          | ~2.8s                     | ~150MB       |
| 1M rows      | ❌ N/A      | ❌ N/A         | ~5s                          | ~4s                       | ~300MB       |

**Key Performance Improvements:**
- **500K Dataset**: Reduced from 15+ seconds to 3 seconds (5x improvement)
- **Intelligent Caching**: Subsequent requests with same dataset size are 20-30% faster
- **Data Generation Optimization**: Vectorized operations using NumPy for 10x faster synthetic data creation
- **Response Optimization**: Smart sampling limits responses to 20K points while maintaining statistical significance

### When to Use Each Architecture

#### 🎯 **Client-Side** - Choose when:
- Prototyping or demos
- Small datasets (< 10K rows)
- Offline functionality needed
- Simple deployment requirements
- No server infrastructure available

#### 🎯 **Next.js Server** - Choose when:
- Medium datasets (10K - 50K rows)
- Integrated with existing Next.js app
- Moderate performance requirements
- Single deployment stack preferred

#### 🎯 **FastAPI + Polars** - Choose when:
- Large datasets (50K+ rows)
- Performance is critical
- Production environment
- Scientific computing workloads
- Need advanced data processing features
- Horizontal scaling required

### Optimization Strategies
- **Data Chunking**: Large datasets processed in batches
- **Virtual Scrolling**: Efficient rendering of large tables
- **Memoization**: Cached calculations for repeated operations
- **WebGL Acceleration**: Hardware-accelerated plotting with Plotly.js scattergl
  - Handles 100K+ omics features with smooth interactions
  - GPU-accelerated rendering for real-time zooming and panning
  - Memory-efficient point management for large multi-omics datasets
  - Optimized for genomics, transcriptomics, proteomics, and metabolomics data

## 🔧 Advanced Configuration

### Custom Themes
\`\`\`css
/* app/globals.css - Custom CSS variables */
:root {
  --volcano-background: hsl(0 0% 100%);
  --volcano-text: hsl(222.2 84% 4.9%);
  --volcano-grid: hsl(210 40% 92%);
  --volcano-neutral: hsl(215.4 16.3% 46.9%);
}
\`\`\`

### Data Schema Customization
\`\`\`typescript
// lib/schema.ts - Extend the data schema
export const CustomDegRowSchema = DegRowSchema.extend({
  pathway: z.string().optional(),
  keggId: z.string().optional(),
  hmdbId: z.string().optional()
})
\`\`\`

### Plot Customization
\`\`\`typescript
// Custom plot configuration
const customPlotConfig = {
  displayModeBar: true,
  modeBarButtonsToRemove: ['pan2d', 'lasso2d'],
  toImageButtonOptions: {
    format: 'png',
    filename: 'custom_volcano_plot',
    height: 800,
    width: 1200,
    scale: 2
  }
}
\`\`\`

## 🐛 Troubleshooting

### Common Issues

#### Development Server Issues
**Problem**: `npm run dev:full` fails with "system cannot find the file specified"
**Solution**: This is a Windows-specific issue with npm command detection. The script has been fixed to handle Windows properly. If issues persist, run servers individually:
```bash
npm run dev:api    # Terminal 1: FastAPI server
npm run dev        # Terminal 2: Next.js server
```

#### Large Dataset Performance
**Problem**: Slow rendering with large datasets
**Solution**: Use server-side processing or implement data pagination

#### CSV Parsing Errors
**Problem**: "Invalid data format" errors
**Solution**: Check column names match expected format or use column mapping

#### Memory Issues
**Problem**: Browser crashes with large datasets
**Solution**: Reduce dataset size or use server-side processing

#### Plot Not Rendering
**Problem**: Blank plot area
**Solution**: Check browser console for JavaScript errors, ensure Plotly.js loaded

### Debug Mode
\`\`\`bash
# Enable debug logging
DEBUG=volcano-plot:* npm run dev
\`\`\`

### Browser Compatibility
- **Chrome/Edge**: Full support for all features
- **Firefox**: Full support with minor performance differences
- **Safari**: Supported with WebGL limitations on older versions
- **Mobile**: Limited support - desktop/tablet recommended

## 🙏 Acknowledgments

- **ClassyFire**: Chemical classification system
- **Plotly.js**: Interactive visualization library
- **shadcn/ui**: Beautiful component library

### Technologies & Libraries
- **[Next.js](https://nextjs.org/)**: The React framework for production
- **[Plotly.js](https://plotly.com/javascript/)**: Interactive visualization library
- **[shadcn/ui](https://ui.shadcn.com/)**: Beautiful and accessible component library
- **[Tailwind CSS](https://tailwindcss.com/)**: Utility-first CSS framework
- **[Papa Parse](https://www.papaparse.com/)**: Powerful CSV parsing library
- **[Zod](https://zod.dev/)**: TypeScript-first schema validation

### Development Tools
- **[Vercel](https://vercel.com/)**: Deployment and hosting platform
- **[Lucide React](https://lucide.dev/)**: Beautiful icon library

---

**Built with ❤️ by Sequentia**

*This project demonstrates modern web development practices for scientific data visualization, combining performance, accessibility, and user experience.*
