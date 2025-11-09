part of 'routes_bloc.dart';

abstract class RoutesState extends Equatable {
  const RoutesState();

  @override
  List<Object> get props => [];
}

// الحالة الأولية / جاري التحميل
class RoutesInitial extends RoutesState {}

// حالة نجاح التحميل
class RoutesLoadSuccess extends RoutesState {
  // اسم المتغير الصحيح هو busLines
  final List<BusLine> busLines;

  const RoutesLoadSuccess({this.busLines = const []});

  @override
  List<Object> get props => [busLines];
}

// حالة فشل التحميل
class RoutesLoadFailure extends RoutesState {
  final String errorMessage;

  const RoutesLoadFailure(this.errorMessage);

  @override
  List<Object> get props => [errorMessage];
}
