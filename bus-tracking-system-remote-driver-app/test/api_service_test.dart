import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:driver_app/services/api_service.dart';

void main() {
  group('ApiService', () {
    test('getBusData returns decoded JSON on 200', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'id': 'bus1', 'name': 'Bus 1'}), 200);
      });

      final service =
          ApiService(baseUrl: 'https://example.test', authToken: 'test');
      final result = await service.getBusData('bus1', client: mockClient);

      expect(result['id'], 'bus1');
      expect(result['name'], 'Bus 1');
    });

    test('updateLocation throws on non-200/204', () async {
      final mockClient = MockClient((request) async {
        return http.Response('bad', 500);
      });

      final service =
          ApiService(baseUrl: 'https://example.test', authToken: 'test');
      expect(
        () => service.updateLocation('bus1', 1.0, 2.0, 3.0, client: mockClient),
        throwsA(isA<Exception>()),
      );
    });
  });
}
