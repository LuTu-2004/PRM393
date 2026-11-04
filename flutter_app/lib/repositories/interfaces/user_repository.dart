import 'package:exe_matching/core/models/models.dart';

/// Hop dong Repository quan ly Nguoi dung & Ho so sinh vien
/// Tuan thu BR-01, BR-02, BR-04, BR-05, BR-34, BR-37
abstract class UserRepository {
  /// Lay thong tin user dang dang nhap
  Future<UserModel?> getCurrentUser();

  /// Lay thong tin user theo ID
  Future<UserModel?> getUserById(String id);

  /// Dang nhap bang Google SSO @fpt.edu.vn (BR-02, BR-37)
  Future<UserModel> loginWithGoogle(String email, {String? fullName});

  /// Dang xuat
  Future<void> logout();

  /// Cap nhat ho so sinh vien (ky nang, dinh huong) (BR-05)
  Future<UserModel> updateProfile(UserModel user);

  /// Lay danh sach sinh vien theo chuyen nganh hoac ky nang de moi (BR-11, BR-14)
  Future<List<UserModel>> getStudents({String? major, String? skillKeyword});
}
