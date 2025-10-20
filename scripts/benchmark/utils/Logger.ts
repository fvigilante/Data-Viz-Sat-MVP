export class Logger {
  private verbose: boolean;
  
  constructor(verbose: boolean = false) {
    this.verbose = verbose;
  }
  
  /**
   * Log info message
   */
  info(message: string, ...args: any[]): void {
    console.log(`[INFO] ${new Date().toISOString()} - ${message}`, ...args);
  }
  
  /**
   * Log error message
   */
  error(message: string, error?: any): void {
    console.error(`[ERROR] ${new Date().toISOString()} - ${message}`);
    if (error && this.verbose) {
      console.error(error);
    }
  }
  
  /**
   * Log warning message
   */
  warn(message: string, ...args: any[]): void {
    console.warn(`[WARN] ${new Date().toISOString()} - ${message}`, ...args);
  }
  
  /**
   * Log debug message (only in verbose mode)
   */
  debug(message: string, ...args: any[]): void {
    if (this.verbose) {
      console.log(`[DEBUG] ${new Date().toISOString()} - ${message}`, ...args);
    }
  }
  
  /**
   * Log success message
   */
  success(message: string, ...args: any[]): void {
    console.log(`[SUCCESS] ${new Date().toISOString()} - ${message}`, ...args);
  }
  
  /**
   * Set verbose mode
   */
  setVerbose(verbose: boolean): void {
    this.verbose = verbose;
  }
}