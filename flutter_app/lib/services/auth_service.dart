import 'dart:async';

import 'package:exe_matching/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// Dang nhap bang Google. Day la cach dang nhap duy nhat: khong co mat khau, khong co nut demo.
/// Ai duoc vao do ViewModel quyet dinh: giang vien theo duoi email @fe.edu.vn, sinh vien phai
/// co email trong danh sach FAP moderator da import (BR-01), ke ca email ca nhan.
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  static bool isLecturerEmail(String email) =>
      email.trim().toLowerCase().endsWith(AppConfig.lecturerEmailDomain);

  Future<User> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});

    final UserCredential credential;
    try {
      if (kIsWeb) {
        credential = await _auth.signInWithPopup(provider);
      } else {
        credential = await _auth.signInWithProvider(provider);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' ||
          e.code == 'canceled' ||
          e.code == 'popup-closed-by-user') {
        throw const AuthException('Bạn đã hủy đăng nhập Google.');
      }
      if (e.code == 'network-request-failed') {
        throw const AuthException('Không có kết nối mạng. Hãy kiểm tra Internet rồi thử lại.');
      }
      throw AuthException('Đăng nhập thất bại (${e.code}).');
    }

    final user = credential.user;
    if (user == null) throw const AuthException('Không nhận được thông tin tài khoản Google.');
    if ((user.email ?? '').isEmpty) {
      await _auth.signOut();
      throw const AuthException('Tài khoản Google này không có email.');
    }
    return user;
  }

  Future<void> signOut() => _auth.signOut();
}
