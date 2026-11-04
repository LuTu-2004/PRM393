import 'package:equatable/equatable.dart';

abstract class InvitationEvent extends Equatable {
  const InvitationEvent();

  @override
  List<Object?> get props => [];
}

/// Su kien tai danh sach loi moi va yeu cau
class LoadInvitationsEvent extends InvitationEvent {
  const LoadInvitationsEvent();
}

/// Sinh vien huy yeu cau da gui de giai phong slot (BR-17)
class CancelSentRequestEvent extends InvitationEvent {
  final String requestId;

  const CancelSentRequestEvent(this.requestId);

  @override
  List<Object?> get props => [requestId];
}

/// Leader phan hoi yeu cau (BR-16, BR-18, BR-19)
class RespondInvitationEvent extends InvitationEvent {
  final String requestId;
  final bool accept;
  final String roomId;
  final String applicantId;
  final String applicantName;
  final String applicantMajor;
  final String? studentCode;
  final bool forceAccept; // true neu Leader da xac nhan bo qua canh bao da dang nganh

  const RespondInvitationEvent({
    required this.requestId,
    required this.accept,
    required this.roomId,
    required this.applicantId,
    required this.applicantName,
    required this.applicantMajor,
    this.studentCode,
    this.forceAccept = false,
  });

  @override
  List<Object?> get props => [
        requestId,
        accept,
        roomId,
        applicantId,
        applicantName,
        applicantMajor,
        studentCode,
        forceAccept,
      ];
}
