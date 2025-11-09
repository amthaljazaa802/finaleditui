import 'package:flutter_test/flutter_test.dart';
import 'package:driver_app/location_point.dart';

void main() {
  test('LocationPoint toMap round-trip', () {
    final lp = LocationPoint()
      ..latitude = '31.9539'
      ..longitude = '35.9106'
      ..speed = '12.3';

    final map = lp.toMap();

    expect(map['latitude'], equals('31.9539'));
    expect(map['longitude'], equals('35.9106'));
    expect(map['speed'], equals('12.3'));
  });
}
