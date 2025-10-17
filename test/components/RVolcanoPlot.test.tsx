import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import RVolcanoPlot from '@/components/RVolcanoPlot'
import { mockFetch } from '../setup'

// Mock the API config
vi.mock('@/lib/api-config', () => ({
  getApiUrl: (endpoint: string) => {
    const urls = {
      rVolcanoData: '/api/r-volcano-data',
      rCacheStatus: '/api/r-cache-status',
      rWarmCache: '/api/r-warm-cache',
      rClearCache: '/api/r-clear-cache',
    }
    return urls[endpoint as keyof typeof urls] || '/api/unknown'
  }
}))

// Mock data for tests
const mockVolcanoResponse = {
  data: [
    {
      gene: 'Test Gene 1',
      logFC: 1.5,
      padj: 0.001,
      category: 'up' as const,
      classyfireSuperclass: 'Lipids',
      classyfireClass: 'Fatty acids'
    },
    {
      gene: 'Test Gene 2', 
      logFC: -1.2,
      padj: 0.01,
      category: 'down' as const,
      classyfireSuperclass: 'Organic acids',
      classyfireClass: 'Amino acids'
    },
    {
      gene: 'Test Gene 3',
      logFC: 0.2,
      padj: 0.5,
      category: 'non_significant' as const,
      classyfireSuperclass: 'Carbohydrates',
      classyfireClass: 'Sugars'
    }
  ],
  stats: {
    up_regulated: 1,
    down_regulated: 1,
    non_significant: 1
  },
  total_rows: 10000,
  filtered_rows: 3,
  points_before_sampling: 3,
  is_downsampled: false
}

const mockCacheStatus = {
  total_cached: 2,
  cached_datasets: [1000, 10000],
  approximate_memory_mb: 15.5
}

