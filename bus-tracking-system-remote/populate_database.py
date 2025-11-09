"""
سكريبت لإضافة بيانات تجريبية في قاعدة البيانات
شغّله مرة واحدة فقط لملء قاعدة البيانات
"""

import os
import django

# إعداد Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'BusTrackingSystem.settings')
django.setup()

from bus_tracking.models import Bus, BusLine, BusStop, Location, BusLineStop
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

def create_sample_data():
    print("🚀 بدء إضافة البيانات التجريبية...")
    
    # 1. إنشاء مستخدم إداري إذا لم يكن موجوداً
    print("\n[1/5] التحقق من المستخدم الإداري...")
    user, created = User.objects.get_or_create(
        username='admin',
        defaults={
            'email': 'admin@bustrack.com',
            'is_staff': True,
            'is_superuser': True
        }
    )
    if created:
        user.set_password('admin123')
        user.save()
        print("✅ تم إنشاء مستخدم إداري: admin / admin123")
    else:
        print("✅ المستخدم الإداري موجود مسبقاً")
    
    # إنشاء Token للمستخدم
    token, _ = Token.objects.get_or_create(user=user)
    print(f"🔑 Token: {token.key}")
    
    # 2. إنشاء محطات الحافلات
    print("\n[2/5] إنشاء محطات الحافلات...")
    stations = [
        {"name": "محطة الملك فهد", "lat": 24.7136, "lon": 46.6753},
        {"name": "محطة العليا", "lat": 24.7200, "lon": 46.6800},
        {"name": "محطة التخصصي", "lat": 24.7250, "lon": 46.6850},
        {"name": "محطة الملز", "lat": 24.7300, "lon": 46.6900},
        {"name": "محطة الرياض بارك", "lat": 24.7350, "lon": 46.6950},
    ]
    
    stops = []
    for station in stations:
        location = Location.objects.create(
            latitude=station["lat"],
            longitude=station["lon"]
        )
        stop = BusStop.objects.create(
            stop_name=station["name"],
            location=location
        )
        stops.append(stop)
        print(f"  ✅ {station['name']}")
    
    # 3. إنشاء خطوط الحافلات
    print("\n[3/5] إنشاء خطوط الحافلات...")
    lines = [
        {"name": "خط 1", "desc": "الملك فهد - الرياض بارك"},
        {"name": "خط 2", "desc": "العليا - الملز"},
    ]
    
    bus_lines = []
    for line_data in lines:
        line = BusLine.objects.create(
            route_name=line_data["name"],
            route_description=line_data["desc"]
        )
        bus_lines.append(line)
        print(f"  ✅ {line_data['name']}: {line_data['desc']}")
    
    # 4. ربط المحطات بالخطوط
    print("\n[4/5] ربط المحطات بالخطوط...")
    # خط 1: جميع المحطات بالترتيب
    for i, stop in enumerate(stops):
        BusLineStop.objects.create(
            bus_line=bus_lines[0],
            bus_stop=stop,
            order=i + 1
        )
    print(f"  ✅ خط 1: {len(stops)} محطات")
    
    # خط 2: بعض المحطات
    for i in [1, 2, 3]:  # العليا، التخصصي، الملز
        BusLineStop.objects.create(
            bus_line=bus_lines[1],
            bus_stop=stops[i],
            order=i
        )
    print(f"  ✅ خط 2: 3 محطات")
    
    # 5. إنشاء حافلات
    print("\n[5/5] إنشاء حافلات...")
    buses_data = [
        {"plate": "أ ب ج 123", "line": bus_lines[0]},
        {"plate": "ه و ز 456", "line": bus_lines[0]},
        {"plate": "ح ط ي 789", "line": bus_lines[1]},
    ]
    
    for bus_data in buses_data:
        # موقع أولي عند أول محطة في الخط
        first_stop = BusLineStop.objects.filter(
            bus_line=bus_data["line"]
        ).order_by('order').first()
        
        initial_location = Location.objects.create(
            latitude=first_stop.bus_stop.location.latitude,
            longitude=first_stop.bus_stop.location.longitude
        )
        
        bus = Bus.objects.create(
            license_plate=bus_data["plate"],
            bus_line=bus_data["line"],
            current_location=initial_location
        )
        print(f"  ✅ حافلة {bus_data['plate']} - {bus_data['line'].route_name}")
    
    print("\n" + "="*50)
    print("🎉 تم إضافة جميع البيانات بنجاح!")
    print("="*50)
    print(f"\n📊 الملخص:")
    print(f"  • المحطات: {BusStop.objects.count()}")
    print(f"  • الخطوط: {BusLine.objects.count()}")
    print(f"  • الحافلات: {Bus.objects.count()}")
    print(f"\n🔐 بيانات الدخول:")
    print(f"  Username: admin")
    print(f"  Password: admin123")
    print(f"  Token: {token.key}")
    print(f"\n🌐 روابط مفيدة:")
    print(f"  Admin Panel: http://127.0.0.1:8000/admin")
    print(f"  API Buses: http://127.0.0.1:8000/api/buses/")
    print(f"  API Lines: http://127.0.0.1:8000/api/bus-lines/")

if __name__ == '__main__':
    try:
        create_sample_data()
    except Exception as e:
        print(f"\n❌ خطأ: {e}")
        import traceback
        traceback.print_exc()
