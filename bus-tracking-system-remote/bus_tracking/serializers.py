# bus_tracking/serializers.py

from rest_framework import serializers
from .models import (
    Bus,
    BusLine,
    BusStop,
    Location,
    BusLocationLog,
    Alert,
    BusLineStop
)

# This serializer must be defined BEFORE BusSerializer uses it.
class BusLineSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusLine
        fields = ['route_id', 'route_name', 'route_description']

# Extended serializer that includes stops (for initial-data endpoint)
class BusLineWithStopsSerializer(serializers.ModelSerializer):
    stops = serializers.SerializerMethodField()
    
    class Meta:
        model = BusLine
        fields = ['route_id', 'route_name', 'route_description', 'stops']
    
    def get_stops(self, obj):
        # Get all stops for this bus line in order
        from .models import BusLineStop
        bus_line_stops = BusLineStop.objects.filter(bus_line=obj).select_related('bus_stop', 'bus_stop__location').order_by('order')
        stops_data = []
        for bls in bus_line_stops:
            stop = bls.bus_stop
            stops_data.append({
                'stop_id': stop.stop_id,
                'stop_name': stop.stop_name,
                'location': {
                    'id': stop.location.id,
                    'latitude': stop.location.latitude,
                    'longitude': stop.location.longitude
                } if stop.location else None
            })
        return stops_data

# Define LocationSerializer before BusSerializer uses it
class LocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Location
        fields = ['id', 'latitude', 'longitude']

class BusSerializer(serializers.ModelSerializer):
    # This field is for READING (GET requests). It shows the full nested object.
    # We name it something different to avoid a clash.
    bus_line = BusLineSerializer(read_only=True)
    
    # Include current location for real-time tracking
    current_location = LocationSerializer(read_only=True)
    
    # This field is for WRITING (POST/PUT requests). It accepts just the route's ID.
    # We use the actual model field name here. 'source' is not needed for writing.
    bus_line_id = serializers.PrimaryKeyRelatedField(
        queryset=BusLine.objects.all(),
        source='bus_line', # Links this to the 'bus_line' model field
        write_only=True,
        allow_null=True,   # Allows the bus to have no assigned route
        required=False     # Makes the field optional on submission
    )

    class Meta:
        model = Bus
        # The fields list now includes our new write_only field and current_location
        fields = ['bus_id', 'license_plate', 'qr_code_value', 'bus_line', 'bus_line_id', 'current_location']


# --- Other Serializers (for completeness) ---

class BusStopSerializer(serializers.ModelSerializer):
    location = LocationSerializer(read_only=True)
    
    class Meta:
        model = BusStop
        fields = ['stop_id', 'stop_name', 'location']

class BusStopWithOrderSerializer(serializers.ModelSerializer):
    bus_stop = BusStopSerializer(read_only=True)
    
    class Meta:
        model = BusLineStop
        fields = ['id', 'bus_stop', 'order']

class BusLocationLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = BusLocationLog
        fields = '__all__'
        depth = 1

class AlertSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alert
        fields = '__all__'
        depth = 1