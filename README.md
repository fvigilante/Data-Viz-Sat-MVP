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
- **Three-Tier Architecture**: Client-side, Next.js server-side, and FastAPI + Polars high-performance processing
- **Manual Level-of-Detail (LOD) Controls**: User-selectable downsampling levels (10K/20K/50K/100K points)
- **Intelligent Downsampling**: Significance-aware sampling that prioritizes biologically relevant data
- **Real-time Filtering**: Adjustable p-value thresholds and log2(FC) ranges with live updates
- **Server-Side Filtering**: All filtering operations (p-value, log2FC, search) handled by backend APIs
- **High-Performance Backend**: FastAPI + Polars for processing 10M+ data points with intelligent caching
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
│   │   ├── heatmap/            # Heatmap visualization (future implementation)
│   │   └── pca/                # PCA visualization (future implementation)
│   └── api/                     # Next.js API routes
│       └── volcano-data/        # Server-side data processing endpoint
│           └── route.ts         # GET endpoint for processed volcano data
├── api/                         # FastAPI Backend
│   ├── main.py                  # FastAPI application with Polars data processing
│   ├── requirements.txt         # Python dependencies
│   ├── Dockerfile              # Docker configuration for API
│   └── README.md               # API documentation
├── components/                   # React components library
│   ├── VolcanoPlot.tsx         # Client-side interactive volcano plot component
│   ├── ServerVolcanoPlot.tsx   # Server-side volcano plot component
│   ├── FastAPIVolcanoPlot.tsx  # FastAPI + Polars volcano plot component
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

### Three-Tier Data Processing Architecture

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

### ClassyFire Integration
The application integrates metabolite classification data:
- **Superclass**: High-level chemical classification
- **Class**: More specific chemical grouping
- **Biological Context**: Helps researchers understand metabolic pathways

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
- **Node.js 18+**: Required for Next.js 15 and modern JavaScript features
- **Package Manager**: npm (included with Node.js), yarn, or pnpm
- **Modern Browser**: Chrome 90+, Firefox 88+, Safari 14+, or Edge 90+

### Installation

#### Option 1: Full Stack Development (Recommended)

1. **Clone the repository**
   \`\`\`bash
   git clone https://github.com/fvigilante/Data-Viz-Sat-MVP.git
   cd Data-Viz-Sat-MVP
   \`\`\`

2. **Install frontend dependencies**
   \`\`\`bash
   npm install
   \`\`\`

3. **Install Python dependencies for FastAPI**
   \`\`\`bash
   cd api
   pip install -r requirements.txt
   cd ..
   \`\`\`

4. **Run both servers concurrently**
   \`\`\`bash
   # Recommended: Single command to start both servers
   npm run dev:full
   
   # Alternative: Run servers individually
   npm run dev:api    # FastAPI server on port 8000
   npm run dev        # Next.js server on port 3000
   
   # Alternative: Use shell script (Linux/Mac)
   chmod +x scripts/dev.sh && ./scripts/dev.sh
   \`\`\`

5. **Access the applications**
   - **Frontend**: [http://localhost:3000](http://localhost:3000)
   - **API**: [http://localhost:8000](http://localhost:8000)
   - **API Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)

#### Option 2: Frontend Only

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

#### Option 3: Docker Development

1. **Build and run with Docker Compose**
   \`\`\`bash
   docker-compose up --build
   \`\`\`

2. **Access the applications**
   - **Frontend**: [http://localhost:3000](http://localhost:3000)
   - **API**: [http://localhost:8000](http://localhost:8000)

### Build for Production

\`\`\`bash
# Build the application
npm run build

# Start the production server
npm run start
\`\`\`

### Usage

#### Quick Start
1. Visit the application homepage
2. Click "Load Example Dataset" to explore with synthetic data
3. Adjust p-value and Log2(FC) thresholds using the controls
4. Explore the interactive plot and data tables

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

## 🚀 Deployment & Production

This project supports three deployment methods: local Docker development, manual Google Cloud deployment, and automated CI/CD deployment. Choose the method that best fits your development workflow.

### 🐳 Local Docker Development

Perfect for development and testing the full multi-container setup locally.

#### Quick Start
\`\`\`bash
# Build and start both containers
docker-compose build
docker-compose up -d

# Run comprehensive tests
./test-local-docker.ps1

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

See [README-Docker-Local.md](README-Docker-Local.md) for detailed local development guide.

### ☁️ Google Cloud Run Multi-Container Deployment

#### Method 1: Automated CI/CD Deployment (Recommended)

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

#### Method 2: Manual Deployment

For direct control over the deployment process.

**Prerequisites**
\`\`\`bash
# Install Google Cloud SDK
# https://cloud.google.com/sdk/docs/install

# Authenticate and set project
gcloud auth login
gcloud config set project YOUR-PROJECT-ID
gcloud config set run/region europe-west1
\`\`\`

**One-Command Deployment**
\`\`\`bash
# Use the automated deployment script
./deploy-and-test.ps1

# Or run individual steps:
gcloud builds submit --config cloudbuild.yaml
gcloud run services replace service.yaml --region=europe-west1
\`\`\`

**Manual Step-by-Step**
\`\`\`bash
# 1. Build and push images
gcloud builds submit --config cloudbuild.yaml

# 2. Deploy the multi-container service
gcloud run services replace service.yaml \
  --region=europe-west1 \
  --platform=managed

# 3. Get service URL
gcloud run services describe data-viz-satellite \
  --region=europe-west1 \
  --format="value(status.url)"
\`\`\`

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

### 🔍 Monitoring & Troubleshooting

#### Service Health Checks
\`\`\`bash
# Check service status
gcloud run services describe data-viz-satellite --region=europe-west1

# View recent logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=data-viz-satellite" --limit=20

# Monitor specific container
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=data-viz-satellite AND labels.container_name=api" --limit=10
\`\`\`

#### Performance Monitoring
- **Cloud Run Metrics**: CPU, memory, request latency in Google Cloud Console
- **Application Logs**: Structured logging for both containers
- **Health Endpoints**: 
  - Frontend: `https://your-service-url/`
  - Backend: `https://your-service-url/api/health` (proxied through frontend)

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

