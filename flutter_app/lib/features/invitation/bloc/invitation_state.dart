import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/invitation_model.dart';
import 'invitation_event.dart';

abstract class InvitationState extends Equatable {
  const InvitationState();

  @override
  List<Object?> get props => [];
}

class InvitationInitialState extends InvitationState {}

class InvitationLoadingState extends InvitationState {}

class DiversityWarningPromptState extends InvitationState {
  final RespondInvitationEvent pendingEvent;
  final double projectedRatio;

  const DiversityWarningPromptState({
    required this.pendingEvent,
    required this.projectedRatio,
  });

  @override
  List<Object?> get props => [pendingEvent, projectedRatio];
}

class InvitationLoadedState extends InvitationState {
  final List<InvitationModel> sentRequests;
  final List<InvitationModel> receivedInvitations;
  final String? successMessage;

  const InvitationLoadedState({
    required this.sentRequests,
    required this.receivedInvitations,
    this.successMessage,
  });

  /// So luong request dang cho sinh vien da gui (BR-17)
  int get pendingSentCount => sentRequests.where((r) => r.isPending).length;

  /// So luong yeu cau Leader chua xu ly
  int get pendingReceivedCount => receivedInvitations.where((r) => r.isPending).length;

  InvitationLoadedState copyWith({
    List<InvitationModel>? sentRequests,
    List<InvitationModel>? receivedInvitations,
    String? successMessage,
  }) {
    return InvitationLoadedState(
      sentRequests: sentRequests ?? this.sentRequests,
      receivedInvitations: receivedInvitations ?? this.receivedInvitations,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [sentRequests, receivedInvitations, successMessage];
}

class InvitationErrorState extends InvitationState {
  final String message;

  const InvitationErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
