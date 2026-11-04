import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/services/matching_service.dart';

abstract class MatchingState extends Equatable {
  const MatchingState();

  @override
  List<Object?> get props => [];
}

class MatchingInitialState extends MatchingState {}

class MatchingLoadingState extends MatchingState {}

class MatchingLoadedState extends MatchingState {
  final UserModel currentUser;
  final List<MatchingResult> recommendations;
  final List<InvitationModel> pendingSentRequests; // Danh sach dang cho de dem so luong (BR-17)
  final String? successMessage;

  const MatchingLoadedState({
    required this.currentUser,
    required this.recommendations,
    required this.pendingSentRequests,
    this.successMessage,
  });

  /// So luong request dang cho (toi da 3 theo BR-17)
  int get pendingCount => pendingSentRequests.length;
  bool get canSendMore => pendingCount < 3;

  /// Kiem tra xem phong da duoc gui request chua
  bool isRoomRequested(String roomId) {
    return pendingSentRequests.any((r) => r.roomId == roomId);
  }

  MatchingLoadedState copyWith({
    UserModel? currentUser,
    List<MatchingResult>? recommendations,
    List<InvitationModel>? pendingSentRequests,
    String? successMessage,
  }) {
    return MatchingLoadedState(
      currentUser: currentUser ?? this.currentUser,
      recommendations: recommendations ?? this.recommendations,
      pendingSentRequests: pendingSentRequests ?? this.pendingSentRequests,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [currentUser, recommendations, pendingSentRequests, successMessage];
}

class MatchingErrorState extends MatchingState {
  final String message;

  const MatchingErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
