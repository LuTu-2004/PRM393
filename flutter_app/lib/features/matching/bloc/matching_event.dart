import 'package:equatable/equatable.dart';

abstract class MatchingEvent extends Equatable {
  const MatchingEvent();

  @override
  List<Object?> get props => [];
}

/// Su kien tai danh sach de xuat phong phu hop
class LoadMatchingRecommendationsEvent extends MatchingEvent {
  const LoadMatchingRecommendationsEvent();
}

/// Su kien sinh vien gui yeu cau vao phong (BR-16)
class SendJoinRequestEvent extends MatchingEvent {
  final String roomId;
  final String roomName;
  final String leaderId;
  final String leaderName;
  final String? message;

  const SendJoinRequestEvent({
    required this.roomId,
    required this.roomName,
    required this.leaderId,
    required this.leaderName,
    this.message,
  });

  @override
  List<Object?> get props => [roomId, leaderId, message];
}
