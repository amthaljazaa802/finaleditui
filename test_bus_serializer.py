#!/usr/bin/env python
"""Test script to check BusSerializer output"""

import os
import sys
import django
import json

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from bus_tracking.serializers import BusSerializer
from bus_tracking.models import Bus

# Get all buses
buses = Bus.objects.all()

print(f"Found {buses.count()} buses\n")

for bus in buses:
    print(f"Bus ID: {bus.bus_id}")
    print(f"License Plate: {bus.license_plate}")
    print(f"QR Code: {bus.qr_code_value}")
    print(f"Bus Line ID: {bus.bus_line_id}")
    print(f"Current Location ID: {bus.current_location_id}")
    print("\nSerialized data:")
    serialized = BusSerializer(bus).data
    print(json.dumps(serialized, indent=2, default=str))
    print("\n" + "="*50 + "\n")
