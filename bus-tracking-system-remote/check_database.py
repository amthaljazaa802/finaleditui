"""
سكريبت للتحقق من البيانات الموجودة في قاعدة البيانات
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from bus_tracking.models import Bus, BusLine, BusStop, Location
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

print("="*50)
print("📊 التحقق من البيانات في قاعدة البيانات")
print("="*50)

# 1. Users and Tokens
users = User.objects.all()
print(f"\n👥 المستخدمين: {users.count()}")
for user in users:
    token = Token.objects.filter(user=user).first()
    print(f"  - {user.username} (Token: {token.key if token else 'لا يوجد'})")

# 2. Bus Lines
lines = BusLine.objects.all()
print(f"\n🚌 خطوط الحافلات: {lines.count()}")
for line in lines:
    desc = line.route_description if hasattr(line, 'route_description') else ''
    print(f"  - {line.route_name}: {desc}")

# 3. Bus Stops
stops = BusStop.objects.all()
print(f"\n🚏 المحطات: {stops.count()}")
for stop in stops:
    print(f"  - {stop.stop_name} ({stop.location.latitude}, {stop.location.longitude})")

# 4. Buses
buses = Bus.objects.all()
print(f"\n🚍 الحافلات: {buses.count()}")
for bus in buses:
    line_name = bus.bus_line.route_name if bus.bus_line else 'بدون خط'
    loc = bus.current_location
    print(f"  - ID:{bus.bus_id} | {bus.license_plate} | {line_name}")
    if loc:
        print(f"    الموقع: ({loc.latitude}, {loc.longitude})")

print("\n" + "="*50)
