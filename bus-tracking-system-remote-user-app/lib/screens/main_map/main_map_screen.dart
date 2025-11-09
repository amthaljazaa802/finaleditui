import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../routes/routes_screen.dart';
import '../complaints/complaints_screen.dart';
import '../payment_screen.dart';
import '../../models/bus.dart';
import '../../models/bus_stop.dart';
import '../../models/bus_line.dart';
import '../../models/upcoming_stop.dart';
import '../../repositories/transport_repository.dart';
import '../../theme/app_theme.dart';
import 'widgets/bus_stop_popup.dart';
import 'widgets/upcoming_stops_widget.dart';
import 'widgets/search_bottom_sheet.dart';
import '../../config/app_config.dart';

class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

enum MapStatus { loading, success, failure }

// ❌ تم حذف MapFilter enum (لم يعد مستخدماً)

class _MainMapScreenState extends State<MainMapScreen> {
  // --- Controller جديد للنوافذ المنبثقة ---
  final PopupController _popupLayerController = PopupController();

  // --- كل المتغيرات الأخرى تبقى كما هي ---
  final MapController _mapController = MapController();
  late final TransportRepository _repository;
  List<BusStop> _busStops = [];
  List<Bus> _buses = [];
  // Cached marker lists to reduce per-build allocations
  List<Marker> _cachedStopMarkers = const [];
  List<Marker> _cachedBusMarkers = const [];
  MapStatus _status = MapStatus.loading;
  String _errorMessage = '';
  StreamSubscription? _stopsSubscription;
  StreamSubscription? _busesSubscription;
  StreamSubscription? _proximitySubscription;
  Timer? _updateTimer;
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  // ❌ تم حذف _lastDataUpdate (لم يعد مستخدم بعد حذف تبويب آخر تحديث)
  // ❌ تم حذف متغيرات الفلاتر (_filter, _nearbyCenter, _nearbyRadiusMeters)
  Bus? _nearestBus;
  String? _estimatedTime;
  String? _nearestBusLineName;
  Bus? _selectedBus;
  BusStopInfo? _selectedBusStopInfo;
  bool _showUpcomingStops = false;
  bool _filterBySelectedBus = false; // فلترة المواقف حسب الباص المختار

  // User location tracking
  Position? _userPosition;
  double? _userHeading; // Direction in degrees (0-360)
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _showUserLocation = true;
  bool _followUserLocation = false;

