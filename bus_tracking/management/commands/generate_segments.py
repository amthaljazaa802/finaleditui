"""
Django management command to generate route segments using OpenStreetMap data.

Usage:
    python manage.py generate_segments [--route-id=X] [--all] [--force]

This command fetches real road routes from OSRM (OpenStreetMap Routing Machine)
and creates RouteSegment objects with accurate distances and polylines.
"""

from django.core.management.base import BaseCommand, CommandError
from bus_tracking.models import BusLine, BusLineStop, RouteSegment, BusStop
import requests
import time
from typing import List, Tuple, Optional
import polyline  # For decoding OSRM polylines


class Command(BaseCommand):
    help = 'Generate route segments from OpenStreetMap data using OSRM API'

    def add_arguments(self, parser):
        parser.add_argument(
            '--route-id',
            type=int,
            help='Generate segments for a specific route ID',
        )
        parser.add_argument(
            '--all',
            action='store_true',
            help='Generate segments for all routes',
        )
        parser.add_argument(
            '--force',
            action='store_true',
            help='Regenerate segments even if they already exist',
        )
        parser.add_argument(
            '--osrm-server',
            type=str,
            default='http://router.project-osrm.org',
            help='OSRM server URL (default: public OSRM server)',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('🗺️  Starting route segment generation from OpenStreetMap...'))
        
        osrm_server = options['osrm_server']
        force = options['force']
        
        # Determine which routes to process
        if options['route_id']:
            try:
                routes = [BusLine.objects.get(pk=options['route_id'])]
                self.stdout.write(f"Processing route: {routes[0].route_name}")
            except BusLine.DoesNotExist:
                raise CommandError(f"Route with ID {options['route_id']} does not exist")
        elif options['all']:
            routes = BusLine.objects.all()
            self.stdout.write(f"Processing all {routes.count()} routes")
        else:
            raise CommandError("Please specify --route-id=X or --all")
        
        total_segments_created = 0
        total_segments_skipped = 0
        
        for route in routes:
            self.stdout.write(f"\n📍 Processing route: {route.route_name} (ID: {route.route_id})")
            
            # Get ordered stops for this route
            stops = list(
                BusLineStop.objects.filter(bus_line=route)
                .select_related('bus_stop__location')
                .order_by('order')
            )
            
            if len(stops) < 2:
                self.stdout.write(self.style.WARNING(f"  ⚠️  Route has less than 2 stops, skipping"))
                continue
            
            # Check if segments already exist
            existing_segments = RouteSegment.objects.filter(bus_line=route).count()
            if existing_segments > 0 and not force:
                self.stdout.write(
                    self.style.WARNING(
                        f"  ⚠️  Route already has {existing_segments} segments. "
                        f"Use --force to regenerate."
                    )
                )
                total_segments_skipped += existing_segments
                continue
            
            # Delete existing segments if force is enabled
            if existing_segments > 0 and force:
                RouteSegment.objects.filter(bus_line=route).delete()
                self.stdout.write(f"  🗑️  Deleted {existing_segments} existing segments")
            
            # Generate segments between consecutive stops
            segments_created = 0
            for i in range(len(stops) - 1):
                from_stop_obj = stops[i]
                to_stop_obj = stops[i + 1]
                
                from_stop = from_stop_obj.bus_stop
                to_stop = to_stop_obj.bus_stop
                
                self.stdout.write(
                    f"  🛣️  Creating segment {i+1}/{len(stops)-1}: "
                    f"{from_stop.stop_name} → {to_stop.stop_name}"
                )
                
                # Fetch route from OSRM
                route_data = self.fetch_osrm_route(
                    osrm_server,
                    from_stop.location.latitude,
                    from_stop.location.longitude,
                    to_stop.location.latitude,
                    to_stop.location.longitude,
                )
                
                if route_data:
                    distance_meters = route_data['distance']
                    duration_seconds = route_data['duration']
                    polyline_points = route_data['polyline']
                    
                    # Create the segment
                    segment = RouteSegment.objects.create(
                        bus_line=route,
                        from_stop=from_stop,
                        to_stop=to_stop,
                        order=from_stop_obj.order,
                        distance_meters=distance_meters,
                        typical_duration_seconds=int(duration_seconds),
                        polyline_points=polyline_points,
                    )
                    
                    segments_created += 1
                    self.stdout.write(
                        self.style.SUCCESS(
                            f"    ✅ Created segment: {distance_meters:.0f}m, "
                            f"{duration_seconds/60:.1f} min, "
                            f"{len(polyline_points)} polyline points"
                        )
                    )
                else:
                    self.stdout.write(
                        self.style.ERROR(
                            f"    ❌ Failed to fetch route data from OSRM"
                        )
                    )
                
                # Rate limiting: be nice to public OSRM server
                if 'router.project-osrm.org' in osrm_server:
                    time.sleep(0.5)  # 500ms delay between requests
            
            total_segments_created += segments_created
            self.stdout.write(
                self.style.SUCCESS(
                    f"  ✅ Created {segments_created} segments for route {route.route_name}"
                )
            )
        
        # Summary
        self.stdout.write(self.style.SUCCESS(
            f"\n🎉 Generation complete!\n"
            f"   Created: {total_segments_created} segments\n"
            f"   Skipped: {total_segments_skipped} segments"
        ))

    def fetch_osrm_route(
        self, 
        osrm_server: str, 
        lat1: float, 
        lon1: float, 
        lat2: float, 
        lon2: float
    ) -> Optional[dict]:
        """
        Fetch route from OSRM API.
        
        Returns:
            dict with 'distance' (meters), 'duration' (seconds), 'polyline' (list of [lat, lon])
            or None if request fails
        """
        url = f"{osrm_server}/route/v1/driving/{lon1},{lat1};{lon2},{lat2}"
        params = {
            'overview': 'full',  # Get full route geometry
            'geometries': 'polyline',  # Use polyline encoding
            'steps': 'false',  # We don't need turn-by-turn
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data.get('code') != 'Ok' or not data.get('routes'):
                self.stdout.write(
                    self.style.ERROR(f"      OSRM error: {data.get('code', 'Unknown')}")
                )
                return None
            
            route = data['routes'][0]
            
            # Decode polyline
            encoded_polyline = route['geometry']
            decoded_coords = polyline.decode(encoded_polyline)  # Returns list of (lat, lon) tuples
            
            # Convert to list of [lat, lon] for JSON storage
            polyline_points = [[lat, lon] for lat, lon in decoded_coords]
            
            return {
                'distance': route['distance'],  # meters
                'duration': route['duration'],  # seconds
                'polyline': polyline_points,
            }
            
        except requests.RequestException as e:
            self.stdout.write(self.style.ERROR(f"      Network error: {e}"))
            return None
        except Exception as e:
            self.stdout.write(self.style.ERROR(f"      Error: {e}"))
            return None
