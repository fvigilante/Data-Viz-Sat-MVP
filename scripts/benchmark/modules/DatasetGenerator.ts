import { TestDataset, VolcanoDataPoint, DatasetMetadata } from '../types';

export class DatasetGenerator {
  private static readonly DEFAULT_SEED = 42;
  private static readonly METABOLITE_PREFIXES = [
    'HMDB', 'CHEBI', 'KEGG', 'LIPID', 'METAB', 'COMP', 'MOL', 'CHEM'
  ];
  
  private static readonly CLASSYFIRE_SUPERCLASSES = [
    'Lipids and lipid-like molecules',
    'Organic acids and derivatives',
    'Organoheterocyclic compounds',
    'Organic oxygen compounds',
    'Phenylpropanoids and polyketides',
    'Alkaloids and derivatives',
    'Nucleosides, nucleotides, and analogues',
    'Organic nitrogen compounds',
    'Benzenoids',
    'Organosulfur compounds'
  ];
  
  private static readonly CLASSYFIRE_CLASSES = [
    'Fatty acids and conjugates',
    'Glycerophospholipids',
    'Sphingolipids',
    'Steroid and steroid derivatives',
    'Amino acids, peptides, and analogues',
    'Carbohydrates and carbohydrate conjugates',
    'Indoles and derivatives',
    'Pyrimidines and pyrimidine derivatives',
    'Purines and purine derivatives',
    'Phenols and phenol ethers'
  ];

  private seed: number;
  private rng: () => number;

  constructor(seed: number = DatasetGenerator.DEFAULT_SEED) {
    this.seed = seed;
    this.rng = this.createSeededRandom(seed);
  }

  /**
   * Generate a single test dataset of specified size
   */
  generateDataset(size: number): TestDataset {
    // Reset RNG with seed for reproducibility
    this.rng = this.createSeededRandom(this.seed);
    
    const data: VolcanoDataPoint[] = [];
    const categoryCount: Record<string, number> = {};
    let significantPoints = 0;

    for (let i = 0; i < size; i++) {
      const dataPoint = this.generateDataPoint(i);
      data.push(dataPoint);
      
      // Count categories
      categoryCount[dataPoint.category] = (categoryCount[dataPoint.category] || 0) + 1;
      
      if (dataPoint.significant) {
        significantPoints++;
      }
    }

    const metadata: DatasetMetadata = {
      generated_at: new Date().toISOString(),
      significant_points: significantPoints,
      categories: categoryCount,
      seed: this.seed
    };

    return {
      size,
      data,
      metadata
    };
  }

  /**
   * Generate multiple consistent datasets with different sizes
   */
  generateConsistentDatasets(sizes: number[]): TestDataset[] {
    return sizes.map(size => this.generateDataset(size));
  }

  /**
   * Generate a single volcano plot data point
   */
  private generateDataPoint(index: number): VolcanoDataPoint {
    // Generate gene/metabolite name
    const prefix = this.randomChoice(DatasetGenerator.METABOLITE_PREFIXES);
    const id = String(index + 1).padStart(6, '0');
    const gene_name = `${prefix}${id}`;

    // Generate log2 fold change with realistic distribution
    // Most points should be around 0, with some extreme values
    const log2_fold_change = this.generateLog2FoldChange();

    // Generate p-values with realistic distribution
    // Most should be non-significant, some significant
    const p_value = this.generatePValue();
    
    // Calculate adjusted p-value (simulate multiple testing correction)
    // Simple Bonferroni-like correction for demonstration
    const adjusted_p_value = Math.min(1.0, p_value * 1.5);

    // Determine significance
    const significant = adjusted_p_value <= 0.05 && Math.abs(log2_fold_change) >= 1.0;

    // Assign ClassyFire categories
    const superclass = this.randomChoice(DatasetGenerator.CLASSYFIRE_SUPERCLASSES);
    const classyfire_class = this.randomChoice(DatasetGenerator.CLASSYFIRE_CLASSES);
    
    // Use superclass as the main category for grouping
    const category = superclass;

    return {
      gene_name,
      log2_fold_change,
      p_value,
      adjusted_p_value,
      category,
      significant
    };
  }

  /**
   * Generate realistic log2 fold change values
   * Distribution: mostly around 0, with some extreme values
   */
  private generateLog2FoldChange(): number {
    // 70% of values between -2 and 2
    // 20% of values between -5 and -2 or 2 and 5
    // 10% of values more extreme
    
    const rand = this.rng();
    
    if (rand < 0.7) {
      // Normal range: -2 to 2
      return (this.rng() - 0.5) * 4;
    } else if (rand < 0.9) {
      // Moderate extreme: -5 to -2 or 2 to 5
      const sign = this.rng() < 0.5 ? -1 : 1;
      return sign * (2 + this.rng() * 3);
    } else {
      // High extreme: beyond ±5
      const sign = this.rng() < 0.5 ? -1 : 1;
      return sign * (5 + this.rng() * 5);
    }
  }

