import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/bus.dart';
import '../models/bus_line.dart';
import '../models/bus_stop.dart';
import '../models/upcoming_stop.dart';
import '../config/app_config.dart';
import 'mock_data_provider.dart';

class TrackingService {
  // ميزاتك الحالية تبقى كما هي
  final bool _useMockData = AppConfig.useMockData;

  // --- WebSocket Connection ---
  WebSocketChannel? _channel;
  StreamSubscription? _webSocketSubscription;
  bool _isWebSocketConnected = false;

  // --- 1. إضافة ذاكرة تخزين مؤقت (Cache) لكل نوع من البيانات ---
  final List<Bus> _buses = [];
  final List<BusStop> _busStops = [];
  final List<BusLine> _busLines = [];

  // Simple content signatures to avoid emitting identical data repeatedly
  int _busesSig = 0;
  int _busStopsSig = 0;
  int _busLinesSig = 0;

  // Bus stop proximity notification
  final StreamController<Map<String, dynamic>> _busStopProximityController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get busStopProximityStream =>
      _busStopProximityController.stream;

  // Track which buses have been notified for which stops (to avoid spam)
  final Map<String, Set<String>> _notifiedBusStops =
      {}; // busId -> Set of stopIds

  // Movement-based throttling for bus updates
  final Map<String, LatLng> _lastBusPositions = <String, LatLng>{};
  DateTime _lastBusEmit = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _busEmitCooldown = Duration(milliseconds: 900);
  static const Duration _busEmitMaxInterval = Duration(seconds: 5);
  static const double _busMovementThresholdMeters =
      30.0; // ~1–2 frames/sec + significant move

  // --- 2. إضافة Getters للوصول الفوري للبيانات المخزنة ---
  //    هذا يسمح لأي شاشة بسؤال الخدمة عن آخر بيانات لديها.
  List<Bus> get buses => _buses;
  List<BusStop> get busStops => _busStops;
  List<BusLine> get busLines => _busLines;

  // Controllers and Streams (تبقى كما هي للتحديثات الحية)
  final StreamController<List<Bus>> _busController =
      StreamController.broadcast();
  final StreamController<List<BusStop>> _busStopsController =
      StreamController.broadcast();
  final StreamController<List<BusLine>> _busLinesController =
      StreamController.broadcast();

  Stream<List<Bus>> get busStream => _busController.stream;
  Stream<List<BusStop>> get busStopsStream => _busStopsController.stream;
  Stream<List<BusLine>> get busLinesStream => _busLinesController.stream;

  final String _apiUrl = AppConfig.baseUrl;

  // --- WebSocket Configuration ---
  // لا نحتاج متغير منفصل لـ WebSocket URL لأننا نستخدمه مباشرة من AppConfig

  /// الاتصال بـ Secure WebSocket (wss://) للحصول على تحديثات مباشرة لمواقع الحافلات
  ///
  /// الاتصال: User app ↔ Server عبر WebSocket الآمن (wss://)
  /// المصادقة: Token-based authentication
  ///
  /// عند الاتصال بـ wss://:
  /// 1. تأكد من وجود شهادة SSL صحيحة على الخادم
  /// 2. في Debug mode: قد يتطلب تخطي التحقق من الشهادة (للـ self-signed certs)
  /// 3. في Release: يجب استخدام شهادة SSL صحيحة من جهة موثوقة
  void connectToWebSocket() {
    if (_isWebSocketConnected) {
      debugPrint('[WebSocket] Already connected');
      return;
    }

    try {
      final wsUrl = AppConfig.websocketUrl;
      debugPrint('[WebSocket] Connecting to $wsUrl');

      // بناء اتصال WebSocket آمن (wss://)
      final uri = Uri.parse(wsUrl);
      _channel = WebSocketChannel.connect(uri);
      _isWebSocketConnected = true;

      _webSocketSubscription = _channel!.stream.listen(
        (message) {
          debugPrint('[WebSocket] Raw message received: $message');
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          debugPrint('[WebSocket] Error: $error');
          _isWebSocketConnected = false;
          _reconnectWebSocket();
        },
        onDone: () {
          debugPrint('[WebSocket] Connection closed');
          _isWebSocketConnected = false;
          _reconnectWebSocket();
        },
      );

      debugPrint('[WebSocket] Connected successfully to wss://');
    } catch (e) {
      debugPrint('[WebSocket] Connection failed: $e');
      _isWebSocketConnected = false;
      _reconnectWebSocket();
    }
  }

