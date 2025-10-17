#!/usr/bin/env node

// Validation script for the benchmarking framework
// Checks that all required files are present and properly structured

const fs = require('fs');
const path = require('path');

// Expected files in the benchmarking framework
const EXPECTED_FILES = [
  'benchmark-framework.R',
  'quick-benchmark.R',
  'memory-profiler.R',
  'automated-benchmark.R',
  'benchmark-runner.bat',
  'benchmark-runner.sh',
  'BENCHMARKING-README.md'
];

// Required functions that should be present in R scripts
const REQUIRED_FUNCTIONS = {
  'benchmark-framework.R': [
    'run_comprehensive_benchmark',
    'generate_performance_report',
    'benchmark_endpoint',
    'get_system_metrics'
  ],
  'quick-benchmark.R': [
    'run_quick_benchmark',
    'time_api_call',
    'check_api_health'
  ],
  'memory-profiler.R': [
    'profile_api_call',
    'run_memory_comparison',
    'generate_memory_report',
    'get_memory_usage'
  ],
  'automated-benchmark.R': [
    'run_automated_benchmark',
    'check_performance_alerts',
    'cleanup_old_results'
  ]
};

function validateFramework() {
  console.log('Validating Benchmarking Framework');
  console.log('='.repeat(50));
  
  let allValid = true;
  
  // Check if all expected files exist
  console.log('\n1. Checking required files...');
  for (const file of EXPECTED_FILES) {
    const filePath = path.join(__dirname, file);
    if (fs.existsSync(filePath)) {
      console.log(`   ✓ ${file}`);
    } else {
      console.log(`   ✗ ${file} - MISSING`);
      allValid = false;
    }
  }
  
  // Check R script structure
  console.log('\n2. Checking R script functions...');
  for (const [scriptName, functions] of Object.entries(REQUIRED_FUNCTIONS)) {
    const scriptPath = path.join(__dirname, scriptName);
    
    if (fs.existsSync(scriptPath)) {
      const content = fs.readFileSync(scriptPath, 'utf8');
      console.log(`   Checking ${scriptName}:`);
      
      for (const func of functions) {
        // Look for function definition pattern
        const funcPattern = new RegExp(`${func}\\s*<-\\s*function`, 'i');
        if (funcPattern.test(content)) {
          console.log(`     ✓ ${func}()`);
        } else {
          console.log(`     ✗ ${func}() - NOT FOUND`);
          allValid = false;
        }
      }
    }
  }
  
  // Check script executability markers
  console.log('\n3. Checking script headers...');
  const rScripts = EXPECTED_FILES.filter(f => f.endsWith('.R'));
  for (const script of rScripts) {
    const scriptPath = path.join(__dirname, script);
    if (fs.existsSync(scriptPath)) {
      const content = fs.readFileSync(scriptPath, 'utf8');
      if (content.startsWith('#!/usr/bin/env Rscript')) {
        console.log(`   ✓ ${script} - Has shebang`);
      } else {
        console.log(`   ⚠ ${script} - Missing shebang (optional)`);
      }
    }
  }
  
  // Check configuration structures
  console.log('\n4. Checking configuration structures...');
  
  // Check benchmark-framework.R for BENCHMARK_CONFIG
  const frameworkPath = path.join(__dirname, 'benchmark-framework.R');
  if (fs.existsSync(frameworkPath)) {
    const content = fs.readFileSync(frameworkPath, 'utf8');
    if (content.includes('BENCHMARK_CONFIG')) {
      console.log('   ✓ benchmark-framework.R - Has BENCHMARK_CONFIG');
    } else {
      console.log('   ✗ benchmark-framework.R - Missing BENCHMARK_CONFIG');
      allValid = false;
    }
  }
  
  // Check automated-benchmark.R for AUTO_CONFIG
  const autoPath = path.join(__dirname, 'automated-benchmark.R');
  if (fs.existsSync(autoPath)) {
    const content = fs.readFileSync(autoPath, 'utf8');
    if (content.includes('AUTO_CONFIG')) {
      console.log('   ✓ automated-benchmark.R - Has AUTO_CONFIG');
    } else {
      console.log('   ✗ automated-benchmark.R - Missing AUTO_CONFIG');
      allValid = false;
    }
  }
  
  // Check runner scripts
  console.log('\n5. Checking runner scripts...');
  
  const batPath = path.join(__dirname, 'benchmark-runner.bat');
  if (fs.existsSync(batPath)) {
    const content = fs.readFileSync(batPath, 'utf8');
    const hasCommands = ['quick', 'full', 'health', 'report'].every(cmd => 
      content.includes(`"${cmd}"`)
    );
    if (hasCommands) {
      console.log('   ✓ benchmark-runner.bat - Has all commands');
    } else {
      console.log('   ✗ benchmark-runner.bat - Missing commands');
      allValid = false;
    }
  }
  
  const shPath = path.join(__dirname, 'benchmark-runner.sh');
  if (fs.existsSync(shPath)) {
    const content = fs.readFileSync(shPath, 'utf8');
    const hasCommands = ['quick', 'full', 'health', 'report'].every(cmd => 
      content.includes(`"${cmd}"`)
    );
    if (hasCommands) {
      console.log('   ✓ benchmark-runner.sh - Has all commands');
    } else {
      console.log('   ✗ benchmark-runner.sh - Missing commands');
      allValid = false;
    }
  }
  
  // Summary
  console.log('\n' + '='.repeat(50));
  if (allValid) {
    console.log('✅ Benchmarking framework validation PASSED');
    console.log('\nFramework is ready for use. Next steps:');
    console.log('1. Ensure R is installed with required packages');
    console.log('2. Start both FastAPI and R API servers');
    console.log('3. Run: benchmark-runner.bat health (Windows) or ./benchmark-runner.sh health (Unix)');
    console.log('4. Execute benchmarks as needed');
  } else {
    console.log('❌ Benchmarking framework validation FAILED');
    console.log('\nPlease fix the issues above before using the framework.');
  }
  
  return allValid;
}

// Generate framework summary
function generateSummary() {
  const summary = {
    framework_name: 'R vs Python Volcano Plot Benchmarking Framework',
    version: '1.0.0',
    created: new Date().toISOString(),
    components: {
      core_scripts: EXPECTED_FILES.filter(f => f.endsWith('.R')).length,
      runner_scripts: EXPECTED_FILES.filter(f => f.includes('runner')).length,
      documentation: EXPECTED_FILES.filter(f => f.endsWith('.md')).length,
      total_files: EXPECTED_FILES.length
    },
    capabilities: [
      'Quick performance comparison',
      'Comprehensive benchmark suite',
      'Memory usage profiling',
      'Automated scheduled benchmarks',
      'Cross-platform execution',
      'HTML report generation',
      'Performance alert system',
      'Historical result tracking'
    ],
    requirements: {
      r_packages: ['httr', 'jsonlite', 'data.table', 'microbenchmark', 'knitr'],
      apis_required: ['FastAPI server', 'R Plumber API server'],
      platforms: ['Windows', 'Linux', 'macOS']
    }
  };
  
  const summaryPath = path.join(__dirname, 'framework-summary.json');
  fs.writeFileSync(summaryPath, JSON.stringify(summary, null, 2));
  console.log(`\nFramework summary saved to: ${summaryPath}`);
  
  return summary;
}

// Main execution
if (require.main === module) {
  const isValid = validateFramework();
  const summary = generateSummary();
  
  process.exit(isValid ? 0 : 1);
}

module.exports = { validateFramework, generateSummary };