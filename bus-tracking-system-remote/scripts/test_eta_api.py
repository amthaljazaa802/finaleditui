import os
import sys
import django
import requests

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from bus_tracking.models import Bus

print("=" * 80)
print("TESTING ETA API")
print("=" * 80)

buses = Bus.objects.select_related('bus_line').all()

for bus in buses:
    if not bus.bus_line:
        continue
    
    route_id = bus.bus_line.route_id
    print(f"\n\nBus {bus.bus_id} on Route {route_id}")
    print("-" * 80)
    
    url = f"http://127.0.0.1:8000/api/bus-lines/{route_id}/stops-with-eta/?bus_id={bus.bus_id}"
    print(f"URL: {url}")
    
    try:
        response = requests.get(url, timeout=5)
        print(f"Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print(f"\nETA Source: {data.get('eta_source', 'N/A')}")
            print(f"Speed: {data.get('speed_kmh', 'N/A')} km/h")
            
            current_seg = data.get('current_segment')
            if current_seg:
                print(f"\nCurrent Segment:")
                print(f"  From: {current_seg.get('from_stop')}")
                print(f"  To: {current_seg.get('to_stop')}")
                print(f"  Progress: {current_seg.get('progress', 0):.1f}%")
            
            stops = data.get('stops', [])
            print(f"\nFirst 3 Stops:")
            for i, stop in enumerate(stops[:3]):
                print(f"\n  Stop {stop['stop_id']} ({stop['stop_name']}):")
                print(f"    Distance: {stop.get('distance_meters', 0):.1f} m ({stop.get('distance_meters', 0)/1000:.2f} km)")
                print(f"    ETA: {stop.get('eta_seconds', 0):.0f} seconds ({stop.get('eta_seconds', 0)/60:.1f} min)")
                print(f"    Passed: {stop.get('passed', False)}")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Error: {e}")
