# Volcano Plot MVP - Interactive Metabolomics Data Visualization

A comprehensive web application for visualizing and analyzing metabolomics differential expression data through interactive volcano plots. Built with Next.js 15, TypeScript, and Plotly.js, featuring both client-side and server-side data processing approaches.

## 🧬 Overview

This application provides researchers with powerful tools to analyze metabolomics data, identify significantly regulated metabolites, and export findings for further analysis. The volcano plot visualization helps identify metabolites with both statistical significance (p-value) and biological significance (fold change).

## ✨ Key Features

### 📊 Interactive Volcano Plots
- **Dual Processing Modes**: Client-side and server-side data processing
- **Real-time Filtering**: Adjustable p-value thresholds and log2(FC) ranges
- **Interactive Legend**: Toggle visibility of up-regulated, down-regulated, and non-significant metabolites
- **Hover Tooltips**: Detailed metabolite information including ClassyFire annotations
- **Export Capabilities**: Download plots as PNG images

### 🔍 Data Analysis Tools
- **Metabolite Classification**: Integration with ClassyFire superclass and class annotations
- **Significance Thresholds**: Visual threshold lines for statistical and biological significance
- **Search Functionality**: Find specific metabolites by name
- **Data Tables**: Separate tables for up-regulated and down-regulated metabolites
- **CSV Export**: Download filtered results and significant metabolites

### 📁 Data Input Options
- **CSV/TSV Upload**: Support for various column naming conventions
- **Example Dataset**: Pre-loaded synthetic metabolomics data for testing
- **Flexible Schema**: Automatic column mapping for different data formats
- **Error Handling**: Comprehensive validation and error reporting

## 🏗️ Project Structure

