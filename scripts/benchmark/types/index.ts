/**
 * Core TypeScript interfaces and types for the Performance Benchmark System
 */

// ============================================================================
// Configuration Types
// ============================================================================

export interface BenchmarkConfig {
  version: string;
  test_sizes: number[];
  iterations_per_test: number;
  timeout_ms: number;
  services: ServiceConfigs;
  output: OutputConfig;
}

export interface ServiceConfigs {
  client_side: ClientSideConfig;
  server_side: ServerSideConfig;
  fastapi: FastAPIConfig;
  r_backend: RBackendConfig;
}

export interface ClientSideConfig {
  enabled: boolean;
  browser: 'chromium' | 'firefox';
  headless: boolean;
}

export interface ServerSideConfig {
  enabled: boolean;
  endpoint: string;
}

export interface FastAPIConfig {
  enabled: boolean;
  endpoint: string;
  test_cache: boolean;
}

export interface RBackendConfig {
  enabled: boolean;
  endpoint: string;
}

export interface OutputConfig {
  format: 'json' | 'csv' | 'both';
  update_about_page: boolean;
  backup_original: boolean;
  output_dir: string;
}

// ============================================================================
// Test Result Types
// ============================================================================

export type ServiceName = 'client-side' | 'server-side' | 'fastapi' | 'r-backend';

export interface BaseTestResult {
  service: ServiceName;
  dataset_size: number;
  success: boolean;
  error?: string;
  total_time: number;
  timestamp: string;
}

export interface ClientSideTestResult extends BaseTestResult {
  service: 'client-side';
  parse_time: number;
  processing_time: number;
  render_time: number;
  memory_usage?: number;
}

export interface ServerSideTestResult extends BaseTestResult {
  service: 'server-side';
  api_response_time: number;
  processing_time: number;
}

export interface FastAPITestResult extends BaseTestResult {
  service: 'fastapi';
  api_response_time: number;
  processing_time: number;
  cache_hit: boolean;
}

export interface RBackendTestResult extends BaseTestResult {
  service: 'r-backend';
  api_response_time: number;
  processing_time: number;
  json_conversion_time: number;
}

export type TestResult = ClientSideTestResult | ServerSideTestResult | FastAPITestResult | RBackendTestResult;

// ============================================================================
// Dataset Types
// ============================================================================

export interface VolcanoDataPoint {
  gene_name: string;
  log2_fold_change: number;
  p_value: number;
  adjusted_p_value: number;
  category: string;
  significant: boolean;
}

export interface TestDataset {
  size: number;
  data: VolcanoDataPoint[];
  metadata: DatasetMetadata;
}

export interface DatasetMetadata {
  generated_at: string;
  significant_points: number;
  categories: Record<string, number>;
  seed: number;
}

// ============================================================================
// Statistics and Analysis Types
// ============================================================================

export interface PerformanceStatistics {
  [service: string]: {
    [dataset_size: number]: ServiceStatistics;
  };
}

export interface ServiceStatistics {
  mean: number;
  std_dev: number;
  min: number;
  max: number;
  success_rate: number;
  sample_size: number;
  confidence_interval_95: [number, number];
}

export interface ServiceRecommendation {
  dataset_size: number;
  recommended_service: ServiceName;
  reason: string;
  performance_comparison: Record<ServiceName, number>;
  confidence_score: number;
}

// ============================================================================
// Health Check Types
// ============================================================================

export interface HealthCheckResult {
  service: ServiceName;
  available: boolean;
  responseTime?: number;
  error?: string;
  version?: string;
  endpoint?: string;
}

// ============================================================================
// Benchmark Results Types
// ============================================================================

export interface BenchmarkResults {
  timestamp: string;
  config: BenchmarkConfig;
  health_checks: HealthCheckResult[];
  results: TestResult[];
  statistics: PerformanceStatistics;
  recommendations: ServiceRecommendation[];
  metadata: BenchmarkMetadata;
}

export interface BenchmarkMetadata {
  version: string;
  execution_time_ms: number;
  total_tests_run: number;
  successful_tests: number;
  failed_tests: number;
  system_info: SystemInfo;
}

export interface SystemInfo {
  platform: string;
  node_version: string;
  memory_total: number;
  cpu_count: number;
}

// ============================================================================
// About Page Integration Types
// ============================================================================

export interface PerformanceMatrixData {
  datasets: DatasetInfo[];
  services: ServiceInfo[];
  results: MatrixResult[];
  metadata: MatrixMetadata;
}

export interface DatasetInfo {
  size: number;
  label: string;
}

export interface ServiceInfo {
  name: ServiceName;
  label: string;
  color_class: string;
}

export interface MatrixResult {
  dataset_size: number;
  service: ServiceName;
  time: string | null;
  status: 'success' | 'timeout' | 'error' | 'not_tested';
  recommendation_badge?: string;
}

export interface MatrixMetadata {
  last_updated: string;
  benchmark_version: string;
  test_iterations: number;
}

export interface AboutPageUpdate {
  performance_matrix: PerformanceMatrixData;
  last_updated: string;
  benchmark_metadata: BenchmarkMetadata;
}

// ============================================================================
// CLI and Runtime Types
// ============================================================================

export interface CLIOptions {
  config?: string;
  sizes?: string;
  services?: string;
  iterations?: number;
  timeout?: number;
  output?: string;
  verbose?: boolean;
  dryRun?: boolean;
  updateAboutPage?: boolean;
}

export interface RuntimeContext {
  config: BenchmarkConfig;
  startTime: number;
  outputDir: string;
  logger: any; // Will be properly typed when Logger is implemented
}

// ============================================================================
// Error Types
// ============================================================================

export interface BenchmarkError extends Error {
  code: string;
  service?: ServiceName;
  dataset_size?: number;
  details?: any;
}

export type ErrorCode = 
  | 'CONFIG_LOAD_ERROR'
  | 'SERVICE_UNAVAILABLE'
  | 'TEST_TIMEOUT'
  | 'DATASET_GENERATION_ERROR'
  | 'RESULTS_AGGREGATION_ERROR'
  | 'FILE_UPDATE_ERROR'
  | 'VALIDATION_ERROR';