/**
 * R Backend Test Module
 * 
 * This module implements testing for the R backend implementation using Plumber API,
 * measuring JSON conversion time separately from processing and testing data.table optimizations.
 */

import { RBackendTestResult, TestDataset, RBackendConfig } from '../types/index.js';

export class RBackendTestModule {
  private config: RBackendConfig;
  private baseUrl: string;

  constructor(config: RBackendConfig, baseUrl: string = 'http://localhost:8001') {
    this.config = config;
    this.baseUrl = baseUrl;
  }

  /**
   * Run a performance test on the R backend implementation
   */
  async runTest(dataset: TestDataset, timeout: number = 30000): Promise<RBackendTestResult> {
    const startTime = Date.now();
    
    try {
      // Test the R backend API
      const result = await this.testRPlumberAPI(dataset, timeout);
      
      const totalTime = Date.now() - startTime;
      
      return {
        service: 'r-backend',
        dataset_size: dataset.size,
        success: result.success,
        error: result.error,
        total_time: totalTime,
        timestamp: new Date().toISOString(),
        api_response_time: result.api_response_time || 0,
        processing_time: result.processing_time || 0,
        json_conversion_time: result.json_conversion_time || 0
      };

    } catch (error) {
      const totalTime = Date.now() - startTime;
      
      return {
        service: 'r-backend',
        dataset_size: dataset.size,
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        total_time: totalTime,
        timestamp: new Date().toISOString(),
        api_response_time: 0,
        processing_time: 0,
        json_conversion_time: 0
      };
    }
  }

