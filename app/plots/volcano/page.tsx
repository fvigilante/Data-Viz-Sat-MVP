"use client"

import { useMemo } from "react"
import type React from "react"
import { useCallback } from "react"
import { useEffect } from "react"
import { useState } from "react"
import { Label } from "@/components/ui/label"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Slider } from "@/components/ui/slider"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Download, RotateCcw, Upload, Loader2, CheckCircle } from "lucide-react"
import { parseCsv } from "@/lib/parseCsv"
import type { DegRow } from "@/lib/schema"
import dynamic from "next/dynamic"

const VolcanoPlot = dynamic(() => import("@/components/VolcanoPlot"), { ssr: false })

export default function VolcanoPage() {
  const [data, setData] = useState<DegRow[]>([])
  const [filteredData, setFilteredData] = useState<DegRow[]>([])
  const [errors, setErrors] = useState<string[]>([])
  const [totalRows, setTotalRows] = useState(0)
  const [selectedDatasetSize, setSelectedDatasetSize] = useState<number | null>(null)

  const [datasetCache, setDatasetCache] = useState<Map<number, DegRow[]>>(new Map())

  const [logFCRange, setLogFCRange] = useState([-0.5, 0.5])
  const [pValue, setPValue] = useState(0.05)
  const [geneSearch, setGeneSearch] = useState("")

  const [isLoading, setIsLoading] = useState(false)
  const [loadingDatasetSize, setLoadingDatasetSize] = useState<number | null>(null)
  const [isDataReady, setIsDataReady] = useState(false)
  const [pValueInput, setPValueInput] = useState(pValue.toString())

  useEffect(() => {
    console.log(
      "[v0] Filtering data. Total rows:",
      data.length,
      "P-value threshold:",
      pValue,
      "LogFC range:",
      logFCRange,
      "Gene search:",
      geneSearch,
    )
    const filtered = data.filter((row) => {
      const passesGeneSearch = !geneSearch || row.gene.toLowerCase().includes(geneSearch.toLowerCase())
      return passesGeneSearch
    })
    console.log("[v0] Filtered data length:", filtered.length)
    setFilteredData(filtered)
  }, [data, pValue, logFCRange, geneSearch]) // Keep all dependencies for consistency

  useEffect(() => {
    setPValueInput(pValue.toString())
  }, [pValue])

  const loadExampleDataset = useCallback(
    async (size: number) => {
      if (datasetCache.has(size)) {
        console.log(`[v0] Loading ${size} points from cache`)
        const cachedData = datasetCache.get(size)!
        setData(cachedData)
        setErrors([])
        setTotalRows(cachedData.length)
        setSelectedDatasetSize(size)
        setTimeout(() => setIsDataReady(true), 300)
        return
      }

      setIsLoading(true)
      setLoadingDatasetSize(size)
      setIsDataReady(false)
      setSelectedDatasetSize(size)
      try {
        const syntheticData: DegRow[] = []

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

        const delay = Math.max(500, size / 100) // Minimum 500ms, scales with dataset size
        await new Promise((resolve) => setTimeout(resolve, delay))

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

        setDatasetCache((prev) => new Map(prev).set(size, syntheticData))

        setData(syntheticData)
        setErrors([])
        setTotalRows(syntheticData.length)
        setTimeout(() => setIsDataReady(true), 500)
      } catch (error) {
        console.error("Error generating example dataset:", error)
        setErrors([`Failed to generate example dataset: ${error instanceof Error ? error.message : "Unknown error"}`])
      } finally {
        setIsLoading(false)
        setLoadingDatasetSize(null)
      }
    },
    [datasetCache],
  )

  const resetView = useCallback(() => {
    setLogFCRange([-0.5, 0.5])
    setPValue(0.05)
    setGeneSearch("")
  }, [])

  const downloadPlot = useCallback(() => {
    const plotlyDownloadButton = document.querySelector('[data-title="Download plot as a png"]') as HTMLElement
    if (plotlyDownloadButton) {
      plotlyDownloadButton.click()
    }
  }, [])

  const handleFileUpload = useCallback(async (file: File) => {
    console.log("[v0] handleFileUpload called with:", file.name)
    setIsLoading(true)
    setSelectedDatasetSize(null)
    try {
      console.log("[v0] Reading file text...")
      const text = await file.text()
      console.log("[v0] File text length:", text.length)
      console.log("[v0] First 200 characters:", text.substring(0, 200))

      console.log("[v0] Calling parseCsv...")
      const result = await parseCsv(text)
      console.log("[v0] Parse result:", result)

      setData(result.data)
      setErrors(result.errors)
      setTotalRows(result.totalRows)
      console.log("[v0] Data set successfully, length:", result.data.length)
    } catch (error) {
      console.error("[v0] Error parsing file:", error)
      setErrors([`Failed to parse file: ${error instanceof Error ? error.message : "Unknown error"}`])
    } finally {
      setIsLoading(false)
    }
  }, [])

  const handleDragOver = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsLoading(true)
  }, [])

  const handleDragLeave = useCallback((e: React.DragEvent) => {
    e.preventDefault()
    setIsLoading(false)
  }, [])

  const handleDrop = useCallback(
    (e: React.DragEvent) => {
      e.preventDefault()
      setIsLoading(false)

      const files = Array.from(e.dataTransfer.files)
      const csvFile = files.find((file) => file.name.endsWith(".csv") || file.name.endsWith(".tsv"))

      if (csvFile) {
        handleFileUpload(csvFile)
      }
    },
    [handleFileUpload],
  )

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

  const handlePValueChange = useCallback((value: string) => {
    if (value === "") {
      return
    }

    const numValue = Number(value)

    if (isNaN(numValue)) {
      return
    }

    let clampedValue = numValue
    if (numValue < 0) {
      clampedValue = 0
    } else if (numValue > 1) {
      clampedValue = 1
    }

    setPValue(clampedValue)
  }, [])

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

  const downloadCSV = useCallback((data: DegRow[], filename: string) => {
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
  }, [])

  return (
    <div className="p-6 space-y-6">
      {(isLoading || isDataReady) && (
        <Card className="border-l-4 border-l-blue-500">
          <CardContent className="p-4">
            <div className="flex items-center gap-3">
              {isLoading ? (
                <>
                  <Loader2 className="h-5 w-5 animate-spin text-blue-500" />
                  <div>
                    <p className="font-medium text-sm">
                      Generating {loadingDatasetSize?.toLocaleString()} synthetic metabolite data points...
                    </p>
                    <p className="text-xs text-muted-foreground">
                      Please wait while we create realistic volcano plot data
                    </p>
                  </div>
                </>
              ) : isDataReady ? (
                <>
                  <CheckCircle className="h-5 w-5 text-green-500" />
                  <div>
                    <p className="font-medium text-sm text-green-700">
                      Ready! Dataset with {data.length.toLocaleString()} points loaded successfully
                    </p>
                    <p className="text-xs text-muted-foreground">
                      You can now navigate and explore the volcano plot results
                    </p>
                  </div>
                </>
              ) : null}
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardContent className="p-6">
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4 items-end">
            <div className="space-y-2">
              <Label className="text-sm font-medium">p-Value</Label>
              <Input
                type="number"
                value={pValueInput}
                onChange={(e) => {
                  setPValueInput(e.target.value)
                  handlePValueChange(e.target.value)
                }}
                onBlur={() => {
                  setPValueInput(pValue.toString())
                }}
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
                value={geneSearch}
                onChange={(e) => setGeneSearch(e.target.value)}
                className="w-full"
                placeholder="Enter metabolite name..."
                disabled={isLoading}
              />
            </div>

            <div className="space-y-2 col-span-2">
              <div className="relative">
                <Label className="text-sm font-medium mb-3 block">Log2(FC)</Label>
                <div className="relative px-3">
                  <div className="flex justify-between items-center mb-3 relative">
                    <div
                      className="absolute bg-card px-2 py-1 text-xs font-semibold rounded shadow-sm border text-destructive"
                      style={{
                        left: `${((logFCRange[0] + 5) / 10) * 100}%`,
                        transform: "translateX(-50%)",
                        top: "-8px",
                      }}
                    >
                      {logFCRange[0].toFixed(2)}
                    </div>
                    <div
                      className="absolute bg-card px-2 py-1 text-xs font-semibold rounded shadow-sm border text-destructive"
                      style={{
                        left: `${((logFCRange[1] + 5) / 10) * 100}%`,
                        transform: "translateX(-50%)",
                        top: "-8px",
                      }}
                    >
                      {logFCRange[1].toFixed(2)}
                    </div>
                  </div>

                  <div className="relative">
                    <div className="relative">
                      <div className="absolute top-1/2 transform -translate-y-1/2 w-full h-2 bg-muted rounded-full"></div>
                      <div
                        className="absolute top-1/2 transform -translate-y-1/2 h-2 bg-destructive/20 rounded-l-full"
                        style={{
                          left: "0%",
                          width: `${((logFCRange[0] + 5) / 10) * 100}%`,
                        }}
                      ></div>
                      <div
                        className="absolute top-1/2 transform -translate-y-1/2 h-2 bg-destructive/20 rounded-r-full"
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
                        className="relative w-full [&_[role=slider]]:bg-destructive [&_[role=slider]]:border-destructive [&_[role=slider]]:shadow-lg [&_[role=slider]]:w-5 [&_[role=slider]]:h-5 [&_[role=slider]]:border-2 [&_[role=slider]]:border-background [&_.relative]:h-2 [&_[data-orientation=horizontal]]:bg-transparent"
                        disabled={isLoading}
                      />
                    </div>
                    <div className="flex justify-between text-xs text-muted-foreground mt-2 font-medium">
                      <span>-5.00</span>
                      <span>5.00</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-between mt-4 pt-4 border-t">
            <div className="flex items-center gap-4">
              <div className="space-y-2">
                <Label className="text-sm font-medium text-muted-foreground">Select synthetic dataset</Label>
                <div className="flex items-center gap-2">
                  <Button
                    onClick={() => loadExampleDataset(1000)}
                    variant={selectedDatasetSize === 1000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                    className="gap-2"
                  >
                    {loadingDatasetSize === 1000 ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      "1K points"
                    )}
                  </Button>
                  <Button
                    onClick={() => loadExampleDataset(10000)}
                    variant={selectedDatasetSize === 10000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                    className="gap-2"
                  >
                    {loadingDatasetSize === 10000 ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      "10K points"
                    )}
                  </Button>
                  <Button
                    onClick={() => loadExampleDataset(50000)}
                    variant={selectedDatasetSize === 50000 ? "default" : "outline"}
                    size="sm"
                    disabled={isLoading}
                    className="gap-2"
                  >
                    {loadingDatasetSize === 50000 ? (
                      <>
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Generating...
                      </>
                    ) : (
                      "50K points"
                    )}
                  </Button>
                </div>
              </div>

              <div className="relative">
                <input
                  type="file"
                  accept=".csv,.tsv"
                  onChange={handleFileInput}
                  className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                  disabled={isLoading}
                />
                <Button variant="outline" size="sm" className="gap-2 bg-transparent" disabled={isLoading}>
                  <Upload className="h-4 w-4" />
                  Upload CSV/TSV
                </Button>
              </div>

              <Button
                onClick={resetView}
                variant="outline"
                size="sm"
                className="gap-2 bg-transparent"
                disabled={isLoading}
              >
                <RotateCcw className="h-4 w-4" />
                Reset view
              </Button>
            </div>

            <Button
              onClick={downloadPlot}
              variant="outline"
              size="sm"
              className="gap-2 bg-transparent"
              disabled={isLoading}
            >
              <Download className="h-4 w-4" />
              Download PNG
            </Button>
          </div>
        </CardContent>
      </Card>

      {errors.length > 0 && (
        <Alert>
          <AlertDescription>
            <div className="text-sm">
              <p className="font-medium mb-1">Parsing errors:</p>
              {errors.slice(0, 3).map((error, i) => (
                <p key={i}>{error}</p>
              ))}
              {errors.length > 3 && <p>... and {errors.length - 3} more errors</p>}
            </div>
          </AlertDescription>
        </Alert>
      )}

      <Card className="min-h-[600px]">
        <CardContent className="p-6">
          {filteredData.length > 0 ? (
            <VolcanoPlot data={filteredData} logFcMin={logFCRange[0]} logFcMax={logFCRange[1]} padjThreshold={pValue} />
          ) : (
            <div className="h-96 flex items-center justify-center text-muted-foreground">
              <div className="text-center">
                <Upload className="mx-auto h-12 w-12 mb-4" />
                <p className="text-lg mb-2">Upload a CSV/TSV file to view the volcano plot</p>
                <p className="text-sm">Expected columns: gene/Metabolite name, logFC/log2(FC), padj/p-Value</p>
              </div>
            </div>
          )}
        </CardContent>
      </Card>

      {filteredData.length > 0 && (downRegulated.length > 0 || upRegulated.length > 0) && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between">
                <CardTitle className="text-lg font-semibold">Down-regulated metabolites</CardTitle>
                <Button
                  onClick={() => downloadCSV(downRegulated, "down-regulated-metabolites.csv")}
                  variant="outline"
                  size="sm"
                  className="gap-2"
                  disabled={downRegulated.length === 0}
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
                      <TableHead className="text-sm font-semibold">Metabolite name</TableHead>
                      <TableHead className="text-sm font-semibold">ClassyFire Superclass</TableHead>
                      <TableHead className="text-sm font-semibold">ClassyFire Class</TableHead>
                      <TableHead className="text-sm font-semibold">Log2(FC)</TableHead>
                      <TableHead className="text-sm font-semibold">p-Value</TableHead>
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
                <CardTitle className="text-lg font-semibold">Up-regulated metabolites</CardTitle>
                <Button
                  onClick={() => downloadCSV(upRegulated, "up-regulated-metabolites.csv")}
                  variant="outline"
                  size="sm"
                  className="gap-2"
                  disabled={upRegulated.length === 0}
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
                      <TableHead className="text-sm font-semibold">Metabolite name</TableHead>
                      <TableHead className="text-sm font-semibold">ClassyFire Superclass</TableHead>
                      <TableHead className="text-sm font-semibold">ClassyFire Class</TableHead>
                      <TableHead className="text-sm font-semibold">Log2(FC)</TableHead>
                      <TableHead className="text-sm font-semibold">p-Value</TableHead>
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

      {(data.length > 0 || errors.length > 0) && (
        <div className="text-sm text-muted-foreground text-center space-y-1">
          <div>Total rows: {totalRows}</div>
          {geneSearch && (
            <div>
              Search results: <span className="text-purple-600 font-medium">{filteredData.length}</span> metabolites found for "{geneSearch}"
            </div>
          )}
          <div>
            Down-regulated: <span className="text-blue-600 font-medium">{downRegulated.length}</span> | Up-regulated:{" "}
            <span className="text-red-600 font-medium">{upRegulated.length}</span> | Rest:{" "}
            <span className="text-gray-600 font-medium">{nonSignificant.length}</span>
          </div>
          {data.length > 0 && filteredData.length === 0 && !geneSearch && (
            <span className="text-orange-600 ml-2">(No genes pass current p-value threshold of {pValue})</span>
          )}
          {data.length > 0 && filteredData.length === 0 && geneSearch && (
            <span className="text-orange-600 ml-2">(No metabolites found matching "{geneSearch}")</span>
          )}
        </div>
      )}
    </div>
  )
}
