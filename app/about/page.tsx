import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Github } from "lucide-react"
import Link from "next/link"

export default function AboutPage() {
  return (
    <div className="p-6 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center justify-between">
            <span>About Data Viz Satellite</span>
            <div className="flex gap-2">
              <Button variant="outline" size="sm" asChild>
                <Link href="https://github.com/fvigilante/Data-Viz-Sat-MVP" target="_blank" rel="noopener noreferrer">
                  <Github className="h-4 w-4 mr-2" />
                  GitHub
                </Link>
              </Button>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent className="prose prose-slate max-w-none">
          <p>
            Data Viz Satellite is a pilot microservice developed by Sequentia Biotech's IT team to evaluate modern
            web technologies for multi-omics data visualization. This satellite application is designed to integrate
            with Sequentia Hub as an independent service within our Kubernetes-based microservices architecture,
            providing enhanced data exploration capabilities for various omics datasets.
          </p>

          <div className="not-prose bg-gradient-to-r from-green-50 to-emerald-50 p-6 rounded-lg border border-green-200 mb-6">
            <h3 className="text-lg font-semibold text-green-900 mb-2">🏢 Sequentia Biotech IT Pilot</h3>
            <p className="text-green-800 text-sm">
              This pilot project evaluates Next.js 15, React 19, and Plotly.js as the technology stack for building
              scalable data visualization microservices. The goal is to create satellite applications that can be
              launched from Sequentia Hub's results pages, allowing users to explore multi-omics data (genomics,
              transcriptomics, proteomics, metabolomics) with advanced interactive visualizations.
            </p>
          </div>

          <h3>🏗️ Architecture Overview</h3>
          <div className="not-prose mb-4 flex gap-2 flex-wrap">
            <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
              Next.js 15 App Router
            </Badge>
            <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
              React 19
            </Badge>
            <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
              TypeScript 5
            </Badge>
            <Badge variant="outline" className="bg-amber-50 text-amber-700 border-amber-200">
              Plotly.js + WebGL
            </Badge>
          </div>
          <p>
            The application leverages Next.js 15 App Router with Server-Side Rendering (SSR) for optimal performance,
            SEO benefits, and modern React 19 features. The architecture supports both static generation and dynamic
            server-side processing, providing flexibility for different deployment scenarios and data processing needs.
          </p>

          <div className="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-6">
            <div className="bg-slate-50 p-4 rounded-lg">
              <h4 className="font-semibold text-slate-900 mb-2">🎨 Frontend</h4>
              <ul className="text-sm text-slate-600 space-y-1">
                <li>• React 19 with concurrent features</li>
                <li>• TypeScript for type safety</li>
                <li>• Tailwind CSS + shadcn/ui</li>
                <li>• Responsive design system</li>
              </ul>
            </div>
            <div className="bg-slate-50 p-4 rounded-lg">
              <h4 className="font-semibold text-slate-900 mb-2">� Multi-Omitcs Support</h4>
              <ul className="text-sm text-slate-600 space-y-1">
                <li>• Genomics: SNP analysis, GWAS results</li>
                <li>• Transcriptomics: Gene expression, RNA-seq</li>
                <li>• Proteomics: Protein abundance, PTMs</li>
                <li>• Metabolomics: Metabolite profiling, pathways</li>
              </ul>
            </div>
            <div className="bg-slate-50 p-4 rounded-lg">
              <h4 className="font-semibold text-slate-900 mb-2">🏗️ Microservice Architecture</h4>
              <ul className="text-sm text-slate-600 space-y-1">
                <li>• Kubernetes-ready containerization</li>
                <li>• API-first design for Hub integration</li>
                <li>• Horizontal scaling capabilities</li>
                <li>• Independent deployment pipeline</li>
              </ul>
            </div>
          </div>

          <h3>🌋 Volcano Plot Implementations & 🧬 PCA Analysis</h3>
          <p>
            The application demonstrates three distinct approaches to data processing and visualization, plus advanced
            PCA analysis with dynamic tables, each optimized for different use cases, dataset sizes, and performance requirements.
          </p>

          <div className="not-prose grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-4 gap-4 my-6">
            <div className="border border-green-200 rounded-lg p-4 bg-green-50/50">
              <div className="flex items-center gap-2 mb-3">
                <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
                  /plots/volcano
                </Badge>
                <span className="text-xs font-medium text-blue-800">Client-Side Processing</span>
              </div>

              <h4 className="font-semibold text-blue-900 mb-2 text-sm">⚡ Real-Time Interactivity</h4>
              <ul className="space-y-1 text-xs text-blue-800">
                <li><strong>Data Flow:</strong> Upload → Parse → Validate → Visualize</li>
                <li><strong>Performance:</strong> Optimal for datasets up to 50K points</li>
                <li><strong>Features:</strong> Live filtering, instant updates</li>
                <li><strong>Technology:</strong> Papa Parse + Zod + React state</li>
              </ul>

              <div className="mt-3 p-2 bg-blue-100 rounded text-xs text-blue-700">
                <strong>Best for:</strong> Interactive analysis, real-time exploration
              </div>
            </div>

            <div className="border border-emerald-200 rounded-lg p-4 bg-emerald-50/50">
              <div className="flex items-center gap-2 mb-3">
                <Badge variant="outline" className="bg-emerald-50 text-emerald-700 border-emerald-200">
                  /plots/volcano-server
                </Badge>
                <span className="text-xs font-medium text-green-800">Server-Side Processing</span>
              </div>

              <h4 className="font-semibold text-green-900 mb-2 text-sm">🚀 Scalable Architecture</h4>
              <ul className="space-y-1 text-xs text-green-800">
                <li><strong>Data Flow:</strong> API → Process → Cache → Render</li>
                <li><strong>Performance:</strong> Handles 100K+ points efficiently</li>
                <li><strong>Features:</strong> Server preprocessing, API caching</li>
                <li><strong>Technology:</strong> Next.js API routes + Papa Parse</li>
              </ul>

              <div className="mt-3 p-2 bg-green-100 rounded text-xs text-green-700">
                <strong>Best for:</strong> Large datasets, batch processing
              </div>
            </div>

            <div className="border border-purple-200 rounded-lg p-4 bg-purple-50/50">
              <div className="flex items-center gap-2 mb-3">
                <Badge variant="outline" className="bg-purple-50 text-purple-700 border-purple-200">
                  FastAPI + Polars
                </Badge>
                <span className="text-xs font-medium text-purple-800">High-Performance Backend</span>
              </div>

              <h4 className="font-semibold text-purple-900 mb-2 text-sm">🔥 Maximum Performance + Smart Downsampling</h4>
              <ul className="space-y-1 text-xs text-purple-800">
                <li><strong>Data Flow:</strong> Python API → Polars → Smart Sampling → JSON</li>
                <li><strong>Performance:</strong> Handles 10M+ points with intelligent downsampling</li>
                <li><strong>Features:</strong> Manual LOD controls, significance-aware sampling</li>
                <li><strong>Technology:</strong> FastAPI + Polars + NumPy + Intelligent Caching</li>
              </ul>

              <div className="mt-3 p-2 bg-purple-100 rounded text-xs text-purple-700">
                <strong>Best for:</strong> Massive datasets, production workloads, optimal user experience
              </div>
            </div>

            <div className="border border-indigo-200 rounded-lg p-4 bg-indigo-50/50">
              <div className="flex items-center gap-2 mb-3">
                <Badge variant="outline" className="bg-indigo-50 text-indigo-700 border-indigo-200">
                  /plots/pca
                </Badge>
                <span className="text-xs font-medium text-indigo-800">PCA + Dynamic Tables</span>
              </div>

              <h4 className="font-semibold text-indigo-900 mb-2 text-sm">🧬 Multi-Omics PCA Analysis</h4>
              <ul className="space-y-1 text-xs text-indigo-800">
                <li><strong>Data Flow:</strong> FastAPI → PCA → 3D Plot → Dynamic Tables</li>
                <li><strong>Performance:</strong> Up to 2K features with safety controls</li>
                <li><strong>Features:</strong> Group management, individual exports, cache control</li>
                <li><strong>Technology:</strong> scikit-learn + Plotly 3D + React tables</li>
              </ul>

              <div className="mt-3 p-2 bg-indigo-100 rounded text-xs text-indigo-700">
                <strong>Best for:</strong> Multi-omics research, experimental design, biomarker discovery
              </div>
            </div>
          </div>

          <h3>🎓 Educational & Technical Features</h3>
          <div className="not-prose bg-gradient-to-r from-blue-50 to-indigo-50 p-6 rounded-lg border border-blue-200 mb-6">
            <h4 className="text-lg font-semibold text-blue-900 mb-2">Interactive Technology Explainers</h4>
            <p className="text-blue-800 text-sm mb-3">
              Each visualization page includes detailed accordion sections explaining the technical architecture,
              performance characteristics, and use cases for different processing approaches.
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs">
              <div>
                <strong className="text-blue-900">Architecture Comparisons:</strong>
                <ul className="text-blue-700 mt-1 space-y-1">
                  <li>• Client-side vs Server-side vs FastAPI processing</li>
                  <li>• Performance benchmarks and limitations</li>
                  <li>• Technology stack breakdowns</li>
                  <li>• Real-world use case recommendations</li>
                </ul>
              </div>
              <div>
                <strong className="text-blue-900">Educational Value:</strong>
                <ul className="text-blue-700 mt-1 space-y-1">
                  <li>• Learn modern web development patterns</li>
                  <li>• Understand data processing trade-offs</li>
                  <li>• Explore scientific computing approaches</li>
                  <li>• Best practices for omics visualization</li>
                </ul>
              </div>
            </div>
          </div>

          <h3>✨ Key Features & Capabilities</h3>

          <div className="not-prose grid grid-cols-1 md:grid-cols-2 gap-6 my-6">
            <div>
              <h4 className="font-semibold text-slate-900 mb-3">📊 Visualization Features</h4>
              <ul className="space-y-2 text-sm text-slate-600">
                <li>• Interactive volcano plots with WebGL acceleration (scattergl)</li>
                <li>• Manual Level-of-Detail (LOD) controls with 10K/20K/50K/100K options</li>
                <li>• Intelligent downsampling that prioritizes significant data points</li>
                <li>• Real-time filtering with dual-range sliders</li>
                <li>• Category-based point visibility controls</li>
                <li>• Rich hover tooltips with metabolite details</li>
                <li>• High-resolution PNG export (up to 2x scale)</li>
                <li>• Responsive design for desktop and tablet</li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold text-slate-900 mb-3">🔬 Scientific Tools</h4>
              <ul className="space-y-2 text-sm text-slate-600">
                <li>• ClassyFire metabolite classification integration</li>
                <li>• Statistical significance threshold visualization</li>
                <li>• Biological significance (fold change) boundaries</li>
                <li>• Metabolite search and filtering by name</li>
                <li>• Separate tables for up/down-regulated compounds</li>
                <li>• CSV export of filtered results</li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold text-slate-900 mb-3">🧬 PCA Analysis Tools</h4>
              <ul className="space-y-2 text-sm text-slate-600">
                <li>• 3D interactive PCA visualization with WebGL</li>
                <li>• Dynamic group management and visibility controls</li>
                <li>• Automatic data tables for each experimental group</li>
                <li>• Individual CSV exports per group</li>
                <li>• Performance safety controls (max 2K features)</li>
                <li>• Intelligent caching with manual cache clearing</li>
                <li>• Color-coordinated plot and table interfaces</li>
                <li>• Batch effect simulation for realistic data</li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold text-slate-900 mb-3">📁 Data Handling</h4>
              <ul className="space-y-2 text-sm text-slate-600">
                <li>• Flexible CSV/TSV upload with drag & drop</li>
                <li>• Intelligent column name mapping</li>
                <li>• Comprehensive data validation with Zod</li>
                <li>• Synthetic dataset generation (1K-100K points)</li>
                <li>• Error reporting with user-friendly messages</li>
                <li>• Multiple file format support</li>
              </ul>
            </div>

            <div>
              <h4 className="font-semibold text-slate-900 mb-3">⚡ Performance</h4>
              <ul className="space-y-2 text-sm text-slate-600">
                <li>• Intelligent downsampling preserves biological significance</li>
                <li>• Manual LOD controls prevent zoom interference loops</li>
                <li>• Memoized calculations for smooth interactions</li>
                <li>• Dataset caching for instant switching</li>
                <li>• Code splitting and dynamic imports</li>
                <li>• Optimized bundle size with tree shaking</li>
                <li>• Memory-efficient data structures</li>
                <li>• Progressive loading for large datasets</li>
              </ul>
            </div>
          </div>

          <h3>🛠️ Technology Stack</h3>

          <div className="not-prose grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 my-6">
            <div className="bg-slate-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-slate-900 mb-3">🎯 Core Framework</h4>
              <ul className="space-y-1 text-sm text-slate-600">
                <li>• <strong>Next.js 15</strong> - App Router with RSC</li>
                <li>• <strong>React 19</strong> - Concurrent features</li>
                <li>• <strong>TypeScript 5</strong> - Full type safety</li>
                <li>• <strong>Node.js 18+</strong> - Runtime environment</li>
              </ul>
            </div>

            <div className="bg-slate-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-slate-900 mb-3">🎨 UI & Styling</h4>
              <ul className="space-y-1 text-sm text-slate-600">
                <li>• <strong>Tailwind CSS 3.4</strong> - Utility-first CSS</li>
                <li>• <strong>shadcn/ui</strong> - Component library</li>
                <li>• <strong>Radix UI</strong> - Accessible primitives</li>
                <li>• <strong>Geist Font</strong> - Modern typography</li>
              </ul>
            </div>

            <div className="bg-slate-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-slate-900 mb-3">📊 Data & Visualization</h4>
              <ul className="space-y-1 text-sm text-slate-600">
                <li>• <strong>Plotly.js</strong> - Interactive plots</li>
                <li>• <strong>Papa Parse</strong> - CSV processing</li>
                <li>• <strong>Zod</strong> - Schema validation</li>
                <li>• <strong>WebGL</strong> - Hardware acceleration</li>
              </ul>
            </div>

            <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
              <h4 className="font-semibold text-purple-900 mb-3">🐍 Python Backend</h4>
              <ul className="space-y-1 text-sm text-purple-800">
                <li>• <strong>FastAPI</strong> - High-performance API framework</li>
                <li>• <strong>Pandas</strong> - Data manipulation and analysis</li>
                <li>• <strong>NumPy</strong> - Numerical computing</li>
                <li>• <strong>Uvicorn</strong> - ASGI server</li>
              </ul>
            </div>

            <div className="bg-slate-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-slate-900 mb-3">🔧 Development</h4>
              <ul className="space-y-1 text-sm text-slate-600">
                <li>• <strong>ESLint</strong> - Code linting</li>
                <li>• <strong>PostCSS</strong> - CSS processing</li>
                <li>• <strong>Autoprefixer</strong> - Browser compatibility</li>
                <li>• <strong>Git</strong> - Version control</li>
              </ul>
            </div>

            <div className="bg-slate-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-slate-900 mb-3">🚀 Deployment</h4>
              <ul className="space-y-1 text-sm text-slate-600">
                <li>• <strong>Vercel</strong> - Hosting platform</li>
                <li>• <strong>Docker</strong> - Containerization</li>
                <li>• <strong>Static Export</strong> - CDN deployment</li>
                <li>• <strong>Analytics</strong> - Performance monitoring</li>
              </ul>
            </div>

            <div className="bg-slate-50 p-4 rounded-lg border">
              <h4 className="font-semibold text-slate-900 mb-3">🔬 Scientific</h4>
              <ul className="space-y-1 text-sm text-slate-600">
                <li>• <strong>ClassyFire</strong> - Chemical classification</li>
                <li>• <strong>HMDB</strong> - Metabolome database</li>
                <li>• <strong>KEGG</strong> - Pathway analysis</li>
                <li>• <strong>Metabolomics</strong> - Domain expertise</li>
              </ul>
            </div>
          </div>



          <h3>📈 Performance Benchmarks & Optimization</h3>

          <div className="not-prose bg-gradient-to-r from-slate-50 to-slate-100 p-6 rounded-lg border my-6">
            <h4 className="font-semibold text-slate-900 mb-4">Dataset Size Performance Matrix</h4>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-slate-300">
                    <th className="text-left py-2 px-2 font-medium">Dataset Size</th>
                    <th className="text-left py-2 px-2 font-medium">Client-Side</th>
                    <th className="text-left py-2 px-2 font-medium">Server-Side</th>
                    <th className="text-left py-2 px-2 font-medium">FastAPI (First)</th>
                    <th className="text-left py-2 px-2 font-medium">FastAPI (Cached)</th>
                    <th className="text-left py-2 px-2 font-medium">Recommendation</th>
                  </tr>
                </thead>
                <tbody className="text-slate-600">
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">1,000 rows</td>
                    <td className="py-2 px-2">~200ms</td>
                    <td className="py-2 px-2">~150ms</td>
                    <td className="py-2 px-2">~300ms</td>
                    <td className="py-2 px-2">~200ms</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-green-50 text-green-700">Client-side</Badge></td>
                  </tr>
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">10,000 rows</td>
                    <td className="py-2 px-2">~800ms</td>
                    <td className="py-2 px-2">~300ms</td>
                    <td className="py-2 px-2">~800ms</td>
                    <td className="py-2 px-2">~400ms</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-green-50 text-green-700">Client-side</Badge></td>
                  </tr>
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">50,000 rows</td>
                    <td className="py-2 px-2">~3s</td>
                    <td className="py-2 px-2">~800ms</td>
                    <td className="py-2 px-2">~2s</td>
                    <td className="py-2 px-2">~1.5s</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-purple-50 text-purple-700">FastAPI</Badge></td>
                  </tr>
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">100,000 rows</td>
                    <td className="py-2 px-2">❌ Crashes</td>
                    <td className="py-2 px-2">~2s</td>
                    <td className="py-2 px-2">~4.5s</td>
                    <td className="py-2 px-2">~3.2s</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-purple-50 text-purple-700">FastAPI</Badge></td>
                  </tr>
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">500,000 rows</td>
                    <td className="py-2 px-2">❌ N/A</td>
                    <td className="py-2 px-2">❌ Timeout</td>
                    <td className="py-2 px-2">~3s</td>
                    <td className="py-2 px-2">~2.8s</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-purple-50 text-purple-700">FastAPI</Badge></td>
                  </tr>
                  <tr>
                    <td className="py-2 px-2 font-medium">1,000,000+ rows</td>
                    <td className="py-2 px-2">❌ N/A</td>
                    <td className="py-2 px-2">❌ N/A</td>
                    <td className="py-2 px-2">~5s</td>
                    <td className="py-2 px-2">~4s</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-purple-50 text-purple-700">FastAPI</Badge></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div className="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-6">
            <div className="bg-green-50 p-4 rounded-lg border border-green-200">
              <h4 className="font-semibold text-green-900 mb-2">🚀 Optimization Strategies</h4>
              <ul className="space-y-1 text-sm text-green-800">
                <li>• Manual LOD system eliminates automatic zoom interference</li>
                <li>• Intelligent downsampling prioritizes significant metabolites</li>
                <li>• Memoized calculations with React.useMemo</li>
                <li>• WebGL acceleration (scattergl) for 100K+ data points</li>
                <li>• FastAPI + Polars for high-performance data processing</li>
                <li>• Vectorized operations with NumPy (10x faster generation)</li>
                <li>• Smart response sampling with user-controlled limits</li>
                <li>• Dynamic imports for code splitting</li>
              </ul>
            </div>

            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
              <h4 className="font-semibold text-blue-900 mb-2">💾 Intelligent Caching</h4>
              <ul className="space-y-1 text-sm text-blue-800">
                <li>• LRU cache for generated datasets</li>
                <li>• Cache warming for common dataset sizes</li>
                <li>• 20-30% faster subsequent requests</li>
                <li>• Memory-efficient data structures</li>
                <li>• Automatic cache management</li>
              </ul>
            </div>

            <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
              <h4 className="font-semibold text-purple-900 mb-2">🌐 Browser Support</h4>
              <ul className="space-y-1 text-sm text-purple-800">
                <li>• Chrome/Edge: Full support</li>
                <li>• Firefox: Full support</li>
                <li>• Safari: Supported (WebGL limitations)</li>
                <li>• Mobile: Limited (desktop recommended)</li>
              </ul>
            </div>
          </div>

          <h3>🚀 Production Scaling & Advanced Optimizations</h3>

          <div className="not-prose bg-gradient-to-r from-emerald-50 to-green-50 p-6 rounded-lg border border-emerald-200 mb-6">
            <h4 className="text-lg font-semibold text-emerald-900 mb-4">Strategic Scaling Approaches for Production Deployment</h4>
            <p className="text-emerald-800 text-sm mb-4">
              The choice of architecture completely determines the scalability strategy and infrastructure requirements. 
              Each approach has unique scaling characteristics that adapt to different types of users and projects.
            </p>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 mb-4">
              <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                <h5 className="font-semibold text-blue-900 mb-2 text-sm">🖥️ Client-Side: Infinite Scalability</h5>
                <div className="text-xs text-blue-800 space-y-2">
                  <p><strong>Capacity:</strong> 200-500+ concurrent users per server</p>
                  <p><strong>Strategy:</strong> Leverages computational power of each user's PC</p>
                  <p><strong>Server Resources:</strong> Minimal (static serving only)</p>
                  <p><strong>Scaling:</strong> Simple horizontal with CDN</p>
                  <div className="bg-blue-100 p-2 rounded mt-2">
                    <strong>Ideal for:</strong> Educational projects, demos, personal analysis, datasets &lt;50K points
                  </div>
                </div>
              </div>

              <div className="bg-amber-50 p-4 rounded-lg border border-amber-200">
                <h5 className="font-semibold text-amber-900 mb-2 text-sm">🌐 Server-Side: Controlled Scaling</h5>
                <div className="text-xs text-amber-800 space-y-2">
                  <p><strong>Capacity:</strong> 20-50 users per VM (16GB RAM)</p>
                  <p><strong>Strategy:</strong> Load balancing + intelligent caching</p>
                  <p><strong>Server Resources:</strong> Moderate (shared processing)</p>
                  <p><strong>Scaling:</strong> Vertical + horizontal with Redis</p>
                  <div className="bg-amber-100 p-2 rounded mt-2">
                    <strong>Ideal for:</strong> Enterprise platforms, 10K-100K point datasets, centralized control
                  </div>
                </div>
              </div>

              <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
                <h5 className="font-semibold text-purple-900 mb-2 text-sm">⚡ FastAPI: High-Performance Computing</h5>
                <div className="text-xs text-purple-800 space-y-2">
                  <p><strong>Capacity:</strong> 10-30 users per VM (advanced configuration)</p>
                  <p><strong>Strategy:</strong> Cluster computing + distributed cache</p>
                  <p><strong>Server Resources:</strong> Intensive (dedicated CPU + RAM)</p>
                  <p><strong>Scaling:</strong> Kubernetes + specialized microservices</p>
                  <div className="bg-purple-100 p-2 rounded mt-2">
                    <strong>Ideal for:</strong> Scientific research, datasets &gt;100K points, critical performance
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-emerald-100 p-4 rounded-lg">
              <h5 className="font-semibold text-emerald-900 mb-2 text-sm">🎯 Recommended Mixed Strategy for Production</h5>
              <p className="text-xs text-emerald-800 mb-2">
                <strong>Intelligent Routing:</strong> Automatically directs users to the optimal architecture based on project type and dataset size.
              </p>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-2 text-xs">
                <div><strong>60% Client-side:</strong> ~120 users (quick analysis)</div>
                <div><strong>30% Server-side:</strong> ~15 users (medium projects)</div>
                <div><strong>10% FastAPI:</strong> ~5 users (advanced research)</div>
              </div>
              <p className="text-xs text-emerald-700 mt-2 font-medium">
                Result: ~140 total concurrent users with a single 16GB + 4CPU VM
              </p>
            </div>
          </div>

          <div className="not-prose bg-gradient-to-r from-indigo-50 to-purple-50 p-6 rounded-lg border border-indigo-200 my-6">
            <h4 className="text-lg font-semibold text-indigo-900 mb-4">Infrastructure Scaling Strategies for Enterprise Deployment</h4>
            
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
              <div>
                <h5 className="font-semibold text-indigo-900 mb-3 text-sm">🔄 Horizontal Scaling Techniques</h5>
                <div className="space-y-3 text-xs text-indigo-800">
                  <div className="bg-indigo-100 p-3 rounded">
                    <strong>Load Balancer + Multiple FastAPI Instances</strong>
                    <p className="mt-1">Docker Compose scaling: <code>docker-compose scale fastapi=3</code></p>
                    <p>Capacity: from 10-30 users → 30-90 concurrent users</p>
                  </div>
                  
                  <div className="bg-indigo-100 p-3 rounded">
                    <strong>Distributed Redis Cache</strong>
                    <p className="mt-1">Shared cache between instances: <code>REDIS_CACHE="redis://cache:6379"</code></p>
                    <p>Reduces RAM usage by 40-60%, increases hit rate to 80%+</p>
                  </div>

                  <div className="bg-indigo-100 p-3 rounded">
                    <strong>CDN for Static Assets</strong>
                    <p className="mt-1">Offload static serving frees ~1GB RAM + 0.5 CPU</p>
                    <p>Capacity increase: +25% client-side users</p>
                  </div>
                </div>
              </div>

              <div>
                <h5 className="font-semibold text-indigo-900 mb-3 text-sm">⚙️ Advanced Configuration Patterns</h5>
                <div className="space-y-3 text-xs text-indigo-800">
                  <div className="bg-purple-100 p-3 rounded">
                    <strong>Resource Allocation Strategy</strong>
                    <p className="mt-1">Frontend: 2GB RAM + 1 CPU (serving)</p>
                    <p>FastAPI: 12GB RAM + 3 CPU (computing)</p>
                    <p>Redis Cache: 2GB dedicated RAM</p>
                  </div>

                  <div className="bg-purple-100 p-3 rounded">
                    <strong>Rate Limiting per Endpoint</strong>
                    <p className="mt-1">Client uploads: 10/minute per user</p>
                    <p>Server processing: 5/minute per user</p>
                    <p>FastAPI large datasets: 2/minute per user</p>
                  </div>

                  <div className="bg-purple-100 p-3 rounded">
                    <strong>Cache Warming Strategy</strong>
                    <p className="mt-1">Pre-cache common datasets: 1K, 10K, 50K, 100K points</p>
                    <p>Expected hit rate: 60-80% for repeated requests</p>
                  </div>
                </div>
              </div>
            </div>

            <div className="bg-gradient-to-r from-green-100 to-emerald-100 p-4 rounded-lg border border-green-300">
              <h5 className="font-semibold text-green-900 mb-2 text-sm">🎯 Production Deployment Decision Matrix</h5>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
                <div className="bg-white p-3 rounded border">
                  <strong className="text-blue-900">Scenario: Educational/Demo Platform</strong>
                  <p className="text-blue-800 mt-1">
                    <strong>Choice:</strong> 100% Client-side<br/>
                    <strong>Infrastructure:</strong> CDN + Static hosting<br/>
                    <strong>Capacity:</strong> Unlimited (distributed computing)<br/>
                    <strong>Cost:</strong> Minimal (~$50/month)
                  </p>
                </div>

                <div className="bg-white p-3 rounded border">
                  <strong className="text-amber-900">Scenario: Enterprise Platform</strong>
                  <p className="text-amber-800 mt-1">
                    <strong>Choice:</strong> Mixed intelligent routing<br/>
                    <strong>Infrastructure:</strong> Load balancer + Redis + CDN<br/>
                    <strong>Capacity:</strong> 100-200 concurrent users<br/>
                    <strong>Cost:</strong> Moderate (~$500/month)
                  </p>
                </div>

                <div className="bg-white p-3 rounded border">
                  <strong className="text-purple-900">Scenario: Research Institution</strong>
                  <p className="text-purple-800 mt-1">
                    <strong>Choice:</strong> FastAPI cluster + Kubernetes<br/>
                    <strong>Infrastructure:</strong> Multi-node + GPU acceleration<br/>
                    <strong>Capacity:</strong> 50-100 simultaneous researchers<br/>
                    <strong>Cost:</strong> High (~$2000/month)
                  </p>
                </div>
              </div>
            </div>

            <div className="mt-4 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <h5 className="font-semibold text-yellow-900 mb-2 text-sm">💡 Key Insight: Architecture Determines Scaling Strategy</h5>
              <p className="text-xs text-yellow-800">
                <strong>Client-side:</strong> Leverages distributed power of user PCs - nearly infinite scalability but limited by individual device capabilities.<br/>
                <strong>Server-side:</strong> Requires dedicated infrastructure but offers complete control and consistent performance for all users.<br/>
                <strong>FastAPI:</strong> Needs advanced configurations and significant resources, but guarantees optimal performance for intensive scientific workloads.
              </p>
            </div>
          </div>

        </CardContent>
      </Card>
    </div>
  )
}
