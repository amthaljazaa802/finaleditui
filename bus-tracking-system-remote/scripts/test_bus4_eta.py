import requests
import json

BASE_URL = "http://127.0.0.1:8000"

print("=" * 80)
print("Testing API Response for Bus 4 at دوار الزراعة Stop")
print("=" * 80)

# Test the stops-with-eta endpoint for Route 3 (دائري شمالي) with Bus 4
url = f"{BASE_URL}/api/bus-lines/3/stops-with-eta/?bus_id=4"
print(f"\nRequesting: {url}\n")

response = requests.get(url)
print(f"Status Code: {response.status_code}\n")

if response.status_code == 200:
    data = response.json()
    
    print(f"ETA Source: {data.get('eta_source', 'N/A')}")
    print(f"Speed: {data.get('speed_kmh', 'N/A')} km/h")
    
    if 'current_segment' in data:
        seg = data['current_segment']
        print(f"\nCurrent Segment:")
        print(f"  From: {seg.get('from_stop', 'N/A')}")
        print(f"  To: {seg.get('to_stop', 'N/A')}")
        print(f"  Progress: {seg.get('progress_percent', 'N/A')}%")
    
    print(f"\nStops with ETA:")
    print("-" * 80)
    
    for stop in data.get('stops', [])[:5]:  # Show first 5 stops
        stop_id = stop.get('stop_id', 'N/A')
        stop_name = stop.get('stop_name', 'N/A')
        eta_sec = stop.get('eta_seconds', 'N/A')
        distance = stop.get('distance_meters', 'N/A')
        passed = stop.get('passed', False)
        at_stop = stop.get('at_stop', False)
        
        if eta_sec != 'N/A':
            eta_min = eta_sec / 60
        else:
            eta_min = 'N/A'
            
        if distance != 'N/A':
            distance_km = distance / 1000
        else:
            distance_km = 'N/A'
        
        if at_stop:
            status = "AT STOP"
        elif passed:
            status = "PASSED"
        else:
            status = "UPCOMING"
        
        print(f"Stop {stop_id}: {stop_name}")
        print(f"  Status: {status}")
        print(f"  Distance: {distance} m ({distance_km} km)")
        print(f"  ETA: {eta_sec} sec ({eta_min} min)")
        print()
else:
    print(f"Error: {response.text}")

print("=" * 80)
