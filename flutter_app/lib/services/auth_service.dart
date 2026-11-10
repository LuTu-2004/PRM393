import 'package:exe_matching/config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

/// Dang nhap bang Google voi email truong (BR-02). Day la cach dang nhap duy nhat:
/// khong co mat khau, khong co nut demo (BR-01: chi kiem tra duoi email).
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  static bool isSchoolEmail(String? email) {
    final lower = (email ?? '').trim().toLowerCase();
    return lower.endsWith(AppConfig.studentEmailDomain) ||
        lower.endsWith(AppConfig.lecturerEmailDomain);
  }

  static bool isLecturerEmail(String email) =>
      email.trim().toLowerCase().endsWith(AppConfig.lecturerEmailDomain);

  Future<User> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..setCustomParameters({'prompt': 'select_account'});

    final UserCredential credential;
    try {
      credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
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
    if (!isSchoolEmail(user.email)) {
      await _auth.signOut();
      throw const AuthException(
        'Chỉ chấp nhận email trường (@fpt.edu.vn cho sinh viên, @fe.edu.vn cho giảng viên).',
      );
    }
    return user;
  }

  Future<void> signOut() => _auth.signOut();
}
