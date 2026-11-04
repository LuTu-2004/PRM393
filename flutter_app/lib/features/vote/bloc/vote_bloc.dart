import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/vote_repository.dart';
import 'vote_event.dart';
import 'vote_state.dart';

class VoteBloc extends Bloc<VoteEvent, VoteState> {
  final VoteRepository voteRepository;
  final RoomRepository roomRepository;
  final String currentUserId;

  VoteBloc({
    required this.voteRepository,
    required this.roomRepository,
    this.currentUserId = 'uid_se_001',
  }) : super(VoteInitialState()) {
    on<LoadVoteSessionEvent>(_onLoadVoteSession);
    on<StartVoteSessionEvent>(_onStartVoteSession);
    on<CastVoteEvent>(_onCastVote);
  }

  Future<void> _onLoadVoteSession(
    LoadVoteSessionEvent event,
    Emitter<VoteState> emit,
  ) async {
    emit(VoteLoadingState());
    try {
      final session = await voteRepository.getActiveSession(event.roomId);
      if (session == null) {
        emit(const VoteSessionLoadedState(
          session: null,
          hasVoted: false,
        ));
        return;
      }

      final hasVoted = await voteRepository.hasUserVoted(
        sessionId: session.id,
        userId: currentUserId,
      );

      final result = await voteRepository.getSessionResult(
        sessionId: session.id,
        totalMembers: event.totalMembers,
      );

      emit(VoteSessionLoadedState(
        session: session,
        hasVoted: hasVoted,
        result: result,
      ));
    } catch (e) {
      emit(VoteErrorState('Không thể tải phiên bỏ phiếu: ${e.toString()}'));
    }
  }

  Future<void> _onStartVoteSession(
    StartVoteSessionEvent event,
    Emitter<VoteState> emit,
  ) async {
    emit(VoteLoadingState());
    try {
      // BR-21: Kiem tra so luong thanh vien hop le de mo vote (4 - 5 nguoi)
      if (event.totalMembers < 4) {
        emit(const VoteErrorState('Nhóm cần có ít nhất 4 thành viên mới được mở phiên bỏ phiếu chốt nhóm!'));
        return;
      }

      final session = await voteRepository.createVoteSession(
        roomId: event.roomId,
        leaderId: currentUserId,
      );

      final result = await voteRepository.getSessionResult(
        sessionId: session.id,
        totalMembers: event.totalMembers,
      );

      emit(VoteSessionLoadedState(
        session: session,
        hasVoted: false,
        result: result,
        successMessage: '🗳️ Đã mở phiên bỏ phiếu kín chốt nhóm 24 giờ!',
      ));
    } catch (e) {
      emit(VoteErrorState(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCastVote(
    CastVoteEvent event,
    Emitter<VoteState> emit,
  ) async {
    try {
      await voteRepository.castVote(
        sessionId: event.sessionId,
        voterId: currentUserId,
        isApproved: event.isApproved,
        leaderCandidateId: event.leaderCandidateId,
      );

      final session = await voteRepository.getActiveSession(event.roomId);
      final result = await voteRepository.getSessionResult(
        sessionId: event.sessionId,
        totalMembers: event.totalMembers,
      );

      emit(VoteSessionLoadedState(
        session: session,
        hasVoted: true,
        result: result,
        successMessage: '🎉 Phiếu bầu kín của bạn đã được ghi nhận an toàn!',
      ));
    } catch (e) {
      emit(VoteErrorState(e.toString().replaceAll('StateError: ', '').replaceAll('Exception: ', '')));
      add(LoadVoteSessionEvent(roomId: event.roomId, totalMembers: event.totalMembers));
    }
  }
}
