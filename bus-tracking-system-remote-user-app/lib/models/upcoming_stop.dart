import 'bus_stop.dart';

class UpcomingStop {
  final BusStop stop;
  final int estimatedTimeMinutes;
  final double distanceMeters;
  final int stopIndex; // Position in the route
  final bool isPassed; // Whether bus has already passed this stop
  final bool atStop; // Whether bus is currently at this stop

  UpcomingStop({
    required this.stop,
    required this.estimatedTimeMinutes,
    required this.distanceMeters,
    required this.stopIndex,
    required this.isPassed,
    this.atStop = false,
  });
}

class BusStopInfo {
  final String busId;
  final String busLicensePlate;
  final String lineName;
  final List<UpcomingStop> upcomingStops;
  final List<UpcomingStop> passedStops;

  BusStopInfo({
    required this.busId,
    required this.busLicensePlate,
    required this.lineName,
    required this.upcomingStops,
    required this.passedStops,
  });
}
