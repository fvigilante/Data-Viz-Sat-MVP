"use client"

import { useEffect, useState, useMemo } from "react"
import dynamic from "next/dynamic"

const Plot = dynamic(() => import("react-plotly.js"), {
  ssr: false,
  loading: () => <div className="flex items-center justify-center h-96 text-slate-500">Loading plot...</div>,
})

interface ServerVolcanoPlotProps {
  data: Array<{
    gene: string // Feature identifier (gene, metabolite, protein, etc.)
    logFC: number
    padj: number
    classyfireSuperclass?: string // For metabolomics data
    classyfireClass?: string // For metabolomics data
  }>
  logFcMin?: number
  logFcMax?: number
  padjThreshold?: number
}

export function ServerVolcanoPlot({
  data,
  logFcMin = -0.5,
  logFcMax = 0.5,
  padjThreshold = 0.05,
}: ServerVolcanoPlotProps) {
  const [plotData, setPlotData] = useState<any[]>([])
  const [layout, setLayout] = useState<any>({})
  const [visibleCategories, setVisibleCategories] = useState({
    downRegulated: true,
    nonSignificant: true,
    upRegulated: true,
  })

  const plotCalculations = useMemo(() => {
    if (!data || data.length === 0) return null

    const getPointCategory = (row: any) => {
      const logFC = Number(row.logFC) || 0
      const padj = Number(row.padj) || 1
      const isSignificant = padj <= padjThreshold

      if (!isSignificant) return "nonSignificant"
      if (isSignificant && logFC > logFcMax) return "upRegulated"
      if (isSignificant && logFC < logFcMin) return "downRegulated"
      return "nonSignificant"
    }

    const visibleData = data.filter((row) => {
      const category = getPointCategory(row)
      return visibleCategories[category]
    })

    if (visibleData.length === 0) {
      return null
    }

    const x = visibleData.map((row) => {
      const logFC = Number(row.logFC)
      return isFinite(logFC) ? logFC : 0
    })

    const y = visibleData.map((row) => {
      const padj = Number(row.padj)
      if (!isFinite(padj) || padj <= 0) return 10
      const logValue = -Math.log10(padj)
      return isFinite(logValue) ? logValue : 10
    })

    const colors = visibleData.map((row) => {
      const category = getPointCategory(row)
      switch (category) {
        case "upRegulated":
          return "#ef4444" // red-500 (keep for biological significance)
        case "downRegulated":
          return "#3b82f6" // blue-500 (keep for biological significance)
        default:
          return "#6b7280" // gray-500
      }
    })

    const hoverText = visibleData.map((row) => {
      const featureName = String(row.gene) || "Unknown"
      const superclass = row.classyfireSuperclass || "N/A"
      const classyClass = row.classyfireClass || "N/A"
      const logFC = Number(row.logFC) || 0
      const pValue = Number(row.padj) || 1

      // Build hover text conditionally based on available data
      let hoverContent = `<b>${featureName}</b><br>`

      // Add classification info if available (mainly for metabolomics)
      if (row.classyfireSuperclass && row.classyfireSuperclass !== "N/A") {
        hoverContent += `ClassyFire Superclass: ${superclass}<br>`
      }
      if (row.classyfireClass && row.classyfireClass !== "N/A") {
        hoverContent += `ClassyFire Class: ${classyClass}<br>`
      }

      hoverContent += `log2(FC): ${logFC.toFixed(3)}<br>`
      hoverContent += `p-Value: ${pValue.toFixed(6)}`

      return hoverContent
    })

    const allX = data
      .map((row) => {
        const logFC = Number(row.logFC)
        return isFinite(logFC) ? logFC : 0
      })
      .filter((val) => isFinite(val))

    const allY = data
      .map((row) => {
        const padj = Number(row.padj)
        if (!isFinite(padj) || padj <= 0) return 10
        const logValue = -Math.log10(padj)
        return isFinite(logValue) ? logValue : 10
      })
      .filter((val) => isFinite(val))

    const xMin = allX.length > 0 ? Math.min(...allX) : -5
    const xMax = allX.length > 0 ? Math.max(...allX) : 5
    const yMax = allY.length > 0 ? Math.max(...allY) : 5

    return {
      x,
      y,
      colors,
      hoverText,
      xMin,
      xMax,
      yMax,
    }
  }, [data, visibleCategories, logFcMin, logFcMax, padjThreshold])

  useEffect(() => {
    if (!plotCalculations) {
      setPlotData([])
      setLayout({})
      return
    }

    const { x, y, colors, hoverText, xMin, xMax, yMax } = plotCalculations

    setPlotData([
      {
        x,
        y,
        mode: "markers",
        type: "scattergl",
        marker: {
          color: colors,
          size: 6,
          opacity: 0.7,
          line: {
            width: 0.5,
            color: "white",
          },
        },
        hovertemplate: "%{hovertext}<extra></extra>",
        hovertext: hoverText,
        showlegend: false,
      },
    ])

    const thresholdLine = -Math.log10(Math.max(padjThreshold, 1e-10))

    setLayout({
      title: {
        text: "",
        font: { size: 16 },
      },
      xaxis: {
        title: {
          text: "Log2(FC)",
          font: { size: 14, color: "#1e293b" },
        },
        zeroline: true,
        zerolinecolor: "#e2e8f0",
        zerolinewidth: 1,
        gridcolor: "#f1f5f9",
        gridwidth: 1,
        showgrid: true,
        tickfont: { size: 12, color: "#64748b" },
        range: [xMin - 0.5, xMax + 0.5],
      },
      yaxis: {
        title: {
          text: "-log10(p-value)",
          font: { size: 14, color: "#1e293b" },
        },
        zeroline: false,
        gridcolor: "#f1f5f9",
        gridwidth: 1,
        showgrid: true,
        tickfont: { size: 12, color: "#64748b" },
        range: [0, yMax + 0.5],
      },
      hovermode: "closest",
      showlegend: false,
      margin: { l: 80, r: 80, t: 40, b: 80 },
      plot_bgcolor: "white",
      paper_bgcolor: "white",
      font: { family: "Inter, system-ui, sans-serif" },
      shapes: [
        // Horizontal significance line
        {
          type: "line",
          x0: xMin - 0.5,
          x1: xMax + 0.5,
          y0: thresholdLine,
          y1: thresholdLine,
          line: { color: "#64748b", width: 1, dash: "dash" },
        },
        // Vertical fold change lines
        {
          type: "line",
          x0: logFcMin,
          x1: logFcMin,
          y0: 0,
          y1: yMax + 0.5,
          line: { color: "#64748b", width: 1, dash: "dash" },
        },
        {
          type: "line",
          x0: logFcMax,
          x1: logFcMax,
          y0: 0,
          y1: yMax + 0.5,
          line: { color: "#64748b", width: 1, dash: "dash" },
        },
      ],
    })
  }, [plotCalculations, logFcMin, logFcMax, padjThreshold])

  const toggleCategory = (category: keyof typeof visibleCategories) => {
    setVisibleCategories((prev) => ({
      ...prev,
      [category]: !prev[category],
    }))
  }

  if (!data || data.length === 0) {
    return (
      <div className="flex items-center justify-center h-96 text-slate-500">
        <div className="text-center">
          <p className="text-lg font-medium">No data available</p>
          <p className="text-sm">Upload a CSV file or load the example dataset</p>
        </div>
      </div>
    )
  }

  if (!plotCalculations) {
    return (
      <div className="h-full w-full flex items-center justify-center">
        <div className="text-slate-500 text-center">
          <p className="text-base font-medium">No visible data points</p>
          <p className="text-sm">Enable categories in the legend to view data</p>
        </div>
      </div>
    )
  }

  return (
    <div className="w-full h-full relative">
      <Plot
        data={plotData}
        layout={layout}
        config={{
          displayModeBar: true,
          modeBarButtonsToRemove: ["lasso2d", "select2d"],
          toImageButtonOptions: {
            format: "png",
            filename: "volcano_plot_server",
            height: 600,
            width: 900,
            scale: 2,
          },
          displaylogo: false,
          responsive: true,
        }}
        style={{ width: "100%", height: "500px" }}
        useResizeHandler={true}
      />

      <div className="absolute bottom-4 right-4 bg-white/90 backdrop-blur-sm border rounded-lg p-3 shadow-lg">
        <div className="space-y-2">
          <button
            onClick={() => toggleCategory("downRegulated")}
            className={`flex items-center gap-2 text-sm transition-opacity ${visibleCategories.downRegulated ? "opacity-100" : "opacity-50"
              }`}
          >
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: "#3b82f6" }}></div>
            <span className="text-slate-600">Down-regulated</span>
          </button>

          <button
            onClick={() => toggleCategory("nonSignificant")}
            className={`flex items-center gap-2 text-sm transition-opacity ${visibleCategories.nonSignificant ? "opacity-100" : "opacity-50"
              }`}
          >
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: "#64748b" }}></div>
            <span className="text-slate-600">Non significant</span>
          </button>

          <button
            onClick={() => toggleCategory("upRegulated")}
            className={`flex items-center gap-2 text-sm transition-opacity ${visibleCategories.upRegulated ? "opacity-100" : "opacity-50"
              }`}
          >
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: "#ef4444" }}></div>
            <span className="text-slate-600">Up-regulated</span>
          </button>
        </div>
      </div>
    </div>
  )
}
