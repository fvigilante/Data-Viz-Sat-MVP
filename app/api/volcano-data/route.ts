import { NextResponse } from "next/server"
import { readFile } from "fs/promises"
import { join } from "path"
import Papa from "papaparse"

export async function GET() {
  try {
    // Read the CSV file from the public directory
    const filePath = join(process.cwd(), "public", "metabolomics_example.csv")
    const fileContent = await readFile(filePath, "utf-8")

    // Parse CSV server-side
    const parseResult = Papa.parse(fileContent, {
      header: true,
      skipEmptyLines: true,
      dynamicTyping: true,
    })

    // Process and normalize data server-side
    const processedData = parseResult.data
      .map((row: any) => {
        // Normalize column names
        const normalizedRow = {
          gene: row["Metabolite name"] || row["gene"] || "",
          logFC: Number(row["log2(FC)"] || row["logFC"] || 0),
          padj: Number(row["p-Value"] || row["padj"] || 1),
          classyfireSuperclass: row["ClassyFire Superclass"] || "",
          classyfireClass: row["ClassyFire Class"] || "",
        }

        return normalizedRow
      })
      .filter((row) => row.gene && !isNaN(row.logFC) && !isNaN(row.padj))

    return NextResponse.json(processedData)
  } catch (error) {
    console.error("Error processing volcano data:", error)
    return NextResponse.json({ error: "Failed to process data" }, { status: 500 })
  }
}
