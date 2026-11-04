import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/user_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final UserRepository userRepository;

  ProfileBloc({required this.userRepository}) : super(ProfileInitialState()) {
    on<LoadProfileEvent>(_onLoadProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
  }

  Future<void> _onLoadProfile(
    LoadProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoadingState());
    try {
      final user = await userRepository.getCurrentUser() ??
          UserModel(
            id: 'uid_se_001',
            email: 'se001@fpt.edu.vn',
            fullName: 'Nguyễn Văn An',
            role: 'student',
            studentCode: 'SE180123',
            major: 'SE',
            cohort: 'K18',
            campus: 'HCM',
            bio: 'Lập trình viên Flutter đam mê khởi nghiệp công nghệ.',
            desiredRole: 'Leader / Mobile Developer',
            skills: const ['Mobile Development (Flutter)', 'Backend Development', 'Clean Architecture'],
            orientation: 'Technology Startup',
            isProfileComplete: true,
            createdAt: DateTime.now(),
          );

      emit(ProfileLoadedState(user: user));
    } catch (e) {
      emit(ProfileErrorState('Không thể tải thông tin hồ sơ: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfileEvent event,
    Emitter<ProfileState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProfileLoadedState) return;

    emit(currentState.copyWith(isSaving: true));
    try {
      final updated = await userRepository.updateProfile(event.updatedUser);
      emit(ProfileLoadedState(
        user: updated,
        successMessage: '🎉 Hồ sơ của bạn đã được cập nhật thành công!',
        isSaving: false,
      ));
    } catch (e) {
      emit(ProfileErrorState('Lỗi khi cập nhật hồ sơ: ${e.toString()}'));
      add(const LoadProfileEvent());
    }
  }
}
