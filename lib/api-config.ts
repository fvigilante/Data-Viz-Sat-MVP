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
  }
}

// Helper function to get full API URL
export function getApiUrl(endpoint: keyof typeof API_CONFIG.endpoints): string {
  const path = API_CONFIG.endpoints[endpoint]
  return isProduction ? path : `${API_CONFIG.baseUrl}${path}`
}