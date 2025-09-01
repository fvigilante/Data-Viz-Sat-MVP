import { Building2, GitBranch } from "lucide-react"
import { Button } from "@/components/ui/button"

export function Footer() {
  return (
    <footer className="bg-white border-t border-slate-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <p className="text-sm text-slate-500">
            © 2025 Sequentia Biotech — Technology Evaluation Pilot
          </p>
          <div className="flex items-center gap-1 text-xs text-slate-400">
            <Building2 className="h-3 w-3" />
            <span>Internal IT Project</span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-slate-400">Next.js 15 + React 19 + Plotly.js</span>
          <Button variant="ghost" size="sm" disabled className="opacity-50">
            <GitBranch className="h-4 w-4" />
          </Button>
        </div>
      </div>
    </footer>
  )
}
