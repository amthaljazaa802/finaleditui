import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  // 🧪 وضع البيانات الوهمية (Mock Mode)
  // غيّر هذا إلى false لاستخدام API حقيقي
  static const bool useMockData = false;

  // Allow overriding values for easier testing. If not provided, try reading from dotenv.
  final String? _overrideBaseUrl;
  final String? _overrideAuthToken;

  ApiService({String? baseUrl, String? authToken})
      : _overrideBaseUrl = baseUrl,
        _overrideAuthToken = authToken;

  String? get _baseUrl {
    if (_overrideBaseUrl != null) return _overrideBaseUrl;
    try {
      final envUrl = dotenv.env['API_BASE_URL'];
      if (envUrl != null && envUrl.isNotEmpty) return envUrl;
    } catch (_) {}
    // Fallback: Using ngrok tunnel or local Android emulator
    return 'http://10.0.2.2:8000';
  }

  String? get _authToken {
    if (_overrideAuthToken != null) return _overrideAuthToken;
    try {
      final envToken = dotenv.env['AUTH_TOKEN'];
      if (envToken != null && envToken.isNotEmpty) return envToken;
    } catch (_) {}
    // No default token - must be set in .env file
    return null;
  }

  // 🧪 البيانات الوهمية للحافلات
  Map<String, dynamic> _getMockBusData(String busId) {
    // بيانات وهمية للحافلات المتاحة
    final mockBuses = {
      '1': {
        'id': 1,
        'license_plate': 'أ ب ج 123',
        'bus_line': {
          'route_id': 1,
          'route_name': 'خط 1: الملك فهد - الرياض بارك',
          'description': 'خط رئيسي يربط الملك فهد بالرياض بارك',
        },
        'last_latitude': 35.4932407,
        'last_longitude': 36.0346846,
        'last_speed': 0.0,
      },
      '2': {
        'id': 2,
        'license_plate': 'ه و ز 456',
        'bus_line': {
          'route_id': 1,
          'route_name': 'خط 1: الملك فهد - الرياض بارك',
          'description': 'خط رئيسي يربط الملك فهد بالرياض بارك',
        },
        'last_latitude': 24.7136,
        'last_longitude': 46.6753,
        'last_speed': 0.0,
      },
      '3': {
        'id': 3,
        'license_plate': 'ح ط ي 789',
        'bus_line': {
          'route_id': 2,
          'route_name': 'خط 2: العليا - الملز',
          'description': 'خط ثانوي يربط العليا بالملز',
        },
        'last_latitude': 24.72,
        'last_longitude': 46.68,
        'last_speed': 0.0,
      },
      '5': {
        'id': 5,
        'license_plate': '123',
        'bus_line': {
          'route_id': 3,
          'route_name': 'بحوارة الحرف',
          'description': 'خط بحوارة',
        },
        'last_latitude': 35.4929681,
        'last_longitude': 36.0348623,
        'last_speed': 0.0,
      },
    };

    if (mockBuses.containsKey(busId)) {
      debugPrint('🧪 [MOCK] Returning mock data for bus $busId');
      return mockBuses[busId]!;
    } else {
      throw Exception(
        'رقم الحافلة $busId غير موجود. الأرقام المتاحة: 1, 2, 3, 5',
      );
    }
  }

  // Accept an optional client for easier testing (defaults to new http.Client())
  Future<Map<String, dynamic>> getBusData(
    String busId, {
    http.Client? client,
  }) async {
    // 🧪 إذا كان وضع البيانات الوهمية مفعّل
    if (useMockData) {
      debugPrint('🧪 [MOCK MODE] Using mock data for bus $busId');
      // تأخير قصير لمحاكاة طلب الشبكة
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockBusData(busId);
    }

    // ⚡ الكود الحقيقي للـ API
    if (_baseUrl == null || _authToken == null) {
      throw Exception(
        'API configuration (URL or Token) is missing in .env file',
      );
    }

    // Correct endpoint based on user-provided API documentation
    final url = Uri.parse('$_baseUrl/api/buses/$busId/');
    final headers = {
      'Authorization': 'Token $_authToken',
      'ngrok-skip-browser-warning': 'true',
    };
    debugPrint('ApiService.getBusData -> GET $url');
    debugPrint('ApiService.getBusData -> headers: $headers');

    final usedClient = client ?? http.Client();
    try {
      final response = await usedClient.get(url, headers: headers);

      final responseBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 200) {
        try {
          return jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (e) {
          // Log full body (or truncated) to help debugging when server returns HTML/error page
          final snippet = responseBody.length > 1000
              ? responseBody.substring(0, 1000)
              : responseBody;
          debugPrint(
            'ApiService.getBusData: Failed to parse JSON. Status: ${response.statusCode}. Body snippet:\n$snippet',
          );
          throw Exception(
            'Invalid JSON response from server: ${e.toString()}\nStatus: ${response.statusCode}\nBody starts with: ${responseBody.substring(0, min(200, responseBody.length))}',
          );
        }
      } else {
        // Provide more details in the error log
        debugPrint(
          'Error fetching bus data (status ${response.statusCode}): $responseBody',
        );
        throw Exception(
          'Failed to load bus data. Status code: ${response.statusCode}',
        );
      }
    } finally {
      if (client == null) usedClient.close();
    }
  }

  Future<void> updateLocation(
    String busId,
    double latitude,
    double longitude,
    double speed, {
    http.Client? client,
  }) async {
    // 🧪 إذا كان وضع البيانات الوهمية مفعّل
    if (useMockData) {
      debugPrint(
        '🧪 [MOCK MODE] Simulating location update for bus $busId: ($latitude, $longitude, ${speed}km/h)',
      );
      // لا نفعل شيء في وضع المحاكاة
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

    // ⚡ الكود الحقيقي للـ API
    if (_baseUrl == null || _authToken == null) {
      throw Exception(
        'API configuration (URL or Token) is missing in .env file',
      );
    }

    // Correct endpoint based on user-provided API documentation
    final url = Uri.parse('$_baseUrl/api/buses/$busId/update-location/');
    final headers = {
      'Authorization': 'Token $_authToken',
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
    final body = jsonEncode({
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'speed': speed.toString(),
    });

    final usedClient = client ?? http.Client();
    try {
      final response = await usedClient.post(url, headers: headers, body: body);

      // A successful POST might return 200 (OK) or 204 (No Content)
      if (response.statusCode != 200 && response.statusCode != 204) {
        // Provide more details in the error log
        debugPrint('Error updating location: ${response.body}');
        throw Exception(
          'Failed to update location. Status code: ${response.statusCode}',
        );
      }
    } finally {
      if (client == null) usedClient.close();
    }
  }
}
