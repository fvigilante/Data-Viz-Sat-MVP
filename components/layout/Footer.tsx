import { Github } from "lucide-react"
import { Button } from "@/components/ui/button"

export function Footer() {
  return (
    <footer className="bg-white border-t border-slate-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <p className="text-sm text-slate-500">
          © 2025 Sequentia Biotech — Internal prototype — Built with Next.js + Plotly.js
        </p>
        <Button variant="ghost" size="sm">
          <Github className="h-4 w-4" />
        </Button>
      </div>
    </footer>
  )
}
