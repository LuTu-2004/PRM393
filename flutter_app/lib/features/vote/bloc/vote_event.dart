import 'package:equatable/equatable.dart';

abstract class VoteEvent extends Equatable {
  const VoteEvent();

  @override
  List<Object?> get props => [];
}

/// Su kien tai phien bo phieu cua phong
class LoadVoteSessionEvent extends VoteEvent {
  final String roomId;
  final int totalMembers;

  const LoadVoteSessionEvent({
    required this.roomId,
    required this.totalMembers,
  });

  @override
  List<Object?> get props => [roomId, totalMembers];
}

/// Leader mo phien bo phieu kin khi phong du 4-5 nguoi (BR-21, BR-22)
class StartVoteSessionEvent extends VoteEvent {
  final String roomId;
  final int totalMembers;

  const StartVoteSessionEvent({
    required this.roomId,
    required this.totalMembers,
  });

  @override
  List<Object?> get props => [roomId, totalMembers];
}

/// Sinh vien thuc hien bo phieu kin (BR-23, BR-24)
class CastVoteEvent extends VoteEvent {
  final String sessionId;
  final String roomId;
  final int totalMembers;
  final bool isApproved;
  final String? leaderCandidateId;

  const CastVoteEvent({
    required this.sessionId,
    required this.roomId,
    required this.totalMembers,
    required this.isApproved,
    this.leaderCandidateId,
  });

  @override
  List<Object?> get props => [sessionId, roomId, totalMembers, isApproved, leaderCandidateId];
}
