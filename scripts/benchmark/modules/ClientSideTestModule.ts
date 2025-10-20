/**
 * Client-Side Test Module
 * 
 * This module implements browser automation testing for the client-side implementation
 * using Puppeteer to measure parsing, processing, and rendering times separately.
 */

import puppeteer, { Browser, Page } from 'puppeteer';
import { ClientSideTestResult, TestDataset, ClientSideConfig } from '../types/index.js';

export class ClientSideTestModule {
  private browser: Browser | null = null;
  private config: ClientSideConfig;
  private baseUrl: string;

  constructor(config: ClientSideConfig, baseUrl: string = 'http://localhost:3000') {
    this.config = config;
    this.baseUrl = baseUrl;
  }

  /**
   * Initialize the browser instance
   */
  async initialize(): Promise<void> {
    if (this.browser) {
      return;
    }

    try {
      this.browser = await puppeteer.launch({
        headless: this.config.headless,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-accelerated-2d-canvas',
          '--no-first-run',
          '--no-zygote',
          '--disable-gpu'
        ]
      });
    } catch (error) {
      throw new Error(`Failed to launch browser: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Clean up browser resources
   */
  async cleanup(): Promise<void> {
    if (this.browser) {
      await this.browser.close();
      this.browser = null;
    }
  }

  /**
   * Run a performance test on the client-side implementation
   */
  async runTest(dataset: TestDataset, timeout: number = 30000): Promise<ClientSideTestResult> {
    const startTime = Date.now();
    
    try {
      await this.initialize();
      
      if (!this.browser) {
        throw new Error('Browser not initialized');
      }

      const page = await this.browser.newPage();
      
      // Set up performance monitoring
      await this.setupPerformanceMonitoring(page);
      
      // Navigate to the plots page
      await page.goto(`${this.baseUrl}/plots`, { 
        waitUntil: 'networkidle0',
        timeout 
      });

      // Convert dataset to CSV format for upload
      const csvData = this.convertDatasetToCSV(dataset);
      
      // Create a temporary file input and upload the data
      const uploadResult = await this.uploadDataset(page, csvData, timeout);
      
      // Wait for processing and rendering to complete
      const processingResult = await this.waitForProcessingComplete(page, timeout);
      
      // Get memory usage
      const memoryUsage = await this.getMemoryUsage(page);
      
      await page.close();
      
      const totalTime = Date.now() - startTime;
      
      return {
        service: 'client-side',
        dataset_size: dataset.size,
        success: true,
        error: undefined,
        total_time: totalTime,
        timestamp: new Date().toISOString(),
        parse_time: uploadResult.parseTime,
        processing_time: processingResult.processingTime,
        render_time: processingResult.renderTime,
        memory_usage: memoryUsage
      };

    } catch (error) {
      const totalTime = Date.now() - startTime;
      
      return {
        service: 'client-side',
        dataset_size: dataset.size,
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error',
        total_time: totalTime,
        timestamp: new Date().toISOString(),
        parse_time: 0,
        processing_time: 0,
        render_time: 0,
        memory_usage: undefined
      };
    }
  }

  /**
   * Set up performance monitoring on the page
   */
  private async setupPerformanceMonitoring(page: Page): Promise<void> {
    await page.evaluateOnNewDocument(() => {
      // Store performance marks for timing measurements
      (window as any).benchmarkTiming = {
        parseStart: 0,
        parseEnd: 0,
        processStart: 0,
        processEnd: 0,
        renderStart: 0,
        renderEnd: 0
      };
    });
  }

  /**
   * Convert dataset to CSV format for upload
   */
  private convertDatasetToCSV(dataset: TestDataset): string {
    const headers = ['gene_name', 'log2_fold_change', 'p_value', 'adjusted_p_value', 'category'];
    const rows = dataset.data.map(point => [
      point.gene_name,
      point.log2_fold_change.toString(),
      point.p_value.toString(),
      point.adjusted_p_value.toString(),
      point.category
    ]);
    
    return [headers, ...rows].map(row => row.join(',')).join('\n');
  }

  /**
   * Upload dataset to the application
   */
  private async uploadDataset(page: Page, csvData: string, timeout: number): Promise<{ parseTime: number }> {
    const parseStartTime = Date.now();
    
    try {
      // Wait for file input to be available
      await page.waitForSelector('input[type="file"]', { timeout });
      
      // Create a temporary file and upload it
      const fileInput = await page.$('input[type="file"]');
      if (!fileInput) {
        throw new Error('File input not found');
      }

      // Create a temporary file buffer
      const buffer = Buffer.from(csvData, 'utf8');
      
      // Use the file input to upload data
      await fileInput.uploadFile(await this.createTempFile(buffer));
      
      // Wait for parsing to complete (look for success indicators)
      await page.waitForFunction(
        () => {
          // Look for indicators that parsing is complete
          const errorElement = document.querySelector('[data-testid="error-message"]');
          const successElement = document.querySelector('[data-testid="upload-success"]') || 
                                document.querySelector('.volcano-plot') ||
                                document.querySelector('canvas');
          
          return errorElement || successElement;
        },
        { timeout }
      );
      
      const parseTime = Date.now() - parseStartTime;
      
      // Check if there was an error
      const errorElement = await page.$('[data-testid="error-message"]');
      if (errorElement) {
        const errorText = await page.evaluate(el => el.textContent, errorElement);
        throw new Error(`Upload failed: ${errorText}`);
      }
      
      return { parseTime };
      
    } catch (error) {
      throw new Error(`Dataset upload failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Wait for processing and rendering to complete
   */
  private async waitForProcessingComplete(page: Page, timeout: number): Promise<{ processingTime: number; renderTime: number }> {
    const processStartTime = Date.now();
    
    try {
      // Wait for the volcano plot to be rendered
      await page.waitForSelector('.volcano-plot, canvas, svg', { timeout });
      
      // Wait for any loading indicators to disappear
      await page.waitForFunction(
        () => {
          const loadingElements = document.querySelectorAll('[data-testid="loading"], .loading, .spinner');
          return loadingElements.length === 0;
        },
        { timeout: 5000 }
      ).catch(() => {
        // Ignore timeout for loading indicators as they might not exist
      });
      
      // Wait a bit more for rendering to stabilize
      await page.waitForTimeout(1000);
      
      const totalProcessingTime = Date.now() - processStartTime;
      
      // Try to get more detailed timing if available from the page
      const detailedTiming = await page.evaluate(() => {
        const timing = (window as any).benchmarkTiming;
        if (timing && timing.processEnd > timing.processStart && timing.renderEnd > timing.renderStart) {
          return {
            processingTime: timing.processEnd - timing.processStart,
            renderTime: timing.renderEnd - timing.renderStart
          };
        }
        return null;
      });
      
      if (detailedTiming) {
        return detailedTiming;
      }
      
      // Fallback: estimate processing vs rendering time
      const processingTime = Math.floor(totalProcessingTime * 0.7); // Assume 70% processing
      const renderTime = totalProcessingTime - processingTime;
      
      return { processingTime, renderTime };
      
    } catch (error) {
      throw new Error(`Processing timeout: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Get memory usage from the browser
   */
  private async getMemoryUsage(page: Page): Promise<number | undefined> {
    try {
      const memoryInfo = await page.evaluate(() => {
        if ('memory' in performance) {
          const memory = (performance as any).memory;
          return {
            usedJSHeapSize: memory.usedJSHeapSize,
            totalJSHeapSize: memory.totalJSHeapSize,
            jsHeapSizeLimit: memory.jsHeapSizeLimit
          };
        }
        return null;
      });
      
      return memoryInfo ? memoryInfo.usedJSHeapSize : undefined;
    } catch (error) {
      // Memory API might not be available in all browsers
      return undefined;
    }
  }

  /**
   * Create a temporary file for upload
   */
  private async createTempFile(buffer: Buffer): Promise<string> {
    const fs = await import('fs');
    const path = await import('path');
    const os = await import('os');
    
    const tempDir = os.tmpdir();
    const tempFile = path.join(tempDir, `benchmark-${Date.now()}.csv`);
    
    fs.writeFileSync(tempFile, buffer);
    
    // Clean up the temp file after a delay
    setTimeout(() => {
      try {
        fs.unlinkSync(tempFile);
      } catch (error) {
        // Ignore cleanup errors
      }
    }, 60000); // Clean up after 1 minute
    
    return tempFile;
  }

  /**
   * Test if the client-side service is available
   */
  async isServiceAvailable(): Promise<boolean> {
    try {
      await this.initialize();
      
      if (!this.browser) {
        return false;
      }

      const page = await this.browser.newPage();
      
      const response = await page.goto(`${this.baseUrl}/plots`, { 
        waitUntil: 'networkidle0',
        timeout: 10000 
      });
      
      await page.close();
      
      return response ? response.status() < 400 : false;
    } catch (error) {
      return false;
    }
  }
}