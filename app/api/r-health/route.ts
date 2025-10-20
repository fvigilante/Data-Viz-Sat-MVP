import { NextRequest, NextResponse } from "next/server"

const API_INTERNAL_URL = process.env.API_INTERNAL_URL || "http://127.0.0.1:8001"

export async function GET(request: NextRequest) {
  try {
    const apiUrl = `${API_INTERNAL_URL}/api/r/health`
    
    console.log(`[R-Proxy] Forwarding r-health request to: ${apiUrl}`)
    
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })
    
    if (!response.ok) {
      console.error(`[R-Proxy] Error response from API: ${response.status} ${response.statusText}`)
      return NextResponse.json(
        { error: `API responded with ${response.status}` },
        { status: response.status }
      )
    }
    
    const data = await response.json()
    return NextResponse.json(data)
    
  } catch (error) {
    console.error('[R-Proxy] Error forwarding r-health request:', error)
    return NextResponse.json(
      { error: 'Failed to forward request to R health endpoint' },
      { status: 500 }
    )
  }
}