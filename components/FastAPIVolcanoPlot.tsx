"use client"

import { useState, useEffect, useCallback, useMemo } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Download, RotateCcw, Loader2, CheckCircle, AlertCircle } from "lucide-react"
import dynamic from "next/dynamic"

const Plot = dynamic(() => import("react-plotly.js"), { ssr: false })

interface VolcanoDataPoint {
  gene: string
  logFC: number
  padj: number
  classyfireSuperclass?: string
  classyfireClass?: string
  category: "up" | "down" | "non_significant"
}

interface VolcanoResponse {
  data: VolcanoDataPoint[]
  stats: {
    up_regulated: number
    down_regulated: number
    non_significant: number
  }
  total_rows: number
  filtered_rows: number
}

interface FilterParams {
  p_value_threshold: number
  log_fc_min: number
  log_fc_max: number
  search_term?: string
  dataset_size: number
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"

export default function FastAPIVolcanoPlot() {
  const [data, setData] = useState<VolcanoDataPoint[]>([])
  const [stats, setStats] = useState({ up_regulated: 0, down_regulated: 0, non_significant: 0 })
  const [totalRows, setTotalRows] = useState(0)
  const [filteredRows, setFilteredRows] = useState(0)
  
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isReady, setIsReady] = useState(false)
  
  // Filter states
  const [pValue, setPValue] = useState(0.05)
  const [pValueInput, setPValueInput] = useState("0.05")
  const [logFCRange, setLogFCRange] = useState([-0.5, 0.5])
  const [searchTerm, setSearchTerm] = useState("")
  const [datasetSize, setDatasetSize] = useState(10000)

  const fetchVolcanoData = useCallback(async (params: FilterParams) => {
    setIsLoading(true)
    setError(null)
    
    try {
      const queryParams = new URLSearchParams({
        p_value_threshold: params.p_value_threshold.toString(),
        log_fc_min: params.log_fc_min.toString(),
        log_fc_max: params.log_fc_max.toString(),
        dataset_size: params.dataset_size.toString(),
        ...(params.search_term && { search_term: params.search_term })
      })

      const response = await fetch(`${API_BASE_URL}/api/volcano-data?${queryParams}`)
      
      if (!response.ok) {
        throw new Error(`API Error: ${response.status} ${response.statusText}`)
      }
      
      const result: VolcanoResponse = await response.json()
      
      setData(result.data)
      setStats(result.stats)
      setTotalRows(result.total_rows)
      setFilteredRows(result.filtered_rows)
      setIsReady(true)
      
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Unknown error occurred"
      setError(errorMessage)
      console.error("Error fetching volcano data:", err)
    } finally {
      setIsLoading(false)
    }
  }, [])

