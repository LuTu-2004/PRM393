import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/user_repository.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/matching_service.dart';
import 'matching_event.dart';
import 'matching_state.dart';

class MatchingBloc extends Bloc<MatchingEvent, MatchingState> {
  final RoomRepository roomRepository;
  final UserRepository userRepository;
  final InvitationRepository invitationRepository;

  MatchingBloc({
    required this.roomRepository,
    required this.userRepository,
    required this.invitationRepository,
  }) : super(MatchingInitialState()) {
    on<LoadMatchingRecommendationsEvent>(_onLoadRecommendations);
    on<SendJoinRequestEvent>(_onSendJoinRequest);
  }

  Future<void> _onLoadRecommendations(
    LoadMatchingRecommendationsEvent event,
    Emitter<MatchingState> emit,
  ) async {
    emit(MatchingLoadingState());
    try {
      // 1. Lay thong tin sinh vien dang dang nhap
      final user = await userRepository.getCurrentUser() ??
          await userRepository.getUserById('uid_se_001') ??
          UserModel(
            id: 'uid_se_001',
            studentCode: 'SE180123',
            email: 'annvse180123@fpt.edu.vn',
            fullName: 'Nguyễn Văn An',
            major: 'SE',
            cohort: 'K18',
            role: 'student',
            skills: const ['Mobile App', 'Flutter', '.NET', 'REST API'],
            orientation: 'Fintech',
            bio: 'Sinh viên SE K18 đam mê lập trình Flutter và khởi nghiệp công nghệ.',
            createdAt: DateTime.now(),
          );

      // 2. Lay danh sach tat ca cac phong
      final allRooms = await roomRepository.getRooms();

      // 3. Tinh toan Matching Recommendations
      final recommendations = MatchingService.calculateMatches(
        student: user,
        allRooms: allRooms,
      );

      // 4. Lay danh sach request dang cho cua sinh vien de kiem soat BR-17 (toi da 3)
      final pendingRequests = await invitationRepository.getSentPendingRequests(user.id);

      emit(MatchingLoadedState(
        currentUser: user,
        recommendations: recommendations,
        pendingSentRequests: pendingRequests,
      ));
    } catch (e) {
      emit(MatchingErrorState('Không thể tải danh sách đề xuất: ${e.toString()}'));
    }
  }

  Future<void> _onSendJoinRequest(
    SendJoinRequestEvent event,
    Emitter<MatchingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MatchingLoadedState) return;

    try {
      // Goi repository de luu request (kiem tra BR-17 ben trong)
      final newRequest = await invitationRepository.sendJoinRequest(
        roomId: event.roomId,
        roomName: event.roomName,
        fromUserId: currentState.currentUser.id,
        fromUserName: currentState.currentUser.fullName,
        toUserId: event.leaderId,
        toUserName: event.leaderName,
        message: event.message,
      );

      // Ghi log Firebase Analytics (Lab 3 requirement)
      await AnalyticsService.logJoinRequestSent(roomId: event.roomId);

      // Cap nhat state moi
      final updatedRequests = List<InvitationModel>.from(currentState.pendingSentRequests)
        ..add(newRequest);

      emit(currentState.copyWith(
        pendingSentRequests: updatedRequests,
        successMessage: 'Đã gửi yêu cầu gia nhập nhóm "${event.roomName}" thành công!',
      ));
    } catch (e) {
      emit(MatchingErrorState(e.toString().replaceAll('Exception: ', '').replaceAll('StateError: ', '')));
      // Reload lai de phuc hoi trang thai
      add(const LoadMatchingRecommendationsEvent());
    }
  }
}
