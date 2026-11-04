import 'package:exe_matching/core/models/models.dart';
import '../interfaces/auth_repository.dart';

/// Mock implementation cua AuthRepository cho phep chay offline, test & demo
/// Tuan thu BR-01, BR-02, BR-34, BR-37
class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  // Tai khoan Sinh vien mau (BR-03, BR-04)
  final UserModel _mockStudent = UserModel(
    id: 'uid_se_001',
    email: 'annvse180123@fpt.edu.vn', // BR-02
    fullName: 'Nguyễn Văn An',
    role: 'student',
    studentCode: 'SE180123',
    major: 'SE',
    cohort: 'K18',
    campus: 'HCM',
    bio: 'Đam mê lập trình Flutter, .NET và xây dựng sản phẩm khởi nghiệp.',
    desiredRole: 'Fullstack / Leader',
    skills: const ['Flutter', 'Dart', 'Firebase', 'C#', '.NET'],
    orientation: 'Fintech Edu',
    isProfileComplete: true, // BR-05
    acceptedPolicyAt: DateTime.now().subtract(const Duration(days: 10)), // BR-34
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  // Tai khoan Giang vien / Dieu phoi vien mau (BR-29 -> BR-33)
  final UserModel _mockModerator = UserModel(
    id: 'uid_mod_001',
    email: 'thaydieuphoi@fe.edu.vn', // BR-02
    fullName: 'Thầy Trần Minh (Ban Điều Phối EXE)',
    role: 'moderator',
    studentCode: null, // Giang vien khong co MSSV
    major: 'SE & Business',
    cohort: null,
    campus: 'HCM',
    bio: 'Ban Điều Phối Chương Trình Khởi Nghiệp Đa Ngành EXE101 & EXE201.',
    desiredRole: 'Moderator / Advisor',
    skills: const ['Mentoring', 'Coordination', 'Project Management'],
    orientation: 'Tech Startups & Impact',
    isProfileComplete: true,
    acceptedPolicyAt: DateTime.now().subtract(const Duration(days: 60)),
    createdAt: DateTime.now().subtract(const Duration(days: 60)),
  );

  MockAuthRepository({UserModel? initialUser, bool startLoggedIn = true}) {
    if (initialUser != null) {
      _currentUser = initialUser;
    } else if (startLoggedIn) {
      _currentUser = _mockStudent;
    } else {
      _currentUser = null;
    }
  }

  @override
  UserModel? get currentCachedUser => _currentUser;

  @override
  Future<UserModel?> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Gia lap Google Sign-In mac dinh voi email truong @fpt.edu.vn (BR-02, BR-37)
    _currentUser = _mockStudent;
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithFptEmail(String email, {String? password}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final trimmed = email.trim();
    if (!isValidFptEmail(trimmed)) {
      throw StateError(
        'BR-02: Chỉ chấp nhận tài khoản email trường Đại học FPT (@fpt.edu.vn hoặc @fe.edu.vn)!',
      );
    }

    final lower = trimmed.toLowerCase();
    final isMod = lower.endsWith('@fe.edu.vn');

    if (isMod) {
      _currentUser = _mockModerator.copyWith(
        email: trimmed,
        fullName: 'Thầy/Cô (${trimmed.split('@').first})',
      );
      return _currentUser!;
    }

    // BR-04: Trich xuat MSSV, Nganh, Khoa tu email (vi du: tulpnse185102@fpt.edu.vn -> SE185102)
    final match = RegExp(r'([a-zA-Z]{2}\d{6})', caseSensitive: false).firstMatch(lower);
    final studentCode = match != null ? match.group(1)!.toUpperCase() : 'SE185102';
    final major = UserModel.extractMajorFromCode(studentCode) ?? 'SE';
    final cohort = UserModel.extractCohortFromCode(studentCode) ?? 'K18';

    _currentUser = UserModel(
      id: 'uid_${studentCode.toLowerCase()}',
      email: trimmed,
      fullName: 'Sinh viên FPT ($studentCode)',
      role: 'student',
      studentCode: studentCode,
      major: major,
      cohort: cohort,
      campus: 'HCM',
      bio: 'Sinh viên Đại học FPT ($studentCode - Khóa $cohort) tham gia môn dự án khởi nghiệp EXE.',
      desiredRole: 'Developer / Team Member',
      skills: const ['Flutter', 'Dart', 'Firebase', 'Teamwork'],
      orientation: 'Fintech Edu Startup',
      isProfileComplete: true,
      acceptedPolicyAt: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    return _currentUser!;
  }

  @override
  Future<UserModel> signInDemo({required String role}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (role == 'moderator') {
      _currentUser = _mockModerator;
    } else {
      _currentUser = _mockStudent;
    }
    return _currentUser!;
  }

  @override
  Future<UserModel> acceptPolicy(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (_currentUser != null && _currentUser!.id == userId) {
      _currentUser = _currentUser!.copyWith(
        acceptedPolicyAt: DateTime.now(), // BR-34: Luu timestamp
      );
      return _currentUser!;
    }
    throw StateError('Không tìm thấy phiên đăng nhập của người dùng để lưu cam kết điều khoản!');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }

  /// Kiem tra email domain FPT hop le (BR-02)
  static bool isValidFptEmail(String email) {
    final lower = email.trim().toLowerCase();
    return lower.endsWith('@fpt.edu.vn') || lower.endsWith('@fe.edu.vn');
  }
}