  // Debounced API calls
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      fetchVolcanoData({
        p_value_threshold: pValue,
        log_fc_min: logFCRange[0],
        log_fc_max: logFCRange[1],
        search_term: searchTerm || undefined,
        dataset_size: datasetSize
      })
    }, 300) // 300ms debounce

    return () => clearTimeout(timeoutId)
  }, [pValue, logFCRange, searchTerm, datasetSize, fetchVolcanoData])

  const handlePValueChange = useCallback((value: string) => {
    setPValueInput(value)
    const numValue = Number(value)
    if (!isNaN(numValue) && numValue >= 0 && numValue <= 1) {
      setPValue(numValue)
    }
  }, [])

  const handlePValueBlur = useCallback(() => {
    setPValueInput(pValue.toString())
  }, [pValue])

  const resetFilters = useCallback(() => {
    setPValue(0.05)
    setPValueInput("0.05")
    setLogFCRange([-0.5, 0.5])
    setSearchTerm("")
  }, [])

  const plotData = useMemo(() => {
    if (!data.length) return []

    const upRegulated = data.filter(d => d.category === "up")
    const downRegulated = data.filter(d => d.category === "down")
    const nonSignificant = data.filter(d => d.category === "non_significant")

    return [
      {
        x: upRegulated.map(d => d.logFC),
        y: upRegulated.map(d => -Math.log10(d.padj)),
        mode: "markers" as const,
        type: "scattergl" as const,
        name: "Up-regulated",
        marker: { color: "#ef4444", size: 6 },
        text: upRegulated.map(d => 
          `${d.gene}<br>Log2(FC): ${d.logFC}<br>p-value: ${d.padj}<br>Superclass: ${d.classyfireSuperclass || "N/A"}`
        ),
        hovertemplate: "%{text}<extra></extra>"
      },
      {
        x: downRegulated.map(d => d.logFC),
        y: downRegulated.map(d => -Math.log10(d.padj)),
        mode: "markers" as const,
        type: "scattergl" as const,
        name: "Down-regulated",
        marker: { color: "#3b82f6", size: 6 },
        text: downRegulated.map(d => 
          `${d.gene}<br>Log2(FC): ${d.logFC}<br>p-value: ${d.padj}<br>Superclass: ${d.classyfireSuperclass || "N/A"}`
        ),
        hovertemplate: "%{text}<extra></extra>"
      },
      {
        x: nonSignificant.map(d => d.logFC),
        y: nonSignificant.map(d => -Math.log10(d.padj)),
        mode: "markers" as const,
        type: "scattergl" as const,
        name: "Non-significant",
        marker: { color: "#6b7280", size: 4, opacity: 0.6 },
        text: nonSignificant.map(d => 
          `${d.gene}<br>Log2(FC): ${d.logFC}<br>p-value: ${d.padj}<br>Superclass: ${d.classyfireSuperclass || "N/A"}`
        ),
        hovertemplate: "%{text}<extra></extra>"
      }
    ]
  }, [data])

  const plotLayout = {
    title: "Volcano Plot (FastAPI + Polars)",
    xaxis: { title: "Log2(Fold Change)" },
    yaxis: { title: "-log10(p-value)" },
    hovermode: "closest" as const,
    showlegend: true,
    shapes: [
      // Vertical lines for fold change thresholds
      {
        type: "line" as const,
        x0: logFCRange[0],
        x1: logFCRange[0],
        y0: 0,
        y1: 1,
        yref: "paper" as const,
        line: { color: "#ef4444", width: 2, dash: "dash" }
      },
      {
        type: "line" as const,
        x0: logFCRange[1],
        x1: logFCRange[1],
        y0: 0,
        y1: 1,
        yref: "paper" as const,
        line: { color: "#ef4444", width: 2, dash: "dash" }
      },
      // Horizontal line for p-value threshold
      {
        type: "line" as const,
        x0: 0,
        x1: 1,
        xref: "paper" as const,
        y0: -Math.log10(pValue),
        y1: -Math.log10(pValue),
        line: { color: "#6b7280", width: 2, dash: "dash" }
      }
    ]
  }

  const downloadCSV = useCallback(() => {
    const headers = ["Metabolite name", "ClassyFire Superclass", "ClassyFire Class", "Log2(FC)", "p-Value", "Category"]
    const csvContent = [
      headers.join(","),
      ...data.map(row =>
        [
          `"${row.gene}"`,
          `"${row.classyfireSuperclass || ""}"`,
          `"${row.classyfireClass || ""}"`,
          row.logFC,
          row.padj,
          row.category
        ].join(",")
      )
    ].join("\n")

    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "fastapi_volcano_data.csv"
    a.click()
    URL.revokeObjectURL(url)
  }, [data])

  return (
    <div className="p-6 space-y-6">
      {/* Status Card */}
      {(isLoading || isReady || error) && (
        <Card className={`border-l-4 ${error ? 'border-l-red-500' : isReady ? 'border-l-green-500' : 'border-l-blue-500'}`}>
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              {isLoading ? (
                <>
                  <Loader2 className="h-5 w-5 animate-spin text-blue-500" />
                  <div>
                    <p className="font-medium text-sm">Processing data with FastAPI + Polars...</p>
                    <p className="text-xs text-muted-foreground">High-performance server-side filtering</p>
                  </div>
                </>
              ) : error ? (
                <>
                  <AlertCircle className="h-5 w-5 text-red-500" />
                  <div>
                    <p className="font-medium text-sm text-red-700">API Error</p>
                    <p className="text-xs text-red-600">{error}</p>
                  </div>
                </>
              ) : isReady ? (
                <>
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <div>
                    <p className="font-medium text-sm text-green-700">
                      Ready! {filteredRows.toLocaleString()} / {totalRows.toLocaleString()} points loaded
                    </p>
                    <p className="text-xs text-muted-foreground">Powered by FastAPI + Polars</p>
                  </div>
                </>
              ) : null}
            </div>
          </CardContent>
        </Card>
      )}

      {/* Controls Card */}
      <Card>
        <CardContent className="p-6">
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 items-end">
            <div className="space-y-2">
              <Label className="text-sm font-medium">Dataset Size</Label>
              <div className="flex gap-2">
                <Button
                  onClick={() => setDatasetSize(10000)}
                  variant={datasetSize === 10000 ? "default" : "outline"}
                  size="sm"
                  disabled={isLoading}
                >
                  10K
                </Button>
                <Button
                  onClick={() => setDatasetSize(50000)}
                  variant={datasetSize === 50000 ? "default" : "outline"}
                  size="sm"
                  disabled={isLoading}
                >
                  50K
                </Button>
                <Button
                  onClick={() => setDatasetSize(100000)}
                  variant={datasetSize === 100000 ? "default" : "outline"}
                  size="sm"
                  disabled={isLoading}
                >
                  100K
                </Button>
              </div>
            </div>

            <div className="space-y-2">
              <Label className="text-sm font-medium">p-Value</Label>
              <Input
                type="number"
                value={pValueInput}
                onChange={(e) => handlePValueChange(e.target.value)}
                onBlur={handlePValueBlur}
                min={0}
                max={1}
                step={0.001}
                className="w-full"
                placeholder="0.000 - 1.000"
                disabled={isLoading}
              />
            </div>

            <div className="space-y-2">
              <Label className="text-sm font-medium">Search Metabolite</Label>
              <Input
                type="text"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full"
                placeholder="Enter metabolite name..."
                disabled={isLoading}
              />
            </div>

            <div className="space-y-2 col-span-2">
              <Label className="text-sm font-medium">Log2(FC) Range</Label>
              <div className="px-3">
                <div className="flex justify-between items-center mb-2">
                  <span className="text-xs font-semibold text-red-600 bg-red-50 px-2 py-1 rounded">
                    {logFCRange[0].toFixed(2)}
                  </span>
                  <span className="text-xs font-semibold text-red-600 bg-red-50 px-2 py-1 rounded">
                    {logFCRange[1].toFixed(2)}
                  </span>
                </div>
                <Slider
                  value={logFCRange}
                  onValueChange={setLogFCRange}
                  min={-5}
                  max={5}
                  step={0.1}
                  className="w-full"
                  disabled={isLoading}
                />
                <div className="flex justify-between text-xs text-muted-foreground mt-1">
                  <span>-5.00</span>
                  <span>5.00</span>
                </div>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between mt-4 pt-4 border-t">
            <Button
              onClick={resetFilters}
              variant="outline"
              size="sm"
              className="gap-2"
              disabled={isLoading}
            >
              <RotateCcw className="h-4 w-4" />
              Reset Filters
            </Button>

            <Button
              onClick={downloadCSV}
              variant="outline"
              size="sm"
              className="gap-2"
              disabled={isLoading || !data.length}
            >
              <Download className="h-4 w-4" />
              Download CSV
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Plot Card */}
      <Card className="min-h-[600px]">
        <CardContent className="p-6">
          {isLoading ? (
            <div className="h-96 flex items-center justify-center">
              <div className="text-center">
                <Loader2 className="mx-auto h-12 w-12 animate-spin text-blue-500 mb-4" />
                <p className="text-lg mb-2">Processing with FastAPI + Polars</p>
                <p className="text-sm text-muted-foreground">High-performance data filtering in progress...</p>
              </div>
            </div>
          ) : error ? (
            <div className="h-96 flex items-center justify-center">
              <Alert className="max-w-md">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  <p className="font-medium mb-1">API Connection Error</p>
                  <p className="text-sm">{error}</p>
                  <p className="text-xs mt-2 text-muted-foreground">
                    Make sure FastAPI server is running on {API_BASE_URL}
                  </p>
                </AlertDescription>
              </Alert>
            </div>
          ) : data.length > 0 ? (
            <Plot
              data={plotData}
              layout={plotLayout}
              config={{
                displayModeBar: true,
                modeBarButtonsToRemove: ["lasso2d", "select2d"],
                responsive: true
              }}
              style={{ width: "100%", height: "600px" }}
            />
          ) : (
            <div className="h-96 flex items-center justify-center text-muted-foreground">
              <div className="text-center">
                <p className="text-lg mb-2">No data available</p>
                <p className="text-sm">Adjust filters or check API connection</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Statistics */}
      {isReady && (
        <div className="text-sm text-muted-foreground text-center space-y-1">
          <div>
            Total: {totalRows.toLocaleString()} | Filtered: {filteredRows.toLocaleString()}
            {searchTerm && ` | Search: "${searchTerm}"`}
          </div>
          <div>
            Down-regulated: <span className="text-blue-600 font-medium">{stats.down_regulated}</span> | 
            Up-regulated: <span className="text-red-600 font-medium">{stats.up_regulated}</span> | 
            Non-significant: <span className="text-gray-600 font-medium">{stats.non_significant}</span>
          </div>
        </div>
      )}
    </div>
  )
}