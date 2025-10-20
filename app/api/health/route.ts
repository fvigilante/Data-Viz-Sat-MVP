import { NextResponse } from "next/server"

const API_INTERNAL_URL = process.env.API_INTERNAL_URL || "http://127.0.0.1:8001"

export async function GET() {
  try {
    // Check if FastAPI backend is healthy
    const apiHealthUrl = `${API_INTERNAL_URL}/api/r/health`
    
    const response = await fetch(apiHealthUrl, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      // Short timeout for health checks
      signal: AbortSignal.timeout(5000)
    })
    
    if (!response.ok) {
      return NextResponse.json(
        { 
          status: 'unhealthy',
          frontend: 'ok',
          backend: 'error',
          error: `Backend responded with ${response.status}`
        },
        { status: 503 }
      )
    }
    
    const backendHealth = await response.json()
    
    return NextResponse.json({
      status: 'healthy',
      frontend: 'ok',
      backend: backendHealth.status || 'ok',
      r_integration: backendHealth.backend || 'unknown',
      timestamp: new Date().toISOString()
    })
    
  } catch (error) {
    console.error('[Health Check] Backend health check failed:', error)
    
    return NextResponse.json(
      { 
        status: 'unhealthy',
        frontend: 'ok',
        backend: 'error',
        error: error instanceof Error ? error.message : 'Unknown error'
      },
      { status: 503 }
    )
  }
}