import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/bus_line.dart';
import '../../../repositories/transport_repository.dart';

part 'routes_event.dart';
part 'routes_state.dart';

class RoutesBloc extends Bloc<RoutesEvent, RoutesState> {
  final TransportRepository repository;
  StreamSubscription? _linesSubscription;

  RoutesBloc({required this.repository}) : super(RoutesInitial()) {
    on<LoadRoutes>(_onLoadRoutes);
    on<_RoutesUpdated>(_onRoutesUpdated);
  }

  void _onLoadRoutes(LoadRoutes event, Emitter<RoutesState> emit) {
    // --- 1. التعديل الرئيسي: طلب البيانات من الذاكرة (Cache) أولاً ---
    final initialLines = repository.busLines;
    if (initialLines.isNotEmpty) {
      // إذا كانت البيانات موجودة بالفعل في الذاكرة، اعرضها فورًا
      emit(RoutesLoadSuccess(busLines: initialLines));
    }

    // --- 2. الاستماع للتحديثات المستقبلية عبر الـ Stream (كما كان) ---
    _linesSubscription?.cancel();
    _linesSubscription = repository.busLinesStream.listen(
      (lines) {
        // عندما تصل بيانات جديدة، قم بتحديث الواجهة
        add(_RoutesUpdated(lines));
      },
      onError: (error) {
        emit(RoutesLoadFailure(error.toString()));
      },
    );
  }

  void _onRoutesUpdated(_RoutesUpdated event, Emitter<RoutesState> emit) {
    // هذه الدالة تبقى كما هي، مسؤولة عن إصدار حالة النجاح
    emit(RoutesLoadSuccess(busLines: event.lines));
  }

  @override
  Future<void> close() {
    _linesSubscription?.cancel();
    return super.close();
  }
}
