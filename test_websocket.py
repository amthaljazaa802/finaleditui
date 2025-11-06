"""
سكريبت بسيط لاختبار إرسال تحديثات مواقع الحافلات عبر API
والتحقق من إرسالها عبر WebSocket
"""

import requests
import time
import random

# إعدادات الخادم
BASE_URL = "http://127.0.0.1:8000"
API_ENDPOINT = f"{BASE_URL}/api/buses/1/update-location/"

# إعدادات المصادقة (Token Authentication)
AUTH_TOKEN = "d1afc8c6685f541724963a55cd0ebca599dac16f"

# نقاط مسار وهمية (الرياض)
route_points = [
    {"latitude": 24.7136, "longitude": 46.6753},  # الملك فهد
    {"latitude": 24.7200, "longitude": 46.6800},
    {"latitude": 24.7250, "longitude": 46.6850},
    {"latitude": 24.7300, "longitude": 46.6900},
    {"latitude": 24.7350, "longitude": 46.6950},
]

def send_location_update(latitude, longitude, speed=None):
    """
    إرسال تحديث موقع الحافلة
    """
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Token {AUTH_TOKEN}"
    }
    
    data = {
        "latitude": latitude,
        "longitude": longitude,
    }
    
    if speed:
        data["speed"] = speed
    
    try:
        response = requests.post(API_ENDPOINT, json=data, headers=headers)
        
        if response.status_code in [200, 201]:
            print(f"✅ تم إرسال التحديث بنجاح:")
            print(f"   📍 الموقع: {latitude}, {longitude}")
            if speed:
                print(f"   🚀 السرعة: {speed} km/h")
            print(f"   📡 الاستجابة: {response.json()}")
            return True
        else:
            print(f"❌ فشل إرسال التحديث:")
            print(f"   رمز الحالة: {response.status_code}")
            print(f"   الاستجابة: {response.text}")
            return False
    except Exception as e:
        print(f"❌ خطأ في الاتصال: {e}")
        return False

def simulate_bus_movement():
    """
    محاكاة حركة الحافلة على المسار
    """
    print("🚌 بدء محاكاة حركة الحافلة...")
    print("=" * 50)
    
    while True:
        for point in route_points:
            # سرعة عشوائية بين 30 و 60 كم/ساعة
            speed = random.uniform(30, 60)
            
            print(f"\n⏱️  {time.strftime('%H:%M:%S')}")
            success = send_location_update(
                point["latitude"],
                point["longitude"],
                speed
            )
            
            if success:
                print("   ⏳ انتظار 5 ثوان...")
            else:
                print("   ⚠️  إعادة المحاولة بعد 10 ثوان...")
                time.sleep(10)
                continue
            
            time.sleep(5)
        
        print("\n" + "=" * 50)
        print("🔄 إعادة المسار...")
        print("=" * 50)

def send_single_update():
    """
    إرسال تحديث واحد فقط
    """
    print("📤 إرسال تحديث واحد...")
    
    latitude = 24.7136
    longitude = 46.6753
    speed = 45.5
    
    send_location_update(latitude, longitude, speed)

if __name__ == "__main__":
    print("""
    ╔════════════════════════════════════════════════╗
    ║  اختبار تحديثات موقع الحافلة عبر WebSocket   ║
    ╚════════════════════════════════════════════════╝
    
    الخيارات:
    1. إرسال تحديث واحد فقط
    2. محاكاة حركة الحافلة (مستمر)
    """)
    
    choice = input("اختر (1 أو 2): ").strip()
    
    if choice == "1":
        send_single_update()
    elif choice == "2":
        simulate_bus_movement()
    else:
        print("❌ خيار غير صحيح!")
