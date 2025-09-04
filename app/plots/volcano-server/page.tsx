"use client"

import type React from "react"

import { useState, useEffect, useMemo, useCallback } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Slider } from "@/components/ui/slider"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Download, Upload, Loader2, RotateCcw } from "lucide-react"
import { ServerVolcanoPlot } from "@/components/ServerVolcanoPlot"
import { parseCsv } from "@/lib/parseCsv"
import type { DegRow } from "@/lib/schema"
import TechExplainer from "@/components/TechExplainer"

function generateVolcanoData(size = 2000) {
  const metaboliteNames = [
    "1,3-Isoquinolinediol",
    "3,4-Dihydro-3-oxo-2H-(1,4)-benzoxazin-2-ylacetic acid",
    "(2-oxo-2,3-dihydro-1H-indol-3-yl)acetic acid",
    "Resedine",
    "Methionine sulfoxide",
    "trans-Urocanic acid",
    "Pro-Tyr",
    "Glu-Gly-Glu",
    "NP-024517",
    "Trp-Pro",
    "Biotin",
    "Pyridoxine",
    "Sulfocholic acid",
    "Pro-Pro",
    "Targinine",
    "L-Carnitine",
    "Taurine",
    "Creatine",
    "Adenosine",
    "Guanosine",
    "Cytidine",
    "Uridine",
    "Thymidine",
    "Inosine",
    "Xanthosine",
    "Hypoxanthine",
    "Xanthine",
    "Uric acid",
    "Allantoin",
    "Creatinine",
  ]

  const superclasses = [
    "Organic acids and derivatives",
    "Organoheterocyclic compounds",
    "Lipids and lipid-like molecules",
    "Others",
    "Nucleosides, nucleotides, and analogues",
  ]

  const classes = [
    "Carboxylic acids and derivatives",
    "Indoles and derivatives",
    "Benzoxazines",
    "Azolidines",
    "Azoles",
    "Biotin and derivatives",
    "Pyridines and derivatives",
    "Steroids and steroid derivatives",
    "Others",
    "Purine nucleosides",
  ]

  const syntheticData: DegRow[] = []

  for (let i = 0; i < size; i++) {
    const logFC = (Math.random() - 0.5) * 8 // Range from -4 to 4
    const basePValue = Math.random()

    let pValue: number
    if (Math.abs(logFC) > 1.5) {
      pValue = Math.random() * 0.1
    } else if (Math.abs(logFC) > 0.8) {
      pValue = Math.random() * 0.3
    } else {
      pValue = Math.random() * 0.8 + 0.2
    }

    syntheticData.push({
      gene: i < metaboliteNames.length ? metaboliteNames[i] : `Metabolite_${i + 1}`,
      logFC: Number(logFC.toFixed(4)),
      padj: Number(pValue.toFixed(6)),
      classyfireSuperclass: superclasses[Math.floor(Math.random() * superclasses.length)],
      classyfireClass: classes[Math.floor(Math.random() * classes.length)],
    })
  }

  return syntheticData
}

