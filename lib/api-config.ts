// API configuration for client-side requests
// In production, use relative paths to proxy through Next.js API routes
// In development, can use direct API calls if needed

const isProduction = process.env.NODE_ENV === 'production'

export const API_CONFIG = {
  // Base URL for API calls
  baseUrl: isProduction ? '' : (process.env.NEXT_PUBLIC_API_URL || ''),
  
  // API endpoints - always use relative paths in production
  endpoints: {
    volcanoData: '/api/volcano-data',
    pcaData: '/api/pca-data',
    cacheStatus: '/api/cache-status',
    pcaCacheStatus: '/api/pca-cache-status',
    warmCache: '/api/warm-cache',
    clearCache: '/api/clear-cache',
    // R-specific endpoints
    rVolcanoData: '/api/r-volcano-data',
    rCacheStatus: '/api/r-cache-status',
    rWarmCache: '/api/r-warm-cache',
    rClearCache: '/api/r-clear-cache',
  }
}

// Helper function to get full API URL
export function getApiUrl(endpoint: keyof typeof API_CONFIG.endpoints): string {
  const path = API_CONFIG.endpoints[endpoint]
  
  // R endpoints should always use relative paths (Next.js proxy)
  if (endpoint.startsWith('r')) {
    return path
  }
  
  return isProduction ? path : `${API_CONFIG.baseUrl}${path}`
}

// Helper function to check if R backend is available
export function isRBackendEnabled(): boolean {
  return process.env.NEXT_PUBLIC_R_BACKEND_ENABLED === 'true'
}

// Helper function to get R backend base URL
export function getRBackendUrl(): string {
  return process.env.NEXT_PUBLIC_R_BACKEND_URL || 'http://localhost:8001'
}

// Helper functions for R-specific API URLs
export function getRVolcanoDataUrl(): string {
  return getApiUrl('rVolcanoData')
}

export function getRCacheStatusUrl(): string {
  return getApiUrl('rCacheStatus')
}

export function getRWarmCacheUrl(): string {
  return getApiUrl('rWarmCache')
}

export function getRClearCacheUrl(): string {
  return getApiUrl('rClearCache')
}

// Helper function to get all R endpoints
export function getREndpoints() {
  return {
    volcanoData: getRVolcanoDataUrl(),
    cacheStatus: getRCacheStatusUrl(),
    warmCache: getRWarmCacheUrl(),
    clearCache: getRClearCacheUrl(),
  }
}