import FastAPIVolcanoPlot from "@/components/FastAPIVolcanoPlot"
import TechExplainer from "@/components/TechExplainer"

export default function VolcanoFastAPIPage() {
  return (
    <div className="flex-1 flex flex-col h-full">
      <div className="bg-white border-b border-slate-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Volcano Plot (FastAPI + Polars)</h1>
            <p className="text-sm text-slate-600 mt-1">
              High-performance server-side data processing with FastAPI and Polars
            </p>
          </div>
          <div className="flex items-center gap-2 text-sm text-emerald-600">
            <div className="h-2 w-2 bg-emerald-600 rounded-full"></div>
            <span>FastAPI + Polars Backend</span>
          </div>
        </div>
      </div>

      <div className="flex-1 bg-slate-50 overflow-auto">
        <FastAPIVolcanoPlot />
        <div className="p-6">
          <TechExplainer type="fastapi" />
        </div>
      </div>
    </div>
  )
}