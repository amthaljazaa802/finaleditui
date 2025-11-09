import 'package:latlong2/latlong.dart';
import 'bus_stop.dart';

class BusLine {
  final String id;
  final String name;
  final String description;
  final List<BusStop> stops;
  final List<LatLng> path;

  BusLine({
    required this.id,
    required this.name,
    required this.description,
    required this.stops,
    required this.path,
  });

  // --- دالة جديدة لتحويل بيانات JSON القادمة من الخادم ---
  // Updated to match Django serializer field names
  factory BusLine.fromJson(Map<String, dynamic> json) {
    // Parse route_id as String (Django sends it as int)
    final String routeId = json['route_id']?.toString() ?? '';

    // Parse route_name and route_description (Django uses snake_case)
    final String routeName = json['route_name']?.toString() ?? '';
    final String routeDescription = json['route_description']?.toString() ?? '';

    // هذا الكود يفترض أن الخادم يرسل قائمة كاملة من كائنات المحطات
    // (Django doesn't send stops by default in BusLineSerializer)
    final stopsList =
        (json['stops'] as List<dynamic>?)
            ?.map((stopJson) => BusStop.fromJson(stopJson))
            .toList() ??
        [];

    // هذا الكود يفترض أن الخادم يرسل قائمة من الإحداثيات
    // (Django doesn't send path by default)
    final pathList =
        (json['path'] as List<dynamic>?)
            ?.map((point) => LatLng(point['lat'], point['lng']))
            .toList() ??
        [];

    return BusLine(
      id: routeId,
      name: routeName,
      description: routeDescription,
      stops: stopsList,
      path: pathList,
    );
  }
}
