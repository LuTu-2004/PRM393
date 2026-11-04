import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/vote_model.dart';
import 'package:exe_matching/repositories/interfaces/vote_repository.dart';

abstract class VoteState extends Equatable {
  const VoteState();

  @override
  List<Object?> get props => [];
}

class VoteInitialState extends VoteState {}

class VoteLoadingState extends VoteState {}

class VoteSessionLoadedState extends VoteState {
  final VoteSessionModel? session;
  final bool hasVoted; // BR-24: Nguoi dung da bo phieu chua
  final VoteResultModel? result; // Ket qua tong hop (BR-25, BR-26)
  final String? successMessage;

  const VoteSessionLoadedState({
    required this.session,
    required this.hasVoted,
    this.result,
    this.successMessage,
  });

  bool get hasActiveSession => session != null && session!.isActive;

  VoteSessionLoadedState copyWith({
    VoteSessionModel? session,
    bool? hasVoted,
    VoteResultModel? result,
    String? successMessage,
  }) {
    return VoteSessionLoadedState(
      session: session ?? this.session,
      hasVoted: hasVoted ?? this.hasVoted,
      result: result ?? this.result,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [session, hasVoted, result, successMessage];
}

class VoteErrorState extends VoteState {
  final String message;

  const VoteErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
