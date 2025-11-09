import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/services/location_utils.dart';

void main() {
  test('LocationUtils.fromValues creates correct LocationPoint', () {
    final lp =
        LocationUtils.fromValues(latitude: 31.0, longitude: 35.0, speed: 12.3);

    expect(lp.latitude, '31.0');
    expect(lp.longitude, '35.0');
    expect(lp.speed, '12.3');
  });
}
