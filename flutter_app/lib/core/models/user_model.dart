import 'package:equatable/equatable.dart';

/// Model nguoi dung he thong (Sinh vien / Moderator)
/// Tuan thu BR-01, BR-02, BR-03, BR-04, BR-05, BR-34, BR-37
/// Tuong thich OpenAPI UserProfileResponse tu PRN232
class UserModel extends Equatable {
  final String id;
  final String email; // BR-02: Email truong (@fpt.edu.vn)
  final String fullName;
  final String role; // 'student' | 'moderator'
  final String? studentCode; // BR-03, BR-04: MSSV (NULL neu la Giang vien)
  final String? major; // BR-04: Nganh tu trich xuat (SE, BA, MKT...)
  final String? cohort; // BR-04: Khoa hoc (K18, K19...)
  final String? campus; // Co so (HCM, HN, DN...)
  final String? bio;
  final String? desiredRole; // Vai tro mong muon trong nhom
  final List<String> skills; // Danh sach ky nang
  final String? orientation; // Dinh huong khoi nghiep
  final bool isProfileComplete; // BR-05: Da hoan thien ho so hay chua
  final DateTime? acceptedPolicyAt; // BR-34: Dong y dieu khoan lan dau
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.role = 'student',
    this.studentCode,
    this.major,
    this.cohort,
    this.campus = 'HCM',
    this.bio,
    this.desiredRole,
    this.skills = const [],
    this.orientation,
    this.isProfileComplete = false,
    this.acceptedPolicyAt,
    required this.createdAt,
  });

  bool get isStudent => role == 'student';
  bool get isModerator => role == 'moderator';

  /// BR-04: Tu dong trich xuat chuyen nganh tu MSSV (vi du: SE180123 -> SE)
  static String? extractMajorFromCode(String? code) {
    if (code == null || code.trim().length < 2) return null;
    final letters = code.replaceAll(RegExp(r'[^a-zA-Z]'), '').toUpperCase();
    return letters.isNotEmpty ? letters : null;
  }

  /// BR-04: Tu dong trich xuat khoa hoc tu MSSV (vi du: SE180123 -> K18)
  static String? extractCohortFromCode(String? code) {
    if (code == null) return null;
    final match = RegExp(r'\d{2}').firstMatch(code);
    return match != null ? 'K' + match.group(0)! : null;
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? studentCode,
    String? major,
    String? cohort,
    String? campus,
    String? bio,
    String? desiredRole,
    List<String>? skills,
    String? orientation,
    bool? isProfileComplete,
    DateTime? acceptedPolicyAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      studentCode: studentCode ?? this.studentCode,
      major: major ?? this.major,
      cohort: cohort ?? this.cohort,
      campus: campus ?? this.campus,
      bio: bio ?? this.bio,
      desiredRole: desiredRole ?? this.desiredRole,
      skills: skills ?? this.skills,
      orientation: orientation ?? this.orientation,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      acceptedPolicyAt: acceptedPolicyAt ?? this.acceptedPolicyAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'studentCode': studentCode,
      'major': major,
      'cohort': cohort,
      'campus': campus,
      'bio': bio,
      'desiredRole': desiredRole,
      'skills': skills,
      'orientation': orientation,
      'isProfileComplete': isProfileComplete,
      'acceptedPolicyAt': acceptedPolicyAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final effectiveId = id ?? map['id'] ?? map['userId'] ?? '';
    var code = map['studentCode'] as String?;
    final email = map['email'] as String? ?? '';
    // Tu dong sua neu MSSV chua dung hoac bi dinh chuoi tu email
    if (code == null || code == 'TULPNSEFPTEDUVN' || code.length > 8 || !RegExp(r'^[a-zA-Z]{2}\d{6}$').hasMatch(code)) {
      final m = RegExp(r'([a-zA-Z]{2}\d{6})', caseSensitive: false).firstMatch(email);
      if (m != null) {
        code = m.group(1)!.toUpperCase();
      }
    }
    final cleanMajor = (map['major'] == 'TULPNSEFPTEDUVN' || map['major'] == null || map['major'].toString().length > 4)
        ? (extractMajorFromCode(code) ?? 'SE')
        : map['major'].toString();
    final cleanCohort = map['cohort'] ?? extractCohortFromCode(code) ?? 'K18';

    return UserModel(
      id: effectiveId,
      email: email,
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'student',
      studentCode: code,
      major: cleanMajor,
      cohort: cleanCohort,
      campus: map['campus'] ?? 'HCM',
      bio: map['bio'],
      desiredRole: map['desiredRole'],
      skills: map['skills'] != null ? List<String>.from(map['skills']) : const [],
      orientation: map['orientation'],
      isProfileComplete: map['isProfileComplete'] ?? false,
      acceptedPolicyAt: map['acceptedPolicyAt'] != null
          ? DateTime.tryParse(map['acceptedPolicyAt'].toString())
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        role,
        studentCode,
        major,
        cohort,
        skills,
        isProfileComplete,
      ];
}
