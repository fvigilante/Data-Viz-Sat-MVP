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

          <h3>🌋 Triple Volcano Plot Implementations</h3>
          <p>
            The application demonstrates three distinct approaches to data processing and visualization, each optimized
            for different use cases, dataset sizes, and performance requirements.
          </p>

          <div className="not-prose grid grid-cols-1 lg:grid-cols-3 gap-4 my-6">
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
                  FastAPI + Python
                </Badge>
                <span className="text-xs font-medium text-purple-800">High-Performance Backend</span>
              </div>

              <h4 className="font-semibold text-purple-900 mb-2 text-sm">🔥 Maximum Performance</h4>
              <ul className="space-y-1 text-xs text-purple-800">
                <li><strong>Data Flow:</strong> Python API → Pandas → Server Filters → JSON</li>
                <li><strong>Performance:</strong> Handles 1M+ points with server-side filtering</li>
                <li><strong>Features:</strong> Advanced filtering, statistical processing</li>
                <li><strong>Technology:</strong> FastAPI + Pandas + NumPy + Uvicorn</li>
              </ul>

              <div className="mt-3 p-2 bg-purple-100 rounded text-xs text-purple-700">
                <strong>Best for:</strong> Massive datasets, scientific computing, production workloads
              </div>
            </div>
          </div>

          <h3>✨ Key Features & Capabilities</h3>

          <div className="not-prose grid grid-cols-1 md:grid-cols-2 gap-6 my-6">
            <div>
              <h4 className="font-semibold text-slate-900 mb-3">📊 Visualization Features</h4>
              <ul className="space-y-2 text-sm text-slate-600">
                <li>• Interactive volcano plots with WebGL acceleration (scattergl)</li>
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
                    <th className="text-left py-2 px-2 font-medium">Python API</th>
                    <th className="text-left py-2 px-2 font-medium">Recommendation</th>
                  </tr>
                </thead>
                <tbody className="text-slate-600">
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">1,000 rows</td>
                    <td className="py-2 px-2">~200ms</td>
                    <td className="py-2 px-2">~150ms</td>
                    <td className="py-2 px-2">~50ms</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-green-50 text-green-700">Client-side</Badge></td>
                  </tr>
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">10,000 rows</td>
                    <td className="py-2 px-2">~800ms</td>
                    <td className="py-2 px-2">~300ms</td>
                    <td className="py-2 px-2">~100ms</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-green-50 text-green-700">Client-side</Badge></td>
                  </tr>
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">50,000 rows</td>
                    <td className="py-2 px-2">~3s</td>
                    <td className="py-2 px-2">~800ms</td>
                    <td className="py-2 px-2">~200ms</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-purple-50 text-purple-700">Python API</Badge></td>
                  </tr>
                  <tr className="border-b border-slate-200">
                    <td className="py-2 px-2 font-medium">100,000 rows</td>
                    <td className="py-2 px-2">Not recommended</td>
                    <td className="py-2 px-2">~1.5s</td>
                    <td className="py-2 px-2">~400ms</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-purple-50 text-purple-700">Python API</Badge></td>
                  </tr>
                  <tr>
                    <td className="py-2 px-2 font-medium">1,000,000+ rows</td>
                    <td className="py-2 px-2">Not supported</td>
                    <td className="py-2 px-2">Not recommended</td>
                    <td className="py-2 px-2">~1-2s</td>
                    <td className="py-2 px-2"><Badge variant="outline" className="bg-purple-50 text-purple-700">Python API</Badge></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div className="not-prose grid grid-cols-1 md:grid-cols-3 gap-4 my-6">
            <div className="bg-green-50 p-4 rounded-lg border border-green-200">
              <h4 className="font-semibold text-green-900 mb-2">🚀 Optimization Strategies</h4>
              <ul className="space-y-1 text-sm text-green-800">
                <li>• Memoized calculations with React.useMemo</li>
                <li>• WebGL acceleration (scattergl) for 100K+ data points</li>
                <li>• Python/Pandas for server-side filtering and processing</li>
                <li>• Dynamic imports for code splitting</li>
                <li>• Efficient data structures and cleanup</li>
              </ul>
            </div>

            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
              <h4 className="font-semibold text-blue-900 mb-2">💾 Memory Management</h4>
              <ul className="space-y-1 text-sm text-blue-800">
                <li>• Dataset caching with Map structures</li>
                <li>• Automatic garbage collection</li>
                <li>• Streaming data processing</li>
                <li>• Memory-efficient filtering algorithms</li>
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

        </CardContent>
      </Card>
    </div>
  )
}
