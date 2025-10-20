import * as fs from 'fs';
import * as path from 'path';
import { BenchmarkConfig, CLIOptions } from '../types';

export class ConfigManager {
  private defaultConfigPath = path.join(__dirname, '../config/default.json');
  
  /**
   * Load configuration from file and merge with CLI options
   */
  async loadConfig(cliOptions: CLIOptions = {}): Promise<BenchmarkConfig> {
    try {
      // Load base configuration
      const configPath = cliOptions.config || this.defaultConfigPath;
      const baseConfig = await this.loadConfigFile(configPath);
      
      // Merge with CLI options
      const mergedConfig = this.mergeWithCLIOptions(baseConfig, cliOptions);
      
      // Validate configuration
      this.validateConfig(mergedConfig);
      
      return mergedConfig;
    } catch (error) {
      throw new Error(`Failed to load configuration: ${error.message}`);
    }
  }
  
  /**
   * Load configuration from JSON file
   */
  private async loadConfigFile(configPath: string): Promise<BenchmarkConfig> {
    if (!fs.existsSync(configPath)) {
      throw new Error(`Configuration file not found: ${configPath}`);
    }
    
    const configContent = fs.readFileSync(configPath, 'utf-8');
    
    try {
      return JSON.parse(configContent) as BenchmarkConfig;
    } catch (error) {
      throw new Error(`Invalid JSON in configuration file: ${configPath}`);
    }
  }
  
  /**
   * Merge base configuration with CLI options
   */
  private mergeWithCLIOptions(baseConfig: BenchmarkConfig, cliOptions: CLIOptions): BenchmarkConfig {
    const config = { ...baseConfig };
    
    // Override test sizes if provided
    if (cliOptions.sizes) {
      config.test_sizes = cliOptions.sizes.split(',').map(size => parseInt(size.trim(), 10));
    }
    
    // Override iterations if provided
    if (cliOptions.iterations !== undefined) {
      config.iterations_per_test = cliOptions.iterations;
    }
    
    // Override timeout if provided
    if (cliOptions.timeout !== undefined) {
      config.timeout_ms = cliOptions.timeout;
    }
    
    // Override output directory if provided
    if (cliOptions.output) {
      config.output.output_dir = cliOptions.output;
    }
    
    // Override about page update setting
    if (cliOptions.updateAboutPage !== undefined) {
      config.output.update_about_page = cliOptions.updateAboutPage;
    }
    
    // Enable/disable specific services if provided
    if (cliOptions.services) {
      const enabledServices = cliOptions.services.split(',').map(s => s.trim());
      
      config.services.client_side.enabled = enabledServices.includes('client-side');
      config.services.server_side.enabled = enabledServices.includes('server-side');
      config.services.fastapi.enabled = enabledServices.includes('fastapi');
      config.services.r_backend.enabled = enabledServices.includes('r-backend');
    }
    
    return config;
  }
  
  /**
   * Validate configuration structure and values
   */
  private validateConfig(config: BenchmarkConfig): void {
    // Validate test sizes
    if (!Array.isArray(config.test_sizes) || config.test_sizes.length === 0) {
      throw new Error('test_sizes must be a non-empty array');
    }
    
    for (const size of config.test_sizes) {
      if (!Number.isInteger(size) || size <= 0) {
        throw new Error(`Invalid test size: ${size}. Must be a positive integer`);
      }
    }
    
    // Validate iterations
    if (!Number.isInteger(config.iterations_per_test) || config.iterations_per_test <= 0) {
      throw new Error('iterations_per_test must be a positive integer');
    }
    
    // Validate timeout
    if (!Number.isInteger(config.timeout_ms) || config.timeout_ms <= 0) {
      throw new Error('timeout_ms must be a positive integer');
    }
    
    // Validate that at least one service is enabled
    const enabledServices = Object.values(config.services).filter(service => service.enabled);
    if (enabledServices.length === 0) {
      throw new Error('At least one service must be enabled');
    }
    
    // Validate service endpoints
    if (config.services.server_side.enabled && !config.services.server_side.endpoint) {
      throw new Error('server_side endpoint is required when service is enabled');
    }
    
    if (config.services.fastapi.enabled && !config.services.fastapi.endpoint) {
      throw new Error('fastapi endpoint is required when service is enabled');
    }
    
    if (config.services.r_backend.enabled && !config.services.r_backend.endpoint) {
      throw new Error('r_backend endpoint is required when service is enabled');
    }
    
    // Validate output configuration
    if (!['json', 'csv', 'both'].includes(config.output.format)) {
      throw new Error('output.format must be "json", "csv", or "both"');
    }
    
    if (!config.output.output_dir) {
      throw new Error('output.output_dir is required');
    }
  }
  
  /**
   * Save configuration to file
   */
  async saveConfig(config: BenchmarkConfig, filePath: string): Promise<void> {
    try {
      const configJson = JSON.stringify(config, null, 2);
      fs.writeFileSync(filePath, configJson, 'utf-8');
    } catch (error) {
      throw new Error(`Failed to save configuration: ${error.message}`);
    }
  }
  
  /**
   * Get default configuration
   */
  getDefaultConfig(): BenchmarkConfig {
    return {
      version: "1.0.0",
      test_sizes: [1000, 10000, 50000, 100000, 500000, 1000000],
      iterations_per_test: 3,
      timeout_ms: 30000,
      services: {
        client_side: {
          enabled: true,
          browser: "chromium",
          headless: true
        },
        server_side: {
          enabled: true,
          endpoint: "http://localhost:3000"
        },
        fastapi: {
          enabled: true,
          endpoint: "http://localhost:8000",
          test_cache: true
        },
        r_backend: {
          enabled: true,
          endpoint: "http://localhost:8001"
        }
      },
      output: {
        format: "json",
        update_about_page: true,
        backup_original: true,
        output_dir: "scripts/benchmark/output"
      }
    };
  }
}