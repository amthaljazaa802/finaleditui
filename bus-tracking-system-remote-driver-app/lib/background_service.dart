import 'dart:async';
import 'dart:ui';
import 'package:driver_app/location_point.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  const String notificationChannelId = 'my_foreground_service';

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: false,
      foregroundServiceNotificationId: 888,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'تطبيق السائق جاهز',
      initialNotificationContent: 'في انتظار بدء عملية التتبع.',
    ),
    iosConfiguration: IosConfiguration(
      onForeground: onStart,
      autoStart: false,
    ),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  debugPrint('BackgroundService: onStart entry');
  // Guard the entire onStart body so plugin/native exceptions do not kill
  // the service unexpectedly. Plugins sometimes call Android APIs that
  // require a main activity/context and will throw when used in a
  // background engine.
  try {
    DartPluginRegistrant.ensureInitialized();

    try {
      await Hive.initFlutter();
    } catch (e, st) {
      debugPrint('BackgroundService: Hive.initFlutter failed: $e');
      debugPrint('$st');
    }
    if (!Hive.isAdapterRegistered(LocationPointAdapter().typeId)) {
      Hive.registerAdapter(LocationPointAdapter());
    }
    Box<LocationPoint>? locationBox;
    try {
      locationBox = await Hive.openBox<LocationPoint>('location_queue');
    } catch (e, st) {
      debugPrint('BackgroundService: openBox failed: $e');
      debugPrint('$st');
    }

    if (service is AndroidServiceInstance) {
      service
          .on('setAsForeground')
          .listen((event) => service.setAsForegroundService());
      service
          .on('setAsBackground')
          .listen((event) => service.setAsBackgroundService());
    }

    StreamSubscription<Position>? positionStream;
    String? serverUrl;
    String? authToken;
    Timer? periodicFlushTimer;

    Future<void> processQueue() async {
      try {
        if (locationBox == null || locationBox.isEmpty) return;
        final keys = locationBox.keys.toList();
        for (final key in keys) {
          final locationPoint = locationBox.get(key);
          debugPrint(
              'BackgroundService.processQueue: serverUrl=$serverUrl auth=${authToken != null} key=$key');

          if (locationPoint == null) continue;
          if (serverUrl == null || authToken == null) {
            debugPrint(
                'BackgroundService.processQueue: serverUrl or authToken is null, stopping processing');
            return;
          }
          try {
            final response = await http.post(
              Uri.parse(serverUrl!),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Token $authToken'
              },
              body: jsonEncode(locationPoint.toMap()),
            );
            debugPrint(
                'BackgroundService.processQueue: POST status=${response.statusCode}');
            if (response.statusCode >= 200 && response.statusCode < 300) {
              await locationBox.delete(key);
            } else {
              // stop retrying this run if server returns non-2xx
              break;
            }
          } catch (e, st) {
            debugPrint('BackgroundService.processQueue: POST failed: $e');
            debugPrint('$st');
            break;
          }
        }
      } catch (e, st) {
        debugPrint('BackgroundService.processQueue: unexpected error: $e');
        debugPrint('$st');
      }
    }

    service.on('startTracking').listen((event) async {
      try {
        if (event == null) return;

        // --- الخطوة 2: استقبال المتغيرات مباشرة ---
        final busId = event['bus_id'];
        final apiBaseUrl = event['api_base_url'];
        authToken = event['auth_token'];
        // --- نهاية الخطوة 2 ---

        if (authToken == null || apiBaseUrl == null || busId == null) {
          debugPrint(
              'BackgroundService.startTracking: missing param busId/apiBaseUrl/authToken -> $event');
          return;
        }

        serverUrl = '$apiBaseUrl/api/buses/$busId/update-location/';

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'تتبع مباشر فعال',
            content: 'الحافلة #$busId قيد التتبع حالياً.',
          );
        }

        const locationSettings = LocationSettings(
            accuracy: LocationAccuracy.high, distanceFilter: 10);

        // Starting the geolocation stream can fail if a plugin expects the main
        // isolate / activity context. Protect it and use a periodic flush as a
        // fallback so queued points are still retried.
        try {
          positionStream =
              Geolocator.getPositionStream(locationSettings: locationSettings)
                  .listen(
            (Position position) async {
              final locationPoint = LocationPoint()
                ..latitude = position.latitude.toString()
                ..longitude = position.longitude.toString()
                ..speed = position.speed.toString();
              debugPrint(
                  'BackgroundService.positionStream: got position; serverUrl=$serverUrl auth=${authToken != null}');

              try {
                if (serverUrl == null || authToken == null) {
                  debugPrint(
                      'BackgroundService.positionStream: serverUrl/authToken null; queuing point');
                  await locationBox?.add(locationPoint);
                  return;
                }

                final response = await http.post(
                  Uri.parse(serverUrl!),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Token $authToken'
                  },
                  body: jsonEncode(locationPoint.toMap()),
                );
                debugPrint(
                    'BackgroundService.positionStream: POST status=${response.statusCode}');
                if (response.statusCode >= 200 && response.statusCode < 300) {
                  await processQueue();
                } else {
                  await locationBox?.add(locationPoint);
                }
              } catch (e, st) {
                debugPrint('BackgroundService.positionStream: POST failed: $e');
                debugPrint('$st');
                await locationBox?.add(locationPoint);
              }
            },
            onError: (error) {
              debugPrint(
                  'BackgroundService.positionStream: stream error: $error');
            },
          );
        } catch (e, st) {
          debugPrint('BackgroundService: failed to start position stream: $e');
          debugPrint('$st');
          // Periodic flush to retry queued points even when the live stream isn't available
          periodicFlushTimer =
              Timer.periodic(const Duration(seconds: 3), (_) async {
            await processQueue();
          });
        }
      } catch (e, st) {
        debugPrint('BackgroundService.startTracking handler failed: $e');
        debugPrint('$st');
      }
    });

    service.on('stopService').listen((event) {
      positionStream?.cancel();
      periodicFlushTimer?.cancel();
      service.stopSelf();
    });
  } catch (e, st) {
    debugPrint('BackgroundService.onStart top-level error: $e');
    debugPrint('$st');
    // keep the service alive; do not rethrow
  }
}
