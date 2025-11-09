import requests
import json

print("Testing Stop-Route Matching Issue\n")
print("=" * 80)

# Test 1: Get stops for Route 1
print("\n1. Route 1 stops:")
r1 = requests.get('http://127.0.0.1:8000/api/bus-lines/1/')
if r1.status_code == 200:
    route1 = json.loads(r1.text)
    print(f"   Route Name: {route1.get('route_name')}")
    stops = route1.get('stops', [])
    print(f"   Stops: {[s['stop_name'] for s in stops]}")

# Test 2: Get stops for Route 3
print("\n2. Route 3 stops:")
r3 = requests.get('http://127.0.0.1:8000/api/bus-lines/3/')
if r3.status_code == 200:
    route3 = json.loads(r3.text)
    print(f"   Route Name: {route3.get('route_name')}")
    stops = route3.get('stops', [])
    print(f"   Stops (first 5): {[s['stop_name'] for s in stops[:5]]}")

# Test 3: Check which buses are on which routes
print("\n3. Active buses:")
buses = requests.get('http://127.0.0.1:8000/api/buses/')
if buses.status_code == 200:
    buses_data = json.loads(buses.text)
    for bus in buses_data:
        print(f"   Bus {bus['bus_id']}: Line {bus['bus_line']} ({bus.get('license_plate', 'N/A')})")

# Test 4: Try to get ETA for a Route 1 stop using a Route 3 bus (this should fail or return no data)
print("\n4. Testing cross-route ETA request:")
print("   Requesting Route 1 stops with Route 3 bus (bus_id=4)...")
url = 'http://127.0.0.1:8000/api/bus-lines/1/stops-with-eta/?bus_id=4'
r = requests.get(url)
if r.status_code == 200:
    data = json.loads(r.text)
    print(f"   Status: {r.status_code}")
    print(f"   ETA Source: {data.get('eta_source')}")
    print(f"   Number of stops returned: {len(data.get('stops', []))}")
    stops_with_eta = [s for s in data['stops'] if s.get('eta_seconds') is not None]
    print(f"   Stops with ETA: {len(stops_with_eta)}")
    if stops_with_eta:
        print("   ❌ PROBLEM: Route 1 API returned ETAs for Route 3 bus!")
        print(f"   First stop: {stops_with_eta[0]['stop_name']} = {stops_with_eta[0]['eta_seconds']}s")
    else:
        print("   ✅ GOOD: No ETAs returned (bus on different route)")

print("\n" + "=" * 80)
