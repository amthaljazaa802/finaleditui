import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

enum BusStatus { IN_SERVICE, DELAYED, NOT_IN_SERVICE, UNKNOWN }

class Bus {
  final String id;
  final String licensePlate;
  final LatLng position;
  final String lineId;
  final BusStatus status;

  Bus({
    required this.id,
    required this.licensePlate,
    required this.position,
    required this.lineId,
    this.status = BusStatus.UNKNOWN,
  });

  // دالة لنسخ الكائن مع تغيير بعض الخصائص
  Bus copyWith({
    String? id,
    String? licensePlate,
    LatLng? position,
    String? lineId,
    BusStatus? status,
  }) {
    return Bus(
      id: id ?? this.id,
      licensePlate: licensePlate ?? this.licensePlate,
      position: position ?? this.position,
      lineId: lineId ?? this.lineId,
      status: status ?? this.status,
    );
  }

  // دالة لتحويل JSON إلى كائن Bus
  // Updated to match Django serializer field names
  factory Bus.fromJson(Map<String, dynamic> json) {
    try {
      // Parse bus_id as String (Django sends it as int)
      final String busId = json['bus_id']?.toString() ?? '';

      if (busId.isEmpty) {
        throw Exception('Bus ID is required');
      }

      // Parse license_plate (Django uses snake_case)
      final String licensePlate = json['license_plate']?.toString() ?? '';

      // Parse current_location (Django sends {id, latitude, longitude})
      final location = json['current_location'];
      double lat = 33.5138; // Default: Damascus center
      double lng = 36.2765;

      if (location != null && location is Map) {
        final parsedLat = (location['latitude'] as num?)?.toDouble();
        final parsedLng = (location['longitude'] as num?)?.toDouble();

        // Only use parsed values if they're valid
        if (parsedLat != null &&
            parsedLng != null &&
            parsedLat.isFinite &&
            parsedLng.isFinite &&
            parsedLat.abs() <= 90 &&
            parsedLng.abs() <= 180 &&
            !(parsedLat == 0.0 && parsedLng == 0.0)) {
          lat = parsedLat;
          lng = parsedLng;
        }
      }

      final LatLng position = LatLng(lat, lng);

      // Parse bus_line to get route_id (Django sends nested bus_line object)
      final busLine = json['bus_line'];
      String lineId = '';

      if (busLine != null && busLine is Map) {
        lineId = busLine['route_id']?.toString() ?? '';
      }

      // Status is not provided by Django API yet, default to IN_SERVICE
      final BusStatus status = BusStatus.IN_SERVICE;

      return Bus(
        id: busId,
        licensePlate: licensePlate,
        position: position,
        lineId: lineId,
        status: status,
      );
    } catch (e) {
      // If parsing fails, return a default bus at Damascus center
      debugPrint('Error parsing bus JSON: $e');
      return Bus(
        id: json['bus_id']?.toString() ?? 'unknown',
        licensePlate: json['license_plate']?.toString() ?? 'N/A',
        position: const LatLng(33.5138, 36.2765),
        lineId: '',
        status: BusStatus.UNKNOWN,
      );
    }
  }
}
