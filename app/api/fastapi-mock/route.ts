import { NextRequest, NextResponse } from "next/server"

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

function generateSyntheticData(size: number): VolcanoDataPoint[] {
  const metaboliteNames = [
    "1,3-Isoquinolinediol", "3,4-Dihydro-3-oxo-2H-(1,4)-benzoxazin-2-ylacetic acid",
    "(2-oxo-2,3-dihydro-1H-indol-3-yl)acetic acid", "Resedine", "Methionine sulfoxide",
    "trans-Urocanic acid", "Pro-Tyr", "Glu-Gly-Glu", "NP-024517", "Trp-Pro",
    "Biotin", "Pyridoxine", "Sulfocholic acid", "Pro-Pro", "Targinine",
    "L-Carnitine", "Taurine", "Creatine", "Adenosine", "Guanosine",
    "Cytidine", "Uridine", "Thymidine", "Inosine", "Xanthosine",
    "Hypoxanthine", "Xanthine", "Uric acid", "Allantoin", "Creatinine"
  ]
  
  const superclasses = [
    "Organic acids and derivatives", "Organoheterocyclic compounds",
    "Lipids and lipid-like molecules", "Others", "Nucleosides, nucleotides, and analogues"
  ]
  
  const classes = [
    "Carboxylic acids and derivatives", "Indoles and derivatives", "Benzoxazines",
    "Azolidines", "Azoles", "Biotin and derivatives", "Pyridines and derivatives",
    "Steroids and steroid derivatives", "Others", "Purine nucleosides"
  ]
  
  const data: VolcanoDataPoint[] = []
  
  for (let i = 0; i < size; i++) {
    const logFC = (Math.random() - 0.5) * 8 // Range -4 to 4
    
    // Realistic p-value distribution based on fold change
    let pValue: number
    if (Math.abs(logFC) > 1.5) {
      pValue = Math.random() * 0.1
    } else if (Math.abs(logFC) > 0.8) {
      pValue = Math.random() * 0.3
    } else {
      pValue = Math.random() * 0.8 + 0.2
    }
    
    const geneName = i < metaboliteNames.length ? metaboliteNames[i] : `Metabolite_${i + 1}`
    
    data.push({
      gene: geneName,
      logFC: Number(logFC.toFixed(4)),
      padj: Number(pValue.toFixed(6)),
      classyfireSuperclass: superclasses[Math.floor(Math.random() * superclasses.length)],
      classyfireClass: classes[Math.floor(Math.random() * classes.length)],
      category: "non_significant" // Will be categorized later
    })
  }
  
  return data
}

function categorizeAndFilter(
  data: VolcanoDataPoint[],
  pThreshold: number,
  logFcMin: number,
  logFcMax: number,
  searchTerm?: string
): VolcanoDataPoint[] {
  let filtered = data
  
  // Apply search filter
  if (searchTerm) {
    filtered = filtered.filter(row => 
      row.gene.toLowerCase().includes(searchTerm.toLowerCase())
    )
  }
  
  // Categorize points
  return filtered.map(row => ({
    ...row,
    category: 
      row.padj <= pThreshold && row.logFC < logFcMin ? "down" :
      row.padj <= pThreshold && row.logFC > logFcMax ? "up" :
      "non_significant"
  }))
}

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url)
    
    const pValueThreshold = Number(searchParams.get("p_value_threshold")) || 0.05
    const logFcMin = Number(searchParams.get("log_fc_min")) || -0.5
    const logFcMax = Number(searchParams.get("log_fc_max")) || 0.5
    const searchTerm = searchParams.get("search_term") || undefined
    const datasetSize = Number(searchParams.get("dataset_size")) || 10000
    
    // Simulate processing delay for realism
    await new Promise(resolve => setTimeout(resolve, 200))
    
    // Generate synthetic data
    const rawData = generateSyntheticData(datasetSize)
    
    // Apply filtering and categorization
    const processedData = categorizeAndFilter(
      rawData,
      pValueThreshold,
      logFcMin,
      logFcMax,
      searchTerm
    )
    
    // Calculate statistics
    const stats = {
      up_regulated: processedData.filter(d => d.category === "up").length,
      down_regulated: processedData.filter(d => d.category === "down").length,
      non_significant: processedData.filter(d => d.category === "non_significant").length
    }
    
    const response: VolcanoResponse = {
      data: processedData,
      stats,
      total_rows: rawData.length,
      filtered_rows: processedData.length
    }
    
    return NextResponse.json(response)
    
  } catch (error) {
    console.error("Error in FastAPI mock:", error)
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    )
  }
}