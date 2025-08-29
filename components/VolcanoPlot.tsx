"use client"

import dynamic from "next/dynamic"
import { useState, useMemo } from "react"
import type { DegRow } from "@/lib/schema"

const Plot = dynamic(() => import("react-plotly.js"), { ssr: false })

interface VolcanoPlotProps {
  data: DegRow[]
  logFcMin?: number
  logFcMax?: number
  padjThreshold?: number
}

export default function VolcanoPlot({ data, logFcMin = -1, logFcMax = 1, padjThreshold = 0.05 }: VolcanoPlotProps) {
  const [visibleCategories, setVisibleCategories] = useState({
    downRegulated: true,
    nonSignificant: true,
    upRegulated: true,
  })

  const plotCalculations = useMemo(() => {
    const getPointCategory = (row: DegRow) => {
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
          return "#ef4444" // red-500
        case "downRegulated":
          return "#3b82f6" // blue-500
        default:
          return "#6b7280" // gray-500
      }
    })

    const hoverText = visibleData.map((row) => {
      const metaboliteName = String(row.gene) || "Unknown"
      const superclass = row.classyfireSuperclass || "N/A"
      const classyClass = row.classyfireClass || "N/A"
      const logFC = Number(row.logFC) || 0
      const pValue = Number(row.padj) || 1

      return (
        `<b>${metaboliteName}</b><br>` +
        `ClassyFire Superclass: ${superclass}<br>` +
        `ClassyFire Class: ${classyClass}<br>` +
        `log2(FC): ${logFC.toFixed(3)}<br>` +
        `p-Value: ${pValue.toFixed(6)}`
      )
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

  const toggleCategory = (category: keyof typeof visibleCategories) => {
    setVisibleCategories((prev) => ({
      ...prev,
      [category]: !prev[category],
    }))
  }

  if (!data || data.length === 0) {
    return (
      <div className="h-full w-full flex items-center justify-center">
        <div className="text-muted-foreground text-center">
          <p className="text-base font-medium">No data to display</p>
          <p className="text-sm">Upload a CSV file to view the volcano plot</p>
        </div>
      </div>
    )
  }

  if (!plotCalculations) {
    return (
      <div className="h-full w-full flex items-center justify-center">
        <div className="text-muted-foreground text-center">
          <p className="text-base font-medium">No visible data points</p>
          <p className="text-sm">Enable categories in the legend to view data</p>
        </div>
      </div>
    )
  }

  const { x, y, colors, hoverText, xMin, xMax, yMax } = plotCalculations

  const plotData = [
    {
      x,
      y,
      mode: "markers" as const,
      type: "scattergl" as const,
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
    },
  ]

  const thresholdLine = -Math.log10(Math.max(padjThreshold, 1e-10))

  const layout = {
    title: {
      text: "",
      font: { size: 16 },
    },
    xaxis: {
      title: {
        text: "Log2(FC)",
        font: { size: 14, color: "hsl(var(--volcano-text))" },
      },
      zeroline: true,
      zerolinecolor: "hsl(var(--volcano-grid))",
      zerolinewidth: 1,
      gridcolor: "hsl(var(--volcano-grid))",
      gridwidth: 1,
      showgrid: true,
      tickfont: { size: 12, color: "hsl(var(--volcano-text-muted))" },
      range: [xMin - 0.5, xMax + 0.5],
    },
    yaxis: {
      title: {
        text: "-log10(p-value)",
        font: { size: 14, color: "hsl(var(--volcano-text))" },
      },
      zeroline: false,
      gridcolor: "hsl(var(--volcano-grid))",
      gridwidth: 1,
      showgrid: true,
      tickfont: { size: 12, color: "hsl(var(--volcano-text-muted))" },
      range: [0, yMax + 0.5],
    },
    shapes: [
      {
        type: "line" as const,
        x0: xMin - 0.5,
        y0: thresholdLine,
        x1: xMax + 0.5,
        y1: thresholdLine,
        line: {
          color: "hsl(var(--volcano-neutral))",
          width: 1,
          dash: "dash",
        },
      },
      {
        type: "line" as const,
        x0: logFcMax,
        y0: 0,
        x1: logFcMax,
        y1: yMax + 0.5,
        line: {
          color: "hsl(var(--volcano-neutral))",
          width: 1,
          dash: "dash",
        },
      },
      {
        type: "line" as const,
        x0: logFcMin,
        y0: 0,
        x1: logFcMin,
        y1: yMax + 0.5,
        line: {
          color: "hsl(var(--volcano-neutral))",
          width: 1,
          dash: "dash",
        },
      },
    ],
    hovermode: "closest" as const,
    showlegend: false,
    margin: { l: 80, r: 80, t: 40, b: 80 },
    plot_bgcolor: "hsl(var(--volcano-background))",
    paper_bgcolor: "hsl(var(--volcano-background))",
    font: { family: "Inter, system-ui, sans-serif" },
  }

  const config = {
    displayModeBar: true,
    modeBarButtonsToRemove: ["lasso2d", "select2d"],
    toImageButtonOptions: {
      format: "png" as const,
      filename: "volcano_plot",
      height: 600,
      width: 900,
      scale: 2,
    },
    displaylogo: false,
    responsive: true,
  }

  return (
    <div className="h-full w-full relative">
      <Plot
        data={plotData}
        layout={layout}
        config={config}
        style={{ width: "100%", height: "500px" }}
        useResizeHandler={true}
      />

      <div className="absolute bottom-4 right-4 bg-card/90 backdrop-blur-sm border rounded-lg p-3 shadow-lg">
        <div className="space-y-2">
          <button
            onClick={() => toggleCategory("downRegulated")}
            className={`flex items-center gap-2 text-sm transition-opacity ${
              visibleCategories.downRegulated ? "opacity-100" : "opacity-50"
            }`}
          >
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: "#3b82f6" }}></div>
            <span className="text-foreground">Down-regulated</span>
          </button>

          <button
            onClick={() => toggleCategory("nonSignificant")}
            className={`flex items-center gap-2 text-sm transition-opacity ${
              visibleCategories.nonSignificant ? "opacity-100" : "opacity-50"
            }`}
          >
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: "#6b7280" }}></div>
            <span className="text-foreground">Non significant</span>
          </button>

          <button
            onClick={() => toggleCategory("upRegulated")}
            className={`flex items-center gap-2 text-sm transition-opacity ${
              visibleCategories.upRegulated ? "opacity-100" : "opacity-50"
            }`}
          >
            <div className="w-3 h-3 rounded-full" style={{ backgroundColor: "#ef4444" }}></div>
            <span className="text-foreground">Up-regulated</span>
          </button>
        </div>
      </div>
    </div>
  )
}
