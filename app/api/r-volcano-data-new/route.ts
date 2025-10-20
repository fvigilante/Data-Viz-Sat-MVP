import { NextRequest, NextResponse } from "next/server"

const API_INTERNAL_URL = process.env.API_INTERNAL_URL || "http://127.0.0.1:9000"

export async function GET(request: NextRequest) {
  try {
    // Get query parameters from the request
    const { searchParams } = new URL(request.url)
    const queryString = searchParams.toString()
    
    // Forward request to internal API (new R endpoint)
    const apiUrl = `${API_INTERNAL_URL}/api/r/volcano-data${queryString ? `?${queryString}` : ''}`
    
    console.log(`[R-Proxy-New] Forwarding r-volcano-data request to: ${apiUrl}`)
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })
    
    if (!response.ok) {
      console.error(`[R-Proxy-New] Error response from API: ${response.status} ${response.statusText}`)
      return NextResponse.json(
        { error: `API responded with ${response.status}` },
        { status: response.status }
      )
    }
    
    const data = await response.json()
    return NextResponse.json(data)
    
  } catch (error) {
    console.error('[R-Proxy-New] Error forwarding r-volcano-data request:', error)
    return NextResponse.json(
      { error: 'Failed to forward request to R volcano data endpoint' },
      { status: 500 }
    )
  }
}