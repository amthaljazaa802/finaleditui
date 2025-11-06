"""
Verify that the route filtering fix is working correctly.
Tests that bus lines include stops in the initial-data API response.
"""
import requests
import json

BASE_URL = 'http://localhost:8000'

print("=" * 80)
print("Testing Route Filtering Fix")
print("=" * 80)

# Test 1: Check that initial-data includes stops in bus lines
print("\n1. Testing /api/initial-data/ includes stops in bus_lines:")
response = requests.get(f'{BASE_URL}/api/initial-data/')
if response.status_code == 200:
    data = response.json()
    bus_lines = data['bus_lines']
    
    print(f"   ✅ Found {len(bus_lines)} bus lines")
    
    for line in bus_lines:
        route_id = line['route_id']
        route_name = line['route_name']
        stops = line.get('stops', [])
        print(f"   Route {route_id} ({route_name}): {len(stops)} stops")
        
        if len(stops) == 0:
            print(f"   ❌ ERROR: Route {route_id} has no stops!")
        else:
            print(f"      First stop: {stops[0]['stop_name']} (ID: {stops[0]['stop_id']})")
            if len(stops) > 1:
                print(f"      Last stop: {stops[-1]['stop_name']} (ID: {stops[-1]['stop_id']})")
    
    # Test 2: Verify Route 1 has 3 stops (A, B, c)
    print("\n2. Verifying Route 1 stops:")
    route1 = next((line for line in bus_lines if line['route_id'] == 1), None)
    if route1 and len(route1['stops']) == 3:
        stop_names = [s['stop_name'] for s in route1['stops']]
        expected = ['A', 'B', 'c']
        if stop_names == expected:
            print(f"   ✅ Route 1 has correct stops: {stop_names}")
        else:
            print(f"   ⚠️  Route 1 stops: {stop_names} (expected: {expected})")
    else:
        print(f"   ❌ Route 1 has wrong number of stops!")
    
    # Test 3: Verify Route 3 has 19 stops
    print("\n3. Verifying Route 3 stops:")
    route3 = next((line for line in bus_lines if line['route_id'] == 3), None)
    if route3 and len(route3['stops']) == 19:
        print(f"   ✅ Route 3 has 19 stops")
        print(f"      First: {route3['stops'][0]['stop_name']}")
        print(f"      Last: {route3['stops'][-1]['stop_name']}")
    else:
        print(f"   ❌ Route 3 has wrong number of stops: {len(route3['stops']) if route3 else 'N/A'}")
    
else:
    print(f"   ❌ Failed to fetch data: {response.status_code}")

print("\n" + "=" * 80)
print("Summary:")
print("The Flutter app can now filter buses by route because each bus_line")
print("object includes a 'stops' array with all stop IDs for that route.")
print("This allows the BusStopPopup to check which routes include a clicked stop")
print("and only show ETAs from buses on those routes.")
print("=" * 80)
