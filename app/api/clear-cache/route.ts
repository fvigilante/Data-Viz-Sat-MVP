import { NextRequest, NextResponse } from "next/server"

const API_INTERNAL_URL = process.env.API_INTERNAL_URL || "http://127.0.0.1:9000"

export async function POST(request: NextRequest) {
  try {
    const apiUrl = `${API_INTERNAL_URL}/api/clear-cache`
    
    console.log(`[Proxy] Forwarding clear-cache request to: ${apiUrl}`)
    
    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': request.headers.get('user-agent') || 'Next.js-Proxy',
        'Accept': request.headers.get('accept') || 'application/json',
      },
    })

    if (!response.ok) {
      console.error(`[Proxy] API error: ${response.status} ${response.statusText}`)
      return NextResponse.json(
        { error: `API Error: ${response.status} ${response.statusText}` },
        { status: response.status }
      )
    }

    const data = await response.json()
    return NextResponse.json(data)
  } catch (error) {
    console.error("[Proxy] Error forwarding clear-cache request:", error)
    return NextResponse.json(
      { error: "Failed to clear cache on internal API" },
      { status: 500 }
    )
  }
}