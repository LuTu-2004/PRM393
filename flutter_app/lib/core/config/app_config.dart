// ==============================================================
// app_config.dart
// Diem kiem soat trung tam: Mock vs Firebase + Hang so nghiep vu
// Doc AI_GUIDELINES.md Phan 4 truoc khi sua file nay
// ==============================================================

class AppConfig {
  // ============================================================
  // DOI GIA TRI NAY DE CHUYEN GIUA MOCK VA FIREBASE THAT
  //
  // true  = MockRepository (offline, test UI, demo khong can mang)
  // false = FirebaseRepository (ket noi Firestore that)
  // ============================================================
  static const bool USE_MOCK_DATA = false;

  // --- Hang so nghiep vu (BR) ---
  // Khong duoc sua cac gia tri nay ma khong co su dong y cua ca nhom

  /// BR-07: So thanh vien toi thieu cua 1 nhom
  static const int TEAM_MIN_MEMBERS = 4;

  /// BR-08: So thanh vien toi da cua 1 nhom
  static const int TEAM_MAX_MEMBERS = 5;

  /// BR-17: Toi da so request dang cho (pending) cung luc
  static const int MAX_PENDING_REQUESTS = 3;

  /// BR-18: Nguong ty le cung chuyen nganh toi da (50%)
  static const double MAX_SAME_MAJOR_RATIO = 0.5;

  /// BR-20: Thoi gian het han cua request (gio)
  static const int REQUEST_EXPIRY_HOURS = 48;

  /// BR-22: Thoi gian bo phieu (gio)
  static const int VOTING_DURATION_HOURS = 24;

  // --- Thong tin Firebase (chi dung khi USE_MOCK_DATA = false) ---
  // Khong commit key that len Git! Dung .env hoac firebase_options.dart
  static const String FIREBASE_PROJECT_ID = 'exe-team-matching-prmxxx';
}
