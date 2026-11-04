import 'package:equatable/equatable.dart';

abstract class CoordinationEvent extends Equatable {
  const CoordinationEvent();

  @override
  List<Object?> get props => [];
}

/// BR-30: Tai tong quan tien do ghep nhom theo ky va mon
class LoadCoordinationDashboardEvent extends CoordinationEvent {
  final String semesterId;
  final String subjectCode;

  const LoadCoordinationDashboardEvent({
    this.semesterId = 'FALL2026',
    this.subjectCode = 'ALL',
  });

  @override
  List<Object?> get props => [semesterId, subjectCode];
}

/// Loc theo mon hoc: ALL / EXE101 / EXE201
class FilterCoordinationSubjectEvent extends CoordinationEvent {
  final String subjectCode;

  const FilterCoordinationSubjectEvent(this.subjectCode);

  @override
  List<Object?> get props => [subjectCode];
}

/// BR-32: Gia han thoi gian dang ky
class ExtendRegistrationDeadlineEvent extends CoordinationEvent {
  final String semesterId;
  final DateTime newDeadline;

  const ExtendRegistrationDeadlineEvent({
    this.semesterId = 'FALL2026',
    required this.newDeadline,
  });

  @override
  List<Object?> get props => [semesterId, newDeadline];
}

/// BR-31: Quyen can thiep: Giai tan nhom vi pham hoac khong hoat dong
class DisbandRoomEvent extends CoordinationEvent {
  final String roomId;
  final String reason;

  const DisbandRoomEvent({
    required this.roomId,
    required this.reason,
  });

  @override
  List<Object?> get props => [roomId, reason];
}

/// BR-33: Gui canh bao khan cap cho phong co nguy co thieu thanh vien
class SendUrgentAlertEvent extends CoordinationEvent {
  final String roomId;
  final String roomName;

  const SendUrgentAlertEvent({
    required this.roomId,
    required this.roomName,
  });

  @override
  List<Object?> get props => [roomId, roomName];
}
