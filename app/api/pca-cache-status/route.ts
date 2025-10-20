import { NextRequest, NextResponse } from "next/server"

const API_INTERNAL_URL = process.env.API_INTERNAL_URL || "http://127.0.0.1:8001"

export async function GET(request: NextRequest) {
  try {
    const apiUrl = `${API_INTERNAL_URL}/api/pca-cache-status`
    
    console.log(`[Proxy] Forwarding pca-cache-status request to: ${apiUrl}`)
    
    const response = await fetch(apiUrl, {
      method: 'GET',
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
    console.error("[Proxy] Error forwarding pca-cache-status request:", error)
    return NextResponse.json(
      { error: "Failed to fetch PCA cache status from internal API" },
      { status: 500 }
    )
  }
}