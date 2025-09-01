import type React from "react"
import type { Metadata } from "next"
import { GeistSans } from "geist/font/sans"
import { GeistMono } from "geist/font/mono"
import "./globals.css"
import { Header } from "@/components/layout/Header"
import { SidebarNav } from "@/components/layout/SidebarNav"
import { Footer } from "@/components/layout/Footer"

export const metadata: Metadata = {
  title: "Data Viz Satellite - Sequentia Pilot",
  description: "Multi-omics data visualization microservice pilot for Sequentia Biotech platform integration",
  generator: "Sequentia Biotech IT Team",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={`${GeistSans.variable} ${GeistMono.variable} antialiased`}>
      <head>
        <style>{`
html {
  font-family: ${GeistSans.style.fontFamily};
  --font-sans: ${GeistSans.variable};
  --font-mono: ${GeistMono.variable};
}
        `}</style>
      </head>
      <body className="bg-slate-50">
        <div className="min-h-screen flex flex-col">
          <Header />
          <div className="flex flex-1">
            <SidebarNav />
            <main className="flex-1 overflow-auto">{children}</main>
          </div>
          <Footer />
        </div>
      </body>
    </html>
  )
}
