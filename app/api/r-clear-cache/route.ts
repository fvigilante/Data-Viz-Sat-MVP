import { NextRequest, NextResponse } from "next/server"

const R_API_INTERNAL_URL = process.env.R_API_INTERNAL_URL || "http://127.0.0.1:8001"

export async function POST(request: NextRequest) {
  try {
    const apiUrl = `${R_API_INTERNAL_URL}/api/clear-cache`
    
    console.log(`[R-Proxy] Forwarding clear-cache request to: ${apiUrl}`)
    
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': request.headers.get('user-agent') || 'Next.js-R-Proxy',
        'Accept': request.headers.get('accept') || 'application/json',
      },
    })

    if (!response.ok) {
      console.error(`[R-Proxy] R API error: ${response.status} ${response.statusText}`)
      return NextResponse.json(
        { error: `R API Error: ${response.status} ${response.statusText}` },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error("[R-Proxy] Error forwarding clear-cache request:", error)
    return NextResponse.json(
      { error: "Failed to clear cache on R backend API" },
      { status: 500 }
    )
  }
}