import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/firestore_utils.dart';
import 'package:exe_matching/services/auth_service.dart';
import 'package:exe_matching/services/group_service.dart';

/// Doc/ghi ho so nguoi dung trong `users/{uid}`.
class UserService {
  final FirebaseFirestore _db;
  final DateTime Function() _now;

  UserService({FirebaseFirestore? firestore, DateTime Function()? clock})
    : _db = firestore ?? FirebaseFirestore.instance,
      _now = clock ?? DateTime.now;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(Collections.users).doc(uid);

  Stream<AppUser?> watchUser(String uid) =>
      _doc(uid).snapshots().map((s) => s.exists ? AppUser.fromMap(s.id, s.data()!) : null);

  /// Tao ho so lan dau dang nhap. MSSV, nganh, khoa lay tu email (BR-04).
  Future<AppUser> ensureUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    final snap = await _doc(uid).get();
    if (snap.exists) return AppUser.fromMap(uid, snap.data()!);

    final isLecturer = AuthService.isLecturerEmail(email);
    final code = isLecturer ? null : AppUser.studentCodeFromEmail(email);
    final user = AppUser(
      uid: uid,
      email: email.toLowerCase(),
      fullName: (displayName?.trim().isNotEmpty ?? false)
          ? displayName!.trim()
          : email.split('@').first,
      photoUrl: photoUrl,
      role: isLecturer ? UserRole.lecturer : UserRole.student,
      studentCode: code,
      major: AppUser.majorFromStudentCode(code),
      cohort: AppUser.cohortFromStudentCode(code),
      createdAt: _now(),
    );
    await _doc(uid).set(user.toMap());
    return user;
  }

  /// Luu FCM token de server biet gui thong bao toi thiet bi nao. Ma tai lieu chinh la token
  /// nen mot thiet bi khong tao ban ghi trung.
  Future<void> saveFcmToken(String uid, String token) =>
      _doc(uid)
          .collection(Collections.fcmTokens)
          .doc(token)
          .set({'updatedAt': writeDate(_now()), 'platform': 'android'});

  Future<void> deleteFcmToken(String uid, String token) =>
      _doc(uid).collection(Collections.fcmTokens).doc(token).delete();

  /// BR-34: dong y dieu khoan lan dau dang nhap.
  Future<void> acceptPolicy(String uid) =>
      _doc(uid).update({'policyAcceptedAt': writeDate(_now())});

  /// BR-05, BR-06: luu ho so. Phai tick cam ket moi luu duoc.
  /// MSSV, nganh, khoa khong nam trong lenh ghi nen sinh vien khong sua duoc (BR-04).
  Future<void> saveProfile({
    required AppUser current,
    required String courseCode,
    required SkillScores skills,
    required bool commitmentAccepted,
  }) async {
    if (!commitmentAccepted) {
      throw const BusinessException('Bạn cần tick ô cam kết chịu trách nhiệm với khai báo.');
    }
    if (!AppConfig.courses.contains(courseCode)) {
      throw const BusinessException('Môn học không hợp lệ.');
    }
    if (current.courseCode != null && current.courseCode != courseCode) {
      throw const BusinessException('Bạn đã chọn môn trước đó, không đổi được.');
    }
    await _doc(current.uid)
        .update({'courseCode': courseCode, 'skills': skills.toMap(), 'commitmentAccepted': true});
  }
}
