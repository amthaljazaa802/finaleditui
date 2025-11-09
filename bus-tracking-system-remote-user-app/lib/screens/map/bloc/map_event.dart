// lib/screens/map/bloc/map_event.dart
part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

// الحدث الأول: يتم إرساله عند بدء تشغيل الشاشة لطلب البيانات
class MapStarted extends MapEvent {
  final String lineId;

  const MapStarted(this.lineId);

  @override
  List<Object?> get props => [lineId];
}

// الحدث الثاني: يتم إرساله عند الضغط على حافلة لتتبعها
class BusTrackingStarted extends MapEvent {
  final String busId;

  const BusTrackingStarted(this.busId);

  @override
  List<Object?> get props => [busId];
}

// حدث داخلي: يُستخدم فقط داخل الـ BLoC لإبلاغه بوصول تحديث من الـ WebSocket
// لا يتم إرساله من الواجهة
class _BusesUpdated extends MapEvent {
  final List<Bus> buses;

  const _BusesUpdated(this.buses);

  @override
  List<Object?> get props => [buses];
}
