import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from bus_tracking.models import Bus, BusStop

print("=" * 80)
print("BUSES CURRENT LOCATIONS")
print("=" * 80)

buses = Bus.objects.select_related('current_location', 'bus_line').all()
for bus in buses:
    if bus.bus_line:
        route_id = bus.bus_line.route_id
        route_name = bus.bus_line.route_name
    else:
        route_id = "None"
        route_name = "None"
    
    print(f"\nBus {bus.bus_id}:")
    print(f"  Route: {route_id} ({route_name})")
    print(f"  Location: ({bus.current_location.latitude:.6f}, {bus.current_location.longitude:.6f})")

print("\n" + "=" * 80)
print("BUS STOPS LOCATIONS (First 5)")
print("=" * 80)

stops = BusStop.objects.filter(stop_id__in=[1,2,3,4,5]).order_by('stop_id')
for stop in stops:
    print(f"\nStop {stop.stop_id} ({stop.stop_name}):")
    print(f"  Location: ({stop.location.latitude:.6f}, {stop.location.longitude:.6f})")

print("\n" + "=" * 80)
print("DISTANCE CHECK")
print("=" * 80)

from math import radians, cos, sin, asin, sqrt

def haversine(lat1, lon1, lat2, lon2):
    """Calculate distance in meters"""
    R = 6371000  # Earth radius in meters
    dLat = radians(lat2 - lat1)
    dLon = radians(lon2 - lon1)
    lat1 = radians(lat1)
    lat2 = radians(lat2)
    
    a = sin(dLat/2)**2 + cos(lat1) * cos(lat2) * sin(dLon/2)**2
    c = 2 * asin(sqrt(a))
    return R * c

stop1 = stops.filter(stop_id=1).first()
if stop1:
    print(f"\nDistance from each bus to Stop 1 ({stop1.stop_name}):")
    for bus in buses:
        dist = haversine(
            bus.current_location.latitude,
            bus.current_location.longitude,
            stop1.location.latitude,
            stop1.location.longitude
        )
        print(f"  Bus {bus.bus_id}: {dist:.1f} meters ({dist/1000:.2f} km)")