  /// معالجة الرسائل الواردة من WebSocket
  void _handleWebSocketMessage(dynamic message) {
    try {
      final decoded = json.decode(message);
      debugPrint('[WebSocket] Received: $decoded');

      // Backend sends {type: 'bus_location_update', data: {bus_id, latitude, longitude, ...}}
      // Extract the actual data from the nested structure
      final messageType = decoded['type'];
      final data = decoded['data'] ?? decoded; // Support both formats

      if (messageType == 'bus_location_update' || data['bus_id'] != null) {
        // تحديث موقع الحافلة في القائمة
        final busId = data['bus_id']?.toString();
        final latitude = data['latitude'];
        final longitude = data['longitude'];

        debugPrint(
          '[WebSocket] Processing update: busId=$busId, lat=$latitude, lon=$longitude',
        );
        debugPrint(
          '[WebSocket] Current buses in cache: ${_buses.length}, IDs: ${_buses.map((b) => b.id).join(", ")}',
        );

        if (busId != null && latitude != null && longitude != null) {
          final busIndex = _buses.indexWhere((bus) => bus.id == busId);
          if (busIndex != -1) {
            // تحديث موقع الحافلة الموجودة
            final newPosition = LatLng(
              (latitude as num).toDouble(),
              (longitude as num).toDouble(),
            );
            _buses[busIndex] = _buses[busIndex].copyWith(position: newPosition);

            // Force immediate emission for WebSocket updates (bypass throttling)
            _updateLastBusPositions(_buses);
            _lastBusEmit = DateTime.now();
            _busesSig = _hashList<Bus>(
              _buses,
              (b) => _hashValues([
                b.id.hashCode,
                (b.position.latitude * 10000).round(),
                (b.position.longitude * 10000).round(),
                b.lineId.hashCode,
                b.status.index,
              ]),
            );
            _busController.add(List<Bus>.unmodifiable(_buses));

            debugPrint(
              '[WebSocket] Updated bus $busId to ${newPosition.latitude}, ${newPosition.longitude}',
            );

            // Check if bus is near any stops
            _checkBusStopProximity(busId, newPosition);
          } else {
            debugPrint('[WebSocket] Bus $busId not found in cache');
          }
        }
      }
    } catch (e) {
      debugPrint('[WebSocket] Error parsing message: $e');
    }
  }

  /// Check if bus is near any stops and notify
  void _checkBusStopProximity(String busId, LatLng busPosition) {
    const double proximityThreshold = 15.0; // 15 meters

    // Initialize notification tracking for this bus if not exists
    _notifiedBusStops.putIfAbsent(busId, () => <String>{});

    // Check each stop
    for (final stop in _busStops) {
      final distance = Geolocator.distanceBetween(
        busPosition.latitude,
        busPosition.longitude,
        stop.position.latitude,
        stop.position.longitude,
      );

      if (distance <= proximityThreshold) {
        // Bus is near this stop
        if (!_notifiedBusStops[busId]!.contains(stop.id)) {
          // Haven't notified for this stop yet
          _notifiedBusStops[busId]!.add(stop.id);

          // Emit notification event
          _busStopProximityController.add({
            'busId': busId,
            'stopId': stop.id,
            'stopName': stop.name,
            'distance': distance,
            'message': 'الحافلة على المحطة: ${stop.name}',
          });

          debugPrint(
            '[Proximity] Bus $busId is at stop ${stop.name} (${distance.toStringAsFixed(1)}m)',
          );
        }
      } else {
        // Bus moved away from this stop, allow re-notification
        _notifiedBusStops[busId]?.remove(stop.id);
      }
    }
  }

