import os
import sys
import django
from math import radians, cos, sin, asin, sqrt

# Setup Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from bus_tracking.models import Bus, BusStop

def haversine(lon1, lat1, lon2, lat2):
    """Calculate distance in meters between two points"""
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    r = 6371000  # Radius of earth in meters
    return c * r

print("=" * 80)
print("Bus 4 Location Check")
print("=" * 80)

# Get Bus 4
bus4 = Bus.objects.get(bus_id=4)
print(f"\nBus 4 Info:")
print(f"  Line: {bus4.bus_line.route_name}")
print(f"  Location: {bus4.current_location.latitude}, {bus4.current_location.longitude}")

# Get دوار الزراعة stop (stop_id=4 based on previous data)
stop = BusStop.objects.filter(stop_name__contains='دوار الزراعة').first()
if not stop:
    print("\nTrying to find stop by ID 4...")
    stop = BusStop.objects.filter(stop_id=4).first()

if stop:
    print(f"\nStop Info:")
    print(f"  ID: {stop.stop_id}")
    print(f"  Name: {stop.stop_name}")
    print(f"  Location: {stop.location.latitude}, {stop.location.longitude}")
    
    # Calculate straight-line distance
    distance = haversine(
        bus4.current_location.longitude,
        bus4.current_location.latitude,
        stop.location.longitude,
        stop.location.latitude
    )
    
    print(f"\nStraight-line Distance: {distance:.1f} meters ({distance/1000:.2f} km)")
else:
    print("\nStop not found!")
    print("\nAll stops on Route 3:")
    route3_stops = BusStop.objects.filter(routes__route_id=3).order_by('stop_order')
    for s in route3_stops:
        print(f"  {s.stop_id}: {s.stop_name}")

print("\n" + "=" * 80)
