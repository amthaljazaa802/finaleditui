import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking_app/models/bus.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('Bus model creates and returns correct fields', () {
    final bus = Bus(
      id: 'bus_1',
      licensePlate: '1234-XYZ',
      position: const LatLng(33.5, 36.3),
      lineId: 'line_1',
      status: BusStatus.IN_SERVICE,
    );
    expect(bus.id, 'bus_1');
    expect(bus.licensePlate, '1234-XYZ');
    expect(bus.lineId, 'line_1');
    expect(bus.status, BusStatus.IN_SERVICE);
  });
}
