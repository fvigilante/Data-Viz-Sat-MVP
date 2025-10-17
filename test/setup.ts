import '@testing-library/jest-dom'
import { vi } from 'vitest'

// Mock Next.js router
vi.mock('next/router', () => ({
  useRouter() {
    return {
      route: '/',
      pathname: '/',
      query: '',
      asPath: '',
      push: vi.fn(),
      pop: vi.fn(),
      reload: vi.fn(),
      back: vi.fn(),
      prefetch: vi.fn().mockResolvedValue(undefined),
      beforePopState: vi.fn(),
      events: {
        on: vi.fn(),
        off: vi.fn(),
        emit: vi.fn(),
      },
    }
  },
}))

// Mock dynamic imports
vi.mock('next/dynamic', () => ({
  default: (fn: any) => {
    const MockedComponent = (props: any) => {
      return { type: 'div', props: { 'data-testid': 'mocked-plot', ...props } }
    }
    MockedComponent.displayName = 'MockedDynamicComponent'
    return MockedComponent
  }
}))

// Mock plotly.js
vi.mock('react-plotly.js', () => ({
  default: (props: any) => {
    return { type: 'div', props: { 'data-testid': 'plotly-plot', ...props } }
  }
}))

// Mock fetch globally
global.fetch = vi.fn()

// Mock ResizeObserver
global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}))

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn(),
}))

// Setup fetch mock helper
export const mockFetch = (response: any, ok = true) => {
  ;(global.fetch as any).mockResolvedValueOnce({
    ok,
    json: async () => response,
    status: ok ? 200 : 500,
    statusText: ok ? 'OK' : 'Internal Server Error',
  })
}

// Reset fetch mock before each test
beforeEach(() => {
  ;(global.fetch as any).mockClear()
})