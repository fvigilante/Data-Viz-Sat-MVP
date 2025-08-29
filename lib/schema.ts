import { z } from "zod"

export const DegRowSchema = z.object({
  gene: z.string().min(1, "Gene/Metabolite name is required"),
  logFC: z.coerce.number(),
  padj: z.coerce.number().min(0).max(1),
  classyfireSuperclass: z.string().optional(),
  classyfireClass: z.string().optional(),
})

export type DegRow = z.infer<typeof DegRowSchema>
