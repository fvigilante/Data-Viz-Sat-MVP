"use client"

import { useState, useEffect, useCallback, useMemo } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Download, RotateCcw, Loader2, CheckCircle, AlertCircle, Trash2 } from "lucide-react"
import dynamic from "next/dynamic"

const Plot = dynamic(() => import("react-plotly.js"), { ssr: false })

interface PCADataPoint {
  sample_id: string
  pc1: number
  pc2: number
  pc3: number
  group: string
  batch?: string
  metadata?: Record<string, any>
}

interface PCAResponse {
  data: PCADataPoint[]
  explained_variance: {
    pc1: number
    pc2: number
    pc3: number
  }
  loadings?: {
    feature: string
    pc1: number
    pc2: number
    pc3: number
  }[]
  stats: {
    total_samples: number
    total_features: number
    groups: string[]
  }
  is_downsampled: boolean
  points_before_sampling: number
}

interface PCAParams {
  dataset_size: number
  n_features: number
  n_groups: number
  max_points?: number
  add_batch_effect: boolean
  noise_level: number
}

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000"

export default function FastAPIPCAPlot() {
  const [data, setData] = useState<PCADataPoint[]>([])
  const [explainedVariance, setExplainedVariance] = useState({ pc1: 0, pc2: 0, pc3: 0 })
  const [stats, setStats] = useState({ total_samples: 0, total_features: 0, groups: [] as string[] })
  const [isDownsampled, setIsDownsampled] = useState(false)
  const [pointsBeforeSampling, setPointsBeforeSampling] = useState(0)

  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [isReady, setIsReady] = useState(false)
  const [loadingType, setLoadingType] = useState<'generating' | 'cached' | null>(null)

  // PCA parameters
  const [datasetSize, setDatasetSize] = useState(1000)
  const [nFeatures, setNFeatures] = useState(100)
  const [nGroups, setNGroups] = useState(3)
  const [maxPoints, setMaxPoints] = useState(10000)
  const [addBatchEffect, setAddBatchEffect] = useState(false)
  const [noiseLevel, setNoiseLevel] = useState(0.1)

  // Group visibility state
  const [visibleGroups, setVisibleGroups] = useState<Set<string>>(new Set())

  // Clear cache function
  const clearCache = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/api/clear-cache`, {
        method: 'POST'
      })
      if (response.ok) {
        console.log('Cache cleared successfully')
        // Optionally show a success message
      }
    } catch (err) {
      console.error('Error clearing cache:', err)
    }
  }, [])

  const fetchPCAData = useCallback(async (params: PCAParams) => {
    setIsLoading(true)
    setError(null)
    setLoadingType('cached') // Default assumption

    try {
      // Check if dataset might need generation
      const cacheStatusResponse = await fetch(`${API_BASE_URL}/api/pca-cache-status`)
      if (cacheStatusResponse.ok) {
        const cacheStatus = await cacheStatusResponse.json()
        const cacheKey = `${params.dataset_size}_${params.n_features}_${params.n_groups}`
        const isDatasetCached = cacheStatus.cached_datasets.includes(cacheKey)
        setLoadingType(isDatasetCached ? 'cached' : 'generating')
      }

      const queryParams = new URLSearchParams({
        dataset_size: params.dataset_size.toString(),
        n_features: params.n_features.toString(),
        n_groups: params.n_groups.toString(),
        max_points: (params.max_points || maxPoints).toString(),
        add_batch_effect: params.add_batch_effect.toString(),
        noise_level: params.noise_level.toString()
      })

      console.log('PCA API Request:', queryParams.toString())

      const response = await fetch(`${API_BASE_URL}/api/pca-data?${queryParams}`)

      if (!response.ok) {
        throw new Error(`API Error: ${response.status} ${response.statusText}`)
      }

      const result: PCAResponse = await response.json()

      console.log('PCA API Response - samples received:', result.data.length, 'explained variance:', result.explained_variance)

      setData(result.data)
      setExplainedVariance(result.explained_variance)
      setStats(result.stats)
      setIsDownsampled(result.is_downsampled)
      setPointsBeforeSampling(result.points_before_sampling)
      setIsReady(true)

      // Initialize visible groups when data loads
      const uniqueGroups = new Set(result.data.map(point => point.group))
      setVisibleGroups(uniqueGroups)

    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Unknown error occurred"
      setError(errorMessage)
      console.error("Error fetching PCA data:", err)
    } finally {
      setIsLoading(false)
      setLoadingType(null)
    }
  }, [maxPoints])

  // Auto-adjust maxPoints when dataset size changes
  useEffect(() => {
    if (maxPoints > datasetSize) {
      if (datasetSize >= 10000) {
        setMaxPoints(10000)
      } else if (datasetSize >= 5000) {
        setMaxPoints(5000)
      } else if (datasetSize >= 1000) {
        setMaxPoints(1000)
      } else {
        setMaxPoints(datasetSize)
      }
    }
  }, [datasetSize])

  // Debounced API calls
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      fetchPCAData({
        dataset_size: datasetSize,
        n_features: nFeatures,
        n_groups: nGroups,
        max_points: maxPoints,
        add_batch_effect: addBatchEffect,
        noise_level: noiseLevel
      })
    }, 300)

    return () => clearTimeout(timeoutId)
  }, [datasetSize, nFeatures, nGroups, maxPoints, addBatchEffect, noiseLevel, fetchPCAData])

  const resetParameters = useCallback(() => {
    setDatasetSize(1000)
    setNFeatures(100)
    setNGroups(3)
    setMaxPoints(10000)
    setAddBatchEffect(false)
    setNoiseLevel(0.1)
  }, [])

  // Performance warning
  const isHighPerformanceLoad = useMemo(() => {
    return (datasetSize > 10000 && nFeatures > 1000) || nFeatures > 2000
  }, [datasetSize, nFeatures])

  // Toggle group visibility
  const toggleGroupVisibility = useCallback((group: string) => {
    setVisibleGroups(prev => {
      const newSet = new Set(prev)
      if (newSet.has(group)) {
        newSet.delete(group)
      } else {
        newSet.add(group)
      }
      return newSet
    })
  }, [])

  // Get grouped data for tables
  const groupedTableData = useMemo(() => {
    if (!data.length) return {}
    
    return data.reduce((acc, point) => {
      if (!acc[point.group]) {
        acc[point.group] = []
      }
      acc[point.group].push(point)
      return acc
    }, {} as Record<string, PCADataPoint[]>)
  }, [data])

  // Get available groups
  const availableGroups = useMemo(() => {
    return Object.keys(groupedTableData).sort()
  }, [groupedTableData])

  // Generate 3D plot data
  const plotData = useMemo(() => {
    if (!data.length) return []

    // Filter data by visible groups
    const filteredData = data.filter(point => visibleGroups.has(point.group))

    // Group data by group
    const groupedData = filteredData.reduce((acc, point) => {
      if (!acc[point.group]) {
        acc[point.group] = []
      }
      acc[point.group].push(point)
      return acc
    }, {} as Record<string, PCADataPoint[]>)

    // Color palette for groups
    const colors = [
      '#ef4444', // red
      '#3b82f6', // blue  
      '#10b981', // green
      '#f59e0b', // amber
      '#8b5cf6', // violet
      '#ec4899', // pink
      '#06b6d4', // cyan
      '#84cc16', // lime
    ]

    return Object.entries(groupedData).map(([group, points], index) => ({
      x: points.map(p => p.pc1),
      y: points.map(p => p.pc2),
      z: points.map(p => p.pc3),
      mode: "markers" as const,
      type: "scatter3d" as const,
      name: `Group ${group}`,
      marker: {
        color: colors[index % colors.length],
        size: 6,
        opacity: 0.8
      },
      text: points.map(p =>
        `Sample: ${p.sample_id}<br>Group: ${p.group}<br>PC1: ${p.pc1.toFixed(3)}<br>PC2: ${p.pc2.toFixed(3)}<br>PC3: ${p.pc3.toFixed(3)}`
      ),
      hovertemplate: "%{text}<extra></extra>"
    }))
  }, [data, visibleGroups])

  const plotLayout = {
    title: `3D PCA Plot - ${data.length.toLocaleString()} samples${isDownsampled ? ` (downsampled from ${pointsBeforeSampling.toLocaleString()})` : ''}`,
    scene: {
      xaxis: {
        title: `PC1 (${(explainedVariance.pc1 * 100).toFixed(1)}% variance)`,
        showgrid: true,
        gridcolor: '#e5e7eb'
      },
      yaxis: {
        title: `PC2 (${(explainedVariance.pc2 * 100).toFixed(1)}% variance)`,
        showgrid: true,
        gridcolor: '#e5e7eb'
      },
      zaxis: {
        title: `PC3 (${(explainedVariance.pc3 * 100).toFixed(1)}% variance)`,
        showgrid: true,
        gridcolor: '#e5e7eb'
      },
      bgcolor: '#f9fafb',
      camera: {
        eye: { x: 1.5, y: 1.5, z: 1.5 }
      }
    },
    hovermode: "closest" as const,
    showlegend: true,
    legend: {
      x: 0,
      y: 1
    }
  }

  const downloadCSV = useCallback(() => {
    const headers = ["Sample ID", "Group", "PC1", "PC2", "PC3", "Batch"]
    const csvContent = [
      headers.join(","),
      ...data.map(row =>
        [
          `"${row.sample_id}"`,
          `"${row.group}"`,
          row.pc1.toFixed(6),
          row.pc2.toFixed(6),
          row.pc3.toFixed(6),
          `"${row.batch || ""}"`
        ].join(",")
      )
    ].join("\n")

    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "pca_data.csv"
    a.click()
    URL.revokeObjectURL(url)
  }, [data])

  const downloadGroupCSV = useCallback((group: string, groupData: PCADataPoint[]) => {
    const headers = ["Sample ID", "Group", "PC1", "PC2", "PC3", "Batch"]
    const csvContent = [
      headers.join(","),
      ...groupData.map(row =>
        [
          `"${row.sample_id}"`,
          `"${row.group}"`,
          row.pc1.toFixed(6),
          row.pc2.toFixed(6),
          row.pc3.toFixed(6),
          `"${row.batch || ""}"`
        ].join(",")
      )
    ].join("\n")

    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = `pca_data_${group.toLowerCase().replace(/\s+/g, '_')}.csv`
    a.click()
    URL.revokeObjectURL(url)
  }, [])

  return (
    <div className="p-6 space-y-6">
      {/* Performance Warning */}
      {isHighPerformanceLoad && (
        <Card className="border-l-4 border-l-orange-500 bg-orange-50">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              <AlertCircle className="h-5 w-5 text-orange-500" />
              <div>
                <p className="font-medium text-sm text-orange-700">Performance Warning</p>
                <p className="text-xs text-orange-600">
                  High feature count ({nFeatures.toLocaleString()}) may cause system slowdown or crash.
                  Consider using ≤1000 features for better performance.
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

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
                        <p className="font-medium text-sm">Generating PCA dataset with FastAPI + scikit-learn...</p>
                        <p className="text-xs text-muted-foreground">Computing principal components - this will be cached for future use</p>
                      </>
                    ) : (
                      <>
                        <p className="font-medium text-sm">Loading cached PCA data...</p>
                        <p className="text-xs text-muted-foreground">Using pre-computed principal components</p>
                      </>
                    )}
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
                      Ready! {data.length.toLocaleString()} samples displayed
                      {isDownsampled && ` (sampled from ${pointsBeforeSampling.toLocaleString()})`}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Total variance explained: {((explainedVariance.pc1 + explainedVariance.pc2 + explainedVariance.pc3) * 100).toFixed(1)}%
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
            {/* First Row: Dataset Parameters */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Dataset Size */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Dataset Size (Samples)</Label>
                <div className="grid grid-cols-3 gap-2">
                  <Button
                    onClick={() => setDatasetSize(500)}
                    variant={datasetSize === 500 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    500
                  </Button>
                  <Button
                    onClick={() => setDatasetSize(1000)}
                    variant={datasetSize === 1000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    1K
                  </Button>
                  <Button
                    onClick={() => setDatasetSize(5000)}
                    variant={datasetSize === 5000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    5K
                  </Button>
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

              {/* Features */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Features (Genes/Metabolites)</Label>
                <div className="grid grid-cols-3 gap-2">
                  <Button
                    onClick={() => setNFeatures(50)}
                    variant={nFeatures === 50 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    50
                  </Button>
                  <Button
                    onClick={() => setNFeatures(100)}
                    variant={nFeatures === 100 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    100
                  </Button>
                  <Button
                    onClick={() => setNFeatures(500)}
                    variant={nFeatures === 500 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    500
                  </Button>
                  <Button
                    onClick={() => setNFeatures(1000)}
                    variant={nFeatures === 1000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    1K
                  </Button>
                  <Button
                    onClick={() => setNFeatures(2000)}
                    variant={nFeatures === 2000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                    className="text-orange-600 border-orange-300"
                  >
                    2K ⚠️
                  </Button>
                </div>
              </div>

              {/* Groups */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Groups</Label>
                <div className="grid grid-cols-4 gap-2">
                  <Button
                    onClick={() => setNGroups(2)}
                    variant={nGroups === 2 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    2
                  </Button>
                  <Button
                    onClick={() => setNGroups(3)}
                    variant={nGroups === 3 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    3
                  </Button>
                  <Button
                    onClick={() => setNGroups(4)}
                    variant={nGroups === 4 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    4
                  </Button>
                  <Button
                    onClick={() => setNGroups(5)}
                    variant={nGroups === 5 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                  >
                    5
                  </Button>
                </div>
              </div>
            </div>

            {/* Second Row: Advanced Parameters */}
            <div className="grid grid-cols-1 lg:grid-cols-4 gap-4 items-end">
              {/* Downsampling Level */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Max Points</Label>
                <div className="grid grid-cols-2 gap-2">
                  <Button
                    onClick={() => setMaxPoints(1000)}
                    variant={maxPoints === 1000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 1000}
                  >
                    1K
                  </Button>
                  <Button
                    onClick={() => setMaxPoints(5000)}
                    variant={maxPoints === 5000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 5000}
                  >
                    5K
                  </Button>
                  <Button
                    onClick={() => setMaxPoints(10000)}
                    variant={maxPoints === 10000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 10000}
                  >
                    10K
                  </Button>
                  <Button
                    onClick={() => setMaxPoints(50000)}
                    variant={maxPoints === 50000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading || datasetSize < 50000}
                  >
                    50K
                  </Button>
                </div>
              </div>

              {/* Noise Level */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Noise Level: {noiseLevel.toFixed(2)}</Label>
                <Slider
                  value={[noiseLevel]}
                  onValueChange={(value) => setNoiseLevel(value[0])}
                  min={0.01}
                  max={1.0}
                  step={0.01}
                  className="w-full"
                  disabled={isLoading}
                />
              </div>

              {/* Batch Effect */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Batch Effect</Label>
                <Button
                  onClick={() => setAddBatchEffect(!addBatchEffect)}
                  variant={addBatchEffect ? "default" : "outline"}
                  size="sm"
                  disabled={isLoading}
                  className="w-full"
                >
                  {addBatchEffect ? "Enabled" : "Disabled"}
                </Button>
              </div>

              {/* Actions */}
              <div className="space-y-2">
                <Label className="text-sm font-medium">Actions</Label>
                <div className="flex gap-2">
                  <Button
                    onClick={resetParameters}
                    variant="outline"
                    size="sm"
                    disabled={isLoading}
                    title="Reset Parameters"
                  >
                    <RotateCcw className="h-4 w-4" />
                  </Button>
                  <Button
                    onClick={clearCache}
                    variant="outline"
                    size="sm"
                    disabled={isLoading}
                    title="Clear Cache"
                    className="text-red-600 hover:text-red-700"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                  <Button
                    onClick={downloadCSV}
                    variant="outline"
                    size="sm"
                    disabled={isLoading || !data.length}
                    title="Download CSV"
                  >
                    <Download className="h-4 w-4" />
                  </Button>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Plot Card */}
      <Card className="min-h-[700px]">
        <CardContent className="p-6">
          {isLoading ? (
            <div className="h-96 flex items-center justify-center">
              <div className="text-center">
                <Loader2 className="mx-auto h-12 w-12 animate-spin text-blue-500 mb-4" />
                {loadingType === 'generating' ? (
                  <>
                    <p className="text-lg mb-2">Computing PCA</p>
                    <p className="text-sm text-muted-foreground">Generating {datasetSize.toLocaleString()} samples with {nFeatures.toLocaleString()} features...</p>
                    <p className="text-xs text-muted-foreground mt-1">This dataset will be cached for future requests</p>
                  </>
                ) : (
                  <>
                    <p className="text-lg mb-2">Loading Cached PCA</p>
                    <p className="text-sm text-muted-foreground">Retrieving pre-computed principal components...</p>
                  </>
                )}
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
                responsive: true,
                showTips: false
              }}
              style={{ width: "100%", height: "650px" }}
            />
          ) : (
            <div className="h-96 flex items-center justify-center text-muted-foreground">
              <div className="text-center">
                <p className="text-lg mb-2">No data available</p>
                <p className="text-sm">Adjust parameters or check API connection</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Group Selection Controls */}
      {availableGroups.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-lg font-semibold">Group Visibility & Data Tables</CardTitle>
          </CardHeader>
          <CardContent className="p-6">
            <div className="space-y-4">
              {/* Group Toggle Buttons */}
              <div className="flex flex-wrap gap-2">
                <Label className="text-sm font-medium mr-4">Toggle Groups:</Label>
                {availableGroups.map((group, index) => {
                  const colors = [
                    'bg-red-500', 'bg-blue-500', 'bg-green-500', 'bg-amber-500',
                    'bg-violet-500', 'bg-pink-500', 'bg-cyan-500', 'bg-lime-500'
                  ]
                  const isVisible = visibleGroups.has(group)
                  return (
                    <Button
                      key={group}
                      onClick={() => toggleGroupVisibility(group)}
                      variant={isVisible ? "default" : "outline"}
                      size="sm"
                      className={`${isVisible ? colors[index % colors.length] + ' text-white' : ''}`}
                    >
                      {group} ({groupedTableData[group]?.length || 0})
                    </Button>
                  )
                })}
              </div>

              {/* Select All / Deselect All */}
              <div className="flex gap-2">
                <Button
                  onClick={() => setVisibleGroups(new Set(availableGroups))}
                  variant="outline"
                  size="sm"
                >
                  Show All Groups
                </Button>
                <Button
                  onClick={() => setVisibleGroups(new Set())}
                  variant="outline"
                  size="sm"
                >
                  Hide All Groups
                </Button>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Dynamic Tables for Each Visible Group */}
      {Array.from(visibleGroups).sort().map((group, index) => {
        const groupData = groupedTableData[group] || []
        const colors = [
          'border-red-500', 'border-blue-500', 'border-green-500', 'border-amber-500',
          'border-violet-500', 'border-pink-500', 'border-cyan-500', 'border-lime-500'
        ]
        const bgColors = [
          'bg-red-50', 'bg-blue-50', 'bg-green-50', 'bg-amber-50',
          'bg-violet-50', 'bg-pink-50', 'bg-cyan-50', 'bg-lime-50'
        ]

        return (
          <Card key={group} className={`border-l-4 ${colors[index % colors.length]} ${bgColors[index % bgColors.length]}`}>
            <CardHeader>
              <CardTitle className="text-lg font-semibold flex items-center justify-between">
                <span>{group} Data ({groupData.length} samples)</span>
                <div className="flex gap-2">
                  <Button
                    onClick={() => downloadGroupCSV(group, groupData)}
                    variant="outline"
                    size="sm"
                    title={`Download ${group} data as CSV`}
                  >
                    <Download className="h-4 w-4" />
                  </Button>
                  <Button
                    onClick={() => toggleGroupVisibility(group)}
                    variant="outline"
                    size="sm"
                    className="text-red-600 hover:text-red-700"
                    title="Hide this table"
                  >
                    Hide Table
                  </Button>
                </div>
              </CardTitle>
            </CardHeader>
            <CardContent className="p-6">
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left p-2 font-medium">Sample ID</th>
                      <th className="text-left p-2 font-medium">PC1</th>
                      <th className="text-left p-2 font-medium">PC2</th>
                      <th className="text-left p-2 font-medium">PC3</th>
                      {groupData.some(d => d.batch) && (
                        <th className="text-left p-2 font-medium">Batch</th>
                      )}
                    </tr>
                  </thead>
                  <tbody>
                    {groupData.slice(0, 50).map((point, idx) => (
                      <tr key={point.sample_id} className={idx % 2 === 0 ? 'bg-white' : 'bg-gray-50'}>
                        <td className="p-2 font-mono text-xs">{point.sample_id}</td>
                        <td className="p-2 font-mono text-xs">{point.pc1.toFixed(4)}</td>
                        <td className="p-2 font-mono text-xs">{point.pc2.toFixed(4)}</td>
                        <td className="p-2 font-mono text-xs">{point.pc3.toFixed(4)}</td>
                        {groupData.some(d => d.batch) && (
                          <td className="p-2 font-mono text-xs">{point.batch || '-'}</td>
                        )}
                      </tr>
                    ))}
                  </tbody>
                </table>
                {groupData.length > 50 && (
                  <div className="mt-4 text-center text-sm text-muted-foreground">
                    Showing first 50 of {groupData.length} samples
                  </div>
                )}
              </div>
            </CardContent>
          </Card>
        )
      })}
    </div>
  )
}