"""
Simulate bus movement by posting successive locations for a bus and printing ETA responses.
Run from repository root with python, requires requests installed and server running at http://127.0.0.1:8000
"""
import time
import requests
from django.conf import settings
import os
import sys

# Configure Django environment to access models if needed (optional)
# but here we will use ORM to read segment points
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
# Ensure project root (Buses_BACK_END-main) is on sys.path so Django settings package can be imported
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
if ROOT not in sys.path:
    sys.path.insert(0, ROOT)

import django
django.setup()

from bus_tracking.models import Bus, RouteSegment

BASE_URL = 'http://127.0.0.1:8000'
BUS_PK = 3  # adjust if needed

try:
    bus = Bus.objects.get(pk=BUS_PK)
except Bus.DoesNotExist:
    print('Bus pk', BUS_PK, 'not found')
    raise SystemExit(1)

segments = RouteSegment.objects.filter(bus_line=bus.bus_line).order_by('order')
if not segments.exists():
    print('No segments for bus line')
    raise SystemExit(1)

# Use the first segment for simulation
seg = segments.first()
points = seg.polyline_points
print('Simulating on segment', seg.order, 'with', len(points), 'points')

for idx, (lat, lon) in enumerate(points):
    payload = {'latitude': lat, 'longitude': lon, 'speed': 20}
    url_update = f"{BASE_URL}/api/buses/{bus.pk}/update-location/"
    try:
        r = requests.post(url_update, json=payload, timeout=5)
        print(f'Posted location {idx+1}/{len(points)} -> status', r.status_code)
    except Exception as e:
        print('Update-location error:', e)
        break

    # Fetch ETA
    try:
        r2 = requests.get(f"{BASE_URL}/api/bus-lines/{bus.bus_line.route_id}/stops-with-eta/?bus_id={bus.bus_id}", timeout=5)
        if r2.status_code == 200:
            data = r2.json()
            print('ETA source:', data.get('eta_source'), 'speed_kmh:', data.get('speed_kmh'))
            for s in data.get('stops', [])[:3]:
                print('  stop', s['stop_name'], 'eta_sec', s.get('eta_seconds'))
        else:
            print('stops-with-eta status', r2.status_code)
    except Exception as e:
        print('stops-with-eta error:', e)
        break

    time.sleep(0.5)

print('Simulation complete')
