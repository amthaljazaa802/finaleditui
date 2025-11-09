import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking_app/screens/routes/bloc/routes_bloc.dart';
import 'package:bus_tracking_app/services/tracking_service.dart';
import 'package:bus_tracking_app/repositories/transport_repository.dart';

void main() {
  group('RoutesBloc', () {
    late TrackingService service;
    late TransportRepository repo;

    setUp(() async {
      service = TrackingService();
      repo = TrackingTransportRepository(service);
      await repo.fetchInitialData();
    });

    tearDown(() {
      repo.dispose();
    });

    blocTest<RoutesBloc, RoutesState>(
      'emits RoutesLoadSuccess immediately if cache has data and updates on stream',
      build: () => RoutesBloc(repository: repo),
      act: (bloc) => bloc.add(LoadRoutes()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<RoutesLoadSuccess>().having(
          (s) => (s as RoutesLoadSuccess).busLines,
          'lines',
          isNotEmpty,
        ),
      ],
    );
  });
}
