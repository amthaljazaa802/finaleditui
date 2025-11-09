part of 'routes_bloc.dart'; // <--- هذا هو السطر الأهم المفقود

abstract class RoutesEvent extends Equatable {
  const RoutesEvent();

  @override
  List<Object> get props => [];
}

// حدث لبدء تحميل قائمة الخطوط
class LoadRoutes extends RoutesEvent {}

// حدث داخلي لتحديث القائمة عند وصول بيانات جديدة
class _RoutesUpdated extends RoutesEvent {
  final List<BusLine> lines;

  const _RoutesUpdated(this.lines);

  @override
  List<Object> get props => [lines];
}
