# Performance Benchmark System

Automated performance testing system for comparing all volcano plot implementations (client-side, server-side, FastAPI, R backend) across different dataset sizes.

## Quick Start

```bash
# Run all tests with default configuration
npm run benchmark

# Show help and available options
npm run benchmark -- --help

# Test specific services only
npm run benchmark -- --services=fastapi,r-backend

# Run with custom dataset sizes
npm run benchmark -- --sizes=1000,10000,50000

# Dry run to see what would be executed
npm run benchmark -- --dry-run
```

## Directory Structure

```
scripts/benchmark/
├── index.ts              # Main entry point
├── cli.ts                # CLI argument parsing
├── types/                # TypeScript interfaces
│   └── index.ts
├── config/               # Configuration files
│   └── default.json      # Default benchmark configuration
├── modules/              # Test modules (to be implemented)
│   ├── BenchmarkRunner.ts
│   ├── ClientSideTestModule.ts
│   ├── ServerSideTestModule.ts
│   ├── FastAPITestModule.ts
│   ├── RBackendTestModule.ts
│   ├── ServiceHealthChecker.ts
│   ├── DatasetGenerator.ts
│   └── ResultsAggregator.ts
├── utils/                # Utility modules
│   ├── ConfigManager.ts  # Configuration loading and validation
│   ├── Logger.ts         # Logging system
│   ├── StatisticsCalculator.ts (to be implemented)
│   ├── FileUpdater.ts    (to be implemented)
│   └── CodeGenerator.ts  (to be implemented)
└── output/               # Benchmark results and reports
    ├── benchmark-results.json
    ├── performance-matrix.json
    ├── benchmark-report.md
    └── about-page-backup.tsx
```

## Configuration

The system uses a JSON configuration file with the following structure:

```json
{
  "version": "1.0.0",
  "test_sizes": [1000, 10000, 50000, 100000, 500000, 1000000],
  "iterations_per_test": 3,
  "timeout_ms": 30000,
  "services": {
    "client_side": { "enabled": true, "browser": "chromium", "headless": true },
    "server_side": { "enabled": true, "endpoint": "http://localhost:3000" },
    "fastapi": { "enabled": true, "endpoint": "http://localhost:8000", "test_cache": true },
    "r_backend": { "enabled": true, "endpoint": "http://localhost:8001" }
  },
  "output": {
    "format": "json",
    "update_about_page": true,
    "backup_original": true,
    "output_dir": "scripts/benchmark/output"
  }
}
```

## CLI Options

| Option | Description | Example |
|--------|-------------|---------|
| `--help, -h` | Show help message | `--help` |
| `--config, -c` | Custom config file | `--config=./my-config.json` |
| `--sizes, -s` | Dataset sizes to test | `--sizes=1000,10000,50000` |
| `--services` | Services to test | `--services=fastapi,r-backend` |
| `--iterations, -i` | Test iterations | `--iterations=5` |
| `--timeout, -t` | Timeout per test (ms) | `--timeout=60000` |
| `--output, -o` | Output directory | `--output=./results` |
| `--verbose, -v` | Verbose logging | `--verbose` |
| `--dry-run` | Show execution plan | `--dry-run` |
| `--update-about` | Update about page | `--update-about` |
| `--no-update-about` | Skip about page update | `--no-update-about` |

## Services

### Client-Side
- Tests browser-based CSV parsing and processing
- Uses Puppeteer for automation
- Measures parse, processing, and render times
- Monitors memory usage

### Server-Side
- Tests Next.js API routes
- Measures end-to-end response times
- Tests with multipart form data

### FastAPI
- Tests Python backend with Polars
- Measures both cached and uncached requests
- Validates downsampling behavior

### R Backend
- Tests R Plumber API with data.table
- Measures processing and JSON conversion separately
- Tests statistical optimizations

## Output Files

- **benchmark-results.json**: Raw test results with all metrics
- **performance-matrix.json**: Processed data for about page integration
- **benchmark-report.md**: Human-readable summary report
- **about-page-backup.tsx**: Backup of original about page (if updating)

## Implementation Status

✅ **Completed:**
- Project structure and directory setup
- TypeScript interfaces and type definitions
- CLI argument parsing and help system
- Configuration management and validation
- Logging system

🚧 **In Progress:**
- Test modules implementation
- Service health checking
- Dataset generation
- Results aggregation
- Statistical analysis
- About page integration

## Next Steps

1. Implement service health checker
2. Create test dataset generator
3. Build individual test modules for each service
4. Add results aggregation and statistical analysis
5. Create about page integration system
6. Add comprehensive error handling and validation

## Requirements

- Node.js with TypeScript support
- All services running (Next.js dev server, FastAPI, R backend)
- Browser automation dependencies (Puppeteer)

## Development

```bash
# Install dependencies (if needed)
npm install

# Run in development mode with verbose logging
npm run benchmark -- --verbose --dry-run

# Test specific configuration
npm run benchmark -- --config=./test-config.json --dry-run
```