// lib/screens/complaints/bloc/complaints_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'complaints_event.dart';
part 'complaints_state.dart';

class ComplaintsBloc extends Bloc<ComplaintsEvent, ComplaintsState> {
  ComplaintsBloc() : super(ComplaintInitial()) {
    on<ComplaintSubmitted>(_onComplaintSubmitted);
  }

  Future<void> _onComplaintSubmitted(
    ComplaintSubmitted event,
    Emitter<ComplaintsState> emit,
  ) async {
    emit(ComplaintSubmissionInProgress());
    try {
      // === محاكاة إرسال البيانات إلى السيرفر ===
      await Future.delayed(const Duration(seconds: 2));
      // هنا في المستقبل ستكتب كود الإرسال الحقيقي باستخدام http أو dio
      // if (response.statusCode == 200) {
      emit(ComplaintSubmissionSuccess());
      // } else {
      //   emit(ComplaintSubmissionFailure("حدث خطأ في الإرسال"));
      // }
    } catch (e) {
      emit(ComplaintSubmissionFailure(e.toString()));
    }
  }
}
