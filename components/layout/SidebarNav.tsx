"use client"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import { BarChart3, Info, ScanText as Scatter, TrendingUp, Server, Zap } from "lucide-react"
import Link from "next/link"
import { usePathname } from "next/navigation"

const navItems = [
  {
    title: "Volcano (Client)",
    href: "/plots/volcano",
    icon: Scatter,
    disabled: false,
  },
  {
    title: "Volcano (Server)",
    href: "/plots/volcano-server",
    icon: Server,
    disabled: false,
  },
  {
    title: "Volcano (FastAPI)",
    href: "/plots/volcano-fastapi",
    icon: Zap,
    disabled: false,
    badge: "NEW",
  },
  {
    title: "PCA",
    href: "/plots/pca",
    icon: TrendingUp,
    disabled: true,
    tooltip: "Coming soon",
  },
  {
    title: "Heatmap",
    href: "/plots/heatmap",
    icon: BarChart3,
    disabled: true,
    tooltip: "Coming soon",
  },
]

export function SidebarNav() {
  const pathname = usePathname()

  return (
    <aside className="w-64 bg-white border-r border-slate-200 flex-shrink-0 hidden lg:block">
      <nav className="p-4 space-y-2">
        {navItems.map((item) => {
          const Icon = item.icon
          const isActive = pathname === item.href

          if (item.disabled) {
            return (
              <div
                key={item.href}
                className="flex items-center gap-3 px-3 py-2 text-sm text-slate-400 cursor-not-allowed"
                title={item.tooltip}
              >
                <Icon className="h-4 w-4" />
                {item.title}
              </div>
            )
          }

          return (
            <Button
              key={item.href}
              variant={isActive ? "secondary" : "ghost"}
              className={cn("w-full justify-start gap-3", isActive && "bg-teal-50 text-teal-700 hover:bg-teal-100")}
              asChild
            >
              <Link href={item.href}>
                <Icon className="h-4 w-4" />
                {item.title}
                {item.badge && (
                  <span className="ml-auto text-xs bg-emerald-100 text-emerald-700 px-2 py-1 rounded-full font-medium">
                    {item.badge}
                  </span>
                )}
              </Link>
            </Button>
          )
        })}

        <div className="border-t border-slate-200 my-4" />

        <Button variant="ghost" className="w-full justify-start gap-3" asChild>
          <Link href="/about">
            <Info className="h-4 w-4" />
            About
          </Link>
        </Button>
      </nav>
    </aside>
  )
}
