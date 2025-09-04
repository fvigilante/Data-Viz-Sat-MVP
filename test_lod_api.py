#!/usr/bin/env python3
"""
Test script for the Level-of-Detail (LOD) API functionality
"""

import requests
import time
import json

API_BASE = "http://localhost:8000"

def test_lod_system():
    """Test the LOD system with different zoom levels and viewports"""
    
    print("🔬 Testing Adaptive Level-of-Detail System")
    print("=" * 50)
    
    # Test parameters
    dataset_size = 100000
    base_params = {
        'dataset_size': dataset_size,
        'p_value_threshold': 0.05,
        'log_fc_min': -0.5,
        'log_fc_max': 0.5,
        'lod_mode': True
    }
    
    test_cases = [
        {
            'name': 'Overview (1x zoom)',
            'zoom_level': 1.0,
            'expected_points': '~2K'
        },
        {
            'name': 'Medium zoom (3x)',
            'zoom_level': 3.0,
            'expected_points': '~18K'
        },
        {
            'name': 'Detailed zoom (5x)',
            'zoom_level': 5.0,
            'expected_points': '~56K'
        },
        {
            'name': 'High zoom (10x)',
            'zoom_level': 10.0,
            'expected_points': '~200K'
        },
        {
            'name': 'Spatial filtering (5x zoom, small viewport)',
            'zoom_level': 5.0,
            'x_min': -2.0,
            'x_max': 2.0,
            'y_min': 0.0,
            'y_max': 5.0,
            'expected_points': '~20K (spatial filtered)'
        }
    ]
    
    results = []
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"\n{i}. Testing: {test_case['name']}")
        print("-" * 30)
        
        # Prepare parameters
        params = base_params.copy()
        params['zoom_level'] = test_case['zoom_level']
        
        # Add spatial parameters if present
        for key in ['x_min', 'x_max', 'y_min', 'y_max']:
            if key in test_case:
                params[key] = test_case[key]
        
        # Make request
        start_time = time.time()
        try:
            response = requests.get(f"{API_BASE}/api/volcano-data", params=params)
            load_time = (time.time() - start_time) * 1000  # Convert to ms
            
            if response.status_code == 200:
                data = response.json()
                
                result = {
                    'test_case': test_case['name'],
                    'zoom_level': test_case['zoom_level'],
                    'load_time_ms': round(load_time, 1),
                    'points_returned': data['filtered_rows'],
                    'total_dataset': data['total_rows'],
                    'is_downsampled': data['is_downsampled'],
                    'points_before_sampling': data['points_before_sampling'],
                    'expected': test_case['expected_points']
                }
                
                results.append(result)
                
                print(f"✅ Load time: {load_time:.1f}ms")
                print(f"📊 Points returned: {data['filtered_rows']:,}")
                print(f"🎯 Expected: {test_case['expected_points']}")
                print(f"📈 From dataset: {data['total_rows']:,}")
                print(f"🔽 Downsampled: {'Yes' if data['is_downsampled'] else 'No'}")
                
                if data['is_downsampled']:
                    print(f"📋 Before sampling: {data['points_before_sampling']:,}")
                
            else:
                print(f"❌ Error: {response.status_code} - {response.text}")
                
        except requests.exceptions.RequestException as e:
            print(f"❌ Request failed: {e}")
    
    # Summary
    print("\n" + "=" * 50)
    print("📊 LOD SYSTEM PERFORMANCE SUMMARY")
    print("=" * 50)
    
    if results:
        print(f"{'Test Case':<35} {'Zoom':<6} {'Time(ms)':<10} {'Points':<10}")
        print("-" * 65)
        
        for result in results:
            print(f"{result['test_case']:<35} {result['zoom_level']:<6} {result['load_time_ms']:<10} {result['points_returned']:<10,}")
        
        # Performance analysis
        avg_load_time = sum(r['load_time_ms'] for r in results) / len(results)
        fastest = min(results, key=lambda x: x['load_time_ms'])
        slowest = max(results, key=lambda x: x['load_time_ms'])
        
        print(f"\n📈 Performance Analysis:")
        print(f"   Average load time: {avg_load_time:.1f}ms")
        print(f"   Fastest: {fastest['test_case']} ({fastest['load_time_ms']}ms)")
        print(f"   Slowest: {slowest['test_case']} ({slowest['load_time_ms']}ms)")
        
        # Verify LOD scaling
        zoom_1x = next((r for r in results if r['zoom_level'] == 1.0), None)
        zoom_10x = next((r for r in results if r['zoom_level'] == 10.0), None)
        
        if zoom_1x and zoom_10x:
            point_ratio = zoom_10x['points_returned'] / zoom_1x['points_returned']
            print(f"\n🔍 LOD Scaling Verification:")
            print(f"   1x zoom: {zoom_1x['points_returned']:,} points")
            print(f"   10x zoom: {zoom_10x['points_returned']:,} points")
            print(f"   Scaling ratio: {point_ratio:.1f}x more points at 10x zoom")
            
            if point_ratio > 5:
                print("   ✅ LOD scaling working correctly!")
            else:
                print("   ⚠️  LOD scaling may need adjustment")

def test_cache_performance():
    """Test cache performance with repeated requests"""
    
    print("\n🚀 Testing Cache Performance")
    print("=" * 30)
    
    params = {
        'dataset_size': 100000,
        'zoom_level': 2.0,
        'lod_mode': True
    }
    
    times = []
    for i in range(3):
        start_time = time.time()
        response = requests.get(f"{API_BASE}/api/volcano-data", params=params)
        load_time = (time.time() - start_time) * 1000
        times.append(load_time)
        
        print(f"Request {i+1}: {load_time:.1f}ms")
    
    if len(times) >= 2:
        cache_improvement = (times[0] - times[1]) / times[0] * 100
        print(f"\n📈 Cache Performance:")
        print(f"   First request: {times[0]:.1f}ms")
        print(f"   Cached request: {times[1]:.1f}ms")
        print(f"   Improvement: {cache_improvement:.1f}%")

if __name__ == "__main__":
    try:
        # Test if API is available
        response = requests.get(f"{API_BASE}/health")
        if response.status_code == 200:
            test_lod_system()
            test_cache_performance()
        else:
            print("❌ API not available. Make sure FastAPI server is running on localhost:8000")
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to API. Make sure FastAPI server is running on localhost:8000")
        print("   Start server with: python api/main.py")