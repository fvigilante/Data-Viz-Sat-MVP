/**
 * FastAPI Backend Test Module
 * 
 * This module implements testing for the FastAPI backend implementation,
 * testing both first-time and cached request scenarios with detailed timing.
 */

import { FastAPITestResult, TestDataset, FastAPIConfig } from '../types/index.js';

export class FastAPITestModule {
  private config: FastAPIConfig;
  private baseUrl: string;

  constructor(config: FastAPIConfig, baseUrl: string = 'http://localhost:8000') {
    this.config = config;
    this.baseUrl = baseUrl;
  }

  /**
   * Run a performance test on the FastAPI backend implementation
   */
  async runTest(dataset: TestDataset, timeout: number = 30000): Promise<FastAPITestResult> {
    const startTime = Date.now();
    
    try {
      // Clear cache first if we want to test first-time performance
      if (this.config.test_cache) {
        await this.clearCache();
      }

      // Test first-time request (no cache)
      const firstTimeResult = await this.testAPIRequest(dataset, timeout, false);
      
      let cacheHitResult = null;
      if (this.config.test_cache) {
        // Test cached request
        cacheHitResult = await this.testAPIRequest(dataset, timeout, true);
      }

      const totalTime = Date.now() - startTime;
      
      // Use the first-time result as primary, but note if cache was tested
      const result = firstTimeResult;
      result.total_time = totalTime;
      result.cache_hit = cacheHitResult ? cacheHitResult.cache_hit : false;
      
      return result;

    } catch (error) {
      const totalTime = Date.now() - startTime;
      
      return {
        service: 'fastapi',
        dataset_size: dataset.size,
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        total_time: totalTime,
        timestamp: new Date().toISOString(),
        api_response_time: 0,
        processing_time: 0,
        cache_hit: false
      };
    }
  }