\`\`\`
├── app/                          # Next.js App Router
│   ├── layout.tsx               # Root layout with navigation
│   ├── page.tsx                 # Home page (redirects to volcano plot)
│   ├── globals.css              # Global styles and CSS variables
│   ├── about/                   # About page
│   ├── plots/                   # Plot visualization pages
│   │   ├── volcano/             # Client-side volcano plot
│   │   ├── volcano-server/      # Server-side volcano plot
│   │   ├── heatmap/            # Heatmap visualization (placeholder)
│   │   └── pca/                # PCA visualization (placeholder)
│   └── api/                     # API routes
│       └── volcano-data/        # Server-side data processing endpoint
├── components/                   # React components
│   ├── VolcanoPlot.tsx         # Client-side interactive volcano plot
│   ├── ServerVolcanoPlot.tsx   # Server-side volcano plot component
│   ├── layout/                 # Layout components
│   │   ├── Header.tsx          # Application header
│   │   ├── SidebarNav.tsx      # Navigation sidebar
│   │   └── Footer.tsx          # Application footer
│   └── ui/                     # Reusable UI components (shadcn/ui)
├── lib/                        # Utility libraries
│   ├── schema.ts               # Data validation schemas
│   ├── parseCsv.ts            # CSV parsing utilities
│   └── utils.ts               # General utilities
└── public/                     # Static assets
    └── metabolomics_example.csv # Example dataset
\`\`\`

## 🧪 Business Logic & Scientific Background

### Volcano Plot Analysis
Volcano plots are essential tools in metabolomics for visualizing differential expression results:

- **X-axis (Log2 Fold Change)**: Represents the magnitude of change between conditions
- **Y-axis (-log10 p-value)**: Represents statistical significance
- **Color Coding**: 
  - 🔴 **Red**: Up-regulated metabolites (high fold change, low p-value)
  - 🔵 **Blue**: Down-regulated metabolites (low fold change, low p-value)
  - ⚫ **Gray**: Non-significant metabolites

### Data Processing Pipeline

#### Client-Side Processing (`/plots/volcano`)
1. **File Upload**: User uploads CSV/TSV file
2. **CSV Parsing**: Client-side parsing with Papa Parse
3. **Data Validation**: Schema validation using Zod
4. **Visualization**: Real-time interactive plotting with Plotly.js
5. **Filtering**: Dynamic filtering based on user-defined thresholds

#### Server-Side Processing (`/plots/volcano-server`)
1. **Data Pre-processing**: Server processes data via API endpoint
2. **Normalization**: Column name mapping and data cleaning
3. **Validation**: Server-side data validation
4. **Response**: JSON data sent to client for visualization
5. **Caching**: Optimized for repeated requests

### ClassyFire Integration
The application integrates metabolite classification data:
- **Superclass**: High-level chemical classification
- **Class**: More specific chemical grouping
- **Biological Context**: Helps researchers understand metabolic pathways

## 🚀 Getting Started

### Prerequisites
- Node.js 18+ 
- npm or yarn package manager

### Installation

1. **Clone the repository**
   \`\`\`bash
   git clone <repository-url>
   cd volcano-plot-mvp
   \`\`\`

2. **Install dependencies**
   \`\`\`bash
   npm install
   # or
   yarn install
   \`\`\`

3. **Run the development server**
   \`\`\`bash
   npm run dev
   # or
   yarn dev
   \`\`\`

4. **Open your browser**
   Navigate to [http://localhost:3000](http://localhost:3000)

### Usage

#### Quick Start
1. Visit the application homepage
2. Click "Load Example Dataset" to explore with synthetic data
3. Adjust p-value and Log2(FC) thresholds using the controls
4. Explore the interactive plot and data tables

#### Upload Your Data
1. Prepare a CSV/TSV file with columns:
   - **Metabolite name** (or "gene")
   - **log2(FC)** (or "logFC") 
   - **p-Value** (or "padj")
   - **ClassyFire Superclass** (optional)
   - **ClassyFire Class** (optional)

2. Upload via the file input or drag-and-drop
3. Review any parsing errors in the alert panel
4. Analyze your results using the interactive tools

## 🛠️ Technical Architecture

### Frontend Stack
- **Next.js 15**: React framework with App Router
- **TypeScript**: Type-safe development
- **Tailwind CSS**: Utility-first styling
- **shadcn/ui**: Modern component library
- **Plotly.js**: Interactive data visualization
- **Zod**: Runtime type validation

### Data Processing
- **Papa Parse**: CSV/TSV parsing
- **Flexible Schema**: Automatic column detection
- **Error Handling**: Comprehensive validation
- **Performance**: Optimized for large datasets

### State Management
- **React Hooks**: useState, useEffect, useMemo
- **Client State**: Real-time filtering and interactions
- **Server State**: API data fetching and caching

## 📊 Data Format Requirements

### Expected CSV Structure
\`\`\`csv
Metabolite name,log2(FC),p-Value,ClassyFire Superclass,ClassyFire Class
Methionine,2.34,0.001,Organic acids and derivatives,Carboxylic acids and derivatives
Tryptophan,-1.87,0.023,Organoheterocyclic compounds,Indoles and derivatives
\`\`\`

### Supported Column Names
- **Metabolite**: "Metabolite name", "gene", "Gene"
- **Fold Change**: "log2(FC)", "logFC", "Log2FC"
- **P-value**: "p-Value", "pvalue", "padj", "FDR"
- **Classification**: "ClassyFire Superclass", "ClassyFire Class"

## 🔧 Configuration

### Environment Variables
No environment variables required for basic functionality.

### Customization
- **Themes**: Modify `app/globals.css` for custom color schemes
- **Data Schema**: Update `lib/schema.ts` for different data formats
- **Plot Settings**: Customize visualization in component files

## 📈 Performance Considerations

- **Client-side Processing**: Suitable for datasets up to ~10,000 rows
- **Server-side Processing**: Optimized for larger datasets
- **Memory Management**: Efficient data structures and cleanup
- **Responsive Design**: Optimized for desktop and tablet viewing

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- **ClassyFire**: Chemical classification system
- **Plotly.js**: Interactive visualization library
- **shadcn/ui**: Beautiful component library
- **Metabolomics Community**: For feedback and requirements

## 📞 Support

For questions, issues, or feature requests:
- Open an issue on GitHub
- Contact the development team
- Check the documentation for common solutions

---

**Built with ❤️ by Sequentia**
