import axios, { AxiosResponse } from 'axios';
import { HealthCheckResult, ServiceName, BenchmarkConfig } from '../types';

export class ServiceHealthChecker {
  private config: BenchmarkConfig;
  private defaultTimeout: number = 10000; // 10 seconds

  constructor(config: BenchmarkConfig) {
    this.config = config;
  }

  /**
   * Check health of all enabled services
   */
  async checkAllServices(): Promise<HealthCheckResult[]> {
    const results: HealthCheckResult[] = [];
    
    // Check each service if enabled
    if (this.config.services.client_side.enabled) {
      results.push(await this.checkClientSideService());
    }
    
    if (this.config.services.server_side.enabled) {
      results.push(await this.checkServerSideService());
    }
    
    if (this.config.services.fastapi.enabled) {
      results.push(await this.checkFastAPIService());
    }
    
    if (this.config.services.r_backend.enabled) {
      results.push(await this.checkRBackendService());
    }
    
    return results;
  }

  /**
   * Check health of a specific service
   */
  async checkService(serviceName: ServiceName): Promise<HealthCheckResult> {
    switch (serviceName) {
      case 'client-side':
        return this.checkClientSideService();
      case 'server-side':
        return this.checkServerSideService();
      case 'fastapi':
        return this.checkFastAPIService();
      case 'r-backend':
        return this.checkRBackendService();
      default:
        throw new Error(`Unknown service: ${serviceName}`);
    }
  }

  /**
   * Check client-side service (browser automation capability)
   */
  private async checkClientSideService(): Promise<HealthCheckResult> {
    const startTime = Date.now();
    
    try {
      // For client-side, we check if we can import Puppeteer
      // This is a basic check - actual browser launch will be tested during execution
      const puppeteer = await import('puppeteer');
      const responseTime = Date.now() - startTime;
      
      return {
        service: 'client-side',
        available: true,
        responseTime,
        version: 'puppeteer-available'
      };
    } catch (error) {
      return {
        service: 'client-side',
        available: false,
        error: `Puppeteer not available: ${error instanceof Error ? error.message : 'Unknown error'}`
      };
    }
  }

  /**
   * Check server-side service (Next.js API routes)
   */
  private async checkServerSideService(): Promise<HealthCheckResult> {
    const endpoint = this.config.services.server_side.endpoint;
    const healthUrl = `${endpoint}/api/health`;
    
    return this.performHttpHealthCheck('server-side', healthUrl);
  }

  /**
   * Check FastAPI service
   */
  private async checkFastAPIService(): Promise<HealthCheckResult> {
    const endpoint = this.config.services.fastapi.endpoint;
    const healthUrl = `${endpoint}/health`;
    
    return this.performHttpHealthCheck('fastapi', healthUrl);
  }

  /**
   * Check R backend service
   */
  private async checkRBackendService(): Promise<HealthCheckResult> {
    const endpoint = this.config.services.r_backend.endpoint;
    const healthUrl = `${endpoint}/api/health`;
    
    return this.performHttpHealthCheck('r-backend', healthUrl);
  }

  /**
   * Perform HTTP health check for API-based services
   */
  private async performHttpHealthCheck(
    serviceName: ServiceName, 
    url: string
  ): Promise<HealthCheckResult> {
    const startTime = Date.now();
    
    try {
      const response: AxiosResponse = await axios.get(url, {
        timeout: this.defaultTimeout,
        validateStatus: (status) => status < 500 // Accept 4xx as "available but not healthy"
      });
      
      const responseTime = Date.now() - startTime;
      
      // Check if response indicates healthy service
      const isHealthy = response.status === 200;
      
      let version: string | undefined;
      if (response.data && typeof response.data === 'object') {
        version = response.data.version || response.data.status || 'unknown';
      }
      
      return {
        service: serviceName,
        available: isHealthy,
        responseTime,
        version,
        endpoint: url,
        error: isHealthy ? undefined : `HTTP ${response.status}: ${response.statusText}`
      };
    } catch (error) {
      const responseTime = Date.now() - startTime;
      
      if (axios.isAxiosError(error)) {
        let errorMessage = 'Unknown network error';
        
        if (error.code === 'ECONNREFUSED') {
          errorMessage = 'Connection refused - service not running';
        } else if (error.code === 'ETIMEDOUT' || error.message.includes('timeout')) {
          errorMessage = `Timeout after ${this.defaultTimeout}ms`;
        } else if (error.response) {
          errorMessage = `HTTP ${error.response.status}: ${error.response.statusText}`;
        } else if (error.message) {
          errorMessage = error.message;
        }
        
        return {
          service: serviceName,
          available: false,
          responseTime,
          endpoint: url,
          error: errorMessage
        };
      }
      
      return {
        service: serviceName,
        available: false,
        responseTime,
        endpoint: url,
        error: error instanceof Error ? error.message : 'Unknown error'
      };
    }
  }

  /**
   * Validate that all required services are available
   */
  async validateRequiredServices(): Promise<{ valid: boolean; errors: string[] }> {
    const healthResults = await this.checkAllServices();
    const errors: string[] = [];
    
    for (const result of healthResults) {
      if (!result.available) {
        errors.push(`${result.service}: ${result.error || 'Service unavailable'}`);
      }
    }
    
    return {
      valid: errors.length === 0,
      errors
    };
  }

  /**
   * Get summary of service availability
   */
  async getServiceSummary(): Promise<{
    total: number;
    available: number;
    unavailable: number;
    results: HealthCheckResult[];
  }> {
    const results = await this.checkAllServices();
    
    return {
      total: results.length,
      available: results.filter(r => r.available).length,
      unavailable: results.filter(r => !r.available).length,
      results
    };
  }

  /**
   * Wait for services to become available (with retry logic)
   */
  async waitForServices(
    maxRetries: number = 5, 
    retryDelay: number = 2000
  ): Promise<HealthCheckResult[]> {
    let attempt = 0;
    
    while (attempt < maxRetries) {
      const results = await this.checkAllServices();
      const allAvailable = results.every(r => r.available);
      
      if (allAvailable) {
        return results;
      }
      
      attempt++;
      if (attempt < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      }
    }
    
    // Return final results even if not all services are available
    return this.checkAllServices();
  }
}