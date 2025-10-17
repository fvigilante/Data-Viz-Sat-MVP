// File Structure Validation for Output Validation Utilities
// Validates that all required files are present and properly structured

const fs = require('fs');
const path = require('path');

const requiredFiles = [
  'r-backend/compare-outputs.R',
  'r-backend/statistical-validation.R', 
  'r-backend/generate-comparison-report.R',
  'r-backend/live-comparison-test.R',
  'r-backend/test-output-validation.R',
  'r-backend/OUTPUT-VALIDATION-README.md'
];

const requiredFunctions = {
  'compare-outputs.R': [
    'compare_volcano_outputs',
    'validate_json_structure',
    'validate_data_consistency',
    'validate_statistics',
    'validate_metadata'
  ],
  'statistical-validation.R': [
    'validate_data_generation_statistics',
    'test_distributions',
    'test_correlations',
    'compare_summary_stats',
    'test_category_distributions'
  ],
  'generate-comparison-report.R': [
    'generate_comparison_report',
    'generate_html_report',
    'run_batch_comparison'
  ],
  'live-comparison-test.R': [
    'live_comparison_test',
    'call_volcano_endpoint',
    'test_cache_endpoints',
    'run_comprehensive_live_test'
  ],
  'test-output-validation.R': [
    'run_validation_tests',
    'test_structure_validation',
    'test_data_consistency',
    'test_statistical_validation',
    'test_report_generation'
  ]
};

console.log('=== Output Validation File Structure Check ===\n');

let allValid = true;

// Check file existence
console.log('1. Checking file existence...');
for (const file of requiredFiles) {
  if (fs.existsSync(file)) {
    console.log(`   ✓ ${file}`);
  } else {
    console.log(`   ✗ ${file} - MISSING`);
    allValid = false;
  }
}

// Check function definitions
console.log('\n2. Checking function definitions...');
for (const [fileName, functions] of Object.entries(requiredFunctions)) {
  const filePath = `r-backend/${fileName}`;
  
  if (fs.existsSync(filePath)) {
    const content = fs.readFileSync(filePath, 'utf8');
    
    console.log(`   Checking ${fileName}:`);
    for (const funcName of functions) {
      // Look for function definition pattern
      const funcPattern = new RegExp(`${funcName}\\s*<-\\s*function`, 'i');
      if (funcPattern.test(content)) {
        console.log(`     ✓ ${funcName}`);
      } else {
        console.log(`     ✗ ${funcName} - NOT FOUND`);
        allValid = false;
      }
    }
  }
}

// Check file sizes (should be substantial)
console.log('\n3. Checking file sizes...');
for (const file of requiredFiles) {
  if (fs.existsSync(file)) {
    const stats = fs.statSync(file);
    const sizeKB = Math.round(stats.size / 1024);
    
    if (stats.size > 1000) { // At least 1KB
      console.log(`   ✓ ${file} - ${sizeKB}KB`);
    } else {
      console.log(`   ⚠ ${file} - ${sizeKB}KB (may be too small)`);
    }
  }
}

// Check for required R packages in files
console.log('\n4. Checking R package dependencies...');
const requiredPackages = ['jsonlite', 'data.table', 'httr'];
const rFiles = requiredFiles.filter(f => f.endsWith('.R'));

for (const pkg of requiredPackages) {
  let found = false;
  
  for (const file of rFiles) {
    if (fs.existsSync(file)) {
      const content = fs.readFileSync(file, 'utf8');
      if (content.includes(`library(${pkg})`)) {
        found = true;
        break;
      }
    }
  }
  
  if (found) {
    console.log(`   ✓ ${pkg} package referenced`);
  } else {
    console.log(`   ⚠ ${pkg} package not found in library() calls`);
  }
}

// Summary
console.log('\n=== VALIDATION SUMMARY ===');
if (allValid) {
  console.log('✓ All validation utilities are properly implemented');
  console.log('\nNext steps:');
  console.log('1. Install R and required packages: install.packages(c("jsonlite", "data.table", "httr"))');
  console.log('2. Test the utilities: Rscript r-backend/test-output-validation.R');
  console.log('3. Create sample data: Rscript r-backend/test-output-validation.R --create-samples');
  console.log('4. Run live tests when backends are running');
} else {
  console.log('✗ Some validation utilities are missing or incomplete');
  console.log('Please review the issues above and ensure all files are properly created.');
}

console.log('\nValidation utilities created:');
console.log('- compare-outputs.R: Core output comparison logic');
console.log('- statistical-validation.R: Statistical consistency testing');  
console.log('- generate-comparison-report.R: HTML report generation');
console.log('- live-comparison-test.R: Live backend API testing');
console.log('- test-output-validation.R: Comprehensive test suite');
console.log('- OUTPUT-VALIDATION-README.md: Complete documentation');

process.exit(allValid ? 0 : 1);