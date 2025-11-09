// lib/screens/map/bloc/map_state.dart
part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object?> get props => [];
}

// الحالة الأولية، قبل أن يحدث أي شيء
class MapInitial extends MapState {}

// حالة تحميل البيانات
class MapLoadInProgress extends MapState {}

// حالة النجاح، تحتوي على كل البيانات التي تحتاجها الواجهة
class MapLoadSuccess extends MapState {
  final List<Bus> buses;
  final String? trackedBusId;
  final BusLine line;

  const MapLoadSuccess({
    required this.line,
    this.buses = const [],
    this.trackedBusId,
  });

  // دالة مساعدة لنسخ الحالة مع تغيير بعض القيم
  // هذا يجعل تحديث الحالة آمناً وسهلاً
  MapLoadSuccess copyWith({
    List<Bus>? buses,
    String? trackedBusId,
    BusLine? line,
  }) {
    return MapLoadSuccess(
      buses: buses ?? this.buses,
      trackedBusId: trackedBusId ?? this.trackedBusId,
      line: line ?? this.line,
    );
  }

  @override
  List<Object?> get props => [buses, trackedBusId, line];
}

// حالة الفشل في تحميل البيانات
class MapLoadFailure extends MapState {
  final String errorMessage;

  const MapLoadFailure(this.errorMessage);
  @override
  List<Object?> get props => [errorMessage];
}
