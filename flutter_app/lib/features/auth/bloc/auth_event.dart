import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Kiem tra trang thai dang nhap khoi tao
class CheckAuthStatusEvent extends AuthEvent {}

/// BR-02, BR-37: Dang nhap bang Google truong (@fpt.edu.vn)
class SignInWithGoogleEvent extends AuthEvent {}

/// BR-02, BR-04: Dang nhap bang Email FPT va Mat khau nhap tay
class SignInWithFptEmailEvent extends AuthEvent {
  final String email;
  final String? password;

  const SignInWithFptEmailEvent(this.email, {this.password});

  @override
  List<Object?> get props => [email, password];
}

/// Dang nhap nhanh phuc vu Demo (role = 'student' | 'moderator')
class SignInDemoEvent extends AuthEvent {
  final String role;

  const SignInDemoEvent({required this.role});

  @override
  List<Object?> get props => [role];
}

/// BR-34: Chap nhan dieu khoan va cam ket quy che ghep nhom EXE
class AcceptTermsEvent extends AuthEvent {
  final String userId;

  const AcceptTermsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Dang xuat khoi he thong
class SignOutEvent extends AuthEvent {}
