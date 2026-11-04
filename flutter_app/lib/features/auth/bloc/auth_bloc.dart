import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/repositories/interfaces/auth_repository.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC quan ly phien dang nhap & phan quyen
/// Tuan thu BR-01, BR-02, BR-34, BR-37
/// Tich hop Analytics va Crashlytics theo tieu chi Lab 3
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository})
      : super(
          authRepository.currentCachedUser != null
              ? AuthenticatedState(user: authRepository.currentCachedUser!)
              : AuthInitialState(),
        ) {
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInWithGoogleEvent>(_onSignInWithGoogle);
    on<SignInWithFptEmailEvent>(_onSignInWithFptEmail);
    on<SignInDemoEvent>(_onSignInDemo);
    on<AcceptTermsEvent>(_onAcceptTerms);
    on<SignOutEvent>(_onSignOut);
  }

  void _trackUserSession(UserModel user) {
    AnalyticsService.setCurrentUser(user.id);
    AnalyticsService.logSignIn(
      role: user.isModerator ? 'moderator' : 'student',
      major: user.major,
      cohort: user.cohort,
    );
    CrashlyticsService.setUserIdentifier(user.id);
    CrashlyticsService.setCustomKey('user_role', user.isModerator ? 'moderator' : 'student');
  }

  Future<void> _onSignInWithFptEmail(
    SignInWithFptEmailEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.signInWithFptEmail(
        event.email,
        password: event.password,
      );

      // BR-34: Kiem tra neu chua xac nhan dieu khoan
      if (user.acceptedPolicyAt == null) {
        emit(NeedsTermsAcceptanceState(user));
      } else {
        _trackUserSession(user);
        final roleLabel = user.isModerator ? 'Giảng Viên' : 'Sinh Viên';
        final codeLabel = user.studentCode != null ? ' (${user.studentCode})' : '';
        emit(AuthenticatedState(
          user: user,
          message: '🎉 Đăng nhập thành công $roleLabel: ${user.fullName}$codeLabel!',
        ));
      }
    } catch (e) {
      emit(UnauthenticatedState(
        errorMessage: e.toString().replaceAll('StateError: ', '').replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatusEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.getCurrentUser();
      if (user == null) {
        emit(const UnauthenticatedState());
        return;
      }

      // BR-34: Kiem tra nguoi dung da dong y dieu khoan lan dau chua
      if (user.acceptedPolicyAt == null) {
        emit(NeedsTermsAcceptanceState(user));
      } else {
        _trackUserSession(user);
        emit(AuthenticatedState(user: user));
      }
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: e.toString()));
    }
  }

  Future<void> _onSignInWithGoogle(
    SignInWithGoogleEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.signInWithGoogle();

      // BR-34: Kiem tra neu chua xac nhan dieu khoan
      if (user.acceptedPolicyAt == null) {
        emit(NeedsTermsAcceptanceState(user));
      } else {
        _trackUserSession(user);
        emit(AuthenticatedState(
          user: user,
          message: '🎉 Đăng nhập thành công với tài khoản ${user.email}!',
        ));
      }
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: 'Lỗi đăng nhập Google: $e'));
    }
  }

  Future<void> _onSignInDemo(
    SignInDemoEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final user = await authRepository.signInDemo(role: event.role);

      // BR-34: Kiem tra neu chua xac nhan dieu khoan
      if (user.acceptedPolicyAt == null) {
        emit(NeedsTermsAcceptanceState(user));
      } else {
        _trackUserSession(user);
        final roleLabel = user.isModerator ? 'Giảng Viên (Moderator)' : 'Sinh Viên';
        emit(AuthenticatedState(
          user: user,
          message: 'Đăng nhập thành công với vai trò $roleLabel: ${user.fullName}',
        ));
      }
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: 'Lỗi đăng nhập: $e'));
    }
  }

  Future<void> _onAcceptTerms(
    AcceptTermsEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      final updatedUser = await authRepository.acceptPolicy(event.userId);
      _trackUserSession(updatedUser);
      emit(AuthenticatedState(
        user: updatedUser,
        message: '✓ Bạn đã đồng ý cam kết quy chế môn học EXE!',
      ));
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: 'Không thể lưu cam kết điều khoản: $e'));
    }
  }

  Future<void> _onSignOut(
    SignOutEvent event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoadingState());
    try {
      await AnalyticsService.logSignOut();
      await authRepository.signOut();
      emit(const UnauthenticatedState());
    } catch (e) {
      emit(UnauthenticatedState(errorMessage: 'Lỗi đăng xuất: $e'));
    }
  }
}
