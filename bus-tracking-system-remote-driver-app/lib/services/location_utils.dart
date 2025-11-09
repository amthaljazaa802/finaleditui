import 'package:driver_app/location_point.dart';

class LocationUtils {
  /// Creates a LocationPoint from primitive values.
  static LocationPoint fromValues(
      {required double latitude,
      required double longitude,
      required double speed}) {
    final lp = LocationPoint()
      ..latitude = latitude.toString()
      ..longitude = longitude.toString()
      ..speed = speed.toString();
    return lp;
  }
}
