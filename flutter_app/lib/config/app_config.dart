/// Hang so cau hinh chung cua app.
///
/// Thong so nghiep vu cua tung mon (si so, he so du phong, gioi han Apply,
/// han dang ky) KHONG nam o day: giang vien cau hinh trong document
/// `spaces/{spaceId}` (BR-08). Day chi la gia tri mac dinh khi tao Space demo.
class AppConfig {
  AppConfig._();

  /// Ma hoc ky hien tai, dung de ghep spaceId va ma Room (BR-11).
  static const String currentTerm = 'FA26';

  /// Cac mon EXE ma he thong ho tro.
  static const List<String> courses = ['EXE101', 'EXE201'];

  /// Duoi email truong (BR-01, BR-02). Khong co danh sach FAP nen chi kiem tra duoi email.
  static const String studentEmailDomain = '@fpt.edu.vn';
  static const String lecturerEmailDomain = '@fe.edu.vn';

  // --- Gia tri mac dinh khi tao Space demo (BR-08) ---
  static const int defaultMaxGroupSize = 5;
  static const int defaultReservePercent = 120; // he so du phong 1,2
  static const int defaultApplyLimit = 3;
  static const int defaultStudentCount = 40;
  static const Duration defaultRegistrationPeriod = Duration(days: 30);

  /// Do dai toi da loi nhan trong don Apply.
  static const int applicationMessageMaxLength = 300;

  // --- Cloudinary: luu file PDF (khong phai bi mat, khong co API secret trong app) ---
  // Truyen khi chay: flutter run --dart-define-from-file=cloudinary.json
  static const String cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const String cloudinaryUploadPreset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  /// Tai khoan sinh vien duoc vao web giang vien de demo khi nhom khong co email @fe.edu.vn.
  /// Truyen khi chay: --dart-define=DEMO_ADMIN_EMAIL=... (rules cung phai cho phep).
  static const String demoAdminEmail = String.fromEnvironment('DEMO_ADMIN_EMAIL');

  /// Thoi han cuoc bau Leader (BR-19).
  static const Duration leaderElectionDuration = Duration(hours: 24);
}

/// Ten cac collection Firestore.
class Collections {
  Collections._();

  static const String users = 'users';
  static const String spaces = 'spaces';
  static const String rooms = 'rooms';
  static const String memberships = 'memberships';
  static const String applications = 'applications';
  static const String elections = 'elections'; // subcollection cua rooms
  static const String transferRequests = 'transfer_requests';
  static const String reports = 'reports'; // subcollection cua users
  static const String fcmTokens = 'fcm_tokens'; // subcollection cua users
  static const String crashLogs = 'crash_logs';
}
