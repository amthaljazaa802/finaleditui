import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking_app/screens/map/bloc/map_bloc.dart';
import 'package:bus_tracking_app/services/tracking_service.dart';
import 'package:bus_tracking_app/repositories/transport_repository.dart';

void main() {
  group('MapBloc', () {
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

    blocTest<MapBloc, MapState>(
      'emits [MapLoadInProgress, MapLoadSuccess] when MapStarted added with existing lineId',
      build: () => MapBloc(repository: repo),
      act: (bloc) => bloc.add(const MapStarted('line_1')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<MapLoadInProgress>(),
        isA<MapLoadSuccess>().having(
          (s) => (s as MapLoadSuccess).line.id,
          'line id',
          'line_1',
        ),
      ],
    );

    blocTest<MapBloc, MapState>(
      'emits MapLoadFailure when MapStarted with invalid lineId',
      build: () => MapBloc(repository: repo),
      act: (bloc) => bloc.add(const MapStarted('invalid_line')),
      expect: () => [isA<MapLoadInProgress>(), isA<MapLoadFailure>()],
    );

    test('updates buses on _BusesUpdated', () async {
      final bloc = MapBloc(repository: repo);
      bloc.add(const MapStarted('line_1'));
      await Future.delayed(const Duration(milliseconds: 100));
      final initial = bloc.state as MapLoadSuccess;
      expect(initial.buses, isNotEmpty);

      // Simulate an update by re-fetching mock data (service will re-emit)
      await repo.fetchInitialData();
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify bloc still in success state after update
      expect(bloc.state, isA<MapLoadSuccess>());
      await bloc.close();
    });
  });
}
