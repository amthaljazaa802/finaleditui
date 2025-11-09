"""
Regenerate RouteSegments with high-detail polylines from OSRM
This uses geometries=full and overview=full for maximum accuracy
"""
import os
import sys
import django
import requests
import json
from math import radians, cos, sin, asin, sqrt

# Setup Django
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, ROOT)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from bus_tracking.models import BusLine, BusLineStop, RouteSegment

def haversine(lon1, lat1, lon2, lat2):
    """Calculate distance in meters between two lat/lon points"""
    R = 6371000  # Earth radius in meters
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])
    dlon = lon2 - lon1
    dlat = lat2 - lat1
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a))
    return R * c

def get_osrm_route(lat1, lon1, lat2, lon2):
    """Get detailed route from OSRM with full geometry"""
    url = f"http://router.project-osrm.org/route/v1/driving/{lon1},{lat1};{lon2},{lat2}"
    params = {
        'overview': 'full',  # Full geometry (not simplified)
        'geometries': 'geojson',  # GeoJSON format (easier to parse)
        'steps': 'true'  # Include turn-by-turn steps for more detail
    }
    
    try:
        response = requests.get(url, params=params, timeout=10)
        if response.status_code == 200:
            data = response.json()
            if data.get('routes'):
                route = data['routes'][0]
                # Get coordinates from geometry
                coordinates = route['geometry']['coordinates']
                # Convert [lon, lat] to [lat, lon] for consistency
                polyline = [[coord[1], coord[0]] for coord in coordinates]
                distance = route['distance']  # in meters
                duration = route['duration']  # in seconds
                return polyline, distance, duration
    except Exception as e:
        print(f"  ❌ OSRM error: {e}")
    
    return None, None, None

def calculate_polyline_distance(polyline):
    """Calculate total distance of a polyline by summing segment lengths"""
    total = 0.0
    for i in range(len(polyline) - 1):
        lat1, lon1 = polyline[i]
        lat2, lon2 = polyline[i + 1]
        total += haversine(lon1, lat1, lon2, lat2)
    return total

def regenerate_all_segments():
    """Regenerate all route segments with detailed OSRM data"""
    print("=" * 80)
    print("REGENERATING ROUTE SEGMENTS WITH HIGH-DETAIL OSRM DATA")
    print("=" * 80)
    
    # Get all bus lines
    bus_lines = BusLine.objects.all().order_by('route_id')
    
    for bus_line in bus_lines:
        print(f"\n📍 Processing Route {bus_line.route_id}: {bus_line.route_name}")
        
        # Get stops for this line in order
        line_stops = BusLineStop.objects.filter(bus_line=bus_line).order_by('order').select_related('bus_stop', 'bus_stop__location')
        
        if line_stops.count() < 2:
            print(f"  ⚠️  Skipping - need at least 2 stops")
            continue
        
        # Get existing segments for comparison
        existing_segments = {
            (seg.from_stop_id, seg.to_stop_id): seg 
            for seg in RouteSegment.objects.filter(bus_line=bus_line)
        }
        
        # Process each consecutive pair of stops
        for i in range(len(line_stops) - 1):
            from_stop = line_stops[i].bus_stop
            to_stop = line_stops[i + 1].bus_stop
            
            if not from_stop.location or not to_stop.location:
                print(f"  ⚠️  Segment {i+1}: {from_stop.stop_name} -> {to_stop.stop_name} - Missing location")
                continue
            
            # Get existing segment for comparison
            existing = existing_segments.get((from_stop.stop_id, to_stop.stop_id))
            old_distance = existing.distance_meters if existing else None
            old_points = len(existing.polyline_points) if existing else 0
            
            print(f"\n  Segment {i+1}: {from_stop.stop_name} -> {to_stop.stop_name}")
            
            # Get OSRM route
            polyline, distance_m, duration_s = get_osrm_route(
                from_stop.location.latitude,
                from_stop.location.longitude,
                to_stop.location.latitude,
                to_stop.location.longitude
            )
            
            if polyline and distance_m:
                # Verify polyline distance
                calculated_dist = calculate_polyline_distance(polyline)
                dist_diff = abs(distance_m - calculated_dist)
                
                print(f"    OSRM distance: {distance_m:.1f}m")
                print(f"    Polyline calc: {calculated_dist:.1f}m (diff: {dist_diff:.1f}m)")
                print(f"    Polyline points: {len(polyline)}")
                print(f"    Duration: {duration_s:.0f}s ({duration_s/60:.1f} min)")
                
                if old_distance:
                    change = distance_m - old_distance
                    change_pct = (change / old_distance) * 100
                    points_change = len(polyline) - old_points
                    print(f"    📊 OLD: {old_distance:.1f}m, {old_points} points")
                    print(f"    📈 CHANGE: {change:+.1f}m ({change_pct:+.1f}%), {points_change:+d} points")
                
                # Create or update segment
                RouteSegment.objects.update_or_create(
                    bus_line=bus_line,
                    from_stop=from_stop,
                    to_stop=to_stop,
                    defaults={
                        'order': i + 1,
                        'distance_meters': distance_m,
                        'typical_duration_seconds': int(duration_s),
                        'polyline_points': polyline
                    }
                )
                print(f"    ✅ Segment saved")
            else:
                print(f"    ❌ Failed to get OSRM route")
    
    print("\n" + "=" * 80)
    print("✅ REGENERATION COMPLETE")
    print("=" * 80)
    
    # Show summary
    total_segments = RouteSegment.objects.count()
    total_distance = sum(seg.distance_meters for seg in RouteSegment.objects.all())
    total_points = sum(len(seg.polyline_points) for seg in RouteSegment.objects.all())
    avg_points_per_seg = total_points / total_segments if total_segments > 0 else 0
    
    print(f"\n📊 SUMMARY:")
    print(f"   Total segments: {total_segments}")
    print(f"   Total distance: {total_distance/1000:.2f} km")
    print(f"   Total polyline points: {total_points}")
    print(f"   Average points per segment: {avg_points_per_seg:.1f}")

if __name__ == '__main__':
    regenerate_all_segments()