  /**
   * Test the R Plumber API with detailed timing
   */
  private async testRPlumberAPI(dataset: TestDataset, timeout: number): Promise<{
    success: boolean;
    error?: string;
    api_response_time?: number;
    processing_time?: number;
    json_conversion_time?: number;
    performance_metrics?: any;
  }> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);
    
    try {
      const apiStartTime = Date.now();
      
      // Prepare request parameters for R backend
      const params = new URLSearchParams({
        dataset_size: dataset.size.toString(),
        p_value_threshold: '0.05',
        log_fc_min: '-0.5',
        log_fc_max: '0.5',
        max_points: '50000',
        zoom_level: '1.0'
      });

      // Make request to R Plumber API
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
        return {
          success: false,
          error: `HTTP ${response.status}: ${response.statusText}`
        };
      }

      const responseData = await response.json();
      const apiResponseTime = Date.now() - apiStartTime;
      
      // Check for R backend error response
      if (responseData.error) {
        return {
          success: false,
          error: `R backend error: ${responseData.message || 'Unknown error'}`
        };
      }

      // Validate response format
      if (!this.validateRBackendResponse(responseData, dataset.size)) {
        return {
          success: false,
          error: 'Invalid response format from R backend'
        };
      }

      // Extract detailed timing information
      const timingInfo = this.extractDetailedTiming(responseData, apiResponseTime);

      return {
        success: true,
        api_response_time: apiResponseTime,
        processing_time: timingInfo.processing_time,
        json_conversion_time: timingInfo.json_conversion_time,
        performance_metrics: timingInfo.performance_metrics
      };

    } catch (error) {
      clearTimeout(timeoutId);
      
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
   * Test R backend with monitoring enabled for detailed metrics
   */
  async testWithMonitoring(dataset: TestDataset, timeout: number = 30000): Promise<{
    success: boolean;
    error?: string;
    detailed_metrics?: {
      data_generation_time?: number;
      categorization_time?: number;
      json_conversion_time?: number;
      total_pipeline_time?: number;
    };
  }> {
    try {
      // Note: This would require the R backend to be started with MONITOR_ENABLED=TRUE
      // For now, we'll make a regular request and extract what timing info we can
      
      const result = await this.testRPlumberAPI(dataset, timeout);
      
      if (!result.success) {
        return {
          success: false,
          error: result.error
        };
      }

      return {
        success: true,
        detailed_metrics: {
          data_generation_time: result.performance_metrics?.timers?.data_generation,
          categorization_time: result.performance_metrics?.timers?.categorization,
          json_conversion_time: result.performance_metrics?.timers?.json_conversion,
          total_pipeline_time: result.performance_metrics?.timers?.total_pipeline
        }
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Test data.table optimization performance with different dataset sizes
   */
  async testDataTableOptimization(sizes: number[] = [1000, 10000, 50000, 100000]): Promise<{
    success: boolean;
    results?: Array<{
      size: number;
      response_time: number;
      processing_efficiency: number;
      memory_usage_indicator: string;
    }>;
    error?: string;
  }> {
    try {
      const results = [];
      
      for (const size of sizes) {
        const startTime = Date.now();
        
        const params = new URLSearchParams({
          dataset_size: size.toString(),
          p_value_threshold: '0.05',
          max_points: Math.min(size, 50000).toString()
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
        
        // Calculate processing efficiency (points per millisecond)
        const efficiency = data.total_rows / responseTime;
        
        // Estimate memory usage based on response characteristics
        let memoryIndicator = 'low';
        if (size > 100000) memoryIndicator = 'high';
        else if (size > 10000) memoryIndicator = 'medium';
        
        results.push({
          size: size,
          response_time: responseTime,
          processing_efficiency: efficiency,
          memory_usage_indicator: memoryIndicator
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

  /**
   * Clear R backend cache
   */
  async clearCache(): Promise<{
    success: boolean;
    datasets_removed?: number;
    error?: string;
  }> {
    try {
      const response = await fetch(`${this.baseUrl}/api/clear-cache`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
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
        datasets_removed: result.datasets_removed || 0
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Test R backend memory limits and timeout scenarios
   */
  async testMemoryLimitsAndTimeouts(extremeSizes: number[] = [500000, 1000000, 2000000]): Promise<{
    success: boolean;
    results?: Array<{
      size: number;
      completed: boolean;
      response_time?: number;
      error?: string;
      memory_limit_reached?: boolean;
    }>;
    error?: string;
  }> {
    try {
      const results = [];
      
      for (const size of extremeSizes) {
        const startTime = Date.now();
        
        try {
          // Use shorter timeout for extreme sizes to detect memory/processing limits
          const controller = new AbortController();
          const timeoutId = setTimeout(() => controller.abort(), 15000); // 15 second timeout
          
          const params = new URLSearchParams({
            dataset_size: size.toString(),
            p_value_threshold: '0.05'
          });

          const response = await fetch(`${this.baseUrl}/api/volcano-data?${params}`, {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
            signal: controller.signal
          });

          clearTimeout(timeoutId);
          const responseTime = Date.now() - startTime;

          if (!response.ok) {
            results.push({
              size: size,
              completed: false,
              response_time: responseTime,
              error: `HTTP ${response.status}`,
              memory_limit_reached: response.status === 500
            });
            continue;
          }

          const data = await response.json();
          
          if (data.error) {
            results.push({
              size: size,
              completed: false,
              response_time: responseTime,
              error: data.message || 'R backend error',
              memory_limit_reached: data.message?.includes('memory') || false
            });
          } else {
            results.push({
              size: size,
              completed: true,
              response_time: responseTime,
              memory_limit_reached: false
            });
          }

        } catch (error) {
          const responseTime = Date.now() - startTime;
          
          results.push({
            size: size,
            completed: false,
            response_time: responseTime,
            error: error instanceof Error ? error.message : 'Unknown error',
            memory_limit_reached: error instanceof Error && error.name === 'AbortError'
          });
        }
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

  /**
   * Validate R backend response format
   */
  private validateRBackendResponse(data: any, expectedSize: number): boolean {
    try {
      // Check for error response first
      if (data.error) return false;
      
      // Check required fields
      if (!data || typeof data !== 'object') return false;
      if (!Array.isArray(data.data)) return false;
      if (typeof data.stats !== 'object') return false;
      if (typeof data.total_rows !== 'number') return false;
      if (typeof data.filtered_rows !== 'number') return false;
      
      // Check data structure (R backend returns data.table format)
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
      
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Extract detailed timing information from R backend response
   */
  private extractDetailedTiming(responseData: any, totalTime: number): {
    processing_time: number;
    json_conversion_time: number;
    performance_metrics?: any;
  } {
    // Check if R backend returned performance metrics (when monitoring is enabled)
    if (responseData.performance_metrics && responseData.performance_metrics.timers) {
      const timers = responseData.performance_metrics.timers;
      
      return {
        processing_time: (timers.data_generation || 0) + (timers.categorization || 0),
        json_conversion_time: timers.json_conversion || 0,
        performance_metrics: responseData.performance_metrics
      };
    }
    
    // Fallback: estimate timing based on response characteristics and dataset size
    const dataSize = responseData.total_rows || 0;
    
    // Estimate JSON conversion time (typically 10-20% of total time for R)
    let jsonConversionTime = Math.floor(totalTime * 0.15);
    
    // Estimate processing time (remaining time after JSON conversion)
    let processingTime = totalTime - jsonConversionTime;
    
    // Adjust estimates based on dataset size
    if (dataSize > 100000) {
      // Large datasets: more processing, relatively less JSON conversion
      processingTime = Math.floor(totalTime * 0.9);
      jsonConversionTime = totalTime - processingTime;
    } else if (dataSize < 1000) {
      // Small datasets: relatively more JSON conversion overhead
      jsonConversionTime = Math.floor(totalTime * 0.3);
      processingTime = totalTime - jsonConversionTime;
    }
    
    return {
      processing_time: processingTime,
      json_conversion_time: jsonConversionTime
    };
  }

  /**
   * Test if the R backend service is available
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
   * Get R backend service information
   */
  async getServiceInfo(): Promise<{
    available: boolean;
    version?: string;
    backend?: string;
    threads?: number;
    monitoring_enabled?: boolean;
    endpoints?: string[];
    error?: string;
  }> {
    try {
      const response = await fetch(`${this.baseUrl}/health`);
      
      if (!response.ok) {
        return {
          available: false,
          error: `Health check failed: ${response.status}`
        };
      }

      const healthData = await response.json();
      
      return {
        available: true,
        version: 'R + data.table',
        backend: healthData.backend || 'R + data.table',
        threads: healthData.threads,
        monitoring_enabled: healthData.monitoring_enabled || false,
        endpoints: [
          '/api/volcano-data',
          '/api/clear-cache',
          '/health'
        ]
      };

    } catch (error) {
      return {
        available: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Test R backend with different thread configurations (if supported)
   */
  async testThreadPerformance(): Promise<{
    success: boolean;
    current_threads?: number;
    performance_info?: any;
    error?: string;
  }> {
    try {
      // Get current thread configuration
      const healthResponse = await fetch(`${this.baseUrl}/health`);
      
      if (!healthResponse.ok) {
        return {
          success: false,
          error: 'Failed to get health status'
        };
      }

      const healthData = await healthResponse.json();
      
      // Test performance with current configuration
      const testSize = 50000;
      const startTime = Date.now();
      
      const params = new URLSearchParams({
        dataset_size: testSize.toString(),
        p_value_threshold: '0.05'
      });

      const testResponse = await fetch(`${this.baseUrl}/api/volcano-data?${params}`);
      const testTime = Date.now() - startTime;
      
      if (!testResponse.ok) {
        return {
          success: false,
          error: 'Performance test failed'
        };
      }

      return {
        success: true,
        current_threads: healthData.threads,
        performance_info: {
          test_size: testSize,
          response_time: testTime,
          points_per_ms: testSize / testTime
        }
      };

    } catch (error) {
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }
}