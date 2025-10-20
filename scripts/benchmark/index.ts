#!/usr/bin/env node

/**
 * Performance Benchmark System
 * Main entry point for running performance tests across all implementations
 */

import { CLIRunner } from './cli';
import { ConfigManager } from './utils/ConfigManager';
import { Logger } from './utils/Logger';

async function main() {
  try {
    // Parse command-line arguments
    const cliRunner = new CLIRunner();
    const cliOptions = cliRunner.parseArgs();
    cliRunner.validateOptions(cliOptions);
    
    // Initialize logger with verbose setting
    const logger = new Logger(cliOptions.verbose || false);
    
    logger.info('Starting Performance Benchmark System...');
    
    if (cliOptions.dryRun) {
      logger.info('DRY RUN MODE - No tests will be executed');
    }
    
    // Load configuration
    const configManager = new ConfigManager();
    const config = await configManager.loadConfig(cliOptions);
    
    logger.debug('Configuration loaded:', config);
    
    if (cliOptions.dryRun) {
      logger.info('Configuration validation completed');
      logger.info('Enabled services:', Object.entries(config.services)
        .filter(([_, service]) => service.enabled)
        .map(([name]) => name));
      logger.info('Test sizes:', config.test_sizes);
      logger.info('Iterations per test:', config.iterations_per_test);
      logger.info('Output directory:', config.output.output_dir);
      return;
    }
    
    // TODO: Initialize and run BenchmarkRunner when implemented
    logger.warn('BenchmarkRunner not yet implemented - this is a placeholder');
    
    // const runner = new BenchmarkRunner(config, logger);
    // const results = await runner.runBenchmarks();
    
    logger.success('Benchmark system setup completed successfully');
    
  } catch (error) {
    const logger = new Logger(true); // Enable verbose for error reporting
    logger.error('Benchmark execution failed:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}