  /**
   * Test a single API request to FastAPI
   */
  private async testAPIRequest(
    dataset: TestDataset, 
    timeout: number, 
    expectCacheHit: boolean
  ): Promise<FastAPITestResult> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);
    
    try {
      const apiStartTime = Date.now();
      
      // Prepare request parameters
      const params = new URLSearchParams({
        dataset_size: dataset.size.toString(),
        p_value_threshold: '0.05',
        log_fc_min: '-0.5',
        log_fc_max: '0.5',
        max_points: '50000',
        zoom_level: '1.0',
        lod_mode: 'true'
      });

      // Make request to FastAPI volcano-data endpoint
      const response = await fetch(`${this.baseUrl}/api/volcano-data?${params}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        signal: controller.signal
      });

      clearTimeout(timeoutId);
      
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const responseData = await response.json();
      const apiResponseTime = Date.now() - apiStartTime;
      
      // Validate response format
      if (!this.validateFastAPIResponse(responseData, dataset.size)) {
        throw new Error('Invalid response format from FastAPI');
      }

      // Extract processing information from response
      const processingTime = this.extractProcessingTime(responseData, apiResponseTime);
      const cacheHit = this.detectCacheHit(responseData, expectCacheHit, apiResponseTime);

      return {
        service: 'fastapi',
        dataset_size: dataset.size,
        success: true,
        error: undefined,
        total_time: apiResponseTime,
        timestamp: new Date().toISOString(),
        api_response_time: apiResponseTime,
        processing_time: processingTime,
        cache_hit: cacheHit
      };

    } catch (error) {
      clearTimeout(timeoutId);
      
      if (error instanceof Error && error.name === 'AbortError') {
        throw new Error('Request timeout');
      }
      
      throw error;
    }
  }

  /**
   * Test FastAPI with POST request (if supported)
   */
  async testWithPostRequest(dataset: TestDataset, timeout: number = 30000): Promise<{
    success: boolean;
    error?: string;
    processing_time?: number;
    cache_hit?: boolean;
  }> {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), timeout);
      
      const processingStartTime = Date.now();
      
      // Prepare POST body with filter parameters
      const requestBody = {
        p_value_threshold: 0.05,
        log_fc_min: -0.5,
        log_fc_max: 0.5,
        search_term: null,
        dataset_size: dataset.size,
        max_points: 50000,
        zoom_level: 1.0,
        x_range: null,
        y_range: null,
        lod_mode: true
      };

      const response = await fetch(`${this.baseUrl}/api/volcano-data`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(requestBody),
        signal: controller.signal
      });

      clearTimeout(timeoutId);
      
      const processingTime = Date.now() - processingStartTime;
      
      if (!response.ok) {
        return {
          success: false,
          error: `HTTP ${response.status}: ${response.statusText}`
        };
      }

      const responseData = await response.json();
      
      // Validate response
      if (!this.validateFastAPIResponse(responseData, dataset.size)) {
        return {
          success: false,
          error: 'Invalid response format'
        };
      }

      return {
        success: true,
        processing_time: processingTime,
        cache_hit: this.detectCacheHit(responseData, false, processingTime)
      };

    } catch (error) {
      if (error instanceof Error && error.name === 'AbortError') {
        return {
          success: false,
          error: 'Request timeout'
        };
      }
      
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Clear FastAPI cache
   */
  private async clearCache(): Promise<void> {
    try {
      const response = await fetch(`${this.baseUrl}/api/clear-cache`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        }
      });

      if (!response.ok) {
        console.warn(`Cache clear failed: ${response.status}`);
      }
    } catch (error) {
      console.warn('Failed to clear cache:', error);
      // Don't throw - cache clearing is optional
    }
  }

  /**
   * Warm up the FastAPI cache
   */
  async warmCache(sizes: number[] = [1000, 10000, 50000, 100000]): Promise<{
    success: boolean;
    error?: string;
    cached_sizes?: number[];
  }> {
    try {
      const response = await fetch(`${this.baseUrl}/api/warm-cache`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(sizes)
      });

      if (!response.ok) {
        return {
          success: false,
          error: `HTTP ${response.status}: ${response.statusText}`
        };
      }

      const result = await response.json();
      
      return {
        success: true,
        cached_sizes: result.cached_sizes || sizes
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Get cache status from FastAPI
   */
  async getCacheStatus(): Promise<{
    success: boolean;
    cached_datasets?: number[];
    total_cached?: number;
    error?: string;
  }> {
    try {
      const response = await fetch(`${this.baseUrl}/api/cache-status`, {
        method: 'GET',
        headers: {
          'Accept': 'application/json'
        }
      });

      if (!response.ok) {
        return {
          success: false,
          error: `HTTP ${response.status}: ${response.statusText}`
        };
      }

      const result = await response.json();
      
      return {
        success: true,
        cached_datasets: result.cached_datasets || [],
        total_cached: result.total_cached || 0
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Validate FastAPI response format
   */
  private validateFastAPIResponse(data: any, expectedSize: number): boolean {
    try {
      // Check required fields
      if (!data || typeof data !== 'object') return false;
      if (!Array.isArray(data.data)) return false;
      if (typeof data.stats !== 'object') return false;
      if (typeof data.total_rows !== 'number') return false;
      if (typeof data.filtered_rows !== 'number') return false;
      
      // Check data structure
      if (data.data.length > 0) {
        const firstPoint = data.data[0];
        const requiredFields = ['gene', 'logFC', 'padj', 'category'];
        
        for (const field of requiredFields) {
          if (!(field in firstPoint)) return false;
        }
      }
      
      // Check stats structure
      const requiredStats = ['up_regulated', 'down_regulated', 'non_significant'];
      for (const stat of requiredStats) {
        if (typeof data.stats[stat] !== 'number') return false;
      }
      
      // Validate data consistency
      const totalFromStats = data.stats.up_regulated + data.stats.down_regulated + data.stats.non_significant;
      if (Math.abs(totalFromStats - data.total_rows) > data.total_rows * 0.1) {
        console.warn('Stats inconsistency detected');
      }
      
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Extract processing time from response metadata
   */
  private extractProcessingTime(responseData: any, totalTime: number): number {
    // FastAPI doesn't return explicit processing time, so we estimate
    // based on response characteristics and total time
    
    if (responseData.is_downsampled) {
      // Downsampling indicates more processing
      return Math.floor(totalTime * 0.8);
    }
    
    // Estimate based on dataset size
    const dataSize = responseData.total_rows || 0;
    if (dataSize > 100000) {
      return Math.floor(totalTime * 0.9);
    } else if (dataSize > 10000) {
      return Math.floor(totalTime * 0.7);
    } else {
      return Math.floor(totalTime * 0.5);
    }
  }

  /**
   * Detect if the request hit cache based on response characteristics
   */
  private detectCacheHit(responseData: any, expected: boolean, responseTime: number): boolean {
    // Heuristics for cache hit detection:
    // 1. Very fast response time (< 50ms) likely indicates cache hit
    // 2. Response metadata might indicate caching
    // 3. Expected cache behavior based on test sequence
    
    if (responseTime < 50) {
      return true; // Very fast response suggests cache hit
    }
    
    if (responseTime < 200 && expected) {
      return true; // Fast response when cache expected
    }
    
    // Check if response has cache indicators
    if (responseData.metadata && responseData.metadata.cached) {
      return true;
    }
    
    return expected && responseTime < 500; // Conservative cache detection
  }

  /**
   * Test if the FastAPI service is available
   */
  async isServiceAvailable(): Promise<boolean> {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 5000);
      
      const response = await fetch(`${this.baseUrl}/health`, {
        method: 'GET',
        signal: controller.signal
      });
      
      clearTimeout(timeoutId);
      
      return response.ok;
    } catch (error) {
      return false;
    }
  }

  /**
   * Get FastAPI service information
   */
  async getServiceInfo(): Promise<{
    available: boolean;
    version?: string;
    endpoints?: string[];
    cache_status?: any;
    error?: string;
  }> {
    try {
      // Check health
      const healthResponse = await fetch(`${this.baseUrl}/health`);
      if (!healthResponse.ok) {
        return {
          available: false,
          error: `Health check failed: ${healthResponse.status}`
        };
      }

      // Get root info
      const rootResponse = await fetch(`${this.baseUrl}/`);
      const rootData = rootResponse.ok ? await rootResponse.json() : {};

      // Get cache status
      const cacheStatus = await this.getCacheStatus();

      return {
        available: true,
        version: rootData.version || 'unknown',
        endpoints: [
          '/api/volcano-data',
          '/api/cache-status',
          '/api/clear-cache',
          '/api/warm-cache',
          '/health'
        ],
        cache_status: cacheStatus.success ? {
          cached_datasets: cacheStatus.cached_datasets,
          total_cached: cacheStatus.total_cached
        } : undefined
      };

    } catch (error) {
      return {
        available: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Test downsampling behavior with large datasets
   */
  async testDownsamplingBehavior(sizes: number[] = [10000, 50000, 100000]): Promise<{
    success: boolean;
    results?: Array<{
      size: number;
      is_downsampled: boolean;
      points_returned: number;
      points_before_sampling: number;
      response_time: number;
    }>;
    error?: string;
  }> {
    try {
      const results = [];
      
      for (const size of sizes) {
        const startTime = Date.now();
        
        const params = new URLSearchParams({
          dataset_size: size.toString(),
          max_points: '10000', // Force downsampling for larger datasets
          p_value_threshold: '0.05'
        });

        const response = await fetch(`${this.baseUrl}/api/volcano-data?${params}`, {
          method: 'GET',
          headers: { 'Accept': 'application/json' }
        });

        const responseTime = Date.now() - startTime;

        if (!response.ok) {
          throw new Error(`Failed for size ${size}: ${response.status}`);
        }

        const data = await response.json();
        
        results.push({
          size: size,
          is_downsampled: data.is_downsampled || false,
          points_returned: data.filtered_rows || data.data.length,
          points_before_sampling: data.points_before_sampling || data.total_rows,
          response_time: responseTime
        });
      }

      return {
        success: true,
        results: results
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}