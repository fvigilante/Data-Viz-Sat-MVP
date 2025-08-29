import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"

export default function AboutPage() {
  return (
    <div className="p-6 space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>About Data Viz Satellite</CardTitle>
        </CardHeader>
        <CardContent className="prose prose-slate max-w-none">
          <p>
            Data Viz Satellite is an example Next.js application demonstrating interactive data visualization
            capabilities using Plotly.js. This prototype showcases modern web technologies for scientific data analysis
            and visualization with both client-side and server-side processing approaches.
          </p>

          <h3>Architecture Overview</h3>
          <div className="not-prose mb-4">
            <Badge variant="outline" className="bg-teal-50 text-teal-700 border-teal-200">
              Server-Side Layout
            </Badge>
          </div>
          <p>
            The application uses Next.js App Router with Server-Side Rendering (SSR) for the main layout, header,
            sidebar navigation, and footer. This provides optimal initial loading performance and SEO benefits while
            maintaining a responsive, professional interface.
          </p>

          <h3>Volcano Plot Implementations</h3>

          <h4>Client-Side Processing</h4>
          <div className="not-prose mb-2">
            <Badge variant="outline" className="bg-blue-50 text-blue-700 border-blue-200">
              /plots/volcano
            </Badge>
          </div>
          <ul>
            <li>
              <strong>Real-time interactivity:</strong> All filtering, data manipulation, and plot updates happen in the
              browser
            </li>
            <li>
              <strong>Performance:</strong> Optimal for datasets up to ~50K points with smooth interactions
            </li>
            <li>
              <strong>Features:</strong> Live filtering, dual-range sliders, real-time table updates, CSV export
            </li>
            <li>
              <strong>Processing:</strong> CSV parsing, data validation, and filtering using PapaParse and JavaScript
            </li>
            <li>
              <strong>Limitations:</strong> Memory constraints for very large datasets {">"}100K points)
            </li>
          </ul>

          <h4>Server-Side Processing</h4>
          <div className="not-prose mb-2">
            <Badge variant="outline" className="bg-green-50 text-green-700 border-green-200">
              /plots/volcano-server
            </Badge>
          </div>
          <ul>
            <li>
              <strong>Scalability:</strong> Can handle much larger datasets by processing data on the server
            </li>
            <li>
              <strong>Performance:</strong> Reduced client-side memory usage and faster initial rendering
            </li>
            <li>
              <strong>Processing:</strong> CSV parsing and data normalization handled by Next.js API routes
            </li>
            <li>
              <strong>Caching:</strong> Server-side data processing with configurable cache strategies
            </li>
            <li>
              <strong>Use case:</strong> Ideal for large datasets, batch processing, or when client resources are
              limited
            </li>
          </ul>

          <h3>Features</h3>
          <ul>
            <li>Interactive volcano plots for differential expression analysis</li>
            <li>Real-time filtering and data exploration (client-side)</li>
            <li>Server-side data processing for large datasets</li>
            <li>CSV/TSV file upload and processing</li>
            <li>Responsive design with scientific color themes</li>
            <li>Export capabilities for plots and filtered data</li>
            <li>Dual-range Log2(FC) sliders with visual threshold indicators</li>
            <li>Interactive legend with category visibility controls</li>
          </ul>

          <h3>Technology Stack</h3>
          <ul>
            <li>Next.js 14 with App Router (SSR + Client-side hydration)</li>
            <li>TypeScript for type safety</li>
            <li>Tailwind CSS for styling</li>
            <li>Plotly.js for interactive visualizations</li>
            <li>shadcn/ui component library</li>
            <li>PapaParse for CSV processing</li>
            <li>Zod for data validation</li>
          </ul>

          <h3>Performance Considerations</h3>
          <div className="bg-slate-50 p-4 rounded-lg not-prose">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <h4 className="font-semibold text-slate-900 mb-2">Client-Side Limits</h4>
                <ul className="space-y-1 text-slate-600">
                  <li>• 1K-10K points: Optimal performance</li>
                  <li>• 10K-50K points: Good performance</li>
                  <li>• 50K-100K points: Acceptable with some lag</li>
                  <li>• 100K+ points: Consider server-side</li>
                </ul>
              </div>
              <div>
                <h4 className="font-semibold text-slate-900 mb-2">Server-Side Benefits</h4>
                <ul className="space-y-1 text-slate-600">
                  <li>• Handles datasets {">"}100K points</li>
                  <li>• Reduced client memory usage</li>
                  <li>• Faster initial page loads</li>
                  <li>• Configurable caching strategies</li>
                </ul>
              </div>
            </div>
          </div>

          <p className="text-sm text-muted-foreground mt-8">
            Built by Sequentia Biotech as an internal prototype for data visualization workflows.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}
