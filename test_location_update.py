"""
اختبار سريع لـ endpoint تحديث الموقع
"""
import requests
import json

# الإعدادات
API_URL = "http://192.168.0.166:8000"
AUTH_TOKEN = "d1afc8c6685f541724963a55cd0ebca599dac16f"
BUS_ID = 1  # ID الحافلة من قاعدة البيانات

# بيانات الموقع التجريبية
test_location = {
    "latitude": "35.52521",
    "longitude": "35.79683",
    "speed": "45.5"
}

headers = {
    "Authorization": f"Token {AUTH_TOKEN}",
    "Content-Type": "application/json"
}

print("="*50)
print("🧪 اختبار endpoint تحديث الموقع")
print("="*50)
print(f"\n🔗 URL: {API_URL}/api/buses/{BUS_ID}/update-location/")
print(f"📍 الموقع: {test_location}")
print("\n⏳ جاري الإرسال...")

try:
    response = requests.post(
        f"{API_URL}/api/buses/{BUS_ID}/update-location/",
        headers=headers,
        json=test_location
    )
    
    print(f"\n✅ الاستجابة:")
    print(f"   Status Code: {response.status_code}")
    
    if response.status_code in [200, 204]:
        print("   ✅ تم تحديث الموقع بنجاح!")
        if response.text:
            print(f"   Response: {response.text}")
    else:
        print(f"   ❌ خطأ: {response.text}")
        
except Exception as e:
    print(f"\n❌ فشل الاتصال: {e}")
    print("\n💡 تأكد من:")
    print("   - السيرفر شغال على 0.0.0.0:8000")
    print("   - الـ Token صحيح")
    print("   - الحافلة موجودة في قاعدة البيانات")

print("\n" + "="*50)
