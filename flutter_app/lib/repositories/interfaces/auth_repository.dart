import 'package:exe_matching/core/models/models.dart';

/// Hop dong Repository cho Phan he Xac thuc & Dang nhap (Auth)
/// Tuan thu BR-01, BR-02, BR-34, BR-37
abstract class AuthRepository {
  /// Lay user hien tai da cache trong phien lam viec (dong bo)
  UserModel? get currentCachedUser;

  /// Lay thong tin user dang dang nhap (neu co)
  Future<UserModel?> getCurrentUser();

  /// BR-02, BR-37: Dang nhap bang Google (@fpt.edu.vn hoac @fe.edu.vn)
  Future<UserModel> signInWithGoogle();

  /// BR-02, BR-04: Dang nhap bang Email FPT bat ky (vd: tulpnse185102@fpt.edu.vn) kem mat khau tuy chon
  /// Tu dong kiem tra hop le BR-02 va trich xuat MSSV, Nganh, Khoa BR-04
  Future<UserModel> signInWithFptEmail(String email, {String? password});

  /// Dang nhap nhanh phuc vu Demo & Chuc nang kiem thu (role = 'student' | 'moderator')
  Future<UserModel> signInDemo({required String role});

  /// BR-34: Luu timestamp khi sinh vien dong y cam ket dieu khoan ghep nhom EXE
  Future<UserModel> acceptPolicy(String userId);

  /// Dang xuat khoi phien lam viec
  Future<void> signOut();
}
