// lib/screens/complaints/bloc/complaints_state.dart
part of 'complaints_bloc.dart';

abstract class ComplaintsState extends Equatable {
  const ComplaintsState();
  @override
  List<Object> get props => [];
}

// الحالة الأولية للنموذج
class ComplaintInitial extends ComplaintsState {}

// حالة جاري الإرسال
class ComplaintSubmissionInProgress extends ComplaintsState {}

// حالة نجاح الإرسال
class ComplaintSubmissionSuccess extends ComplaintsState {}

// حالة فشل الإرسال
class ComplaintSubmissionFailure extends ComplaintsState {
  final String errorMessage;
  const ComplaintSubmissionFailure(this.errorMessage);
  @override
  List<Object> get props => [errorMessage];
}
