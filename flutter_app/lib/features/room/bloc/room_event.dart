import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/models.dart';

abstract class RoomEvent extends Equatable {
  const RoomEvent();

  @override
  List<Object?> get props => [];
}

class LoadRoomsEvent extends RoomEvent {
  final String? subjectCode;
  final String? searchKeyword;

  const LoadRoomsEvent({this.subjectCode, this.searchKeyword});

  @override
  List<Object?> get props => [subjectCode, searchKeyword];
}

class FilterSubjectEvent extends RoomEvent {
  final String? subjectCode;

  const FilterSubjectEvent(this.subjectCode);

  @override
  List<Object?> get props => [subjectCode];
}

class SearchRoomsEvent extends RoomEvent {
  final String keyword;

  const SearchRoomsEvent(this.keyword);

  @override
  List<Object?> get props => [keyword];
}

/// Event tao phong moi (BR-09, BR-10)
class CreateRoomEvent extends RoomEvent {
  final RoomModel room;

  const CreateRoomEvent(this.room);

  @override
  List<Object?> get props => [room];
}

/// Event Leader kick thanh vien khoi phong (BR-13)
class KickMemberEvent extends RoomEvent {
  final String roomId;
  final String memberId;
  final String memberName;

  const KickMemberEvent({
    required this.roomId,
    required this.memberId,
    required this.memberName,
  });

  @override
  List<Object?> get props => [roomId, memberId, memberName];
}

/// Event Leader moi truc tiep sinh vien qua MSSV hoac Email (BR-11)
class DirectInviteEvent extends RoomEvent {
  final String roomId;
  final String roomName;
  final String leaderId;
  final String leaderName;
  final String targetStudentCodeOrEmail;
  final String? message;

  const DirectInviteEvent({
    required this.roomId,
    required this.roomName,
    required this.leaderId,
    required this.leaderName,
    required this.targetStudentCodeOrEmail,
    this.message,
  });

  @override
  List<Object?> get props => [
        roomId,
        roomName,
        leaderId,
        leaderName,
        targetStudentCodeOrEmail,
        message,
      ];
}