  @override
  void initState() {
    super.initState();
    _repository = Provider.of<TransportRepository>(context, listen: false);

    // Precache marker image for smoother first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('lib/assets/images/thumbnail.png'),
        context,
      );
    });

    _stopsSubscription = _repository.busStopsStream.listen(
      (stops) {
        if (mounted) setState(() => _busStops = stops);
        _rebuildStopMarkers();
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'فشل في جلب بيانات المواقف';
            _status = MapStatus.failure;
          });
        }
      },
    );

    _busesSubscription = _repository.busStream.listen(
      (buses) {
        if (mounted) {
          setState(() {
            _buses = buses;
            _status = MapStatus.success;
            // ❌ تم حذف _lastDataUpdate (لم يعد مستخدم)
            _rebuildBusMarkers(); // Rebuild markers inside setState so UI updates
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'فشل في جلب بيانات الحافلات';
            _status = MapStatus.failure;
          });
        }
      },
    );

    // Listen for bus stop proximity notifications
    _proximitySubscription = _repository.busStopProximityStream.listen((event) {
      if (mounted) {
        final message = event['message'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    _repository.fetchInitialData();

    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final now = DateTime.now();
      // تحديث كل نصف ثانية للحصول على حركة سلسة
      if (now.difference(_lastUiUpdate).inMilliseconds < 400) return;
      _lastUiUpdate = now;
      _updateNearestBusInfo();
    });

    // 🎯 تمركز على موقع المستخدم بعد تحميل البيانات (بتأخير 2 ثانية)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _status == MapStatus.success) {
        _centerOnUserLocation();
      }
    });

    // Start tracking user location
    _startLocationTracking();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _stopsSubscription?.cancel();
    _busesSubscription?.cancel();
    _proximitySubscription?.cancel();
    _updateTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(33.5138, 36.2765),
              initialZoom: 14.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (tapPosition, point) {
                debugPrint(
                  '[MapTap] Map tapped at: ${point.latitude}, ${point.longitude}',
                );

                // Check if tap is near any bus
                Bus? tappedBus;
                for (final bus in _buses) {
                  final distance = const Distance().distance(
                    LatLng(bus.position.latitude, bus.position.longitude),
                    point,
                  );
                  debugPrint(
                    '[MapTap] Distance to bus ${bus.id}: ${distance.toStringAsFixed(2)}m',
                  );
                  // If tap is within 50 meters of bus position, consider it a tap on that bus
                  if (distance < 50) {
                    tappedBus = bus;
                    break;
                  }
                }

                if (tappedBus != null) {
                  // Bus was tapped
                  debugPrint('[MapTap] Bus ${tappedBus.id} detected!');
                  _onBusMarkerTapped(tappedBus);
                } else {
                  // Empty map area tapped
                  _popupLayerController.hideAllPopups();
                  // Clear any selection state
                  if (_nearestBus != null ||
                      _estimatedTime != null ||
                      _nearestBusLineName != null ||
                      _selectedBus != null) {
                    setState(() {
                      _nearestBus = null;
                      _estimatedTime = null;
                      _nearestBusLineName = null;
                      _selectedBus = null;
                      _selectedBusStopInfo = null;
                      _showUpcomingStops = false;
                    });
                  }
                }
              },
            ),
            children: [
              TileLayer(
                // 🗺️ CartoDB Positron - خريطة فاتحة ونظيفة
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.bus_tracking_app',
              ),
              // User location circle (accuracy circle)
              if (_userPosition != null && _showUserLocation)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: LatLng(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                      ),
                      radius: _userPosition!.accuracy,
                      useRadiusInMeter: true,
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderColor: Colors.blue.withValues(alpha: 0.3),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
              // طبقة الحافلات بدون تجميع للسماح بالنقر
              MarkerLayer(markers: _cachedBusMarkers),
              // User location marker (Apple Maps style with direction arrow)
              if (_userPosition != null && _showUserLocation)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(
                        _userPosition!.latitude,
                        _userPosition!.longitude,
                      ),
                      width: 50,
                      height: 50,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer pulsing ring (light blue)
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.2),
                            ),
                          ),
                          // Middle ring (slightly darker blue)
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          // White border ring
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          // Inner solid blue dot
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF007AFF), // iOS blue
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          // Direction arrow (only shown when heading is available)
                          if (_userHeading != null)
                            Transform.rotate(
                              angle:
                                  _userHeading! *
                                  (3.14159265359 /
                                      180), // Convert degrees to radians
                              child: Icon(
                                Icons.navigation,
                                color: const Color(0xFF007AFF),
                                size: 30,
                                shadows: [
                                  Shadow(color: Colors.white, blurRadius: 3),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              // الكود الجديد الصحيح
              RepaintBoundary(
                child: PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    popupController: _popupLayerController,
                    // أظهر النوافذ المنبثقة لمواقف الحافلات فقط
                    markers: _cachedStopMarkers,
                    // --- بداية الإصلاح ---
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (BuildContext context, Marker marker) {
                        // كل منطق بناء النافذة المنبثقة يأتي هنا
                        if (marker.key is ValueKey<String>) {
                          final keyString =
                              (marker.key as ValueKey<String>).value;
                          if (keyString.startsWith('stop_')) {
                            final stopId = keyString.substring(5);
                            final stop = _busStops.firstWhere(
                              (s) => s.id == stopId,
                            );
                            return BusStopPopup(
                              stop: stop,
                              allBuses: _buses,
                              allBusLines: _repository.busLines,
                              popupController: _popupLayerController,
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // --- نهاية الإصلاح ---
                  ),
                ),
              ),
            ],
          ),
          if (_status == MapStatus.loading)
            Container(
              color: AppColors.background.withValues(alpha: 0.95),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('جارٍ التحديث…', style: AppTextStyles.bodyLarge),
                  ],
                ),
              ),
            ),
          if (_status == MapStatus.failure)
            Container(
              color: AppColors.background.withValues(alpha: 0.95),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      Text('حدث خطأ', style: AppTextStyles.heading2),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () {
                          setState(() => _status = MapStatus.loading);
                          _repository.fetchInitialData();
                        },
                        label: Text(
                          'حاول مرة أخرى',
                          style: AppTextStyles.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppBorders.medium,
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_status == MapStatus.success) ...[
            _buildFloatingSearchBar(), // ✅ إرجاع شريط البحث
            _buildLeftSideButtons(),
            _buildFloatingActionButtons(),
            _buildBottomInfoSheet(),
            if (_showUpcomingStops) _buildUpcomingStopsSheet(),
          ],
        ],
      ),
    );
  }

  List<Marker> _buildStopMarkers() {
    // ✅ عرض المحطات مع الفلترة حسب الباص المختار
    List<BusStop> stopsToShow = _busStops;

    // تطبيق الفلتر إذا كان مفعلاً وهناك باص محدد
    if (_filterBySelectedBus && _selectedBus != null) {
      final selectedStopIds = <String>{};

      // الحصول على معلومات الخط للباص المختار
      final selectedBusLine = _repository.busLines.firstWhere(
        (line) => line.id == _selectedBus!.lineId,
        orElse: () =>
            BusLine(id: '', name: '', description: '', stops: [], path: []),
      );

      if (selectedBusLine.stops.isNotEmpty) {
        selectedStopIds.addAll(selectedBusLine.stops.map((stop) => stop.id));
      } else if (_selectedBusStopInfo != null) {
        // استخدام قائمة المواقف القادمة كبديل عندما لا يوفر الخط قائمة محطات كاملة
        selectedStopIds.addAll(
          _selectedBusStopInfo!.upcomingStops.map(
            (upcoming) => upcoming.stop.id,
          ),
        );
      }

      if (selectedStopIds.isNotEmpty) {
        stopsToShow = _busStops
            .where((stop) => selectedStopIds.contains(stop.id))
            .toList();
      }
    }

    return stopsToShow.map((stop) {
      return Marker(
        key: ValueKey('stop_${stop.id}'),
        width: 120.0, // زيادة العرض لاستيعاب النص
        height: 70.0, // زيادة الارتفاع للنص والأيقونة
        point: stop.position,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // اسم الموقف
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                stop.name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // أيقونة الموقف
            SizedBox(
              width: 40,
              height: 40,
              child: Image.asset('lib/assets/images/thumbnail.png'),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Marker> _buildBusMarkers() {
    // ✅ عرض جميع الباصات مع أسماء الخطوط
    return _buses.map((bus) {
      final isSelected = _selectedBus?.id == bus.id;

      // الحصول على اسم الخط
      final busLine = _repository.busLines.firstWhere(
        (line) => line.id == bus.lineId,
        orElse: () => BusLine(
          id: bus.lineId,
          name: 'خط ${bus.lineId}',
          description: '',
          stops: [],
          path: [],
        ),
      );

      return Marker(
        key: ValueKey('bus_${bus.id}'),
        width: 120.0, // نفس عرض المواقف
        height: 75.0, // ارتفاع يستوعب النص والأيقونة
        point: bus.position,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // اسم الخط
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                busLine.name,
                style: const TextStyle(
                  fontSize: 11, // نفس حجم خط المواقف
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1a1a1a),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            // أيقونة الباص
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint('[BusTap] Raw tap detected on bus ${bus.id}');
                  _onBusMarkerTapped(bus);
                },
                child: Container(
                  width: isSelected ? 50.0 : 45.0,
                  height: isSelected ? 50.0 : 45.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: isSelected
                        ? Border.all(color: AppColors.primary, width: 3)
                        : Border.all(color: AppColors.divider, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: _getBusColor(bus.status),
                    size: isSelected ? 28 : 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _onBusMarkerTapped(Bus bus) {
    debugPrint('[BusTap] Bus ${bus.id} tapped');
    setState(() {
      if (_selectedBus?.id == bus.id) {
        // Toggle off if clicking same bus
        debugPrint('[BusTap] Deselecting bus ${bus.id}');
        _selectedBus = null;
        _selectedBusStopInfo = null;
        _showUpcomingStops = false;
        _filterBySelectedBus = false;
        _rebuildStopMarkers();
      } else {
        // Select new bus and get its upcoming stops
        debugPrint('[BusTap] Selecting bus ${bus.id}, lineId: ${bus.lineId}');
        _selectedBus = bus;
        _showUpcomingStops = true;

        // Fetch upcoming stops asynchronously from backend
        _repository
            .getUpcomingStops(bus.id)
            .then((stopInfo) {
              setState(() {
                _selectedBusStopInfo = stopInfo;
                if (_selectedBusStopInfo != null) {
                  debugPrint(
                    '[BusTap] Got ${_selectedBusStopInfo!.upcomingStops.length} upcoming stops from backend',
                  );
                } else {
                  debugPrint('[BusTap] No stop info available');
                }
                _rebuildStopMarkers();
              });
            })
            .catchError((e) {
              debugPrint('[BusTap] Error getting upcoming stops: $e');
              setState(() {
                _selectedBusStopInfo = null;
                _rebuildStopMarkers();
              });
            });
      }
      _rebuildBusMarkers(); // Rebuild to show selection
    });
  }

  void _rebuildStopMarkers() {
    _cachedStopMarkers = _buildStopMarkers();
  }

  void _rebuildBusMarkers() {
    _cachedBusMarkers = _buildBusMarkers();
  }

  Future<void> _updateNearestBusInfo() async {
    if (_status != MapStatus.success || _buses.isEmpty) return;
    try {
      final userLocationData = await _determinePosition();
      final userLocation = LatLng(
        userLocationData.latitude,
        userLocationData.longitude,
      );
      final nearest = _findNearestBus(userLocation, _buses);
      if (nearest != null) {
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          nearest.position.latitude,
          nearest.position.longitude,
        );
        final lineName = _getLineNameById(nearest.lineId) ?? 'خط غير معروف';
        final newEta = _estimateArrivalTime(distance);
        final shouldUpdate =
            _nearestBus?.id != nearest.id ||
            _estimatedTime != newEta ||
            _nearestBusLineName != lineName;
        if (mounted && shouldUpdate) {
          setState(() {
            _nearestBus = nearest;
            _estimatedTime = newEta;
            _nearestBusLineName = lineName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating nearest bus info: $e');
      if (mounted) setState(() => _nearestBus = null);
    }
  }

  String? _getLineNameById(String lineId) {
    try {
      return _repository.busLines.firstWhere((line) => line.id == lineId).name;
    } catch (e) {
      return null;
    }
  }

  Bus? _findNearestBus(LatLng userLocation, List<Bus> buses) {
    if (buses.isEmpty) return null;
    Bus? nearestBus;
    double smallestD2 = double.infinity;
    for (final bus in buses) {
      final d2 = _distance2(userLocation, bus.position);
      if (d2 < smallestD2) {
        smallestD2 = d2;
        nearestBus = bus;
      }
    }
    return nearestBus;
  }

  // Fast approximate squared distance in degrees (good for nearest comparisons)
  double _distance2(LatLng a, LatLng b) {
    final dx = a.latitude - b.latitude;
    final dy = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }

  String _estimateArrivalTime(double distanceInMeters) {
    const averageBusSpeedKmh = 25.0;
    final speedMps = averageBusSpeedKmh * 1000 / 3600;
    if (distanceInMeters < 50) return 'قريب جدًا';
    final timeInSeconds = distanceInMeters / speedMps;
    final timeInMinutes = (timeInSeconds / 60).ceil();
    return ' ~ $timeInMinutes دقائق';
  }

  // ❌ تم حذف دوال الفلاتر بالكامل (_applyBusFilter, _applyStopFilter, _buildFilterChips, _chip)

  Future<void> _centerOnUserLocation() async {
    if (!mounted) return;

    // If we already have user position, use it
    if (_userPosition != null) {
      _mapController.move(
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
        15.0,
      );
      return;
    }

    // Otherwise, fetch position
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تحديد موقعك...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final position = await _determinePosition();
      if (mounted) {
        setState(() {
          _userPosition = position;
        });
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          15.0,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن تحديد الموقع: ${e.toString()}')),
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('خدمات تحديد الموقع معطلة.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('تم رفض صلاحيات الوصول للموقع.');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('تم رفض صلاحيات الموقع بشكل دائم.');
    return await Geolocator.getCurrentPosition();
  }

  void _startLocationTracking() async {
    try {
      // Get initial position
      final initialPosition = await _determinePosition();
      if (mounted) {
        setState(() {
          _userPosition = initialPosition;
          _userHeading = initialPosition.heading;
        });
      }

      // Start listening to position updates
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      );

      Position? previousPosition = initialPosition;

      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              if (mounted) {
                // Calculate heading from movement if GPS heading is not available or invalid
                double? heading = position.heading;
                if (heading < 0 && previousPosition != null) {
                  // Calculate heading from previous position
                  heading = Geolocator.bearingBetween(
                    previousPosition!.latitude,
                    previousPosition!.longitude,
                    position.latitude,
                    position.longitude,
                  );
                }

                setState(() {
                  _userPosition = position;
                  _userHeading = (heading != null && heading >= 0)
                      ? heading
                      : null;
                });

                previousPosition = position;

                // If follow mode is enabled, move map to user location
                if (_followUserLocation) {
                  _mapController.move(
                    LatLng(position.latitude, position.longitude),
                    _mapController.camera.zoom,
                  );
                }
              }
            },
            onError: (error) {
              debugPrint('Error tracking location: $error');
            },
          );
    } catch (e) {
      debugPrint('Failed to start location tracking: $e');
    }
  }

  Color _getBusColor(BusStatus status) {
    switch (status) {
      case BusStatus.IN_SERVICE:
        return Colors.lightBlue;
      case BusStatus.DELAYED:
        return Colors.orange;
      case BusStatus.NOT_IN_SERVICE:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
    String? label,
  }) {
    // 🎨 أزرار دائرية بخلفية بيضاء وأيقونة سوداء (نمط موحد)
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xCC000000),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: AppBorders.circular,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: backgroundColor ?? const Color(0xF2FFFFFF),
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: backgroundColor != null
                    ? Colors.white
                    : const Color(0xCC000000),
                size: 26,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 🎨 نمط الأزرار الموحد للخريطة (نسخة طبق الأصل من ما أرسلت)
  Widget buildMapButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          shape: BoxShape.circle,
          boxShadow: [
            const BoxShadow(
              color: Color(0x26000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xCC000000), size: 26),
      ),
    );
  }

  Widget _buildLeftSideButtons() {
    // All left side buttons removed (zoom, layers, schedule, filter)
    return const SizedBox.shrink();
  }

  // 🔍 شريط البحث العلوي - يمتد على كامل الشاشة
  Widget _buildFloatingSearchBar() {
    return Positioned(
      top: 50.0,
      left: 15.0,
      right: 15.0, // تغيير من 80 إلى 15 ليمتد على كامل الشاشة
      child: GestureDetector(
        onTap: _showSearchBottomSheet,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppBorders.large,
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ابحث عن محطة أو حافلة...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    // 🎨 الأزرار الجانبية - مرتبة حسب الأولوية مع تسميات واضحة
    return Positioned(
      top: 120.0,
      right: 15.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 📍 مجموعة الموقع والتنقل (أهم الأزرار)
          _buildCircularButton(
            icon: Icons.my_location,
            onPressed: _centerOnUserLocation,
            backgroundColor: null,
            label: 'موقعي',
          ),
          const SizedBox(height: 12),
          _buildCircularButton(
            icon: _followUserLocation
                ? Icons.navigation
                : Icons.navigation_outlined,
            onPressed: () {
              setState(() {
                _followUserLocation = !_followUserLocation;
                if (_followUserLocation && _userPosition != null) {
                  _mapController.move(
                    LatLng(_userPosition!.latitude, _userPosition!.longitude),
                    _mapController.camera.zoom,
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _followUserLocation
                        ? 'تم تفعيل وضع المتابعة'
                        : 'تم إيقاف وضع المتابعة',
                  ),
                  duration: const Duration(seconds: 2),
                  backgroundColor: _followUserLocation
                      ? Colors.green[700]
                      : Colors.grey[700],
                ),
              );
            },
            backgroundColor: null,
            label: _followUserLocation ? 'تتبع' : 'تتبع',
          ),

          const SizedBox(height: 20), // فاصل أكبر بين المجموعات
          // 🚍 مجموعة المعلومات والخدمات
          _buildCircularButton(
            icon: Icons.route,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RoutesScreen()));
            },
            backgroundColor: null,
            label: 'الخطوط',
          ),
          const SizedBox(height: 12),
          _buildCircularButton(
            icon: Icons.refresh,
            onPressed: _resetMapView,
            backgroundColor: null,
            label: 'تحديث',
          ),

          const SizedBox(height: 20), // فاصل أكبر بين المجموعات
          // ⚙️ مجموعة الإجراءات والخدمات الإضافية
          _buildCircularButton(
            icon: Icons.feedback_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
              );
            },
            backgroundColor: null,
            label: 'شكاوى',
          ),
          const SizedBox(height: 12),
          _buildCircularButton(
            icon: Icons.qr_code_scanner,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PaymentScreen()));
            },
            backgroundColor: null,
            label: 'الدفع',
          ),
        ],
      ),
    );
  }

  // 🔍 عرض شاشة البحث المنبثقة
  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        onLocationSelected: (location) {
          // الانتقال إلى الموقع المحدد
          _mapController.move(location, 16.0);
        },
        useMockData: AppConfig.useMockData,
        busStops: _busStops,
        buses: _buses,
        busLines: [], // يمكن إضافتها لاحقاً
      ),
    );
  }

  void _resetMapView() {
    // Try to fit all stops, fallback to initial center/zoom
    if (_busStops.isNotEmpty) {
      try {
        final latitudes = _busStops.map((s) => s.position.latitude).toList();
        final longitudes = _busStops.map((s) => s.position.longitude).toList();

        // Validate coordinates - ensure they're not NaN or Infinity
        if (latitudes.any((lat) => !lat.isFinite) ||
            longitudes.any((lng) => !lng.isFinite)) {
          // Invalid coordinates, use default view
          _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
          return;
        }

        final minLat = latitudes.reduce((a, b) => a < b ? a : b);
        final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
        final minLng = longitudes.reduce((a, b) => a < b ? a : b);
        final maxLng = longitudes.reduce((a, b) => a > b ? a : b);

        // Additional validation - ensure bounds are valid
        if (!minLat.isFinite ||
            !maxLat.isFinite ||
            !minLng.isFinite ||
            !maxLng.isFinite ||
            minLat == maxLat ||
            minLng == maxLng) {
          _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
          return;
        }

        final bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
        );
      } catch (e) {
        debugPrint('Error fitting camera to bounds: $e');
        _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
      }
    } else {
      _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
    }
    // Also clear popups and selection
    _popupLayerController.hideAllPopups();
    if (_nearestBus != null ||
        _estimatedTime != null ||
        _nearestBusLineName != null) {
      setState(() {
        _nearestBus = null;
        _estimatedTime = null;
        _nearestBusLineName = null;
      });
    }
  }

  Widget _buildBottomInfoSheet() {
    if (_nearestBus == null || _estimatedTime == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 20.0,
      left: 20.0,
      right: 20.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(26, 0, 0, 0),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _nearestBusLineName ?? '...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  _estimatedTime!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.access_time, color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingStopsSheet() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // Prevent tap from propagating to map
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: UpcomingStopsWidget(
              busStopInfo: _selectedBusStopInfo,
              isFilterActive: _filterBySelectedBus,
              onFilterToggle: () {
                setState(() {
                  _filterBySelectedBus = !_filterBySelectedBus;
                  _rebuildStopMarkers(); // إعادة بناء markers المواقف
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
