import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/interfaces/user_repository.dart';

/// Mock Implementation cua UserRepository
/// Tuan thu BR-02 (@fpt.edu.vn), BR-04, BR-05, BR-34, BR-37
class MockUserRepository implements UserRepository {
  UserModel? _currentUser;
  final List<UserModel> _students = [];

  MockUserRepository() {
    _initMockData();
  }

  void _initMockData() {
    final now = DateTime.now();

    // Default current logged in user: Nguyen Van An (Leader Alpha Team)
    _currentUser = UserModel(
      id: 'uid_se_001',
      email: 'se001@fpt.edu.vn',
      fullName: 'Nguyễn Văn An',
      role: 'student',
      studentCode: 'SE180123',
      major: 'SE',
      cohort: 'K18',
      campus: 'HCM',
      bio: 'Lap trinh vien Flutter dam me khoi nghiep cong nghe',
      desiredRole: 'Leader / Mobile Developer',
      skills: const ['Mobile Development (Flutter)', 'Backend Development', 'Clean Architecture'],
      orientation: 'Technology Startup',
      isProfileComplete: true,
      acceptedPolicyAt: now.subtract(const Duration(days: 30)),
      createdAt: now.subtract(const Duration(days: 30)),
    );

    _students.addAll([
      _currentUser!,
      UserModel(
        id: 'uid_se_002',
        email: 'se002@fpt.edu.vn',
        fullName: 'Tran Thi Bich',
        role: 'student',
        studentCode: 'SE180456',
        major: 'SE',
        cohort: 'K18',
        campus: 'HCM',
        bio: 'Frontend developer yeu thich UI/UX',
        desiredRole: 'Frontend Developer',
        skills: const ['Frontend Development', 'UI/UX Design', 'React'],
        orientation: 'EdTech',
        isProfileComplete: true,
        createdAt: now.subtract(const Duration(days: 25)),
      ),
      UserModel(
        id: 'uid_ba_002',
        email: 'ba002@fpt.edu.vn',
        fullName: 'Hoang Van Em',
        role: 'student',
        studentCode: 'BA180222',
        major: 'BA',
        cohort: 'K18',
        campus: 'HCM',
        bio: 'Chuyen gia phan tich mo hinh kinh doanh va tai chinh',
        desiredRole: 'Leader / Business Analyst',
        skills: const ['Business Analysis', 'Finance', 'Project Management'],
        orientation: 'FinTech',
        isProfileComplete: true,
        createdAt: now.subtract(const Duration(days: 20)),
      ),
      UserModel(
        id: 'uid_mkt_001',
        email: 'mkt001@fpt.edu.vn',
        fullName: 'Vo Thi Phuong',
        role: 'student',
        studentCode: 'MKT180333',
        major: 'MKT',
        cohort: 'K18',
        campus: 'HCM',
        bio: 'Digital Marketing, am hieu tang truong nguoi dung',
        desiredRole: 'Marketing Lead',
        skills: const ['Marketing', 'Content Creation', 'SEO'],
        orientation: 'Technology Startup',
        isProfileComplete: true,
        createdAt: now.subtract(const Duration(days: 15)),
      ),
      // Moderator
      UserModel(
        id: 'uid_mod_001',
        email: 'ha_lecturer@fpt.edu.vn',
        fullName: 'Nguyen Thi Thu Ha',
        role: 'moderator',
        campus: 'HCM',
        isProfileComplete: true,
        createdAt: now.subtract(const Duration(days: 60)),
      ),
    ]);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserModel?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _students.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> loginWithGoogle(String email, {String? fullName}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // BR-02: Bat buoc dung email truong @fpt.edu.vn
    if (!email.toLowerCase().endsWith('@fpt.edu.vn')) {
      throw Exception('BR-02: Chi chap nhan tai khoan email truong (@fpt.edu.vn)');
    }

    try {
      final existing = _students.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );
      _currentUser = existing;
      return existing;
    } catch (_) {
      // Tao moi neu chua co
      final newUser = UserModel(
        id: 'uid_',
        email: email,
        fullName: fullName ?? email.split('@')[0],
        role: 'student',
        isProfileComplete: false,
        createdAt: DateTime.now(),
      );
      _students.add(newUser);
      _currentUser = newUser;
      return newUser;
    }
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _students.indexWhere((u) => u.id == user.id);
    final updated = user.copyWith(
      isProfileComplete: user.skills.isNotEmpty && user.orientation != null,
    );
    if (index != -1) {
      _students[index] = updated;
    } else {
      _students.add(updated);
    }
    if (_currentUser?.id == user.id) {
      _currentUser = updated;
    }
    return updated;
  }

  @override
  Future<List<UserModel>> getStudents({String? major, String? skillKeyword}) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _students.where((u) {
      if (u.role != 'student') return false;
      if (major != null && major.isNotEmpty && u.major != major) return false;
      if (skillKeyword != null && skillKeyword.isNotEmpty) {
        final kw = skillKeyword.toLowerCase();
        final hasSkill = u.skills.any((s) => s.toLowerCase().contains(kw));
        if (!hasSkill) return false;
      }
      return true;
    }).toList();
  }
}
