"""
اختبار الاتصال بـ WebSocket من Python
يستمع لتحديثات مواقع الحافلات المباشرة
"""

import asyncio
import websockets
import json

WS_URL = "ws://127.0.0.1:8000/ws/bus-locations/"

async def listen_to_bus_updates():
    """
    الاتصال بـ WebSocket والاستماع للتحديثات
    """
    print(f"🔌 محاولة الاتصال بـ: {WS_URL}")
    
    try:
        async with websockets.connect(WS_URL) as websocket:
            print("✅ تم الاتصال بنجاح!")
            print("👂 جاري الاستماع للتحديثات...")
            print("=" * 60)
            
            # الاستماع للرسائل بشكل مستمر
            async for message in websocket:
                try:
                    data = json.loads(message)
                    
                    print(f"\n📡 تحديث جديد وصل!")
                    print(f"   🚌 معرف الحافلة: {data.get('bus_id')}")
                    print(f"   🚗 لوحة الترخيص: {data.get('license_plate')}")
                    print(f"   📍 الموقع: {data.get('latitude')}, {data.get('longitude')}")
                    print(f"   🚀 السرعة: {data.get('speed')} km/h")
                    print(f"   ⏰ الوقت: {data.get('timestamp')}")
                    print("=" * 60)
                    
                except json.JSONDecodeError:
                    print(f"⚠️  رسالة غير صالحة: {message}")
                    
    except websockets.exceptions.WebSocketException as e:
        print(f"❌ خطأ في WebSocket: {e}")
    except ConnectionRefusedError:
        print("❌ فشل الاتصال! تأكد من تشغيل السيرفر على المنفذ 8000")
    except Exception as e:
        print(f"❌ خطأ: {e}")

if __name__ == "__main__":
    print("""
    ╔══════════════════════════════════════════════════╗
    ║     مستمع تحديثات الحافلات عبر WebSocket       ║
    ╚══════════════════════════════════════════════════╝
    
    📝 تأكد من تشغيل السيرفر أولاً:
       python manage.py runserver
    
    💡 لاختبار التحديثات، افتح نافذة أخرى وشغل:
       python test_websocket.py
    
    اضغط Ctrl+C للإيقاف
    """)
    
    try:
        asyncio.run(listen_to_bus_updates())
    except KeyboardInterrupt:
        print("\n\n👋 تم الإيقاف بنجاح!")
