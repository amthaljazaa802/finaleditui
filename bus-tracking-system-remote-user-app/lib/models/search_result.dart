import 'package:latlong2/latlong.dart';

/// نموذج لنتيجة البحث (محطة أو باص أو خط)
class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultType type;
  final LatLng? location;
  final Map<String, dynamic>? metadata;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.location,
    this.metadata,
  });

  factory SearchResult.fromBusStop(Map<String, dynamic> json) {
    return SearchResult(
      id: json['stop_id'].toString(),
      title: json['stop_name'] ?? 'محطة',
      subtitle: 'محطة • ${_formatDistance(json)}',
      type: SearchResultType.busStop,
      location: json['location'] != null
          ? LatLng(
              json['location']['latitude'] ?? 0.0,
              json['location']['longitude'] ?? 0.0,
            )
          : null,
      metadata: json,
    );
  }

  factory SearchResult.fromBus(Map<String, dynamic> json) {
    return SearchResult(
      id: json['bus_id'].toString(),
      title: json['license_plate'] ?? 'باص',
      subtitle: 'باص ${json['bus_line']?['route_name'] ?? ''}',
      type: SearchResultType.bus,
      location: json['current_location'] != null
          ? LatLng(
              json['current_location']['latitude'] ?? 0.0,
              json['current_location']['longitude'] ?? 0.0,
            )
          : null,
      metadata: json,
    );
  }

  factory SearchResult.fromBusLine(Map<String, dynamic> json) {
    return SearchResult(
      id: json['route_id'].toString(),
      title: json['route_name'] ?? 'خط',
      subtitle: 'خط ${json['route_description'] ?? ''}',
      type: SearchResultType.busLine,
      location: null,
      metadata: json,
    );
  }

  static String _formatDistance(Map<String, dynamic>? json) {
    if (json == null) return '';
    // يمكن إضافة حساب المسافة هنا لاحقاً
    return '';
  }
}

enum SearchResultType { busStop, bus, busLine }

/// فئات البحث (الفلاتر)
enum SearchCategory { all, busStops, buses, busLines }

extension SearchCategoryExtension on SearchCategory {
  String get label {
    switch (this) {
      case SearchCategory.all:
        return 'الكل';
      case SearchCategory.busStops:
        return 'محطات';
      case SearchCategory.buses:
        return 'حافلات';
      case SearchCategory.busLines:
        return 'خطوط';
    }
  }

  String get apiEndpoint {
    switch (this) {
      case SearchCategory.all:
        return 'initial-data'; // نستخدم endpoint واحد
      case SearchCategory.busStops:
        return 'bus-stops';
      case SearchCategory.buses:
        return 'buses';
      case SearchCategory.busLines:
        return 'bus-lines';
    }
  }
}
