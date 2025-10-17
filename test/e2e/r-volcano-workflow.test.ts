import { describe, it, expect, beforeAll, afterAll } from 'vitest'

// End-to-End Test Suite for R Volcano Plot Workflow
// Tests complete user workflow from frontend to R backend

describe('R Volcano Plot End-to-End Workflow', () => {
  const R_API_BASE = 'http://localhost:8001'
  const NEXT_API_BASE = 'http://localhost:3000'
  
  // Helper function to check if servers are running
  const checkServer = async (url: string) => {
    try {
      const response = await fetch(url)
      return response.ok
    } catch {
      return false
    }
  }

  beforeAll(async () => {
    // Check if required servers are running
    const rServerRunning = await checkServer(`${R_API_BASE}/health`)
    const nextServerRunning = await checkServer(`${NEXT_API_BASE}/api/health`)
    
    if (!rServerRunning) {
      console.warn('R server not running on port 8001. Some tests may be skipped.')
    }
    
    if (!nextServerRunning) {
      console.warn('Next.js server not running on port 3000. Some tests may be skipped.')
    }
  })

  it('should complete full workflow: cache clear -> data generation -> filtering -> export', async () => {
    // Skip if servers not running
    const rServerRunning = await checkServer(`${R_API_BASE}/health`)
    const nextServerRunning = await checkServer(`${NEXT_API_BASE}/api/r-cache-status`)
    
    if (!rServerRunning || !nextServerRunning) {
      console.log('Skipping E2E test - servers not available')
      return
    }

    // Step 1: Clear cache via Next.js API
    const clearResponse = await fetch(`${NEXT_API_BASE}/api/r-clear-cache`, {
      method: 'POST'
    })
    expect(clearResponse.ok).toBe(true)
    
    const clearResult = await clearResponse.json()
    expect(clearResult.message).toMatch(/cleared/i)

    // Step 2: Check cache status
    const statusResponse = await fetch(`${NEXT_API_BASE}/api/r-cache-status`)
    expect(statusResponse.ok).toBe(true)
    
    const statusResult = await statusResponse.json()
    expect(statusResult.total_cached).toBe(0)

    // Step 3: Generate volcano data (should create new dataset)
    const dataParams = new URLSearchParams({
      dataset_size: '1000',
      p_value_threshold: '0.05',
      log_fc_min: '-0.5',
      log_fc_max: '0.5',
      max_points: '5000'
    })
    
    const dataResponse = await fetch(`${NEXT_API_BASE}/api/r-volcano-data?${dataParams}`)
    expect(dataResponse.ok).toBe(true)
    
    const dataResult = await dataResponse.json()
    
    // Verify response structure
    expect(dataResult).toHaveProperty('data')
    expect(dataResult).toHaveProperty('stats')
    expect(dataResult).toHaveProperty('total_rows')
    expect(dataResult).toHaveProperty('filtered_rows')
    expect(dataResult).toHaveProperty('is_downsampled')
    
    // Verify data content
    expect(Array.isArray(dataResult.data)).toBe(true)
    expect(dataResult.data.length).toBeGreaterThan(0)
    expect(dataResult.total_rows).toBe(1000)
    
    // Verify stats
    expect(dataResult.stats).toHaveProperty('up_regulated')
    expect(dataResult.stats).toHaveProperty('down_regulated')
    expect(dataResult.stats).toHaveProperty('non_significant')
    
    const totalStats = dataResult.stats.up_regulated + 
                      dataResult.stats.down_regulated + 
                      dataResult.stats.non_significant
    expect(totalStats).toBe(dataResult.total_rows)

    // Step 4: Verify cache was populated
    const statusResponse2 = await fetch(`${NEXT_API_BASE}/api/r-cache-status`)
    const statusResult2 = await statusResponse2.json()
    expect(statusResult2.total_cached).toBeGreaterThan(0)
    expect(statusResult2.cached_datasets).toContain(1000)

    // Step 5: Apply search filter
    const searchParams = new URLSearchParams({
      dataset_size: '1000',
      search_term: 'acid',
      max_points: '5000'
    })
    
    const searchResponse = await fetch(`${NEXT_API_BASE}/api/r-volcano-data?${searchParams}`)
    expect(searchResponse.ok).toBe(true)
    
    const searchResult = await searchResponse.json()
    expect(searchResult.filtered_rows).toBeLessThanOrEqual(searchResult.total_rows)

    // Step 6: Test with different thresholds
    const strictParams = new URLSearchParams({
      dataset_size: '1000',
      p_value_threshold: '0.01',
      log_fc_min: '-1.0',
      log_fc_max: '1.0',
      max_points: '5000'
    })
    
    const strictResponse = await fetch(`${NEXT_API_BASE}/api/r-volcano-data?${strictParams}`)
    expect(strictResponse.ok).toBe(true)
    
    const strictResult = await strictResponse.json()
    
    // Stricter thresholds should generally result in fewer significant points
    const originalSig = dataResult.stats.up_regulated + dataResult.stats.down_regulated
    const strictSig = strictResult.stats.up_regulated + strictResult.stats.down_regulated
    
    // Allow some tolerance for randomness in data generation
    expect(strictSig).toBeLessThanOrEqual(originalSig + 50)
  }, 30000) // 30 second timeout for E2E test

  it('should handle large dataset requests efficiently', async () => {
    const rServerRunning = await checkServer(`${R_API_BASE}/health`)
    const nextServerRunning = await checkServer(`${NEXT_API_BASE}/api/r-cache-status`)
    
    if (!rServerRunning || !nextServerRunning) {
      console.log('Skipping large dataset E2E test - servers not available')
      return
    }

    // Test with larger dataset
    const largeParams = new URLSearchParams({
      dataset_size: '50000',
      max_points: '10000',
      p_value_threshold: '0.05'
    })
    
    const startTime = Date.now()
    const response = await fetch(`${NEXT_API_BASE}/api/r-volcano-data?${largeParams}`)
    const endTime = Date.now()
    
    expect(response.ok).toBe(true)
    
    const result = await response.json()
    
    // Should handle large dataset
    expect(result.total_rows).toBe(50000)
    
    // Should apply downsampling
    expect(result.is_downsampled).toBe(true)
    expect(result.data.length).toBeLessThanOrEqual(10000)
    
    // Should complete in reasonable time (less than 15 seconds)
    const responseTime = endTime - startTime
    expect(responseTime).toBeLessThan(15000)
    
  }, 20000) // 20 second timeout

  it('should maintain data consistency across multiple requests', async () => {
    const rServerRunning = await checkServer(`${R_API_BASE}/health`)
    const nextServerRunning = await checkServer(`${NEXT_API_BASE}/api/r-cache-status`)
    
    if (!rServerRunning || !nextServerRunning) {
      console.log('Skipping consistency E2E test - servers not available')
      return
    }

    const params = new URLSearchParams({
      dataset_size: '2000',
      p_value_threshold: '0.05',
      log_fc_min: '-0.5',
      log_fc_max: '0.5',
      max_points: '5000'
    })
    
    // Make multiple requests with same parameters
    const responses = await Promise.all([
      fetch(`${NEXT_API_BASE}/api/r-volcano-data?${params}`),
      fetch(`${NEXT_API_BASE}/api/r-volcano-data?${params}`),
      fetch(`${NEXT_API_BASE}/api/r-volcano-data?${params}`)
    ])
    
    // All should succeed
    responses.forEach(response => {
      expect(response.ok).toBe(true)
    })
    
    const results = await Promise.all(
      responses.map(response => response.json())
    )
    
    // Should have consistent total_rows (same dataset)
    const totalRows = results[0].total_rows
    results.forEach(result => {
      expect(result.total_rows).toBe(totalRows)
    })
    
    // Should have consistent stats (same filtering)
    const firstStats = results[0].stats
    results.forEach(result => {
      expect(result.stats.up_regulated).toBe(firstStats.up_regulated)
      expect(result.stats.down_regulated).toBe(firstStats.down_regulated)
      expect(result.stats.non_significant).toBe(firstStats.non_significant)
    })
  })

  it('should handle cache warming workflow', async () => {
    const rServerRunning = await checkServer(`${R_API_BASE}/health`)
    const nextServerRunning = await checkServer(`${NEXT_API_BASE}/api/r-cache-status`)
    
    if (!rServerRunning || !nextServerRunning) {
      console.log('Skipping cache warming E2E test - servers not available')
      return
    }

    // Clear cache first
    await fetch(`${NEXT_API_BASE}/api/r-clear-cache`, { method: 'POST' })
    
    // Warm cache with multiple sizes
    const warmResponse = await fetch(`${NEXT_API_BASE}/api/r-warm-cache`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ sizes: [1000, 5000, 10000] })
    })
    
    expect(warmResponse.ok).toBe(true)
    
    const warmResult = await warmResponse.json()
    expect(warmResult.message).toMatch(/warmed/i)
    
    // Verify cache was warmed
    const statusResponse = await fetch(`${NEXT_API_BASE}/api/r-cache-status`)
    const statusResult = await statusResponse.json()
    
    expect(statusResult.total_cached).toBeGreaterThanOrEqual(3)
    expect(statusResult.cached_datasets).toContain(1000)
    expect(statusResult.cached_datasets).toContain(5000)
    expect(statusResult.cached_datasets).toContain(10000)
    
    // Subsequent requests should be fast (cached)
    const cachedParams = new URLSearchParams({
      dataset_size: '5000',
      max_points: '2000'
    })
    
    const startTime = Date.now()
    const cachedResponse = await fetch(`${NEXT_API_BASE}/api/r-volcano-data?${cachedParams}`)
    const endTime = Date.now()
    
    expect(cachedResponse.ok).toBe(true)
    
    // Cached request should be very fast (< 2 seconds)
    const responseTime = endTime - startTime
    expect(responseTime).toBeLessThan(2000)
  })

  it('should handle error conditions gracefully', async () => {
    const nextServerRunning = await checkServer(`${NEXT_API_BASE}/api/r-cache-status`)
    
    if (!nextServerRunning) {
      console.log('Skipping error handling E2E test - Next.js server not available')
      return
    }

    // Test with invalid parameters
    const invalidParams = new URLSearchParams({
      dataset_size: '-100',
      p_value_threshold: '1.5',
      max_points: '-50'
    })
    
    const response = await fetch(`${NEXT_API_BASE}/api/r-volcano-data?${invalidParams}`)
    
    // Should either handle gracefully (200 with corrected params) or return error (400/500)
    if (response.ok) {
      const result = await response.json()
      // If handled gracefully, should have valid data
      expect(result).toHaveProperty('data')
      expect(result.total_rows).toBeGreaterThan(0)
    } else {
      // If returns error, should be appropriate status code
      expect([400, 422, 500]).toContain(response.status)
    }
  })

  afterAll(async () => {
    // Cleanup: Clear cache after tests
    try {
      const nextServerRunning = await checkServer(`${NEXT_API_BASE}/api/r-cache-status`)
      if (nextServerRunning) {
        await fetch(`${NEXT_API_BASE}/api/r-clear-cache`, { method: 'POST' })
      }
    } catch (error) {
      console.log('Cleanup failed:', error)
    }
  })
})