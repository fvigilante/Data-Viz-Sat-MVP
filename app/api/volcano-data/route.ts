import { NextRequest, NextResponse } from "next/server"

const API_INTERNAL_URL = process.env.API_INTERNAL_URL || "http://127.0.0.1:8001"

export async function GET(request: NextRequest) {
  try {
    // Get query parameters from the request
    const { searchParams } = new URL(request.url)
    const queryString = searchParams.toString()
    
    // Forward request to internal API
    const apiUrl = `${API_INTERNAL_URL}/api/volcano-data${queryString ? `?${queryString}` : ''}`
    
    console.log(`[Proxy] Forwarding volcano-data request to: ${apiUrl}`)
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        // Forward essential headers
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
    console.log(`[Proxy] Successfully forwarded volcano-data request, received ${JSON.stringify(data).length} bytes`)
    
    return NextResponse.json(data)
  } catch (error) {
    console.error("[Proxy] Error forwarding volcano-data request:", error)
    return NextResponse.json(
      { error: "Failed to fetch data from internal API" },
      { status: 500 }
    )
  }
}
