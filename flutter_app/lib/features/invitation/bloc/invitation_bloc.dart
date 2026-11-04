import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'invitation_event.dart';
import 'invitation_state.dart';

class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  final InvitationRepository invitationRepository;
  final RoomRepository roomRepository;
  final String currentUserId;

  InvitationBloc({
    required this.invitationRepository,
    required this.roomRepository,
    this.currentUserId = 'uid_se_001',
  }) : super(InvitationInitialState()) {
    on<LoadInvitationsEvent>(_onLoadInvitations);
    on<CancelSentRequestEvent>(_onCancelSentRequest);
    on<RespondInvitationEvent>(_onRespondInvitation);
  }

  Future<void> _onLoadInvitations(
    LoadInvitationsEvent event,
    Emitter<InvitationState> emit,
  ) async {
    emit(InvitationLoadingState());
    try {
      final sent = await invitationRepository.getSentRequests(currentUserId);
      final received = await invitationRepository.getReceivedInvitations(currentUserId);

      emit(InvitationLoadedState(
        sentRequests: sent,
        receivedInvitations: received,
      ));
    } catch (e) {
      emit(InvitationErrorState('Không thể tải danh sách lời mời: ${e.toString()}'));
    }
  }

  Future<void> _onCancelSentRequest(
    CancelSentRequestEvent event,
    Emitter<InvitationState> emit,
  ) async {
    try {
      await invitationRepository.cancelRequest(event.requestId);
      final sent = await invitationRepository.getSentRequests(currentUserId);
      final received = await invitationRepository.getReceivedInvitations(currentUserId);

      emit(InvitationLoadedState(
        sentRequests: sent,
        receivedInvitations: received,
        successMessage: 'Đã hủy yêu cầu. Bạn đã được hoàn lại 1 lượt gửi yêu cầu!',
      ));
    } catch (e) {
      emit(InvitationErrorState('Không thể hủy yêu cầu: ${e.toString()}'));
    }
  }

  Future<void> _onRespondInvitation(
    RespondInvitationEvent event,
    Emitter<InvitationState> emit,
  ) async {
    try {
      if (event.accept) {
        // 1. Kiem tra canh bao da dang chuyen nganh (BR-18, BR-19)
        if (!event.forceAccept) {
          final willExceed = await roomRepository.willExceedMajorDiversity(
            event.roomId,
            event.applicantMajor,
          );

          if (willExceed) {
            final room = await roomRepository.getRoomById(event.roomId);
            final sameMajorCount = room != null
                ? room.members.where((m) => m.major.toUpperCase() == event.applicantMajor.toUpperCase()).length + 1
                : 1;
            final totalAfter = room != null ? room.members.length + 1 : 1;
            final ratio = sameMajorCount / totalAfter;

            // Ghi log su kien canh bao len Analytics (Lab 3 requirement)
            await AnalyticsService.logMajorWarningShown(
              roomId: event.roomId,
              ratio: ratio,
            );

            // Emit state canh bao de UI hien AlertDialog xac nhan
            emit(DiversityWarningPromptState(
              pendingEvent: event,
              projectedRatio: ratio,
            ));
            return;
          }
        }

        // 2. Chap nhan ung vien va them vao phong (BR-08: Max 5 thanh vien)
        await invitationRepository.respondToRequest(
          requestId: event.requestId,
          accept: true,
        );

        final newMember = RoomMemberModel(
          userId: event.applicantId,
          fullName: event.applicantName,
          studentCode: event.studentCode ?? 'ST180000',
          major: event.applicantMajor,
          role: 'Member',
          joinedAt: DateTime.now(),
        );

        await roomRepository.joinRoom(event.roomId, newMember);

        final sent = await invitationRepository.getSentRequests(currentUserId);
        final received = await invitationRepository.getReceivedInvitations(currentUserId);

        emit(InvitationLoadedState(
          sentRequests: sent,
          receivedInvitations: received,
          successMessage: '🎉 Đã duyệt "${event.applicantName}" vào nhóm thành công!',
        ));
      } else {
        // Tu choi ung vien
        await invitationRepository.respondToRequest(
          requestId: event.requestId,
          accept: false,
        );

        final sent = await invitationRepository.getSentRequests(currentUserId);
        final received = await invitationRepository.getReceivedInvitations(currentUserId);

        emit(InvitationLoadedState(
          sentRequests: sent,
          receivedInvitations: received,
          successMessage: 'Đã từ chối yêu cầu của "${event.applicantName}".',
        ));
      }
    } catch (e) {
      emit(InvitationErrorState(e.toString().replaceAll('Exception: ', '')));
      add(const LoadInvitationsEvent());
    }
  }
}
