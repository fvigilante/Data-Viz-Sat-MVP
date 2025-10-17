"use client"

import { useState, useEffect, useCallback, useMemo, useRef } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Download, RotateCcw, Loader2, CheckCircle, AlertCircle } from "lucide-react"
import dynamic from "next/dynamic"
import { getApiUrl } from "@/lib/api-config"

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
  points_before_sampling: number
  is_downsampled: boolean
}

interface FilterParams {
  p_value_threshold: number
  log_fc_min: number
  log_fc_max: number
  search_term?: string
  dataset_size: number
  max_points?: number
}

export default function RVolcanoPlot() {
  const [data, setData] = useState<VolcanoDataPoint[]>([])
  const [stats, setStats] = useState({ up_regulated: 0, down_regulated: 0, non_significant: 0 })
  const [totalRows, setTotalRows] = useState(0)
  const [filteredRows, setFilteredRows] = useState(0)
  const [pointsBeforeSampling, setPointsBeforeSampling] = useState(0)
  const [isDownsampled, setIsDownsampled] = useState(false)

  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isReady, setIsReady] = useState(false)
  const [loadingType, setLoadingType] = useState<'generating' | 'cached' | null>(null)

  // Filter states
  const [pValue, setPValue] = useState(0.05)
  const [pValueInput, setPValueInput] = useState("0.05")
  const [logFCRange, setLogFCRange] = useState([-0.5, 0.5])
  const [searchTerm, setSearchTerm] = useState("")
  const [datasetSize, setDatasetSize] = useState(10000)
  const [maxPoints, setMaxPoints] = useState(20000)

  // Simple downsampling - user chooses max points directly

  const fetchVolcanoData = useCallback(async (params: FilterParams) => {
    setIsLoading(true)
    setError(null)
    setLoadingType('cached') // Default assumption

    try {
      // Check if dataset might need generation
      const cacheStatusResponse = await fetch(getApiUrl('rCacheStatus'))
      if (cacheStatusResponse.ok) {
        const cacheStatus = await cacheStatusResponse.json()
        const isDatasetCached = cacheStatus.cached_datasets.includes(params.dataset_size)
        setLoadingType(isDatasetCached ? 'cached' : 'generating')
      }

      const finalMaxPoints = params.max_points || maxPoints
      const queryParams = new URLSearchParams({
        p_value_threshold: params.p_value_threshold.toString(),
        log_fc_min: params.log_fc_min.toString(),
        log_fc_max: params.log_fc_max.toString(),
        dataset_size: params.dataset_size.toString(),
        max_points: finalMaxPoints.toString(),
        ...(params.search_term && { search_term: params.search_term })
      })

      console.log('R API Request - finalMaxPoints:', finalMaxPoints, 'params.max_points:', params.max_points, 'maxPoints state:', maxPoints, 'datasetSize:', params.dataset_size)
      console.log('Full query params:', queryParams.toString())

      const response = await fetch(`${getApiUrl('rVolcanoData')}?${queryParams}`)

      if (!response.ok) {
        throw new Error(`R API Error: ${response.status} ${response.statusText}`)
      }

      const result: VolcanoResponse = await response.json()

      console.log('R API Response - data points received:', result.data.length, 'filtered_rows:', result.filtered_rows, 'is_downsampled:', result.is_downsampled, 'points_before_sampling:', result.points_before_sampling)

      setData(result.data)
      setStats(result.stats)
      setTotalRows(result.total_rows)
      setFilteredRows(result.filtered_rows)
      setPointsBeforeSampling(result.points_before_sampling)
      setIsDownsampled(result.is_downsampled)
      setIsReady(true)

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Unknown error occurred"
      setError(errorMessage)
      console.error("Error fetching R volcano data:", err)
    } finally {
      setIsLoading(false)
      setLoadingType(null)
    }
  }, [maxPoints])

  // Debug: Monitor maxPoints changes
  useEffect(() => {
    console.log('maxPoints state changed to:', maxPoints)
  }, [maxPoints])

  // Auto-adjust maxPoints when dataset size changes (only when dataset size changes, not maxPoints)
  useEffect(() => {
    // If current maxPoints is larger than dataset, adjust it
    if (maxPoints > datasetSize) {
      if (datasetSize >= 100000) {
        setMaxPoints(100000)
      } else if (datasetSize >= 50000) {
        setMaxPoints(50000)
      } else if (datasetSize >= 20000) {
        setMaxPoints(20000)
      } else if (datasetSize >= 10000) {
        setMaxPoints(10000)
      } else {
        // For very small datasets, use the dataset size itself
        setMaxPoints(datasetSize)
      }
    }
  }, [datasetSize]) // Removed maxPoints from dependencies to prevent interference

  // Debounced API calls for filters and downsampling
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      fetchVolcanoData({
        p_value_threshold: pValue,
        log_fc_min: logFCRange[0],
        log_fc_max: logFCRange[1],
        search_term: searchTerm || undefined,
        dataset_size: datasetSize,
        max_points: maxPoints
      })
    }, 300) // 300ms debounce

    return () => clearTimeout(timeoutId)
  }, [pValue, logFCRange, searchTerm, datasetSize, maxPoints, fetchVolcanoData])

  // Simple downsampling - no complex timeout management needed

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
    title: `Volcano Plot - ${filteredRows.toLocaleString()} points${isDownsampled ? ` (downsampled from ${pointsBeforeSampling.toLocaleString()})` : ''}`,
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

  // Memoized table data - now keeping all data for virtual scrolling
  const tableData = useMemo(() => {
    const downRegulated = data
      .filter(d => d.category === "down")
      .sort((a, b) => a.logFC - b.logFC)

    const upRegulated = data
      .filter(d => d.category === "up")
      .sort((a, b) => b.logFC - a.logFC)

    return { downRegulated, upRegulated }
  }, [data])

  // Virtual scrolling state
  const [downScrollTop, setDownScrollTop] = useState(0)
  const [upScrollTop, setUpScrollTop] = useState(0)
  const downScrollRef = useRef<HTMLDivElement>(null)
  const upScrollRef = useRef<HTMLDivElement>(null)

  // Virtual scrolling constants
  const ROW_HEIGHT = 53 // Height of each table row in pixels
  const CONTAINER_HEIGHT = 384 // max-h-96 = 384px
  const VISIBLE_ROWS = Math.ceil(CONTAINER_HEIGHT / ROW_HEIGHT)
  const BUFFER_ROWS = 5 // Extra rows to render for smooth scrolling

  // Calculate visible rows for virtual scrolling
  const getVisibleRows = (scrollTop: number, totalRows: number) => {
    const startIndex = Math.max(0, Math.floor(scrollTop / ROW_HEIGHT) - BUFFER_ROWS)
    const endIndex = Math.min(totalRows, startIndex + VISIBLE_ROWS + (BUFFER_ROWS * 2))
    return { startIndex, endIndex, visibleRows: endIndex - startIndex }
  }

  const downVisibleRange = getVisibleRows(downScrollTop, tableData.downRegulated.length)
  const upVisibleRange = getVisibleRows(upScrollTop, tableData.upRegulated.length)

  // Download functions for individual tables
  const downloadDownRegulated = useCallback(() => {
    const headers = ["Metabolite name", "ClassyFire Superclass", "ClassyFire Class", "Log2(FC)", "p-Value"]
    const csvContent = [
      headers.join(","),
      ...tableData.downRegulated.map(row =>
        [
          `"${row.gene}"`,
          `"${row.classyfireSuperclass || ""}"`,
          `"${row.classyfireClass || ""}"`,
          row.logFC,
          row.padj
        ].join(",")
      )
    ].join("\n")

    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "r_down_regulated_metabolites.csv"
    a.click()
    URL.revokeObjectURL(url)
  }, [tableData.downRegulated])

  const downloadUpRegulated = useCallback(() => {
    const headers = ["Metabolite name", "ClassyFire Superclass", "ClassyFire Class", "Log2(FC)", "p-Value"]
    const csvContent = [
      headers.join(","),
      ...tableData.upRegulated.map(row =>
        [
          `"${row.gene}"`,
          `"${row.classyfireSuperclass || ""}"`,
          `"${row.classyfireClass || ""}"`,
          row.logFC,
          row.padj
        ].join(",")
      )
    ].join("\n")

    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "r_up_regulated_metabolites.csv"
    a.click()
    URL.revokeObjectURL(url)
  }, [tableData.upRegulated])

  const warmCache = useCallback(async () => {
    setIsLoading(true)
    setError(null)

    try {
      const response = await fetch(getApiUrl('rWarmCache'), {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify([10000, 50000, 100000, 500000, 1000000, 5000000])
      })

      if (!response.ok) {
        throw new Error(`R cache warming failed: ${response.status}`)
      }

      const result = await response.json()
      console.log('R cache warmed:', result)

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "R cache warming failed"
      setError(errorMessage)
      console.error("Error warming R cache:", err)
    } finally {
      setIsLoading(false)
    }
  }, [])

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
    a.download = "r_volcano_data.csv"
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
                    {loadingType === 'generating' ? (
                      <>
                        <p className="font-medium text-sm">Generating dataset with R + data.table...</p>
                        <p className="text-xs text-muted-foreground">First-time generation - this will be cached for future use</p>
                      </>
                    ) : (
                      <>
                        <p className="font-medium text-sm">Loading cached data with R + data.table...</p>
                        <p className="text-xs text-muted-foreground">Using pre-generated dataset for faster response</p>
                      </>
                    )}
                  </div>
                </>
              ) : error ? (
                <>
                  <AlertCircle className="h-5 w-5 text-red-500" />
                  <div>
                    <p className="font-medium text-sm text-red-700">R API Error</p>
                    <p className="text-xs text-red-600">{error}</p>
                  </div>
                </>
              ) : isReady ? (
                <>
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <div>
                    <p className="font-medium text-sm text-green-700">
                      Ready! {filteredRows.toLocaleString()} points displayed
                      {isDownsampled && ` (sampled from ${pointsBeforeSampling.toLocaleString()})`}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {isDownsampled
                        ? "Intelligently sampled for optimal performance - significant points prioritized"
                        : "Powered by R + data.table"
                      }
                    </p>
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
          <div className="space-y-4">
            {/* First Row: Dataset Size and Downsampling Level */}
            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
              {/* Dataset Size */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Dataset Size</Label>
                <div className="grid grid-cols-4 gap-2">
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
                  <Button
                    onClick={() => setDatasetSize(500000)}
                    variant={datasetSize === 500000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    500K
                  </Button>
                  <Button
                    onClick={() => setDatasetSize(1000000)}
                    variant={datasetSize === 1000000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    1M
                  </Button>
                  <Button
                    onClick={() => setDatasetSize(5000000)}
                    variant={datasetSize === 5000000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    5M
                  </Button>
                  <Button
                    onClick={() => setDatasetSize(10000000)}
                    variant={datasetSize === 10000000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    10M
                  </Button>
                </div>
              </div>

              {/* Downsampling Level */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Downsampling Level</Label>
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    onClick={() => {
                      console.log('Button clicked: Setting maxPoints to 10000, current maxPoints:', maxPoints)
                      setMaxPoints(10000)
                    }}
                    variant={maxPoints === 10000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 10000}
                    title={datasetSize < 10000 ? "Dataset too small for this downsampling level" : ""}
                  >
                    10K points
                  </Button>
                  <Button
                    onClick={() => {
                      console.log('Button clicked: Setting maxPoints to 20000, current maxPoints:', maxPoints)
                      setMaxPoints(20000)
                    }}
                    variant={maxPoints === 20000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 20000}
                    title={datasetSize < 20000 ? "Dataset too small for this downsampling level" : ""}
                  >
                    20K points
                  </Button>
                  <Button
                    onClick={() => {
                      console.log('Setting maxPoints to 50000')
                      setMaxPoints(50000)
                    }}
                    variant={maxPoints === 50000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 50000}
                    title={datasetSize < 50000 ? "Dataset too small for this downsampling level" : ""}
                  >
                    50K points
                  </Button>
                  <Button
                    onClick={() => {
                      console.log('Setting maxPoints to 100000')
                      setMaxPoints(100000)
                    }}
                    variant={maxPoints === 100000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 100000}
                    title={datasetSize < 100000 ? "Dataset too small for this downsampling level" : ""}
                  >
                    100K points
                  </Button>
                </div>
                <div className="text-xs text-muted-foreground">
                  Current dataset: {datasetSize.toLocaleString()} points. 
                  {filteredRows > 0 && ` Showing: ${filteredRows.toLocaleString()} points`}
                  {isDownsampled && ` (downsampled from ${pointsBeforeSampling.toLocaleString()})`}
                </div>
              </div>
            </div>

            {/* Second Row: Filters */}
            <div className="grid grid-cols-1 lg:grid-cols-4 gap-4 items-end">
              {/* p-Value */}
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

              {/* Log2(FC) Range */}
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

              {/* Search Metabolite */}
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
            </div>
          </div>

          <div className="flex items-center justify-between mt-4 pt-4 border-t">
            <div className="flex gap-2">
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
                onClick={warmCache}
                variant="outline"
                size="sm"
                className="gap-2"
                disabled={isLoading}
                title="Pre-generate common dataset sizes (10K, 50K, 100K, 500K, 1M, 5M) for instant loading"
              >
                <Loader2 className="h-4 w-4" />
                Warm Cache
              </Button>
            </div>

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
                {loadingType === 'generating' ? (
                  <>
                    <p className="text-lg mb-2">Generating Dataset</p>
                    <p className="text-sm text-muted-foreground">Creating {datasetSize.toLocaleString()} synthetic data points with R...</p>
                    <p className="text-xs text-muted-foreground mt-1">This dataset will be cached for future requests</p>
                  </>
                ) : (
                  <>
                    <p className="text-lg mb-2">Loading Cached Data</p>
                    <p className="text-sm text-muted-foreground">Retrieving pre-generated dataset from R backend...</p>
                  </>
                )}
              </div>
            </div>
          ) : error ? (
            <div className="h-96 flex items-center justify-center">
              <Alert className="max-w-md">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  <p className="font-medium mb-1">R API Connection Error</p>
                  <p className="text-sm">{error}</p>
                  <p className="text-xs mt-2 text-muted-foreground">
                    Make sure the R backend server is running and accessible
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
                responsive: true,
                scrollZoom: true,
                doubleClick: 'reset+autosize',
                showTips: false
              }}
              style={{ width: "100%", height: "600px" }}

            />
          ) : (
            <div className="h-96 flex items-center justify-center text-muted-foreground">
              <div className="text-center">
                <p className="text-lg mb-2">No data available</p>
                <p className="text-sm">Adjust filters or check R API connection</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Metabolite Tables */}
      {isReady && data.length > 0 && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Down-regulated Metabolites Table */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-blue-500 rounded-full"></div>
                  Down-regulated Metabolites ({stats.down_regulated})
                </div>
                <Button
                  onClick={downloadDownRegulated}
                  variant="outline"
                  size="sm"
                  className="gap-2"
                  disabled={isLoading || tableData.downRegulated.length === 0}
                >
                  <Download className="h-4 w-4" />
                  Download CSV
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div
                ref={downScrollRef}
                className="max-h-96 overflow-y-auto"
                onScroll={(e) => setDownScrollTop(e.currentTarget.scrollTop)}
              >
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Metabolite</TableHead>
                      <TableHead>Log2(FC)</TableHead>
                      <TableHead>p-Value</TableHead>
                      <TableHead>Superclass</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {/* Virtual scrolling spacer - top */}
                    {downVisibleRange.startIndex > 0 && (
                      <tr style={{ height: downVisibleRange.startIndex * ROW_HEIGHT }}>
                        <td colSpan={4}></td>
                      </tr>
                    )}

                    {/* Visible rows */}
                    {tableData.downRegulated
                      .slice(downVisibleRange.startIndex, downVisibleRange.endIndex)
                      .map((metabolite, index) => (
                        <TableRow key={`down-${metabolite.gene}-${downVisibleRange.startIndex + index}`}>
                          <TableCell className="font-medium">{metabolite.gene}</TableCell>
                          <TableCell className="text-blue-600 font-medium">
                            {metabolite.logFC.toFixed(3)}
                          </TableCell>
                          <TableCell>{metabolite.padj.toExponential(2)}</TableCell>
                          <TableCell className="text-sm text-muted-foreground">
                            {metabolite.classyfireSuperclass || "N/A"}
                          </TableCell>
                        </TableRow>
                      ))}

                    {/* Virtual scrolling spacer - bottom */}
                    {downVisibleRange.endIndex < tableData.downRegulated.length && (
                      <tr style={{ height: (tableData.downRegulated.length - downVisibleRange.endIndex) * ROW_HEIGHT }}>
                        <td colSpan={4}></td>
                      </tr>
                    )}
                  </TableBody>
                </Table>
                {tableData.downRegulated.length === 0 && (
                  <div className="text-center py-8 text-muted-foreground">
                    No down-regulated metabolites found
                  </div>
                )}
              </div>
            </CardContent>
          </Card>

          {/* Up-regulated Metabolites Table */}
          <Card>
            <CardHeader>
              <CardTitle className="text-lg flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="w-3 h-3 bg-red-500 rounded-full"></div>
                  Up-regulated Metabolites ({stats.up_regulated})
                </div>
                <Button
                  onClick={downloadUpRegulated}
                  variant="outline"
                  size="sm"
                  className="gap-2"
                  disabled={isLoading || tableData.upRegulated.length === 0}
                >
                  <Download className="h-4 w-4" />
                  Download CSV
                </Button>
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div
                ref={upScrollRef}
                className="max-h-96 overflow-y-auto"
                onScroll={(e) => setUpScrollTop(e.currentTarget.scrollTop)}
              >
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Metabolite</TableHead>
                      <TableHead>Log2(FC)</TableHead>
                      <TableHead>p-Value</TableHead>
                      <TableHead>Superclass</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {/* Virtual scrolling spacer - top */}
                    {upVisibleRange.startIndex > 0 && (
                      <tr style={{ height: upVisibleRange.startIndex * ROW_HEIGHT }}>
                        <td colSpan={4}></td>
                      </tr>
                    )}

                    {/* Visible rows */}
                    {tableData.upRegulated
                      .slice(upVisibleRange.startIndex, upVisibleRange.endIndex)
                      .map((metabolite, index) => (
                        <TableRow key={`up-${metabolite.gene}-${upVisibleRange.startIndex + index}`}>
                          <TableCell className="font-medium">{metabolite.gene}</TableCell>
                          <TableCell className="text-red-600 font-medium">
                            {metabolite.logFC.toFixed(3)}
                          </TableCell>
                          <TableCell>{metabolite.padj.toExponential(2)}</TableCell>
                          <TableCell className="text-sm text-muted-foreground">
                            {metabolite.classyfireSuperclass || "N/A"}
                          </TableCell>
                        </TableRow>
                      ))}

                    {/* Virtual scrolling spacer - bottom */}
                    {upVisibleRange.endIndex < tableData.upRegulated.length && (
                      <tr style={{ height: (tableData.upRegulated.length - upVisibleRange.endIndex) * ROW_HEIGHT }}>
                        <td colSpan={4}></td>
                      </tr>
                    )}
                  </TableBody>
                </Table>
                {tableData.upRegulated.length === 0 && (
                  <div className="text-center py-8 text-muted-foreground">
                    No up-regulated metabolites found
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Statistics */}
      {isReady && (
        <div className="text-sm text-muted-foreground text-center space-y-1">
          <div>
            Dataset: {totalRows.toLocaleString()} | Displayed: {filteredRows.toLocaleString()}
            {isDownsampled && ` (sampled from ${pointsBeforeSampling.toLocaleString()})`}
            {searchTerm && ` | Search: "${searchTerm}"`}
          </div>
          <div>
            Down-regulated: <span className="text-blue-600 font-medium">{stats.down_regulated}</span> |
            Up-regulated: <span className="text-red-600 font-medium">{stats.up_regulated}</span> |
            Non-significant: <span className="text-gray-600 font-medium">{stats.non_significant}</span>
          </div>
          {isDownsampled && (
            <div className="text-xs text-amber-600">
              ⚡ Smart sampling active - significant points prioritized for performance
            </div>
          )}
        </div>
      )}
    </div>
  )
}