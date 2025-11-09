import 'package:latlong2/latlong.dart';

class BusStop {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  BusStop({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  // دالة لتحويل JSON إلى كائن BusStop
  // Updated to match Django serializer field names
  factory BusStop.fromJson(Map<String, dynamic> json) {
    // Parse stop_id as String (Django sends it as int)
    final String stopId = json['stop_id']?.toString() ?? '';

    // Parse stop_name (Django uses snake_case)
    final String stopName = json['stop_name']?.toString() ?? '';

    // Parse location (Django sends {id, latitude, longitude})
    final location = json['location'];
    final double lat = location != null
        ? (location['latitude'] as num?)?.toDouble() ?? 0.0
        : 0.0;
    final double lng = location != null
        ? (location['longitude'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return BusStop(id: stopId, name: stopName, latitude: lat, longitude: lng);
  }

  // للوصول السهل إلى الموقع كـ LatLng
  // Only return position if coordinates are valid
  LatLng get position {
    // Validate coordinates are finite and within reasonable range
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      // Return a default valid position (Damascus center) if invalid
      return const LatLng(33.5138, 36.2765);
    }
    return LatLng(latitude, longitude);
  }
}
