import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/search_result.dart';

/// خدمة البحث - تجلب البيانات من السيرفر
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final String _baseUrl = AppConfig.baseUrl;
  final String _authToken = AppConfig.authToken;

  /// بحث في كل البيانات
  Future<List<SearchResult>> search({
    required String query,
    SearchCategory category = SearchCategory.all,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final List<SearchResult> results = [];

      // نجلب البيانات حسب الفئة
      if (category == SearchCategory.all) {
        // نجلب كل البيانات
        final response = await _fetchData('initial-data');
        if (response != null) {
          results.addAll(_parseAllData(response, query));
        }
      } else {
        // نجلب فئة محددة
        final response = await _fetchData(category.apiEndpoint);
        if (response != null) {
          results.addAll(_parseCategory(response, category, query));
        }
      }

      return results;
    } catch (e) {
      debugPrint('[SearchService] Error: $e');
      return [];
    }
  }

  /// جلب البيانات من API
  Future<dynamic> _fetchData(String endpoint) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Token $_authToken',
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'BusTrackingApp/1.0',
      };

      final uri = Uri.parse('$_baseUrl/api/$endpoint/');
      debugPrint('[SearchService] Fetching: $uri');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint(
          '[SearchService] Error ${response.statusCode}: ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('[SearchService] Fetch error: $e');
      return null;
    }
  }

  /// معالجة كل البيانات
  List<SearchResult> _parseAllData(dynamic data, String query) {
    final List<SearchResult> results = [];

    // محطات الباص
    if (data['bus_stops'] != null) {
      for (var item in data['bus_stops']) {
        if (_matchesQuery(item['stop_name'], query)) {
          results.add(SearchResult.fromBusStop(item));
        }
      }
    }

    // الباصات
    if (data['buses'] != null) {
      for (var item in data['buses']) {
        if (_matchesQuery(item['license_plate'], query)) {
          results.add(SearchResult.fromBus(item));
        }
      }
    }

    // خطوط الباصات
    if (data['bus_lines'] != null) {
      for (var item in data['bus_lines']) {
        if (_matchesQuery(item['route_name'], query)) {
          results.add(SearchResult.fromBusLine(item));
        }
      }
    }

    return results;
  }

  /// معالجة فئة محددة
  List<SearchResult> _parseCategory(
    dynamic data,
    SearchCategory category,
    String query,
  ) {
    final List<SearchResult> results = [];

    if (data is List) {
      for (var item in data) {
        bool matches = false;
        SearchResult? result;

        switch (category) {
          case SearchCategory.busStops:
            matches = _matchesQuery(item['stop_name'], query);
            if (matches) result = SearchResult.fromBusStop(item);
            break;
          case SearchCategory.buses:
            matches = _matchesQuery(item['license_plate'], query);
            if (matches) result = SearchResult.fromBus(item);
            break;
          case SearchCategory.busLines:
            matches = _matchesQuery(item['route_name'], query);
            if (matches) result = SearchResult.fromBusLine(item);
            break;
          default:
            break;
        }

        if (result != null) {
          results.add(result);
        }
      }
    }

    return results;
  }

  /// تحقق من تطابق النص مع الاستعلام
  bool _matchesQuery(String? text, String query) {
    if (text == null) return false;
    return text.toLowerCase().contains(query.toLowerCase());
  }

  /// بحث محلي (للبيانات الوهمية)
  List<SearchResult> searchLocal({
    required String query,
    required List<dynamic> busStops,
    required List<dynamic> buses,
    required List<dynamic> busLines,
    SearchCategory category = SearchCategory.all,
  }) {
    if (query.trim().isEmpty) return [];

    final List<SearchResult> results = [];

    if (category == SearchCategory.all || category == SearchCategory.busStops) {
      for (var stop in busStops) {
        if (_matchesQuery(stop.stopName, query)) {
          results.add(
            SearchResult(
              id: stop.stopId.toString(),
              title: stop.stopName,
              subtitle: 'محطة',
              type: SearchResultType.busStop,
              location: stop.position,
            ),
          );
        }
      }
    }

    if (category == SearchCategory.all || category == SearchCategory.buses) {
      for (var bus in buses) {
        if (_matchesQuery(bus.licensePlate, query)) {
          results.add(
            SearchResult(
              id: bus.busId.toString(),
              title: bus.licensePlate,
              subtitle: 'باص ${bus.busLine?.routeName ?? ''}',
              type: SearchResultType.bus,
              location: bus.position,
            ),
          );
        }
      }
    }

    if (category == SearchCategory.all || category == SearchCategory.busLines) {
      for (var line in busLines) {
        if (_matchesQuery(line.routeName, query)) {
          results.add(
            SearchResult(
              id: line.routeId.toString(),
              title: line.routeName,
              subtitle: 'خط ${line.routeDescription ?? ''}',
              type: SearchResultType.busLine,
            ),
          );
        }
      }
    }

    return results;
  }
}
