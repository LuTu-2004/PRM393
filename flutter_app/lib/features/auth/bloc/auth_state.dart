import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/models/models.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class UnauthenticatedState extends AuthState {
  final String? errorMessage;

  const UnauthenticatedState({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

/// BR-34: Nguoi dung da dang nhap nhung can dong y cam ket dieu khoan lan dau
class NeedsTermsAcceptanceState extends AuthState {
  final UserModel user;

  const NeedsTermsAcceptanceState(this.user);

  @override
  List<Object?> get props => [user];
}

/// Da xac thuc va dong y dieu khoan thanh cong
class AuthenticatedState extends AuthState {
  final UserModel user;
  final String? message;

  const AuthenticatedState({
    required this.user,
    this.message,
  });

  bool get isModerator => user.isModerator;
  bool get isStudent => user.isStudent;

  @override
  List<Object?> get props => [user, message];
}
