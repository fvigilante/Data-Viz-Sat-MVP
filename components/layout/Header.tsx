"use client"

import { Button } from "@/components/ui/button"
import { Info, Menu } from "lucide-react"
import Link from "next/link"

export function Header() {
  return (
    <header className="bg-white border-b border-slate-200 px-6 py-4">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <button className="lg:hidden p-2 hover:bg-slate-100 rounded-md">
            <Menu className="h-5 w-5" />
          </button>
          <div>
            <h1 className="text-xl font-bold text-slate-900">Data Viz Satellite</h1>
            <p className="text-sm text-slate-500">Example of Next.js + Plotly.js data visualization app</p>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="ghost" size="sm" asChild>
            <Link href="/about">
              <Info className="h-4 w-4" />
            </Link>
          </Button>
        </div>
      </div>
    </header>
  )
}
