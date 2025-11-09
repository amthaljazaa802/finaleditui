import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/bus.dart';
import '../../../models/bus_line.dart';
import '../../../repositories/transport_repository.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final TransportRepository repository;
  StreamSubscription? _busStreamSubscription;

  MapBloc({required this.repository}) : super(MapInitial()) {
    on<MapStarted>(_onMapStarted);
    on<BusTrackingStarted>(_onBusTrackingStarted);
    on<_BusesUpdated>(_onBusesUpdated);
  }

  void _onMapStarted(MapStarted event, Emitter<MapState> emit) {
    emit(MapLoadInProgress());

    try {
      // --- 1. جلب البيانات المفلترة من ذاكرة الخدمة (Cache) ---

      // ابحث عن الخط المطلوب بالكامل باستخدام الـ ID
      final line = repository.busLines.firstWhere((l) => l.id == event.lineId);

      // قم بفلترة قائمة الحافلات الكلية لعرض حافلات هذا الخط فقط
      final lineBuses = repository.buses
          .where((b) => b.lineId == event.lineId)
          .toList();

      // --- 2. إصدار حالة النجاح مع البيانات المفلترة فورًا ---
      emit(MapLoadSuccess(line: line, buses: lineBuses));

      // --- 3. الاستماع للتحديثات المستقبلية ---
      //    هذا سيجعل الحافلات تتحرك على الخريطة المخصصة أيضًا
      _busStreamSubscription?.cancel();
      _busStreamSubscription = repository.busStream.listen((allBuses) {
        final updatedLineBuses = allBuses
            .where((b) => b.lineId == event.lineId)
            .toList();
        add(_BusesUpdated(updatedLineBuses));
      });
    } catch (e) {
      // في حال لم يتم العثور على الخط
      emit(MapLoadFailure('Line with ID ${event.lineId} not found. Error: $e'));
    }
  }

  void _onBusesUpdated(_BusesUpdated event, Emitter<MapState> emit) {
    final currentState = state;
    if (currentState is MapLoadSuccess) {
      // تحديث قائمة الحافلات فقط في الحالة الحالية
      emit(currentState.copyWith(buses: event.buses));
    }
  }

  void _onBusTrackingStarted(BusTrackingStarted event, Emitter<MapState> emit) {
    final currentState = state;
    if (currentState is MapLoadSuccess) {
      emit(currentState.copyWith(trackedBusId: event.busId));
    }
  }

  @override
  Future<void> close() {
    _busStreamSubscription?.cancel();
    return super.close();
  }
}
