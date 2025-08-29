"use client"

import { useEffect, useState } from "react"
import dynamic from "next/dynamic"

const Plot = dynamic(() => import("react-plotly.js"), {
  ssr: false,
  loading: () => <div className="flex items-center justify-center h-96 text-slate-500">Loading plot...</div>,
})

interface ServerVolcanoPlotProps {
  data: Array<{
    gene: string
    logFC: number
    padj: number
    classyfireSuperclass?: string
    classyfireClass?: string
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

  useEffect(() => {
    if (!data || data.length === 0) return

    // Process data for plotting (client-side visualization of server-processed data)
    const x = data.map((row) => row.logFC)
    const y = data.map((row) => -Math.log10(row.padj))
    const text = data.map((row) => row.gene)

    const colors = data.map((row) => {
      const logFC = Number(row.logFC) || 0
      const padj = Number(row.padj) || 1
      const isSignificant = padj <= padjThreshold

      if (!isSignificant) return "#9CA3AF" // Gray for non-significant
      if (isSignificant && logFC > logFcMax) return "#EF4444" // Red for up-regulated
      if (isSignificant && logFC < logFcMin) return "#3B82F6" // Blue for down-regulated
      return "#9CA3AF" // Gray for significant but within range
    })

    const hoverText = data.map(
      (row) =>
        `<b>${row.gene}</b><br>` +
        `Log2(FC): ${row.logFC.toFixed(3)}<br>` +
        `p-Value: ${row.padj.toFixed(6)}<br>` +
        `${row.classyfireSuperclass ? `Superclass: ${row.classyfireSuperclass}<br>` : ""}` +
        `${row.classyfireClass ? `Class: ${row.classyfireClass}` : ""}`,
    )

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
        text,
        hovertemplate: hoverText.map((text) => text + "<extra></extra>"),
        showlegend: false,
      },
    ])

    const xMin = Math.min(...x)
    const xMax = Math.max(...x)
    const yMax = Math.max(...y)

    setLayout({
      title: {
        text: "Volcano Plot (Server-Processed Data)",
        font: { size: 16, color: "#1e293b" },
      },
      xaxis: {
        title: "Log2(FC)",
        zeroline: true,
        zerolinecolor: "#e2e8f0",
        gridcolor: "#f1f5f9",
      },
      yaxis: {
        title: "-log10(p-value)",
        zeroline: false,
        gridcolor: "#f1f5f9",
      },
      plot_bgcolor: "white",
      paper_bgcolor: "white",
      margin: { t: 50, r: 50, b: 50, l: 60 },
      shapes: [
        // Horizontal significance line
        {
          type: "line",
          x0: xMin - 1,
          x1: xMax + 1,
          y0: -Math.log10(padjThreshold),
          y1: -Math.log10(padjThreshold),
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
  }, [data, logFcMin, logFcMax, padjThreshold])

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

  return (
    <div className="w-full h-full">
      <Plot
        data={plotData}
        layout={layout}
        config={{
          displayModeBar: true,
          displaylogo: false,
          modeBarButtonsToRemove: ["pan2d", "lasso2d", "select2d"],
          responsive: true,
        }}
        style={{ width: "100%", height: "100%" }}
      />
    </div>
  )
}
