import { NextRequest, NextResponse } from "next/server"

const R_API_INTERNAL_URL = process.env.R_API_INTERNAL_URL || "http://127.0.0.1:8001"

export async function GET(request: NextRequest) {
  try {
    // Get query parameters from the request
    const { searchParams } = new URL(request.url)
    const queryString = searchParams.toString()
    
    // Forward request to R backend API
    const apiUrl = `${R_API_INTERNAL_URL}/api/volcano-data${queryString ? `?${queryString}` : ''}`
    
    console.log(`[R-Proxy] Forwarding volcano-data request to: ${apiUrl}`)
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        // Forward essential headers
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
    console.log(`[R-Proxy] Successfully forwarded volcano-data request, received ${JSON.stringify(data).length} bytes`)
    
    return NextResponse.json(data)
  } catch (error) {
    console.error("[R-Proxy] Error forwarding volcano-data request:", error)
    return NextResponse.json(
      { error: "Failed to fetch data from R backend API" },
      { status: 500 }
    )
  }
}