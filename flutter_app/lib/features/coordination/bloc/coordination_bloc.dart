import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/coordination_repository.dart';
import 'coordination_event.dart';
import 'coordination_state.dart';

/// BLoC xu ly nghiep vu cho Phan he Giang vien / Dieu phoi vien (Moderator)
/// Tuan thu BR-29, BR-30, BR-31, BR-32, BR-33
class CoordinationBloc extends Bloc<CoordinationEvent, CoordinationState> {
  final CoordinationRepository coordinationRepository;
  String _currentSubject = 'ALL';
  String _currentSemester = 'FALL2026';

  CoordinationBloc({required this.coordinationRepository})
      : super(CoordinationInitialState()) {
    on<LoadCoordinationDashboardEvent>(_onLoadDashboard);
    on<FilterCoordinationSubjectEvent>(_onFilterSubject);
    on<ExtendRegistrationDeadlineEvent>(_onExtendDeadline);
    on<DisbandRoomEvent>(_onDisbandRoom);
    on<SendUrgentAlertEvent>(_onSendUrgentAlert);
  }

  Future<void> _onLoadDashboard(
    LoadCoordinationDashboardEvent event,
    Emitter<CoordinationState> emit,
  ) async {
    emit(CoordinationLoadingState());
    _currentSemester = event.semesterId;
    _currentSubject = event.subjectCode;

    try {
      final results = await Future.wait([
        coordinationRepository.getSemesterProgress(
          semesterId: _currentSemester,
          subjectCode: _currentSubject,
        ),
        coordinationRepository.getAtRiskRooms(
          semesterId: _currentSemester,
          subjectCode: _currentSubject,
        ),
        coordinationRepository.getFinalizedRooms(
          semesterId: _currentSemester,
          subjectCode: _currentSubject,
        ),
      ]);

      emit(CoordinationDashboardLoadedState(
        progress: results[0] as SemesterProgressModel,
        atRiskRooms: results[1] as List<RoomModel>,
        finalizedRooms: results[2] as List<RoomModel>,
        selectedSubject: _currentSubject,
      ));
    } catch (e) {
      emit(CoordinationErrorState('Không thể tải dữ liệu điều phối: $e'));
    }
  }

  Future<void> _onFilterSubject(
    FilterCoordinationSubjectEvent event,
    Emitter<CoordinationState> emit,
  ) async {
    _currentSubject = event.subjectCode;
    add(LoadCoordinationDashboardEvent(
      semesterId: _currentSemester,
      subjectCode: _currentSubject,
    ));
  }

  Future<void> _onExtendDeadline(
    ExtendRegistrationDeadlineEvent event,
    Emitter<CoordinationState> emit,
  ) async {
    try {
      final updatedProgress = await coordinationRepository.updateRegistrationDeadline(
        event.semesterId,
        event.newDeadline,
      );

      if (state is CoordinationDashboardLoadedState) {
        final current = state as CoordinationDashboardLoadedState;
        emit(current.copyWith(
          progress: updatedProgress,
          successMessage: '📅 Đã cập nhật hạn chót đăng ký nhóm thành công!',
        ));
      }
    } catch (e) {
      emit(CoordinationErrorState('Lỗi cập nhật hạn chót: $e'));
    }
  }

  Future<void> _onDisbandRoom(
    DisbandRoomEvent event,
    Emitter<CoordinationState> emit,
  ) async {
    try {
      await coordinationRepository.disbandRoom(event.roomId, event.reason);

      if (state is CoordinationDashboardLoadedState) {
        final current = state as CoordinationDashboardLoadedState;
        final updatedAtRisk = current.atRiskRooms.where((r) => r.id != event.roomId).toList();
        final updatedFinalized = current.finalizedRooms.where((r) => r.id != event.roomId).toList();

        emit(current.copyWith(
          atRiskRooms: updatedAtRisk,
          finalizedRooms: updatedFinalized,
          successMessage: '⚠️ Đã giải tán nhóm "${event.roomId}" theo quyết định của Ban điều phối!',
        ));
      }
    } catch (e) {
      emit(CoordinationErrorState('Lỗi giải tán nhóm: $e'));
    }
  }

  Future<void> _onSendUrgentAlert(
    SendUrgentAlertEvent event,
    Emitter<CoordinationState> emit,
  ) async {
    try {
      await coordinationRepository.sendUrgentAlertToRoom(
        event.roomId,
        'Cảnh báo: Nhóm còn thiếu thành viên trước hạn chót đăng ký!',
      );

      if (state is CoordinationDashboardLoadedState) {
        final current = state as CoordinationDashboardLoadedState;
        emit(current.copyWith(
          successMessage: '🔔 Đã gửi cảnh báo khẩn cấp tới Trưởng nhóm "${event.roomName}"!',
        ));
      }
    } catch (e) {
      emit(CoordinationErrorState('Lỗi gửi thông báo: $e'));
    }
  }
}
