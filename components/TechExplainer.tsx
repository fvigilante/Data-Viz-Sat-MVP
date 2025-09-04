"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { Badge } from "@/components/ui/badge"
import { Monitor, Server, Zap, Database, Globe, Cpu } from "lucide-react"

interface TechExplainerProps {
  type: "client" | "server" | "fastapi" | "pca"
}

export default function TechExplainer({ type }: TechExplainerProps) {
  const configs = {
    client: {
      title: "Client-Side Processing Architecture",
      icon: <Monitor className="h-5 w-5" />,
      badge: { text: "Browser", color: "bg-blue-500" },
      description: "All data processing happens in your browser using JavaScript",
      sections: [
        {
          title: "🔄 Data Flow",
          content: `
**User Upload → Browser Processing → Real-time Visualization**

1. **File Upload**: CSV/TSV files are read directly in the browser
2. **Papa Parse**: High-performance CSV parsing library processes the data
3. **Zod Validation**: Runtime type checking ensures data integrity
4. **React State**: Data stored in browser memory for instant access
5. **Plotly.js**: WebGL-accelerated rendering for smooth interactions
          `
        },
        {
          title: "⚡ Performance Characteristics",
          content: `
**Best for**: Small to medium datasets (up to 50K points)

**Advantages:**
- ⚡ **Instant Response**: No network requests after initial load
- 🔒 **Privacy**: Your data never leaves your browser
- 📱 **Offline Capable**: Works without internet connection
- 💰 **Cost Effective**: No server processing costs

**Limitations:**
- 💾 **Memory Bound**: Limited by browser RAM (typically 2-4GB)
- 🐌 **Large Data**: Performance degrades with 100K+ points
- 🔄 **No Caching**: Data regenerated on each page refresh
          `
        },
        {
          title: "🛠️ Technology Stack",
          content: `
**Frontend Technologies:**
- **React 19**: Latest React with concurrent features
- **TypeScript**: Full type safety and IntelliSense
- **Papa Parse**: Fast CSV/TSV parsing (up to 1GB/s)
- **Zod**: Runtime schema validation
- **Plotly.js**: Interactive plotting with WebGL acceleration
- **Tailwind CSS**: Utility-first styling

**Data Processing:**
- **JavaScript Arrays**: Native browser data structures
- **Web Workers**: Background processing (future enhancement)
- **IndexedDB**: Browser storage for large datasets (future)
          `
        },
        {
          title: "🎯 Use Cases",
          content: `
**Perfect for:**
- 📊 **Quick Analysis**: Rapid data exploration and prototyping
- 🔒 **Sensitive Data**: When data cannot leave your organization
- 📱 **Demos**: Presentations and proof-of-concepts
- 🎓 **Education**: Learning data visualization concepts
- 🏠 **Personal Use**: Individual research and analysis

**Example Scenarios:**
- Pilot studies with <10K metabolites
- Conference presentations
- Educational workshops
- Personal research projects
          `
        }
      ]
    },
    server: {
      title: "Server-Side Processing Architecture",
      icon: <Server className="h-5 w-5" />,
      badge: { text: "Next.js API", color: "bg-green-500" },
      description: "Data processing happens on the Next.js server with API routes",
      sections: [
        {
          title: "🔄 Data Flow",
          content: `
**User Request → Next.js API → Server Processing → JSON Response → Client Rendering**

1. **API Request**: Client sends parameters to Next.js API route
2. **Server Processing**: Node.js processes data on the server
3. **Papa Parse**: CSV parsing happens server-side
4. **Data Transformation**: Column mapping and validation
5. **JSON Response**: Processed data sent to client
6. **Client Rendering**: Plotly.js renders the visualization
          `
        },
        {
          title: "⚡ Performance Characteristics",
          content: `
**Best for**: Medium to large datasets (10K-100K points)

**Advantages:**
- 🚀 **Scalable**: Server resources can be increased
- 💾 **Memory Efficient**: Client only stores final results
- 🔄 **Cacheable**: API responses can be cached
- 📊 **Preprocessing**: Complex calculations on server

**Limitations:**
- 🌐 **Network Dependent**: Requires internet connection
- ⏱️ **Latency**: Network round-trip for each request
- 💰 **Server Costs**: Requires server infrastructure
- 🔒 **Data Transfer**: Data sent over network
          `
        },
        {
          title: "🛠️ Technology Stack",
          content: `
**Backend Technologies:**
- **Next.js 15**: Full-stack React framework
- **Node.js**: JavaScript runtime for server processing
- **API Routes**: Built-in API endpoints
- **Papa Parse**: Server-side CSV processing
- **TypeScript**: End-to-end type safety

**Infrastructure:**
- **Vercel**: Serverless deployment platform
- **Edge Functions**: Global distribution
- **Automatic Scaling**: Handles traffic spikes
- **CDN**: Fast static asset delivery

**Data Processing:**
- **JavaScript V8**: High-performance engine
- **Streaming**: Large file processing
- **Memory Management**: Automatic garbage collection
          `
        },
        {
          title: "🎯 Use Cases",
          content: `
**Perfect for:**
- 🏢 **Enterprise**: Integrated with existing systems
- 🔄 **Shared Analysis**: Multiple users accessing same data
- 📈 **Medium Scale**: 10K-100K data points
- 🌐 **Web Apps**: Browser-based applications
- 🔗 **API Integration**: Part of larger data pipeline

**Example Scenarios:**
- Company-wide metabolomics platform
- Shared research datasets
- Integration with LIMS systems
- Multi-user analysis platform
          `
        }
      ]
    },
    fastapi: {
      title: "FastAPI + Polars High-Performance Architecture",
      icon: <Zap className="h-5 w-5" />,
      badge: { text: "FastAPI + Polars", color: "bg-purple-500" },
      description: "Dedicated Python backend optimized for large-scale scientific data processing",
      sections: [
        {
          title: "🔄 Data Flow",
          content: `
**Client Request → FastAPI → Polars Processing → Intelligent Caching → JSON Response**

1. **FastAPI Endpoint**: High-performance Python API receives requests
2. **Polars DataFrames**: Lightning-fast data manipulation (10x faster than pandas)
3. **Vectorized Operations**: NumPy-based calculations for maximum speed
4. **Intelligent Caching**: LRU cache stores processed datasets in memory
5. **Smart Sampling**: Significance-aware downsampling preserves important data
6. **Streaming Response**: Efficient data transfer to client
          `
        },
        {
          title: "⚡ Performance Characteristics",
          content: `
**Best for**: Large to massive datasets (100K-10M+ points)

**Advantages:**
- 🚀 **Blazing Fast**: Polars is 10-100x faster than pandas
- 💾 **Memory Efficient**: Lazy evaluation and columnar storage
- 🧠 **Intelligent Caching**: Instant access to processed datasets
- 📊 **Scientific Computing**: Optimized for omics data
- 🔄 **Streaming**: Handles datasets larger than RAM
- ⚡ **Parallel Processing**: Multi-core CPU utilization

**Performance Benchmarks:**
- 1M points: ~2 seconds processing
- 10M points: ~15 seconds processing
- Cached datasets: <100ms response time
          `
        },
        {
          title: "🛠️ Technology Stack",
          content: `
**Backend Technologies:**
- **FastAPI**: Modern, fast web framework for APIs
- **Polars**: Lightning-fast DataFrame library (Rust-based)
- **Pydantic**: Data validation and serialization
- **NumPy**: Vectorized numerical computing
- **Uvicorn**: ASGI server for production deployment

**Scientific Computing:**
- **Rust Engine**: Polars core written in Rust for maximum performance
- **Apache Arrow**: Columnar memory format
- **SIMD Instructions**: CPU-level optimizations
- **Lazy Evaluation**: Query optimization

**Infrastructure:**
- **Docker**: Containerized deployment
- **Google Cloud Run**: Serverless scaling
- **Multi-container**: Separate frontend/backend scaling
- **Health Checks**: Production monitoring
          `
        },
        {
          title: "🎯 Use Cases",
          content: `
**Perfect for:**
- 🧬 **Omics Research**: Genomics, transcriptomics, proteomics, metabolomics
- 📊 **Big Data**: Datasets with millions of data points
- 🏭 **Production Systems**: High-throughput analysis pipelines
- 🔬 **Scientific Computing**: Research institutions and pharma
- ⚡ **Performance Critical**: When speed is essential

**Example Scenarios:**
- Whole-genome association studies (GWAS)
- Large-scale metabolomics studies
- Multi-omics integration platforms
- High-throughput screening analysis
- Population-scale biomarker discovery

**Real-world Performance:**
- Process 10M metabolite measurements in <30 seconds
- Handle 100+ concurrent users
- Scale to petabyte-scale datasets
          `
        }
      ]
    },
    pca: {
      title: "PCA Analysis with Dynamic Tables",
      icon: <Database className="h-5 w-5" />,
      badge: { text: "PCA + Tables", color: "bg-indigo-500" },
      description: "Principal Component Analysis with interactive group management and data tables",
      sections: [
        {
          title: "🔄 Data Flow & Architecture",
          content: `
**FastAPI Backend → PCA Computation → 3D Visualization → Dynamic Tables**

1. **Data Generation**: Synthetic multi-omics datasets with realistic group separation
2. **PCA Computation**: scikit-learn Principal Component Analysis
3. **3D Visualization**: Interactive Plotly.js 3D scatter plots
4. **Group Management**: Toggle visibility of experimental groups
5. **Dynamic Tables**: Automatically generated tables for each visible group
6. **Export Options**: Individual CSV downloads per group
          `
        },
        {
          title: "⚡ Performance & Features",
          content: `
**Advanced PCA Features:**

**Performance Optimizations:**
- ⚡ **Intelligent Caching**: Pre-computed PCA results stored in memory
- 🎛️ **Performance Limits**: Safety controls prevent system crashes
- 📊 **Smart Sampling**: Maintains group proportions in large datasets
- 🔄 **Real-time Updates**: Instant group visibility changes

**Interactive Features:**
- 🎨 **Color Coordination**: Consistent colors between plot and tables
- 📋 **Dynamic Tables**: One table per selected group
- 📥 **Individual Downloads**: CSV export for each group separately
- 🎯 **Group Selection**: Show/hide groups with visual feedback
          `
        },
        {
          title: "🛠️ Technology Stack",
          content: `
**Scientific Computing:**
- **scikit-learn**: Industry-standard PCA implementation
- **NumPy**: Vectorized mathematical operations
- **StandardScaler**: Feature normalization for PCA
- **make_blobs**: Realistic synthetic data generation

**Visualization:**
- **Plotly.js 3D**: Hardware-accelerated 3D scatter plots
- **WebGL Rendering**: Smooth interaction with large datasets
- **Dynamic Filtering**: Real-time plot updates
- **Interactive Legend**: Group visibility controls

**Data Management:**
- **Group-based Organization**: Automatic data grouping
- **Proportional Sampling**: Maintains statistical validity
- **Memory Optimization**: Efficient handling of large datasets
- **Cache Management**: Manual cache clearing for memory control
          `
        },
        {
          title: "🎯 Use Cases & Applications",
          content: `
**Perfect for:**
- 🧬 **Multi-omics Analysis**: Genomics, transcriptomics, proteomics integration
- 🔬 **Experimental Design**: Comparing treatment groups
- 📊 **Dimensionality Reduction**: Visualizing high-dimensional data
- 🎯 **Biomarker Discovery**: Identifying group-specific patterns
- 📈 **Quality Control**: Detecting batch effects and outliers

**Research Applications:**
- **Clinical Studies**: Patient vs control comparisons
- **Drug Discovery**: Treatment response analysis  
- **Biomarker Research**: Disease state classification
- **Systems Biology**: Pathway analysis and integration
- **Pharmacogenomics**: Drug response prediction

**Data Exploration:**
- Visualize up to 2000 features safely
- Handle multiple experimental groups (2-5)
- Export group-specific data for further analysis
- Interactive exploration of PC space
          `
        }
      ]
    }
  }

  const config = configs[type]

  return (
    <Card className="mt-6 border-l-4 border-l-blue-500">
      <CardContent className="p-6">
        <div className="flex items-center gap-3 mb-4">
          {config.icon}
          <h3 className="text-lg font-semibold">{config.title}</h3>
          <Badge className={`${config.badge.color} text-white`}>
            {config.badge.text}
          </Badge>
        </div>
        
        <p className="text-sm text-muted-foreground mb-4">
          {config.description}
        </p>

        <Accordion type="single" collapsible className="w-full">
          {config.sections.map((section, index) => (
            <AccordionItem key={index} value={`item-${index}`}>
              <AccordionTrigger className="text-left">
                {section.title}
              </AccordionTrigger>
              <AccordionContent>
                <div className="prose prose-sm max-w-none">
                  {section.content.split('\n').map((line, lineIndex) => {
                    if (line.trim() === '') return <br key={lineIndex} />
                    
                    if (line.startsWith('**') && line.endsWith('**')) {
                      return (
                        <h4 key={lineIndex} className="font-semibold text-sm mt-3 mb-2">
                          {line.slice(2, -2)}
                        </h4>
                      )
                    }
                    
                    if (line.startsWith('- ')) {
                      const parts = line.slice(2).split(': ')
                      if (parts.length === 2) {
                        return (
                          <div key={lineIndex} className="flex gap-2 mb-1">
                            <span className="text-xs">{parts[0]}:</span>
                            <span className="text-xs text-muted-foreground">{parts[1]}</span>
                          </div>
                        )
                      }
                      return (
                        <div key={lineIndex} className="text-xs mb-1">
                          {line}
                        </div>
                      )
                    }
                    
                    return (
                      <p key={lineIndex} className="text-xs text-muted-foreground mb-1">
                        {line}
                      </p>
                    )
                  })}
                </div>
              </AccordionContent>
            </AccordionItem>
          ))}
        </Accordion>
      </CardContent>
    </Card>
  )
}