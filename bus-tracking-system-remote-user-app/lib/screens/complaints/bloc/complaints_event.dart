// lib/screens/complaints/bloc/complaints_event.dart
part of 'complaints_bloc.dart';

abstract class ComplaintsEvent extends Equatable {
  const ComplaintsEvent();
  @override
  List<Object?> get props => [];
}

// حدث الإرسال، يحمل معه كل بيانات النموذج
class ComplaintSubmitted extends ComplaintsEvent {
  final String type;
  final String details;
  final String? busInfo;
  final String? contactInfo;

  const ComplaintSubmitted({
    required this.type,
    required this.details,
    this.busInfo,
    this.contactInfo,
  });

  @override
  List<Object?> get props => [type, details, busInfo, contactInfo];
}
