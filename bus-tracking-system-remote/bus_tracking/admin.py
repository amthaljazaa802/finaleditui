# bus_tracking/admin.py

from django.contrib import admin
from .models import Bus, BusLine, BusStop, Location, BusLocationLog, Alert, BusLineStop, RouteSegment

# Register your models here.
admin.site.register(Bus)
admin.site.register(BusLine)
admin.site.register(BusStop)
admin.site.register(Location)
admin.site.register(BusLocationLog) # New log model
admin.site.register(Alert)
admin.site.register(BusLineStop)

@admin.register(RouteSegment)
class RouteSegmentAdmin(admin.ModelAdmin):
    list_display = ('bus_line', 'from_stop', 'to_stop', 'order', 'distance_meters', 'typical_duration_seconds')
    list_filter = ('bus_line',)
    search_fields = ('from_stop__stop_name', 'to_stop__stop_name')
    ordering = ('bus_line', 'order')