describe('RVolcanoPlot Component', () => {
  beforeEach(() => {
    // Reset all mocks before each test
    vi.clearAllMocks()
  })

  it('renders initial loading state correctly', () => {
    render(<RVolcanoPlot />)
    
    expect(screen.getByText('Generate Volcano Plot')).toBeInTheDocument()
    expect(screen.getByText('Dataset Size')).toBeInTheDocument()
    expect(screen.getByText('P-value Threshold')).toBeInTheDocument()
    expect(screen.getByText('Log2 Fold Change Range')).toBeInTheDocument()
  })

  it('displays default filter values', () => {
    render(<RVolcanoPlot />)
    
    // Check default p-value
    const pValueInput = screen.getByDisplayValue('0.05')
    expect(pValueInput).toBeInTheDocument()
    
    // Check default dataset size
    expect(screen.getByText('10,000')).toBeInTheDocument()
    
    // Check default max points
    expect(screen.getByText('20,000')).toBeInTheDocument()
  })

  it('fetches and displays volcano data when generate button is clicked', async () => {
    const user = userEvent.setup()
    
    // Mock the API responses
    mockFetch(mockCacheStatus) // Cache status call
    mockFetch(mockVolcanoResponse) // Volcano data call
    
    render(<RVolcanoPlot />)
    
    const generateButton = screen.getByText('Generate Volcano Plot')
    await user.click(generateButton)
    
    // Should show loading state
    await waitFor(() => {
      expect(screen.getByText('Generating...')).toBeInTheDocument()
    })
    
    // Should display results after loading
    await waitFor(() => {
      expect(screen.getByText('Up-regulated: 1')).toBeInTheDocument()
      expect(screen.getByText('Down-regulated: 1')).toBeInTheDocument()
      expect(screen.getByText('Non-significant: 1')).toBeInTheDocument()
    })
    
    // Should display total rows
    expect(screen.getByText(/Total: 10,000/)).toBeInTheDocument()
    expect(screen.getByText(/Filtered: 3/)).toBeInTheDocument()
  })

  it('updates p-value threshold when input changes', async () => {
    const user = userEvent.setup()
    
    render(<RVolcanoPlot />)
    
    const pValueInput = screen.getByDisplayValue('0.05')
    await user.clear(pValueInput)
    await user.type(pValueInput, '0.01')
    
    expect(screen.getByDisplayValue('0.01')).toBeInTheDocument()
  })

  it('updates dataset size when dropdown selection changes', async () => {
    const user = userEvent.setup()
    
    render(<RVolcanoPlot />)
    
    // Find and click the dataset size dropdown
    const datasetButton = screen.getByRole('button', { name: /10,000/ })
    await user.click(datasetButton)
    
    // Select a different size
    const option50k = screen.getByText('50,000')
    await user.click(option50k)
    
    // Verify the selection changed
    expect(screen.getByRole('button', { name: /50,000/ })).toBeInTheDocument()
  })

  it('updates max points when dropdown selection changes', async () => {
    const user = userEvent.setup()
    
    render(<RVolcanoPlot />)
    
    // Find and click the max points dropdown
    const maxPointsButton = screen.getByRole('button', { name: /20,000/ })
    await user.click(maxPointsButton)
    
    // Select a different value
    const option50k = screen.getByText('50,000 points')
    await user.click(option50k)
    
    // Verify the selection changed
    expect(screen.getByRole('button', { name: /50,000/ })).toBeInTheDocument()
  })

  it('handles search term input', async () => {
    const user = userEvent.setup()
    
    render(<RVolcanoPlot />)
    
    const searchInput = screen.getByPlaceholderText('Search metabolites...')
    await user.type(searchInput, 'biotin')
    
    expect(screen.getByDisplayValue('biotin')).toBeInTheDocument()
  })

  it('displays error message when API call fails', async () => {
    const user = userEvent.setup()
    
    // Mock failed API response
    mockFetch(mockCacheStatus) // Cache status succeeds
    mockFetch({ error: 'Server error' }, false) // Volcano data fails
    
    render(<RVolcanoPlot />)
    
    const generateButton = screen.getByText('Generate Volcano Plot')
    await user.click(generateButton)
    
    await waitFor(() => {
      expect(screen.getByText(/R API Error: 500/)).toBeInTheDocument()
    })
  })

  it('shows cached vs generating status correctly', async () => {
    const user = userEvent.setup()
    
    // Mock cache status showing dataset is not cached
    mockFetch({ ...mockCacheStatus, cached_datasets: [] })
    mockFetch(mockVolcanoResponse)
    
    render(<RVolcanoPlot />)
    
    const generateButton = screen.getByText('Generate Volcano Plot')
    await user.click(generateButton)
    
    // Should show generating status
    await waitFor(() => {
      expect(screen.getByText('Generating...')).toBeInTheDocument()
    })
  })

  it('handles log fold change range slider', async () => {
    const user = userEvent.setup()
    
    render(<RVolcanoPlot />)
    
    // Find the range display
    expect(screen.getByText('-0.5 to 0.5')).toBeInTheDocument()
    
    // The actual slider interaction is complex to test with user events
    // We'll test that the slider elements are present
    const sliders = screen.getAllByRole('slider')
    expect(sliders).toHaveLength(2) // Min and max sliders
  })

  it('displays downsampling information when applicable', async () => {
    const user = userEvent.setup()
    
    // Mock response with downsampling
    const downsampledResponse = {
      ...mockVolcanoResponse,
      points_before_sampling: 50000,
      is_downsampled: true
    }
    
    mockFetch(mockCacheStatus)
    mockFetch(downsampledResponse)
    
    render(<RVolcanoPlot />)
    
    const generateButton = screen.getByText('Generate Volcano Plot')
    await user.click(generateButton)
    
    await waitFor(() => {
      expect(screen.getByText(/Downsampled from 50,000/)).toBeInTheDocument()
    })
  })

  it('shows plot component when data is available', async () => {
    const user = userEvent.setup()
    
    mockFetch(mockCacheStatus)
    mockFetch(mockVolcanoResponse)
    
    render(<RVolcanoPlot />)
    
    const generateButton = screen.getByText('Generate Volcano Plot')
    await user.click(generateButton)
    
    await waitFor(() => {
      // The plot should be rendered (mocked as div with data-testid)
      expect(screen.getByTestId('mocked-plot')).toBeInTheDocument()
    })
  })

  it('handles export functionality', async () => {
    const user = userEvent.setup()
    
    mockFetch(mockCacheStatus)
    mockFetch(mockVolcanoResponse)
    
    render(<RVolcanoPlot />)
    
    // Generate data first
    const generateButton = screen.getByText('Generate Volcano Plot')
    await user.click(generateButton)
    
    await waitFor(() => {
      expect(screen.getByText('Up-regulated: 1')).toBeInTheDocument()
    })
    
    // Find and click export button
    const exportButton = screen.getByText('Export CSV')
    expect(exportButton).toBeInTheDocument()
    
    // Note: Actual file download testing would require more complex setup
    // This test verifies the button is present and clickable
    await user.click(exportButton)
  })

  it('resets filters when reset button is clicked', async () => {
    const user = userEvent.setup()
    
    render(<RVolcanoPlot />)
    
    // Change some values first
    const pValueInput = screen.getByDisplayValue('0.05')
    await user.clear(pValueInput)
    await user.type(pValueInput, '0.01')
    
    const searchInput = screen.getByPlaceholderText('Search metabolites...')
    await user.type(searchInput, 'test search')
    
    // Click reset
    const resetButton = screen.getByText('Reset Filters')
    await user.click(resetButton)
    
    // Values should be back to defaults
    expect(screen.getByDisplayValue('0.05')).toBeInTheDocument()
    expect(screen.getByDisplayValue('')).toBeInTheDocument() // Search should be empty
  })

  it('displays data table when results are available', async () => {
    const user = userEvent.setup()
    
    mockFetch(mockCacheStatus)
    mockFetch(mockVolcanoResponse)
    
    render(<RVolcanoPlot />)
    
    const generateButton = screen.getByText('Generate Volcano Plot')
    await user.click(generateButton)
    
    await waitFor(() => {
      // Check for table headers
      expect(screen.getByText('Gene')).toBeInTheDocument()
      expect(screen.getByText('Log2 FC')).toBeInTheDocument()
      expect(screen.getByText('Adj. P-value')).toBeInTheDocument()
      expect(screen.getByText('Category')).toBeInTheDocument()
      
      // Check for data rows
      expect(screen.getByText('Test Gene 1')).toBeInTheDocument()
      expect(screen.getByText('Test Gene 2')).toBeInTheDocument()
      expect(screen.getByText('Test Gene 3')).toBeInTheDocument()
    })
  })

  it('handles API configuration correctly', () => {
    // This test verifies that the component uses the correct API endpoints
    render(<RVolcanoPlot />)
    
    // The component should be rendered without errors
    expect(screen.getByText('Generate Volcano Plot')).toBeInTheDocument()
    
    // API calls will be made with the mocked endpoints
    // This is implicitly tested in other tests that make API calls
  })
})