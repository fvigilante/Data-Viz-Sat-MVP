#!/usr/bin/env node

/**
 * CLI Runner for Performance Benchmark System
 * Handles command-line argument parsing and help system
 */

import { CLIOptions } from './types';

export class CLIRunner {
  private args: string[];
  
  constructor(args: string[] = process.argv.slice(2)) {
    this.args = args;
  }
  
  /**
   * Parse command-line arguments
   */
  parseArgs(): CLIOptions {
    const options: CLIOptions = {};
    
    for (let i = 0; i < this.args.length; i++) {
      const arg = this.args[i];
      
      // Handle --option=value format
      if (arg.includes('=')) {
        const [option, value] = arg.split('=', 2);
        this.handleOption(option, value, options);
        continue;
      }
      
      // Handle --option value format
      switch (arg) {
        case '--help':
        case '-h':
          this.showHelp();
          process.exit(0);
          break;
          
        case '--config':
        case '-c':
          options.config = this.getNextArg(i++, 'config');
          break;
          
        case '--sizes':
        case '-s':
          options.sizes = this.getNextArg(i++, 'sizes');
          break;
          
        case '--services':
          options.services = this.getNextArg(i++, 'services');
          break;
          
        case '--iterations':
        case '-i':
          const iterationsStr = this.getNextArg(i++, 'iterations');
          options.iterations = parseInt(iterationsStr, 10);
          if (isNaN(options.iterations)) {
            throw new Error(`Invalid iterations value: ${iterationsStr}`);
          }
          break;
          
        case '--timeout':
        case '-t':
          const timeoutStr = this.getNextArg(i++, 'timeout');
          options.timeout = parseInt(timeoutStr, 10);
          if (isNaN(options.timeout)) {
            throw new Error(`Invalid timeout value: ${timeoutStr}`);
          }
          break;
          
        case '--output':
        case '-o':
          options.output = this.getNextArg(i++, 'output');
          break;
          
        case '--verbose':
        case '-v':
          options.verbose = true;
          break;
          
        case '--dry-run':
          options.dryRun = true;
          break;
          
        case '--no-update-about':
          options.updateAboutPage = false;
          break;
          
        case '--update-about':
          options.updateAboutPage = true;
          break;
          
        default:
          if (arg.startsWith('-')) {
            throw new Error(`Unknown option: ${arg}`);
          }
          break;
      }
    }
    
    return options;
  }
  
  /**
   * Handle option=value format
   */
  private handleOption(option: string, value: string, options: CLIOptions): void {
    switch (option) {
      case '--config':
      case '-c':
        options.config = value;
        break;
        
      case '--sizes':
      case '-s':
        options.sizes = value;
        break;
        
      case '--services':
        options.services = value;
        break;
        
      case '--iterations':
      case '-i':
        options.iterations = parseInt(value, 10);
        if (isNaN(options.iterations)) {
          throw new Error(`Invalid iterations value: ${value}`);
        }
        break;
        
      case '--timeout':
      case '-t':
        options.timeout = parseInt(value, 10);
        if (isNaN(options.timeout)) {
          throw new Error(`Invalid timeout value: ${value}`);
        }
        break;
        
      case '--output':
      case '-o':
        options.output = value;
        break;
        
      default:
        throw new Error(`Unknown option: ${option}`);
    }
  }
  
  /**
   * Get the next argument value
   */
  private getNextArg(index: number, optionName: string): string {
    const nextArg = this.args[index + 1];
    if (!nextArg || nextArg.startsWith('-')) {
      throw new Error(`Option --${optionName} requires a value`);
    }
    return nextArg;
  }
  
  /**
   * Show help information
   */
  showHelp(): void {
    console.log(`
Performance Benchmark System

USAGE:
  npm run benchmark [OPTIONS]
  node scripts/benchmark/index.ts [OPTIONS]

OPTIONS:
  -h, --help                    Show this help message
  -c, --config <path>          Path to configuration file (default: config/default.json)
  -s, --sizes <sizes>          Comma-separated list of dataset sizes (e.g., "1000,10000,50000")
  --services <services>        Comma-separated list of services to test (client-side,server-side,fastapi,r-backend)
  -i, --iterations <number>    Number of test iterations per size (default: 3)
  -t, --timeout <ms>           Timeout per test in milliseconds (default: 30000)
  -o, --output <path>          Output directory path (default: scripts/benchmark/output)
  -v, --verbose                Enable verbose logging
  --dry-run                    Show what would be executed without running tests
  --update-about               Update about page with results (default: true)
  --no-update-about            Skip updating about page

EXAMPLES:
  # Run all tests with default configuration
  npm run benchmark

  # Test only specific services with custom sizes
  npm run benchmark -- --services=fastapi,r-backend --sizes=1000,10000

  # Run with more iterations for better accuracy
  npm run benchmark -- --iterations=5 --verbose

  # Dry run to see what would be executed
  npm run benchmark -- --dry-run

  # Test with custom timeout and output directory
  npm run benchmark -- --timeout=60000 --output=./my-results

SERVICES:
  client-side    Test client-side implementation with browser automation
  server-side    Test Next.js server-side API routes
  fastapi        Test Python FastAPI backend with Polars
  r-backend      Test R backend with data.table and Plumber

DATASET SIZES:
  Default sizes: 1K, 10K, 50K, 100K, 500K, 1M data points
  Custom sizes can be specified with --sizes option

OUTPUT:
  Results are saved to the output directory in JSON format
  If --update-about is enabled, the about page performance matrix is updated
  Backup files are created before any file modifications

For more information, see the documentation in the design.md file.
`);
  }
  
  /**
   * Validate parsed options
   */
  validateOptions(options: CLIOptions): void {
    // Validate sizes format if provided
    if (options.sizes) {
      const sizes = options.sizes.split(',');
      for (const size of sizes) {
        const num = parseInt(size.trim(), 10);
        if (isNaN(num) || num <= 0) {
          throw new Error(`Invalid size value: ${size}. Must be a positive integer`);
        }
      }
    }
    
    // Validate services format if provided
    if (options.services) {
      const validServices = ['client-side', 'server-side', 'fastapi', 'r-backend'];
      const services = options.services.split(',').map(s => s.trim());
      
      for (const service of services) {
        if (!validServices.includes(service)) {
          throw new Error(`Invalid service: ${service}. Valid services: ${validServices.join(', ')}`);
        }
      }
    }
    
    // Validate iterations
    if (options.iterations !== undefined && (options.iterations <= 0 || !Number.isInteger(options.iterations))) {
      throw new Error('Iterations must be a positive integer');
    }
    
    // Validate timeout
    if (options.timeout !== undefined && (options.timeout <= 0 || !Number.isInteger(options.timeout))) {
      throw new Error('Timeout must be a positive integer');
    }
  }
}