  /// إعادة الاتصال بـ WebSocket بعد فترة انتظار
  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!_isWebSocketConnected) {
        debugPrint('[WebSocket] Attempting to reconnect...');
        connectToWebSocket();
      }
    });
  }

  /// قطع الاتصال بـ WebSocket
  void disconnectWebSocket() {
    debugPrint('[WebSocket] Disconnecting...');
    _webSocketSubscription?.cancel();
    _channel?.sink.close();
    _isWebSocketConnected = false;
  }

  // الدالة الرئيسية الذكية (تبقى كما هي)
  Future<void> fetchInitialData() async {
    if (_useMockData) {
      debugPrint('[log] Using Mock Data mode. Loading all fake data...');
      await _loadMockData();
    } else {
      debugPrint(
        '[log] Using Real Data mode. Fetching all data from server...',
      );
      await _loadRealDataFromServer();
      // الاتصال بـ WebSocket للحصول على تحديثات مباشرة
      connectToWebSocket();
    }
  }

  // دالة البيانات الوهمية (تم تحديثها لتعبئة الذاكرة)
  Future<void> _loadMockData() async {
    await Future.delayed(const Duration(seconds: 1));

    // --- 3. تخزين البيانات في الذاكرة المؤقتة (Cache) ---
    _busStops.clear(); // مسح البيانات القديمة قبل إضافة الجديدة
    _busStops.addAll(MockDataProvider.getMockStops());

    _buses.clear();
    _buses.addAll(MockDataProvider.getMockBuses());

    _busLines.clear();
    _busLines.addAll(MockDataProvider.getMockBusLines());

    // --- 4. بث البيانات عبر الـ Streams كما كان ---
    _emitBusStopsIfChanged();
    _emitBusesIfChanged();
    _emitBusLinesIfChanged();

    debugPrint('[log] Mock data cached and broadcasted successfully.');
  }

  // دالة البيانات الحقيقية (تم تحديثها لتعبئة الذاكرة)
  // استخدام endpoint واحد بدلاً من 3 طلبات منفصلة (تحسين لـ ngrok rate limits)
  Future<void> _loadRealDataFromServer() async {
    try {
      // إعداد Headers مع Token للمصادقة
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Token ${AppConfig.authToken}',
        'ngrok-skip-browser-warning': 'true', // تجاوز صفحة تحذير ngrok
        'User-Agent': 'BusTrackingApp/1.0',
      };

      // استخدام endpoint واحد يرجع كل البيانات (bus_stops, buses, bus_lines)
      // هذا يقلل عدد الطلبات من 3 إلى 1 فقط!
      final response = await http.get(
        Uri.parse('$_apiUrl/api/initial-data/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // معالجة bus_stops
        if (data['bus_stops'] != null) {
          final List<dynamic> stopsJson = data['bus_stops'];
          final List<BusStop> stops = stopsJson
              .map((json) => BusStop.fromJson(json))
              .toList();
          _busStops.clear();
          _busStops.addAll(stops);
          _emitBusStopsIfChanged();
          debugPrint('[API] Loaded ${stops.length} bus stops');
        }

        // معالجة buses
        if (data['buses'] != null) {
          final List<dynamic> busesJson = data['buses'];
          final List<Bus> buses = busesJson
              .map((json) => Bus.fromJson(json))
              .toList();
          _buses.clear();
          _buses.addAll(buses);
          _emitBusesIfChanged();
          debugPrint('[API] Loaded ${buses.length} buses');
        }

        // معالجة bus_lines
        if (data['bus_lines'] != null) {
          final List<dynamic> linesJson = data['bus_lines'];
          final List<BusLine> lines = linesJson
              .map((json) => BusLine.fromJson(json))
              .toList();
          _busLines.clear();
          _busLines.addAll(lines);
          _emitBusLinesIfChanged();
          debugPrint('[API] Loaded ${lines.length} bus lines');
        }

        debugPrint('[API] ✅ Successfully loaded all data in ONE request!');
      } else {
        throw Exception('Failed to load initial data: ${response.statusCode}');
      }

      debugPrint(
        '[API] ✅ Successfully loaded data from server with authentication',
      );
    } catch (e) {
      debugPrint('[API] ❌ Error loading data: $e');

      // Don't add error to streams - just log it
      // This prevents constant error popups for users
      // The UI will show cached data or loading state instead

      // Only add error if this is a critical failure (e.g., no internet)
      if (e.toString().contains('Failed to host lookup') ||
          e.toString().contains('SocketException')) {
        _busStopsController.addError('No internet connection');
        _busController.addError('No internet connection');
        _busLinesController.addError('No internet connection');
      }
    }
  }

  // دالة dispose (تبقى كما هي)
  void dispose() {
    disconnectWebSocket();
    _busController.close();
    _busStopsController.close();
    _busLinesController.close();
    _busStopProximityController.close();
    debugPrint('[log] TrackingService disposed and all streams closed.');
  }

  // --- Helpers: emit only when content changed (cheap signatures) ---
  void _emitBusesIfChanged() {
    // Higher precision to detect smaller movements (~11m per 1e-4 deg latitude)
    final sig = _hashList<Bus>(
      _buses,
      (b) => _hashValues([
        b.id.hashCode,
        (b.position.latitude * 10000).round(),
        (b.position.longitude * 10000).round(),
        b.lineId.hashCode,
        b.status.index,
      ]),
    );

    final now = DateTime.now();
    final cooldownOk = now.difference(_lastBusEmit) >= _busEmitCooldown;
    final maxMove = _computeMaxFleetMovementMeters(_buses);
    final movedSignificantly = maxMove >= _busMovementThresholdMeters;
    final maxIntervalElapsed =
        now.difference(_lastBusEmit) >= _busEmitMaxInterval;

    // Only emit if content changed and either we moved enough, cooldown passed, or a safety interval elapsed
    if (sig != _busesSig &&
        cooldownOk &&
        (movedSignificantly || maxIntervalElapsed)) {
      _busesSig = sig;
      _lastBusEmit = now;
      _updateLastBusPositions(_buses);
      _busController.add(List<Bus>.unmodifiable(_buses));
    }
  }

  void _emitBusStopsIfChanged() {
    final sig = _hashList<BusStop>(
      _busStops,
      (s) => _hashValues([
        s.id.hashCode,
        (s.latitude * 10000).round(),
        (s.longitude * 10000).round(),
        s.name.hashCode,
      ]),
    );
    if (sig != _busStopsSig) {
      _busStopsSig = sig;
      _busStopsController.add(List<BusStop>.unmodifiable(_busStops));
    }
  }

  void _emitBusLinesIfChanged() {
    final sig = _hashList<BusLine>(
      _busLines,
      (l) =>
          _hashValues([l.id.hashCode, l.name.hashCode, l.description.hashCode]),
    );
    if (sig != _busLinesSig) {
      _busLinesSig = sig;
      _busLinesController.add(List<BusLine>.unmodifiable(_busLines));
    }
  }

  int _hashList<T>(List<T> items, int Function(T) itemHash) {
    var hash = items.length;
    for (final item in items) {
      hash = _combine(hash, itemHash(item));
    }
    return _finish(hash);
  }

  int _hashValues(List<Object?> values) {
    var hash = 0;
    for (final v in values) {
      hash = _combine(hash, v?.hashCode ?? 0);
    }
    return _finish(hash);
  }

  int _combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  int _finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }

  // --- Movement helpers ---
  double _computeMaxFleetMovementMeters(List<Bus> buses) {
    double maxMeters = 0.0;
    for (final b in buses) {
      final prev = _lastBusPositions[b.id];
      if (prev == null) {
        // First time seeing this bus; treat as moved to allow initial emission
        maxMeters = _busMovementThresholdMeters;
        continue;
      }
      final meters = _distanceMetersApprox(prev, b.position);
      if (meters > maxMeters) maxMeters = meters;
    }
    return maxMeters;
  }

  void _updateLastBusPositions(List<Bus> buses) {
    for (final b in buses) {
      _lastBusPositions[b.id] = b.position;
    }
  }

  // Haversine approximation to avoid extra deps in service layer
  double _distanceMetersApprox(LatLng a, LatLng b) {
    const double R = 6371000.0; // meters
    final double dLat = _deg2rad(b.latitude - a.latitude);
    final double dLon = _deg2rad(b.longitude - a.longitude);
    final double lat1 = _deg2rad(a.latitude);
    final double lat2 = _deg2rad(b.latitude);
    final double s =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.sin(dLon / 2) * math.sin(dLon / 2)) *
            math.cos(lat1) *
            math.cos(lat2);
    final double c = 2 * math.atan2(math.sqrt(s), math.sqrt(1 - s));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (3.141592653589793 / 180.0);

  /// Calculate upcoming stops for a specific bus using backend API
  /// Returns list of upcoming stops with accurate ETA from backend
  Future<BusStopInfo?> getUpcomingStops(String busId) async {
    try {
      // Find the bus
      final busIndex = _buses.indexWhere((b) => b.id == busId);
      if (busIndex == -1) {
        debugPrint('[UpcomingStops] Bus $busId not found');
        return null;
      }
      final bus = _buses[busIndex];

      // Find the bus line
      final lineIndex = _busLines.indexWhere((line) => line.id == bus.lineId);
      if (lineIndex == -1) {
        debugPrint('[UpcomingStops] Bus line ${bus.lineId} not found');
        return null;
      }
      final busLine = _busLines[lineIndex];

      // Call backend API to get stops with accurate ETA
  // NOTE: backend registers BusLineViewSet under 'bus-lines' prefix
  final url = '${AppConfig.baseUrl}/api/bus-lines/${bus.lineId}/stops-with-eta/?bus_id=$busId';
      
      debugPrint('[UpcomingStops] Fetching ETA from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token ${AppConfig.authToken}',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('[UpcomingStops] API error: ${response.statusCode}');
        return _fallbackLocalCalculation(bus, busLine);
      }

      final data = json.decode(response.body);
      final stopsData = data['stops'] as List;
      
      debugPrint('[UpcomingStops] Received ${stopsData.length} stops from API');

      final List<UpcomingStop> allStops = [];

      for (int i = 0; i < stopsData.length; i++) {
        final stopData = stopsData[i];
        final stopId = stopData['stop_id'].toString();
        final stopName = stopData['stop_name'] as String;
        final etaSeconds = stopData['eta_seconds'];
        final isPassed = stopData['passed'] ?? false;
        
        // Find the stop in our local data
        final stop = _busStops.firstWhere(
          (s) => s.id == stopId,
          orElse: () => busLine.stops.firstWhere(
            (s) => s.id == stopId,
            orElse: () => BusStop(
              id: stopId,
              name: stopName,
              latitude: 0,
              longitude: 0, // Fallback position
            ),
          ),
        );

        // Get road distance from backend (if provided), otherwise calculate straight-line
        final double distance;
        if (stopData['distance_meters'] != null) {
          // Use accurate road distance from backend
          distance = (stopData['distance_meters'] as num).toDouble();
        } else {
          // Fallback to straight-line distance
          distance = Geolocator.distanceBetween(
            bus.position.latitude,
            bus.position.longitude,
            stop.position.latitude,
            stop.position.longitude,
          );
        }

        // Use backend ETA or null if passed/hidden
        final int? estimatedMinutes = etaSeconds != null 
          ? (etaSeconds / 60).ceil() 
          : null;

        // Check if bus is at this stop
        final bool atStop = stopData['at_stop'] == true;

        // Only add stops that have ETA (not passed or hidden by backend)
        if (etaSeconds != null) {
          allStops.add(
            UpcomingStop(
              stop: stop,
              estimatedTimeMinutes: estimatedMinutes ?? 0,
              distanceMeters: distance,
              stopIndex: i,
              isPassed: isPassed,
              atStop: atStop,
            ),
          );
        }
      }

      // Separate into passed and upcoming
      final passedStops = allStops.where((s) => s.isPassed).toList();
      final upcomingStops = allStops.where((s) => !s.isPassed).toList();

      // Sort upcoming by ETA (soonest first)
      upcomingStops.sort(
        (a, b) => a.estimatedTimeMinutes.compareTo(b.estimatedTimeMinutes),
      );

      debugPrint(
        '[UpcomingStops] Found ${upcomingStops.length} upcoming stops, ${passedStops.length} passed',
      );

      return BusStopInfo(
        busId: bus.id,
        busLicensePlate: bus.licensePlate,
        lineName: busLine.name,
        upcomingStops: upcomingStops,
        passedStops: passedStops,
      );
    } catch (e) {
      debugPrint('[UpcomingStops] Error: $e');
      // Fallback to local calculation if API fails
      final busIndex = _buses.indexWhere((b) => b.id == busId);
      if (busIndex != -1) {
        final bus = _buses[busIndex];
        final lineIndex = _busLines.indexWhere((line) => line.id == bus.lineId);
        if (lineIndex != -1) {
          return _fallbackLocalCalculation(bus, _busLines[lineIndex]);
        }
      }
      return null;
    }
  }

  /// Fallback to local ETA calculation if backend API fails
  BusStopInfo _fallbackLocalCalculation(Bus bus, BusLine busLine) {
    final stopsToUse = busLine.stops.isEmpty ? _busStops : busLine.stops;
    final List<UpcomingStop> allStops = [];

    for (int i = 0; i < stopsToUse.length; i++) {
      final stop = stopsToUse[i];
      final distance = Geolocator.distanceBetween(
        bus.position.latitude,
        bus.position.longitude,
        stop.position.latitude,
        stop.position.longitude,
      );

      bool isPassed = false;
      if (i < stopsToUse.length - 1) {
        final nextStop = stopsToUse[i + 1];
        final distanceToNext = Geolocator.distanceBetween(
          bus.position.latitude,
          bus.position.longitude,
          nextStop.position.latitude,
          nextStop.position.longitude,
        );
        if (distance > 50 && distanceToNext < distance) {
          isPassed = true;
        }
      }

      const double avgSpeedMps = 5.56;
      final int estimatedMinutes = (distance / avgSpeedMps / 60).ceil();

      allStops.add(
        UpcomingStop(
          stop: stop,
          estimatedTimeMinutes: estimatedMinutes,
          distanceMeters: distance,
          stopIndex: i,
          isPassed: isPassed,
        ),
      );
    }

    final passedStops = allStops.where((s) => s.isPassed).toList();
    final upcomingStops = allStops.where((s) => !s.isPassed).toList();
    upcomingStops.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

    return BusStopInfo(
      busId: bus.id,
      busLicensePlate: bus.licensePlate,
      lineName: busLine.name,
      upcomingStops: upcomingStops,
      passedStops: passedStops,
    );
  }
}
