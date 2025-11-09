/// =====================================================================
/// Bus Tracking App - Configuration
/// =====================================================================
/// إعدادات الاتصال بالسيرفر والـ WebSocket
/// التطبيق يستخدم:
/// - HTTPS للـ REST API (Driver app)
/// - WSS (Secure WebSocket) للتحديثات الحقيقية (User app)
/// - Token-based authentication
///
/// قم بتحديث هذه الإعدادات حسب بيئة التشغيل الخاصة بك

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // =====================================================================
  // SERVER CONFIGURATION
  // =====================================================================

  /// عنوان URL الأساسي للـ API
  /// الاتصال: User app ↔ Server عبر HTTP (for development)
  ///
  /// للتطوير المحلي:
  ///   - المحاكي (Android): 'http://10.0.2.2:8000'
  ///   - المحاكي (iOS): 'http://127.0.0.1:8000'
  ///   - الجهاز الحقيقي: 'http://YOUR-COMPUTER-IP:8000' (e.g., 'http://192.168.1.100:8000')
  ///
  /// للإنتاج:
  ///   - 'https://api.example.com'
  ///   - استخدم شهادة SSL صحيحة
  ///
  /// ⚠️ IMPORTANT: Set this in .env file instead!
  /// This is just a fallback value for development
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';

  /// عنوان WebSocket (ws:// for development, wss:// for production)
  /// الاتصال: User app ↔ Server عبر WebSocket
  ///
  /// للتطوير المحلي:
  ///   - المحاكي (Android): 'ws://10.0.2.2:8000/ws/bus-locations/'
  ///   - المحاكي (iOS): 'ws://127.0.0.1:8000/ws/bus-locations/'
  ///   - الجهاز الحقيقي: 'ws://YOUR-COMPUTER-IP:8000/ws/bus-locations/'
  ///
  /// للإنتاج:
  ///   - 'wss://api.example.com/ws/bus-locations/'
  ///
  /// ملاحظة: wss:// يتطلب شهادة SSL صحيحة على الخادم
  ///
  /// ⚠️ IMPORTANT: Set this in .env file instead!
  /// This is just a fallback value for development
  static String get websocketUrl => dotenv.env['WEBSOCKET_URL'] ?? 'ws://10.0.2.2:8000/ws/bus-locations/'; // =====================================================================
  // APPLICATION SETTINGS
  // =====================================================================

  /// استخدام البيانات الوهمية أم البيانات الحقيقية
  ///
  /// true: استخدام بيانات وهمية (للتطوير بدون سيرفر)
  /// false: استخدام بيانات حقيقية من السيرفر
  static const bool useMockData = false;

  // =====================================================================
  // AUTHENTICATION
  // =====================================================================

  /// Token للمصادقة مع السيرفر
  /// احصل على token من Django Admin أو API endpoint للمصادقة
  ///
  /// يتم إرساله في header:
  /// Authorization: Token <authToken>
  ///
  /// ⚠️ أمني: لا تضع token حقيقي في المستودع العام
  /// استخدم متغيرات بيئة أو ملف .env
  ///
  /// ⚠️ IMPORTANT: Set this in .env file!
  /// This is just a fallback value - the actual token should be in .env
  static String get authToken => dotenv.env['AUTH_TOKEN'] ?? '';

  /// تفعيل WebSocket للتحديثات المباشرة
  ///
  /// ملاحظة: يتم تفعيله تلقائياً عند useMockData = false
  static const bool enableWebSocket = true;

  // =====================================================================
  // WEBSOCKET SETTINGS
  // =====================================================================

  /// مدة إعادة المحاولة في حالة فشل الاتصال (بالثواني)
  static const int reconnectDelay = 5;

  /// عدد محاولات إعادة الاتصال
  static const int maxReconnectAttempts = 5;

  // =====================================================================
  // API ENDPOINTS
  // =====================================================================

  /// مسارات API
  static const String busesEndpoint = '/api/buses/';
  static const String busStopsEndpoint = '/api/bus-stops/';
  static const String busLinesEndpoint = '/api/bus-lines/';
  static const String updateLocationEndpoint = '/update-location/';

  // --- إعدادات الخريطة ---

  /// الموقع الافتراضي للخريطة (الرياض)
  static const double defaultLatitude = 24.7136;
  static const double defaultLongitude = 46.6753;
  static const double defaultZoom = 13.0;

  // --- دليل الاستخدام ---

  /// كيفية الحصول على عنوان IP للجهاز:
  ///
  /// Windows (PowerShell):
  /// ```
  /// ipconfig
  /// ```
  /// ابحث عن "IPv4 Address" تحت قسم WiFi
  ///
  /// macOS/Linux:
  /// ```
  /// ifconfig | grep inet
  /// ```
  ///
  /// مثال على النتيجة: 192.168.1.100
  ///
  /// ثم قم بتحديث baseUrl و websocketUrl:
  /// ```dart
  /// static const String baseUrl = 'http://192.168.1.100:8000';
  /// static const String websocketUrl = 'ws://192.168.1.100:8000/ws/bus-locations/';
  /// ```
}
