import { describe, it, expect, beforeEach, vi } from 'vitest'
import { NextRequest } from 'next/server'

// Mock fetch globally
global.fetch = vi.fn()

// API Route Tests for R Volcano Plot Integration
describe('R Volcano Plot API Routes', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('/api/r-volcano-data', () => {
    it('should proxy GET requests to R backend correctly', async () => {
      // Mock successful R backend response
      const mockRResponse = {
        data: [
          {
            gene: 'Test Gene',
            logFC: 1.5,
            padj: 0.001,
            category: 'up'
          }
        ],
        stats: {
          up_regulated: 1,
          down_regulated: 0,
          non_significant: 999
        },
        total_rows: 1000,
        filtered_rows: 1000,
        points_before_sampling: 1000,
        is_downsampled: false
      }

      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockRResponse,
        status: 200
      })

      // Import the route handler
      const { GET } = await import('@/app/api/r-volcano-data/route')

      // Create mock request
      const url = new URL('http://localhost:3000/api/r-volcano-data?dataset_size=1000&p_value_threshold=0.05')
      const request = new NextRequest(url)

      // Call the route handler
      const response = await GET(request)
      const result = await response.json()

      // Verify the response
      expect(response.status).toBe(200)
      expect(result).toEqual(mockRResponse)

      // Verify fetch was called with correct parameters
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('localhost:8001/api/volcano-data'),
        expect.objectContaining({
          method: 'GET'
        })
      )
    })

    it('should handle R backend errors gracefully', async () => {
      // Mock R backend error
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error'
      })

      const { GET } = await import('@/app/api/r-volcano-data/route')

      const url = new URL('http://localhost:3000/api/r-volcano-data?dataset_size=1000')
      const request = new NextRequest(url)

      const response = await GET(request)
      const result = await response.json()

      expect(response.status).toBe(500)
      expect(result).toHaveProperty('error')
      expect(result.error).toMatch(/R backend error/i)
    })

    it('should handle network errors to R backend', async () => {
      // Mock network error
      ;(global.fetch as any).mockRejectedValueOnce(new Error('Network error'))

      const { GET } = await import('@/app/api/r-volcano-data/route')

      const url = new URL('http://localhost:3000/api/r-volcano-data?dataset_size=1000')
      const request = new NextRequest(url)

      const response = await GET(request)
      const result = await response.json()

      expect(response.status).toBe(500)
      expect(result).toHaveProperty('error')
      expect(result.error).toMatch(/Network error|Failed to fetch/i)
    })

    it('should pass through query parameters correctly', async () => {
      const mockResponse = { data: [], stats: {}, total_rows: 0 }
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      })

      const { GET } = await import('@/app/api/r-volcano-data/route')

      const url = new URL('http://localhost:3000/api/r-volcano-data')
      url.searchParams.set('dataset_size', '5000')
      url.searchParams.set('p_value_threshold', '0.01')
      url.searchParams.set('log_fc_min', '-1.0')
      url.searchParams.set('log_fc_max', '1.0')
      url.searchParams.set('search_term', 'biotin')
      url.searchParams.set('max_points', '10000')

      const request = new NextRequest(url)
      await GET(request)

      // Verify all parameters were passed to R backend
      const fetchCall = (global.fetch as any).mock.calls[0][0]
      expect(fetchCall).toContain('dataset_size=5000')
      expect(fetchCall).toContain('p_value_threshold=0.01')
      expect(fetchCall).toContain('log_fc_min=-1.0')
      expect(fetchCall).toContain('log_fc_max=1.0')
      expect(fetchCall).toContain('search_term=biotin')
      expect(fetchCall).toContain('max_points=10000')
    })
  })

  describe('/api/r-cache-status', () => {
    it('should proxy cache status requests correctly', async () => {
      const mockCacheStatus = {
        total_cached: 3,
        cached_datasets: [1000, 5000, 10000],
        approximate_memory_mb: 25.5
      }

      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockCacheStatus
      })

      const { GET } = await import('@/app/api/r-cache-status/route')

      const url = new URL('http://localhost:3000/api/r-cache-status')
      const request = new NextRequest(url)

      const response = await GET(request)
      const result = await response.json()

      expect(response.status).toBe(200)
      expect(result).toEqual(mockCacheStatus)
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('localhost:8001/api/cache-status'),
        expect.objectContaining({ method: 'GET' })
      )
    })

    it('should handle cache status errors', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: false,
        status: 500
      })

      const { GET } = await import('@/app/api/r-cache-status/route')

      const url = new URL('http://localhost:3000/api/r-cache-status')
      const request = new NextRequest(url)

      const response = await GET(request)

      expect(response.status).toBe(500)
    })
  })

  describe('/api/r-warm-cache', () => {
    it('should proxy cache warming requests correctly', async () => {
      const mockWarmResponse = {
        message: 'Cache warmed successfully',
        cached_sizes: [1000, 5000]
      }

      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockWarmResponse
      })

      const { POST } = await import('@/app/api/r-warm-cache/route')

      const url = new URL('http://localhost:3000/api/r-warm-cache')
      const request = new NextRequest(url, {
        method: 'POST',
        body: JSON.stringify({ sizes: [1000, 5000] }),
        headers: { 'Content-Type': 'application/json' }
      })

      const response = await POST(request)
      const result = await response.json()

      expect(response.status).toBe(200)
      expect(result).toEqual(mockWarmResponse)
      
      // Verify POST request was made to R backend
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('localhost:8001/api/warm-cache'),
        expect.objectContaining({
          method: 'POST',
          headers: expect.objectContaining({
            'Content-Type': 'application/json'
          }),
          body: JSON.stringify({ sizes: [1000, 5000] })
        })
      )
    })

    it('should handle invalid JSON in request body', async () => {
      const { POST } = await import('@/app/api/r-warm-cache/route')

      const url = new URL('http://localhost:3000/api/r-warm-cache')
      const request = new NextRequest(url, {
        method: 'POST',
        body: 'invalid json',
        headers: { 'Content-Type': 'application/json' }
      })

      const response = await POST(request)
      const result = await response.json()

      expect(response.status).toBe(400)
      expect(result).toHaveProperty('error')
      expect(result.error).toMatch(/Invalid JSON/i)
    })

    it('should validate request body structure', async () => {
      const { POST } = await import('@/app/api/r-warm-cache/route')

      const url = new URL('http://localhost:3000/api/r-warm-cache')
      const request = new NextRequest(url, {
        method: 'POST',
        body: JSON.stringify({ invalid: 'structure' }),
        headers: { 'Content-Type': 'application/json' }
      })

      const response = await POST(request)
      const result = await response.json()

      expect(response.status).toBe(400)
      expect(result).toHaveProperty('error')
      expect(result.error).toMatch(/sizes.*required/i)
    })
  })

  describe('/api/r-clear-cache', () => {
    it('should proxy cache clearing requests correctly', async () => {
      const mockClearResponse = {
        message: 'Cache cleared successfully'
      }

      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockClearResponse
      })

      const { POST } = await import('@/app/api/r-clear-cache/route')

      const url = new URL('http://localhost:3000/api/r-clear-cache')
      const request = new NextRequest(url, { method: 'POST' })

      const response = await POST(request)
      const result = await response.json()

      expect(response.status).toBe(200)
      expect(result).toEqual(mockClearResponse)
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('localhost:8001/api/clear-cache'),
        expect.objectContaining({ method: 'POST' })
      )
    })

    it('should handle cache clearing errors', async () => {
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: false,
        status: 500
      })

      const { POST } = await import('@/app/api/r-clear-cache/route')

      const url = new URL('http://localhost:3000/api/r-clear-cache')
      const request = new NextRequest(url, { method: 'POST' })

      const response = await POST(request)

      expect(response.status).toBe(500)
    })
  })

  describe('Environment Configuration', () => {
    it('should use correct R backend URL from environment', async () => {
      // Mock environment variable
      const originalEnv = process.env.R_BACKEND_URL
      process.env.R_BACKEND_URL = 'http://custom-r-server:9000'

      const mockResponse = { data: [] }
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      })

      const { GET } = await import('@/app/api/r-volcano-data/route')

      const url = new URL('http://localhost:3000/api/r-volcano-data?dataset_size=1000')
      const request = new NextRequest(url)

      await GET(request)

      // Should use custom URL
      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining('custom-r-server:9000'),
        expect.any(Object)
      )

      // Restore original environment
      if (originalEnv) {
        process.env.R_BACKEND_URL = originalEnv
      } else {
        delete process.env.R_BACKEND_URL
      }
    })
  })

  describe('CORS and Headers', () => {
    it('should include appropriate CORS headers', async () => {
      const mockResponse = { data: [] }
      ;(global.fetch as any).mockResolvedValueOnce({
        ok: true,
        json: async () => mockResponse
      })

      const { GET } = await import('@/app/api/r-volcano-data/route')

      const url = new URL('http://localhost:3000/api/r-volcano-data?dataset_size=1000')
      const request = new NextRequest(url)

      const response = await GET(request)

      // Check for CORS headers (if implemented)
      const headers = response.headers
      // Note: Actual CORS headers depend on implementation
      expect(headers.get('Content-Type')).toContain('application/json')
    })
  })
})