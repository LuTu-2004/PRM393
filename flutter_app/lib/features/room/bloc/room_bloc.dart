import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';
import 'package:exe_matching/repositories/interfaces/invitation_repository.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final RoomRepository roomRepository;
  final InvitationRepository? invitationRepository;
  String? _currentSubject;
  String _currentKeyword = '';

  RoomBloc({
    required this.roomRepository,
    this.invitationRepository,
  }) : super(RoomInitialState()) {
    on<LoadRoomsEvent>(_onLoadRooms);
    on<FilterSubjectEvent>(_onFilterSubject);
    on<SearchRoomsEvent>(_onSearchRooms);
    on<CreateRoomEvent>(_onCreateRoom);
    on<KickMemberEvent>(_onKickMember);
    on<DirectInviteEvent>(_onDirectInvite);
  }

  Future<void> _onLoadRooms(LoadRoomsEvent event, Emitter<RoomState> emit) async {
    emit(RoomLoadingState());
    _currentSubject = event.subjectCode;
    _currentKeyword = event.searchKeyword ?? '';
    try {
      final rooms = await roomRepository.getRooms(
        subjectCode: _currentSubject,
        searchKeyword: _currentKeyword,
      );
      emit(RoomLoadedState(
        rooms: rooms,
        selectedSubject: _currentSubject,
        searchKeyword: _currentKeyword,
      ));
    } catch (e) {
      emit(RoomErrorState('Không thể tải danh sách phòng: \${e.toString()}'));
    }
  }

  Future<void> _onFilterSubject(FilterSubjectEvent event, Emitter<RoomState> emit) async {
    _currentSubject = event.subjectCode;
    emit(RoomLoadingState());
    try {
      final rooms = await roomRepository.getRooms(
        subjectCode: _currentSubject,
        searchKeyword: _currentKeyword,
      );
      emit(RoomLoadedState(
        rooms: rooms,
        selectedSubject: _currentSubject,
        searchKeyword: _currentKeyword,
      ));
    } catch (e) {
      emit(RoomErrorState(e.toString()));
    }
  }

  Future<void> _onSearchRooms(SearchRoomsEvent event, Emitter<RoomState> emit) async {
    _currentKeyword = event.keyword;
    emit(RoomLoadingState());
    try {
      final rooms = await roomRepository.getRooms(
        subjectCode: _currentSubject,
        searchKeyword: _currentKeyword,
      );
      emit(RoomLoadedState(
        rooms: rooms,
        selectedSubject: _currentSubject,
        searchKeyword: _currentKeyword,
      ));
    } catch (e) {
      emit(RoomErrorState(e.toString()));
    }
  }

  Future<void> _onCreateRoom(CreateRoomEvent event, Emitter<RoomState> emit) async {
    try {
      await roomRepository.createRoom(event.room);
      final rooms = await roomRepository.getRooms(
        subjectCode: _currentSubject,
        searchKeyword: _currentKeyword,
      );
      emit(RoomLoadedState(
        rooms: rooms,
        selectedSubject: _currentSubject,
        searchKeyword: _currentKeyword,
      ));
    } catch (e) {
      emit(RoomErrorState('Không thể tạo phòng: \${e.toString()}'));
    }
  }

  Future<void> _onKickMember(KickMemberEvent event, Emitter<RoomState> emit) async {
    try {
      await roomRepository.removeMember(event.roomId, event.memberId);
      final rooms = await roomRepository.getRooms(
        subjectCode: _currentSubject,
        searchKeyword: _currentKeyword,
      );
      emit(RoomLoadedState(
        rooms: rooms,
        selectedSubject: _currentSubject,
        searchKeyword: _currentKeyword,
        successMessage: '✓ Đã xóa thành viên "${event.memberName}" khỏi phòng!',
      ));
    } catch (e) {
      emit(RoomErrorState('Không thể xóa thành viên: \${e.toString()}'));
    }
  }

  Future<void> _onDirectInvite(DirectInviteEvent event, Emitter<RoomState> emit) async {
    try {
      final invRepo = invitationRepository ?? getIt<InvitationRepository>();
      await invRepo.sendDirectInvite(
        roomId: event.roomId,
        roomName: event.roomName,
        leaderId: event.leaderId,
        leaderName: event.leaderName,
        targetStudentCodeOrEmail: event.targetStudentCodeOrEmail,
        message: event.message,
      );
      final rooms = await roomRepository.getRooms(
        subjectCode: _currentSubject,
        searchKeyword: _currentKeyword,
      );
      emit(RoomLoadedState(
        rooms: rooms,
        selectedSubject: _currentSubject,
        searchKeyword: _currentKeyword,
        successMessage: '✉️ Đã gửi lời mời trực tiếp tới "${event.targetStudentCodeOrEmail}"!',
      ));
    } catch (e) {
      emit(RoomErrorState(e.toString().replaceAll('StateError: ', '').replaceAll('Exception: ', '')));
    }
  }
}
