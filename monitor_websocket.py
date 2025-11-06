"""
مراقبة WebSocket - يستمع للتحديثات القادمة من تطبيق السائق
"""
import asyncio
import websockets
import json
from datetime import datetime

async def listen_to_websocket():
    uri = "ws://192.168.0.166:8000/ws/bus-locations/"
    
    print(f"🔗 محاولة الاتصال بـ WebSocket: {uri}")
    print("⏳ انتظار رسائل من تطبيق السائق...\n")
    
    try:
        async with websockets.connect(uri) as websocket:
            print("✅ اتصال WebSocket ناجح!")
            print("=" * 60)
            
            while True:
                try:
                    message = await websocket.recv()
                    data = json.loads(message)
                    
                    timestamp = datetime.now().strftime("%H:%M:%S")
                    print(f"\n⏰ [{timestamp}] رسالة جديدة:")
                    print(f"📍 الباص: {data.get('bus_id', 'N/A')}")
                    print(f"🌍 الموقع: ({data.get('latitude', 'N/A')}, {data.get('longitude', 'N/A')})")
                    print(f"⚡ السرعة: {data.get('speed', 'N/A')} km/h")
                    print(f"🧭 الاتجاه: {data.get('bearing', 'N/A')}°")
                    print(f"👤 السائق: {data.get('driver_id', 'N/A')}")
                    print(f"⏱️ التوقيت: {data.get('timestamp', 'N/A')}")
                    print("=" * 60)
                    
                except websockets.exceptions.ConnectionClosed:
                    print("\n❌ انقطع الاتصال بـ WebSocket")
                    break
                except json.JSONDecodeError as e:
                    print(f"\n⚠️ خطأ في تحليل JSON: {e}")
                except Exception as e:
                    print(f"\n⚠️ خطأ: {e}")
                    
    except ConnectionRefusedError:
        print("❌ فشل الاتصال - تأكد من أن السيرفر شغال على http://192.168.0.166:8000")
    except Exception as e:
        print(f"❌ خطأ في الاتصال: {e}")

if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("📡 مراقب WebSocket - Bus Tracking System")
    print("=" * 60 + "\n")
    
    try:
        asyncio.run(listen_to_websocket())
    except KeyboardInterrupt:
        print("\n\n👋 تم إيقاف المراقبة")