export default function VolcanoServerPage() {
  const [data, setData] = useState<DegRow[]>([])
  const [selectedDatasetSize, setSelectedDatasetSize] = useState<number>(10000)
  const [datasetCache, setDatasetCache] = useState<Map<number, DegRow[]>>(new Map())
  const [isLoading, setIsLoading] = useState(false)
  const [loadingDatasetSize, setLoadingDatasetSize] = useState<number | null>(null)
  const [isReady, setIsReady] = useState(false)
  const [pValue, setPValue] = useState(0.05)
  const [pValueDisplay, setPValueDisplay] = useState("0.05")
  const [logFCRange, setLogFCRange] = useState([-0.5, 0.5])
  const [geneSearch, setGeneSearch] = useState("")
  const [errors, setErrors] = useState<string[]>([])
  const [totalRows, setTotalRows] = useState(0)
  const [isUploadMode, setIsUploadMode] = useState(false)

  useEffect(() => {
    const generateData = async () => {
      if (datasetCache.has(selectedDatasetSize)) {
        console.log(`[v0] Loading ${selectedDatasetSize} points from cache`)
        const cachedData = datasetCache.get(selectedDatasetSize)!
        setData(cachedData)
        setTotalRows(cachedData.length)
        setErrors([])
        setTimeout(() => setIsReady(true), 300)
        return
      }

      setIsLoading(true)
      setIsReady(false)

      const delay = selectedDatasetSize > 50000 ? 2000 : selectedDatasetSize > 10000 ? 1000 : 500

      await new Promise((resolve) => setTimeout(resolve, delay))

      const initialData = generateVolcanoData(selectedDatasetSize)
      setDatasetCache((prev) => new Map(prev).set(selectedDatasetSize, initialData))
      setData(initialData)
      setTotalRows(initialData.length)
      setErrors([])
      setIsLoading(false)
      setTimeout(() => setIsReady(true), 500)

      console.log("[v0] Server-side data initialized. Total rows:", initialData.length)
    }

    if (!isUploadMode) {
      generateData()
    }
  }, [selectedDatasetSize, isUploadMode, datasetCache])

  const filteredData = useMemo(() => {
    if (!data || data.length === 0) {
      console.log("[v0] Filtering data. Total rows: 0")
      return []
    }

    console.log(
      "[v0] Filtering data. Total rows:",
      data.length,
      "P-value threshold:",
      pValue,
      "LogFC range:",
      logFCRange,
    )

    const filtered = data.filter((row) => {
      const passesGeneSearch = !geneSearch || row.gene.toLowerCase().includes(geneSearch.toLowerCase())
      return passesGeneSearch
    })

    console.log("[v0] Filtered data length:", filtered.length)
    return filtered
  }, [data, pValue, logFCRange, geneSearch])

  const { downRegulated, upRegulated } = useMemo(() => {
    const down = filteredData.filter((row) => {
      const logFC = Number(row.logFC) || 0
      const padj = Number(row.padj) || 1
      return padj <= pValue && logFC < logFCRange[0]
    })

    const up = filteredData.filter((row) => {
      const logFC = Number(row.logFC) || 0
      const padj = Number(row.padj) || 1
      return padj <= pValue && logFC > logFCRange[1]
    })

    return { downRegulated: down, upRegulated: up }
  }, [filteredData, pValue, logFCRange])

  const nonSignificant = useMemo(() => {
    return filteredData.filter((row) => {
      const logFC = Number(row.logFC) || 0
      const padj = Number(row.padj) || 1
      return padj > pValue || (logFC >= logFCRange[0] && logFC <= logFCRange[1])
    })
  }, [filteredData, pValue, logFCRange])

  const handleFileUpload = useCallback(async (file: File) => {
    console.log("[v0] handleFileUpload called with:", file.name)
    setIsLoading(true)
    setIsUploadMode(true)
    try {
      console.log("[v0] Reading file text...")
      const text = await file.text()
      console.log("[v0] File text length:", text.length)

      console.log("[v0] Calling parseCsv...")
      const result = await parseCsv(text)
      console.log("[v0] Parse result:", result)

      setData(result.data)
      setErrors(result.errors)
      setTotalRows(result.totalRows)
      setIsReady(true)
      console.log("[v0] Data set successfully, length:", result.data.length)
    } catch (error) {
      console.error("[v0] Error parsing file:", error)
      setErrors([`Failed to parse file: ${error instanceof Error ? error.message : "Unknown error"}`])
    } finally {
      setIsLoading(false)
    }
  }, [])

  const handleFileInput = useCallback(
    (e: React.ChangeEvent<HTMLInputElement>) => {
      console.log("[v0] File input triggered")
      const file = e.target.files?.[0]
      console.log("[v0] Selected file:", file?.name, file?.type, file?.size)
      if (file) {
        console.log("[v0] Calling handleFileUpload")
        handleFileUpload(file)
      } else {
        console.log("[v0] No file selected")
      }
      e.target.value = ""
    },
    [handleFileUpload],
  )

  const validatePValue = (value: string) => {
    const num = Number.parseFloat(value)
    if (isNaN(num)) return 0.05
    return Math.max(0, Math.min(1, num))
  }

  const handlePValueChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value
    setPValueDisplay(value)
  }

  const handlePValueBlur = () => {
    const validatedValue = validatePValue(pValueDisplay)
    setPValue(validatedValue)
    setPValueDisplay(validatedValue.toString())
  }

  const handleReset = () => {
    setPValue(0.05)
    setPValueDisplay("0.05")
    setLogFCRange([-0.5, 0.5])
    setGeneSearch("")
  }

  const downloadCSV = () => {
    const headers = ["Metabolite name", "ClassyFire Superclass", "ClassyFire Class", "log2(FC)", "p-Value"]
    const csvContent = [
      headers.join(","),
      ...filteredData.map((row) =>
        [
          `"${row.gene}"`,
          `"${row.classyfireSuperclass || ""}"`,
          `"${row.classyfireClass || ""}"`,
          row.logFC.toFixed(6),
          row.padj.toFixed(6),
        ].join(","),
      ),
    ].join("\n")

    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "server_volcano_filtered.csv"
    a.click()
    URL.revokeObjectURL(url)
  }

  const downloadPlotPNG = useCallback(() => {
    const plotlyDownloadButton = document.querySelector('[data-title="Download plot as a png"]') as HTMLElement
    if (plotlyDownloadButton) {
      plotlyDownloadButton.click()
    }
  }, [])

  const downloadTableCSV = (data: DegRow[], filename: string) => {
    const headers = ["Metabolite name", "ClassyFire Superclass", "ClassyFire Class", "Log2(FC)", "p-Value"]
    const csvContent = [
      headers.join(","),
      ...data.map((row) =>
        [
          `"${row.gene || ""}"`,
          `"${row.classyfireSuperclass || ""}"`,
          `"${row.classyfireClass || ""}"`,
          row.logFC || "",
          row.padj || "",
        ].join(","),
      ),
    ].join("\n")

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" })
    const link = document.createElement("a")
    const url = URL.createObjectURL(blob)
    link.setAttribute("href", url)
    link.setAttribute("download", filename)
    link.style.visibility = "hidden"
    document.body.appendChild(link)
    link.click()
    document.body.removeChild(link)
  }

  const handleDatasetSizeChange = async (size: number) => {
    setLoadingDatasetSize(size)
    setSelectedDatasetSize(size)
    setIsUploadMode(false)

    setTimeout(() => {
      setLoadingDatasetSize(null)
    }, 100)
  }

  return (
    <div className="flex-1 flex flex-col h-full">
      <div className="bg-white border-b border-slate-200 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-slate-900">Volcano Plot (Server-Side)</h1>
            <p className="text-sm text-slate-600 mt-1">Interactive volcano plot with server-side data processing</p>
          </div>
          {isLoading && (
            <div className="flex items-center gap-2 text-sm text-blue-600">
              <div className="animate-spin rounded-full h-4 w-4 border-2 border-blue-600 border-t-transparent"></div>
              <span>{isUploadMode ? "Processing CSV File..." : "Generating dataset..."}</span>
            </div>
          )}
          {isReady && !isLoading && (
            <div className="flex items-center gap-2 text-sm text-green-600">
              <div className="h-2 w-2 bg-green-600 rounded-full"></div>
              <span>Ready!</span>
            </div>
          )}
        </div>
      </div>

      <div className="flex-1 p-6 bg-slate-50 overflow-auto">
        {isLoading && (
          <div className="fixed inset-0 bg-white/80 backdrop-blur-sm z-50 flex items-center justify-center">
            <div className="bg-white rounded-lg shadow-lg p-6 max-w-sm mx-4">
              <div className="flex items-center gap-3 mb-4">
                <div className="animate-spin rounded-full h-6 w-6 border-2 border-blue-600 border-t-transparent"></div>
                <h3 className="text-lg font-semibold">{isUploadMode ? "Processing CSV File" : "Generating Dataset"}</h3>
              </div>
              <p className="text-sm text-slate-600 mb-2">
                {isUploadMode
                  ? "Parsing and processing your CSV file..."
                  : `Creating ${selectedDatasetSize.toLocaleString()} synthetic metabolite data points...`}
              </p>
              <p className="text-xs text-slate-500">
                {isUploadMode
                  ? "Please wait while we process your data"
                  : selectedDatasetSize > 50000
                    ? "Large dataset - this may take a moment"
                    : selectedDatasetSize > 10000
                      ? "Processing data..."
                      : "Almost ready..."}
              </p>
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 xl:grid-cols-4 gap-6">
          <div className="xl:col-span-1 space-y-4">
            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium">Data Upload</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="border-2 border-dashed border-slate-300 rounded-lg p-6 text-center">
                  <Upload className="h-8 w-8 text-slate-400 mx-auto mb-2" />
                  <p className="text-sm text-slate-600 mb-2">Upload your CSV/TSV file</p>
                  <p className="text-xs text-slate-500 mb-3">Server-side processing</p>
                  <div className="relative">
                    <input
                      type="file"
                      accept=".csv,.tsv"
                      onChange={handleFileInput}
                      className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                      disabled={isLoading}
                    />
                    <Button size="sm" variant="outline" disabled={isLoading} className="gap-2 bg-transparent">
                      {isLoading && isUploadMode ? (
                        <>
                          <Loader2 className="h-4 w-4 animate-spin" />
                          Processing...
                        </>
                      ) : (
                        <>
                          <Upload className="h-4 w-4" />
                          Upload CSV/TSV
                        </>
                      )}
                    </Button>
                  </div>
                </div>

                <div className="space-y-2 pt-2 border-t">
                  <p className="text-xs text-slate-500 text-center">Or select synthetic dataset:</p>
                  <div className="grid grid-cols-1 gap-2">
                    <Button
                      size="sm"
                      className="w-full"
                      variant={selectedDatasetSize === 10000 && !isUploadMode ? "default" : "outline"}
                      onClick={() => handleDatasetSizeChange(10000)}
                      disabled={isLoading}
                    >
                      {loadingDatasetSize === 10000 ? (
                        <div className="flex items-center gap-2">
                          <div className="animate-spin rounded-full h-3 w-3 border-2 border-current border-t-transparent"></div>
                          <span>Loading...</span>
                        </div>
                      ) : (
                        "10K points"
                      )}
                    </Button>
                    <Button
                      size="sm"
                      className="w-full"
                      variant={selectedDatasetSize === 50000 && !isUploadMode ? "default" : "outline"}
                      onClick={() => handleDatasetSizeChange(50000)}
                      disabled={isLoading}
                    >
                      {loadingDatasetSize === 50000 ? (
                        <div className="flex items-center gap-2">
                          <div className="animate-spin rounded-full h-3 w-3 border-2 border-current border-t-transparent"></div>
                          <span>Loading...</span>
                        </div>
                      ) : (
                        "50K points"
                      )}
                    </Button>
                    <Button
                      size="sm"
                      className="w-full"
                      variant={selectedDatasetSize === 100000 && !isUploadMode ? "default" : "outline"}
                      onClick={() => handleDatasetSizeChange(100000)}
                      disabled={isLoading}
                    >
                      {loadingDatasetSize === 100000 ? (
                        <div className="flex items-center gap-2">
                          <div className="animate-spin rounded-full h-3 w-3 border-2 border-current border-t-transparent"></div>
                          <span>Loading...</span>
                        </div>
                      ) : (
                        "100K points"
                      )}
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>

            {errors.length > 0 && (
              <Card className="border-orange-200 bg-orange-50">
                <CardHeader className="pb-3">
                  <CardTitle className="text-sm font-medium text-orange-800">Parsing Errors</CardTitle>
                </CardHeader>
                <CardContent>
                  <div className="text-xs text-orange-700 space-y-1">
                    {errors.slice(0, 3).map((error, i) => (
                      <p key={i}>{error}</p>
                    ))}
                    {errors.length > 3 && <p>... and {errors.length - 3} more errors</p>}
                  </div>
                </CardContent>
              </Card>
            )}

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium">Filtering Controls</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label className="text-xs font-medium">p-Value Threshold</Label>
                  <Input
                    type="number"
                    value={pValueDisplay}
                    onChange={handlePValueChange}
                    onBlur={handlePValueBlur}
                    min={0}
                    max={1}
                    step={0.001}
                    className="w-full text-xs"
                    placeholder="0.000 - 1.000"
                    disabled={isLoading}
                  />
                </div>

                <div className="space-y-3">
                  <Label className="text-xs font-medium">Log2(FC) Range</Label>
                  <div className="px-2">
                    <div className="flex justify-between items-center mb-2">
                      <div className="text-xs font-semibold text-red-600 bg-red-50 px-2 py-1 rounded">
                        {logFCRange[0].toFixed(2)}
                      </div>
                      <div className="text-xs font-semibold text-red-600 bg-red-50 px-2 py-1 rounded">
                        {logFCRange[1].toFixed(2)}
                      </div>
                    </div>

                    <div className="relative">
                      <div className="absolute top-1/2 transform -translate-y-1/2 w-full h-2 bg-slate-200 rounded-full"></div>
                      <div
                        className="absolute top-1/2 transform -translate-y-1/2 h-2 bg-red-200 rounded-l-full"
                        style={{
                          left: "0%",
                          width: `${((logFCRange[0] + 5) / 10) * 100}%`,
                        }}
                      ></div>
                      <div
                        className="absolute top-1/2 transform -translate-y-1/2 h-2 bg-red-200 rounded-r-full"
                        style={{
                          left: `${((logFCRange[1] + 5) / 10) * 100}%`,
                          width: `${100 - ((logFCRange[1] + 5) / 10) * 100}%`,
                        }}
                      ></div>
                      <Slider
                        value={logFCRange}
                        onValueChange={setLogFCRange}
                        min={-5}
                        max={5}
                        step={0.1}
                        className="relative w-full"
                        disabled={isLoading}
                      />
                    </div>
                    <div className="flex justify-between text-xs text-slate-500 mt-1">
                      <span>-5.00</span>
                      <span>5.00</span>
                    </div>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label className="text-xs font-medium">Search Metabolite</Label>
                  <Input
                    type="text"
                    value={geneSearch}
                    onChange={(e) => setGeneSearch(e.target.value)}
                    className="w-full text-xs"
                    placeholder="Enter metabolite name..."
                    disabled={isLoading}
                  />
                </div>

                <Button
                  size="sm"
                  variant="outline"
                  className="w-full bg-transparent"
                  onClick={handleReset}
                  disabled={isLoading}
                >
                  <RotateCcw className="h-3 w-3 mr-2" />
                  Reset Filters
                </Button>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <CardTitle className="text-sm font-medium">Dataset Info</CardTitle>
              </CardHeader>
              <CardContent>
                <div className="space-y-2 text-xs">
                  <div className="flex justify-between">
                    <span className="text-slate-600">Total rows:</span>
                    <span className="font-medium">{totalRows}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-600">Down-regulated:</span>
                    <span className="font-medium text-blue-600">{downRegulated.length}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-600">Up-regulated:</span>
                    <span className="font-medium text-red-600">{upRegulated.length}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-600">Rest:</span>
                    <span className="font-medium text-gray-600">{nonSignificant.length}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-600">Processing:</span>
                    <span className="font-medium text-teal-600">Server-side</span>
                  </div>
                </div>

                <Button
                  size="sm"
                  variant="outline"
                  className="w-full mt-4 bg-transparent"
                  onClick={downloadCSV}
                  disabled={isLoading}
                >
                  <Download className="h-3 w-3 mr-2" />
                  Download filtered CSV
                </Button>

                <Button
                  size="sm"
                  variant="outline"
                  className="w-full mt-2 bg-transparent"
                  onClick={downloadPlotPNG}
                  disabled={isLoading || filteredData.length === 0}
                >
                  <Download className="h-3 w-3 mr-2" />
                  Download plot PNG
                </Button>
              </CardContent>
            </Card>
          </div>

          <div className="xl:col-span-3">
            <Card className="min-h-[600px]">
              <CardContent className="p-6 h-full">
                {isLoading ? (
                  <div className="h-full flex items-center justify-center">
                    <div className="text-center">
                      <div className="animate-spin rounded-full h-8 w-8 border-2 border-blue-600 border-t-transparent mx-auto mb-4"></div>
                      <p className="text-sm text-slate-600">Preparing visualization...</p>
                    </div>
                  </div>
                ) : filteredData.length > 0 ? (
                  <ServerVolcanoPlot
                    data={filteredData}
                    logFcMin={logFCRange[0]}
                    logFcMax={logFCRange[1]}
                    padjThreshold={pValue}
                  />
                ) : (
                  <div className="h-96 flex items-center justify-center text-slate-500">
                    <div className="text-center">
                      <Upload className="mx-auto h-12 w-12 mb-4" />
                      <p className="text-lg mb-2">Upload a CSV/TSV file to view the volcano plot</p>
                      <p className="text-sm">Expected columns: gene/Metabolite name, logFC/log2(FC), padj/p-Value</p>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>

        {(data.length > 0 || errors.length > 0) && (
          <div className="text-sm text-muted-foreground text-center space-y-1">
            <div>Total rows: {totalRows}</div>
            <div>
              Down-regulated: <span className="text-blue-600 font-medium">{downRegulated.length}</span> | Up-regulated:{" "}
              <span className="text-red-600 font-medium">{upRegulated.length}</span> | Rest:{" "}
              <span className="text-gray-600 font-medium">{nonSignificant.length}</span>
            </div>
            {data.length > 0 && filteredData.length === 0 && (
              <span className="text-orange-600 ml-2">(No genes pass current p-value threshold of {pValue})</span>
            )}
          </div>
        )}

        {filteredData.length > 0 && (downRegulated.length > 0 || upRegulated.length > 0) && (
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mt-6">
            <Card>
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg font-semibold">Down-regulated metabolites (Server)</CardTitle>
                  <Button
                    onClick={() => downloadTableCSV(downRegulated, "server-down-regulated-metabolites.csv")}
                    variant="outline"
                    size="sm"
                    className="gap-2"
                    disabled={downRegulated.length === 0 || isLoading}
                  >
                    <Download className="h-4 w-4" />
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                <div className="max-h-96 overflow-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className="text-sm">Metabolite name</TableHead>
                        <TableHead className="text-sm">ClassyFire Superclass</TableHead>
                        <TableHead className="text-sm">ClassyFire Class</TableHead>
                        <TableHead className="text-sm">Log2(FC)</TableHead>
                        <TableHead className="text-sm">p-Value</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {downRegulated.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                            No down-regulated metabolites found
                          </TableCell>
                        </TableRow>
                      ) : (
                        downRegulated.map((row, index) => (
                          <TableRow key={index}>
                            <TableCell className="text-sm font-medium">{row.gene || "-"}</TableCell>
                            <TableCell className="text-sm">{row.classyfireSuperclass || "-"}</TableCell>
                            <TableCell className="text-sm">{row.classyfireClass || "-"}</TableCell>
                            <TableCell className="text-sm font-mono">{Number(row.logFC).toFixed(4)}</TableCell>
                            <TableCell className="text-sm font-mono">{Number(row.padj).toFixed(4)}</TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader className="pb-3">
                <div className="flex items-center justify-between">
                  <CardTitle className="text-lg font-semibold">Up-regulated metabolites (Server)</CardTitle>
                  <Button
                    onClick={() => downloadTableCSV(upRegulated, "server-up-regulated-metabolites.csv")}
                    variant="outline"
                    size="sm"
                    className="gap-2"
                    disabled={upRegulated.length === 0 || isLoading}
                  >
                    <Download className="h-4 w-4" />
                  </Button>
                </div>
              </CardHeader>
              <CardContent>
                <div className="max-h-96 overflow-auto">
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead className="text-sm">Metabolite name</TableHead>
                        <TableHead className="text-sm">ClassyFire Superclass</TableHead>
                        <TableHead className="text-sm">ClassyFire Class</TableHead>
                        <TableHead className="text-sm">Log2(FC)</TableHead>
                        <TableHead className="text-sm">p-Value</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {upRegulated.length === 0 ? (
                        <TableRow>
                          <TableCell colSpan={5} className="text-center text-muted-foreground py-8">
                            No up-regulated metabolites found
                          </TableCell>
                        </TableRow>
                      ) : (
                        upRegulated.map((row, index) => (
                          <TableRow key={index}>
                            <TableCell className="text-sm font-medium">{row.gene || "-"}</TableCell>
                            <TableCell className="text-sm">{row.classyfireSuperclass || "-"}</TableCell>
                            <TableCell className="text-sm">{row.classyfireClass || "-"}</TableCell>
                            <TableCell className="text-sm font-mono">{Number(row.logFC).toFixed(4)}</TableCell>
                            <TableCell className="text-sm font-mono">{Number(row.padj).toFixed(4)}</TableCell>
                          </TableRow>
                        ))
                      )}
                    </TableBody>
                  </Table>
                </div>
              </CardContent>
            </Card>
          </div>
        )}

        <TechExplainer type="server" />
      </div>
    </div>
  )
}