  /**
   * Generate realistic p-values
   * Distribution: mostly non-significant, some significant
   */
  private generatePValue(): number {
    const rand = this.rng();
    
    if (rand < 0.1) {
      // 10% highly significant (p < 0.001)
      return this.rng() * 0.001;
    } else if (rand < 0.2) {
      // 10% significant (0.001 < p < 0.05)
      return 0.001 + this.rng() * 0.049;
    } else if (rand < 0.3) {
      // 10% borderline (0.05 < p < 0.1)
      return 0.05 + this.rng() * 0.05;
    } else {
      // 70% non-significant (p > 0.1)
      return 0.1 + this.rng() * 0.9;
    }
  }

  /**
   * Create a seeded random number generator
   * Uses a simple Linear Congruential Generator for reproducibility
   */
  private createSeededRandom(seed: number): () => number {
    let state = seed;
    
    return function() {
      // LCG parameters (from Numerical Recipes)
      state = (state * 1664525 + 1013904223) % Math.pow(2, 32);
      return state / Math.pow(2, 32);
    };
  }

  /**
   * Choose a random element from an array
   */
  private randomChoice<T>(array: T[]): T {
    const index = Math.floor(this.rng() * array.length);
    return array[index];
  }

  /**
   * Convert VolcanoDataPoint to DegRow format (for compatibility with existing components)
   */
  static convertToDegRow(dataPoint: VolcanoDataPoint): any {
    return {
      gene: dataPoint.gene_name,
      logFC: dataPoint.log2_fold_change,
      padj: dataPoint.adjusted_p_value,
      classyfireSuperclass: dataPoint.category,
      classyfireClass: dataPoint.category // Simplified for testing
    };
  }

  /**
   * Convert entire dataset to DegRow format
   */
  static convertDatasetToDegRows(dataset: TestDataset): any[] {
    return dataset.data.map(point => DatasetGenerator.convertToDegRow(point));
  }

  /**
   * Generate CSV content from dataset (for testing file upload scenarios)
   */
  static generateCSVContent(dataset: TestDataset): string {
    const headers = ['gene', 'logFC', 'padj', 'classyfireSuperclass', 'classyfireClass'];
    const rows = dataset.data.map(point => {
      const degRow = DatasetGenerator.convertToDegRow(point);
      return [
        degRow.gene,
        degRow.logFC.toFixed(6),
        degRow.padj.toFixed(8),
        degRow.classyfireSuperclass || '',
        degRow.classyfireClass || ''
      ].join(',');
    });
    
    return [headers.join(','), ...rows].join('\n');
  }

  /**
   * Get dataset statistics for validation
   */
  static getDatasetStatistics(dataset: TestDataset): {
    size: number;
    significantCount: number;
    significantPercentage: number;
    logFCRange: [number, number];
    pValueRange: [number, number];
    categoryDistribution: Record<string, number>;
  } {
    const logFCValues = dataset.data.map(d => d.log2_fold_change);
    const pValues = dataset.data.map(d => d.p_value);
    
    return {
      size: dataset.size,
      significantCount: dataset.metadata.significant_points,
      significantPercentage: (dataset.metadata.significant_points / dataset.size) * 100,
      logFCRange: [Math.min(...logFCValues), Math.max(...logFCValues)],
      pValueRange: [Math.min(...pValues), Math.max(...pValues)],
      categoryDistribution: dataset.metadata.categories
    };
  }

  /**
   * Validate dataset integrity
   */
  static validateDataset(dataset: TestDataset): { valid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    // Check basic structure
    if (!dataset.data || !Array.isArray(dataset.data)) {
      errors.push('Dataset data is not an array');
      return { valid: false, errors };
    }
    
    if (dataset.data.length !== dataset.size) {
      errors.push(`Dataset size mismatch: expected ${dataset.size}, got ${dataset.data.length}`);
    }
    
    // Validate each data point
    for (let i = 0; i < Math.min(dataset.data.length, 100); i++) { // Check first 100 points
      const point = dataset.data[i];
      
      if (!point.gene_name || typeof point.gene_name !== 'string') {
        errors.push(`Invalid gene_name at index ${i}`);
      }
      
      if (!isFinite(point.log2_fold_change)) {
        errors.push(`Invalid log2_fold_change at index ${i}`);
      }
      
      if (!isFinite(point.p_value) || point.p_value < 0 || point.p_value > 1) {
        errors.push(`Invalid p_value at index ${i}: ${point.p_value}`);
      }
      
      if (!isFinite(point.adjusted_p_value) || point.adjusted_p_value < 0 || point.adjusted_p_value > 1) {
        errors.push(`Invalid adjusted_p_value at index ${i}: ${point.adjusted_p_value}`);
      }
      
      if (typeof point.significant !== 'boolean') {
        errors.push(`Invalid significant flag at index ${i}`);
      }
    }
    
    return {
      valid: errors.length === 0,
      errors
    };
  }
}