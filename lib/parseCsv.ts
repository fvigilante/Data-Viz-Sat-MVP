import Papa from "papaparse"
import { DegRowSchema, type DegRow } from "./schema"

export interface ParseResult {
  data: DegRow[]
  errors: string[]
  totalRows: number
}

export function parseCsv(csvText: string): ParseResult {
  const result = Papa.parse(csvText, {
    header: true,
    skipEmptyLines: true,
    transformHeader: (header: string) => {
      // Normalize column names to match expected schema
      const normalized = header.trim().toLowerCase()

      // Map various gene/metabolite name columns
      if (normalized.includes("gene") || normalized.includes("metabolite")) {
        return "gene"
      }

      // Map various log2(FC) columns
      if (normalized.includes("log2(fc)") || normalized.includes("logfc") || normalized.includes("log2fc")) {
        return "logFC"
      }

      // Map various p-value columns
      if (
        normalized.includes("p-value") ||
        normalized.includes("pvalue") ||
        normalized.includes("padj") ||
        normalized.includes("fdr")
      ) {
        return "padj"
      }

      // Map ClassyFire columns
      if (normalized.includes("superclass")) {
        return "classyfireSuperclass"
      }

      if (normalized.includes("class") && !normalized.includes("superclass")) {
        return "classyfireClass"
      }

      return header
    },
  })

  const errors: string[] = []
  const validData: DegRow[] = []

  result.data.forEach((row: any, index: number) => {
    try {
      const validatedRow = DegRowSchema.parse(row)
      validData.push(validatedRow)
    } catch (error) {
      errors.push(`Row ${index + 1}: Invalid data format`)
    }
  })

  return {
    data: validData,
    errors,
    totalRows: result.data.length,
  }
}