### 🚀 Production Optimization

#### Performance Tuning
- **Container Resources**: Adjust CPU/memory based on usage patterns
- **Concurrency**: Tune `containerConcurrency` for optimal throughput
- **Caching**: Enable Cloud CDN for static assets
- **Database**: Consider Cloud SQL or Firestore for persistent data

#### Security Best Practices
- **IAM**: Use least-privilege service accounts
- **VPC**: Deploy in private VPC for sensitive data
- **Secrets**: Use Secret Manager for API keys and credentials
- **HTTPS**: Automatic SSL/TLS termination with Cloud Run

#### Cost Optimization
- **Auto-scaling**: Configure min/max instances based on traffic
- **Resource Limits**: Right-size CPU and memory allocations
- **Regional Deployment**: Choose regions close to your users
- **Request Timeout**: Optimize timeout settings to prevent resource waste

### 📋 Deployment Summary

| Method | Use Case | Setup Time | Automation | Best For |
|--------|----------|------------|------------|----------|
| **🐳 Local Docker** | Development & Testing | 5 minutes | Manual | Local development, debugging |
| **🤖 Automated CI/CD** | Production | 10 minutes setup | Full automation | Production deployments, team collaboration |
| **⚡ Manual Cloud** | Quick deployment | 2 minutes | Semi-automated | Hotfixes, one-off deployments |

**Live Application**: https://data-viz-satellite-18592493990.europe-west1.run.app

### Alternative Deployment Options

#### Vercel (Frontend Only)
\`\`\`bash
# Install Vercel CLI
npm i -g vercel

# Deploy to Vercel
vercel

# Production deployment
vercel --prod
\`\`\`

#### Docker Compose (Development)
\`\`\`bash
# Build and run both containers locally
docker-compose up --build

# Access the application
# Frontend: http://localhost:3000
# API: http://localhost:8000
\`\`\`

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

#### Performance Monitoring
- **Vercel Analytics**: Built-in performance monitoring
- **Core Web Vitals**: Optimized for Google's performance metrics
- **Bundle Analysis**: Use `npm run analyze` to inspect bundle size

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

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **ClassyFire**: Chemical classification system
- **Plotly.js**: Interactive visualization library
- **shadcn/ui**: Beautiful component library
- **Metabolomics Community**: For feedback and requirements

## 📞 Support & Contributing

### Getting Help
For questions, issues, or feature requests:
- **GitHub Issues**: [Open an issue](https://github.com/fvigilante/Data-Viz-Sat-MVP/issues)
- **Documentation**: Check this README for common solutions
- **Discussions**: Use GitHub Discussions for questions and ideas

### Contributing Guidelines
1. **Fork the repository** and create a feature branch
2. **Follow TypeScript best practices** and maintain type safety
3. **Add tests** for new functionality when applicable
4. **Update documentation** for any API or feature changes
5. **Submit a Pull Request** with a clear description

### Development Workflow
\`\`\`bash
# Create feature branch
git checkout -b feature/amazing-feature

# Make your changes
npm run dev

# Test your changes
npm run build
npm run lint

# Commit and push
git commit -m 'Add amazing feature'
git push origin feature/amazing-feature
\`\`\`

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

### Technologies & Libraries
- **[Next.js](https://nextjs.org/)**: The React framework for production
- **[Plotly.js](https://plotly.com/javascript/)**: Interactive visualization library
- **[shadcn/ui](https://ui.shadcn.com/)**: Beautiful and accessible component library
- **[Tailwind CSS](https://tailwindcss.com/)**: Utility-first CSS framework
- **[Papa Parse](https://www.papaparse.com/)**: Powerful CSV parsing library
- **[Zod](https://zod.dev/)**: TypeScript-first schema validation

### Scientific Resources
- **[ClassyFire](http://classyfire.wishartlab.com/)**: Chemical classification system
- **[HMDB](https://hmdb.ca/)**: Human Metabolome Database
- **[KEGG](https://www.kegg.jp/)**: Kyoto Encyclopedia of Genes and Genomes

### Development Tools
- **[Vercel](https://vercel.com/)**: Deployment and hosting platform
- **[Geist Font](https://vercel.com/font)**: Modern typography system
- **[Lucide React](https://lucide.dev/)**: Beautiful icon library

---

**Built with ❤️ by Sequentia**

*This project demonstrates modern web development practices for scientific data visualization, combining performance, accessibility, and user experience.*
