import { NextResponse } from 'next/server'

export async function GET() {
  try {
    // Basic health check - can be extended with database connectivity, etc.
    const healthStatus = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'data-viz-satellite',
      version: process.env.npm_package_version || 'unknown',
      environment: process.env.NODE_ENV || 'development',
      uptime: process.uptime(),
    }

    return NextResponse.json(healthStatus, { status: 200 })
  } catch (error) {
    return NextResponse.json(
      { 
        status: 'unhealthy', 
        error: error instanceof Error ? error.message : 'Unknown error',
        timestamp: new Date().toISOString()
      }, 
      { status: 500 }
    )
  }
}