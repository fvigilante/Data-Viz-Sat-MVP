# R Volcano Plot Integration - Testing Suite

This directory contains comprehensive tests for the R Volcano Plot integration feature. The testing suite covers all aspects of the implementation from unit tests to end-to-end workflows.

## Test Structure

### Frontend Tests (JavaScript/TypeScript)
- **Component Tests**: `test/components/RVolcanoPlot.test.tsx`
- **API Route Tests**: `test/api/r-volcano-routes.test.ts`
- **End-to-End Tests**: `test/e2e/r-volcano-workflow.test.ts`

### Backend Tests (R)
- **Unit Tests**: `r-backend/test-comprehensive-suite.R`
- **Integration Tests**: `r-backend/test-integration-suite.R`
- **Existing Tests**: Various `r-backend/test-*.R` files

## Running Tests

### All Tests
```bash
# Run all frontend tests
npm run test

# Run all R backend tests
npm run test:r

# Run integration tests (requires servers running)
npm run test:integration
```

### Individual Test Suites

#### Frontend Tests
```bash
# Run component tests only
npx vitest run test/components

# Run API route tests only  
npx vitest run test/api

# Run E2E tests only
npx vitest run test/e2e

# Watch mode for development
npx vitest watch
```

#### R Backend Tests
```bash
# Run comprehensive unit tests
cd r-backend && Rscript test-comprehensive-suite.R

# Run integration tests (requires R server running)
cd r-backend && Rscript test-integration-suite.R

# Run all R tests
cd r-backend && Rscript run-all-tests.R

# Run specific test
cd r-backend && Rscript test-data-generation.R
```

## Test Categories

### 1. Unit Tests

#### R Unit Tests (`test-comprehensive-suite.R`)
Tests core R functions in isolation:
- ✅ Dataset size validation
- ✅ Data generation structure and quality
- ✅ Categorization logic (up/down/non-significant)
- ✅ Intelligent sampling algorithm
- ✅ Search functionality
- ✅ Caching system
- ✅ Spatial filtering
- ✅ Level-of-detail calculations
- ✅ Error handling and edge cases
- ✅ Data consistency and reproducibility

#### React Component Tests (`RVolcanoPlot.test.tsx`)
Tests the React component behavior:
- ✅ Initial rendering and default values
- ✅ User interactions (filters, buttons, dropdowns)
- ✅ API integration and data fetching
- ✅ Error handling and loading states
- ✅ Data visualization and export functionality

### 2. Integration Tests

#### R API Integration (`test-integration-suite.R`)
Tests complete API endpoint functionality:
- ✅ Health check endpoint
- ✅ Main volcano data endpoint
- ✅ Cache management endpoints
- ✅ Parameter validation
- ✅ Search functionality
- ✅ Large dataset handling
- ✅ Concurrent request handling
- ✅ End-to-end workflow simulation

#### Next.js API Routes (`r-volcano-routes.test.ts`)
Tests the Next.js proxy layer:
- ✅ Request proxying to R backend
- ✅ Error handling and network failures
- ✅ Parameter passing and validation
- ✅ Response formatting
- ✅ Environment configuration

### 3. End-to-End Tests

#### Complete Workflow (`r-volcano-workflow.test.ts`)
Tests the entire application flow:
- ✅ Cache management workflow
- ✅ Data generation and filtering
- ✅ Large dataset performance
- ✅ Data consistency across requests
- ✅ Error condition handling

## Test Requirements

### Prerequisites
1. **Node.js Dependencies**:
   ```bash
   npm install
   ```

2. **R Dependencies**:
   ```bash
   cd r-backend
   Rscript install-packages.R
   ```

3. **Running Servers** (for integration/E2E tests):
   ```bash
   # Terminal 1: Start Next.js
   npm run dev
   
   # Terminal 2: Start R backend
   cd r-backend
   Rscript start-server.R
   ```

### Environment Variables
```bash
# Optional: Custom R backend URL
R_BACKEND_URL=http://localhost:8001

# Test environment
NODE_ENV=test
```

## Test Data and Mocking

### Frontend Mocks
- **Plotly.js**: Mocked to avoid rendering issues in tests
- **Next.js Router**: Mocked for navigation testing
- **Fetch API**: Mocked for API call testing
- **Dynamic Imports**: Mocked for component loading

### R Test Data
- **Synthetic Datasets**: Generated with known properties for validation
- **Edge Cases**: Boundary conditions and error scenarios
- **Performance Data**: Large datasets for performance testing

## Coverage and Quality

### Test Coverage Goals
- **R Functions**: 100% function coverage
- **React Components**: >90% line coverage
- **API Routes**: 100% endpoint coverage
- **Integration Paths**: All user workflows covered

### Quality Metrics
- **Performance**: Response times under acceptable limits
- **Reliability**: Consistent results across multiple runs
- **Error Handling**: Graceful degradation in failure scenarios
- **Data Integrity**: Validation of data consistency and accuracy

## Continuous Integration

### GitHub Actions (if configured)
```yaml
# Example CI configuration
- name: Run Frontend Tests
  run: npm run test

- name: Setup R
  uses: r-lib/actions/setup-r@v2

- name: Install R Dependencies
  run: cd r-backend && Rscript install-packages.R

- name: Run R Tests
  run: npm run test:r
```

### Local Pre-commit Hooks
```bash
# Run all tests before commit
npm run test && npm run test:r
```

## Debugging Tests

### Frontend Test Debugging
```bash
# Run tests with verbose output
npx vitest run --reporter=verbose

# Debug specific test
npx vitest run --reporter=verbose test/components/RVolcanoPlot.test.tsx

# Run in watch mode with debugging
npx vitest watch --inspect-brk
```

### R Test Debugging
```bash
# Run with detailed output
cd r-backend
Rscript test-comprehensive-suite.R 2>&1 | tee test-output.log

# Debug specific functions
R -e "source('plumber-api.R'); debugonce(generate_volcano_data); generate_volcano_data(100)"
```

### Common Issues and Solutions

#### Frontend Tests
- **Mock Issues**: Ensure all external dependencies are properly mocked
- **Async Issues**: Use `waitFor` for async operations
- **Component Rendering**: Check that all required props are provided

#### R Tests
- **Package Dependencies**: Run `install-packages.R` if tests fail to load libraries
- **Server Connection**: Ensure R server is running for integration tests
- **Memory Issues**: Reduce dataset sizes in tests if memory is limited

#### Integration Tests
- **Port Conflicts**: Ensure ports 3000 and 8001 are available
- **Timing Issues**: Increase timeouts for slower systems
- **Network Issues**: Check firewall settings for local connections

## Test Maintenance

### Adding New Tests
1. **Unit Tests**: Add to appropriate test file or create new one
2. **Integration Tests**: Update integration suite with new endpoints
3. **E2E Tests**: Add new workflow scenarios as needed

### Updating Tests
- Update tests when API contracts change
- Maintain test data consistency with production data
- Keep mocks synchronized with actual implementations

### Performance Monitoring
- Monitor test execution times
- Optimize slow tests without losing coverage
- Use appropriate test data sizes for different test types

## Reporting and Metrics

### Test Reports
- **Frontend**: Vitest generates coverage reports
- **R Backend**: Custom test runner provides detailed results
- **Integration**: End-to-end test results with performance metrics

### Success Criteria
- All unit tests pass
- Integration tests pass with servers running
- E2E tests complete full workflows successfully
- Performance tests meet response time requirements
- Error handling tests verify graceful degradation