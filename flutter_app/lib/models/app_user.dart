import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/firestore_utils.dart';

enum UserRole { student, lecturer }

/// BR-05: 5 ky nang tu danh gia, luu thang 0-100 (thang % hay 1-5 dang cho thay chot).
class SkillScores {
  final int tech;
  final int management;
  final int graphicDesign;
  final int marketing;
  final int sale;

  const SkillScores({
    this.tech = 0,
    this.management = 0,
    this.graphicDesign = 0,
    this.marketing = 0,
    this.sale = 0,
  });

  static const labels = {
    'tech': 'Tech',
    'management': 'Management',
    'graphicDesign': 'Graphic Design',
    'marketing': 'Marketing',
    'sale': 'Sale',
  };

  int valueOf(String key) => toMap()[key] ?? 0;

  SkillScores withValue(String key, int value) {
    final map = toMap()..[key] = value.clamp(0, 100);
    return SkillScores.fromMap(map);
  }

  Map<String, int> toMap() => {
    'tech': tech,
    'management': management,
    'graphicDesign': graphicDesign,
    'marketing': marketing,
    'sale': sale,
  };

  factory SkillScores.fromMap(Map<String, dynamic>? map) {
    int read(String key) => ((map?[key] as num?) ?? 0).toInt().clamp(0, 100);
    return SkillScores(
      tech: read('tech'),
      management: read('management'),
      graphicDesign: read('graphicDesign'),
      marketing: read('marketing'),
      sale: read('sale'),
    );
  }
}

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
  final UserRole role;

  /// BR-04: MSSV, nganh, khoa lay tu email/MSSV, sinh vien khong sua duoc.
  final String? studentCode;
  final String? major;
  final String? cohort;

  /// Mon dang hoc. Sinh vien tu chon mon khi khai ho so; mon da co danh sach FAP thi phai co ten.
  final String? courseCode;
  final SkillScores skills;

  /// BR-06: tick cam ket chiu trach nhiem voi khai bao.
  final bool commitmentAccepted;

  /// BR-34: dong y dieu khoan giang vien toan quyen dieu phoi.
  final DateTime? policyAcceptedAt;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.role,
    this.studentCode,
    this.major,
    this.cohort,
    this.courseCode,
    this.skills = const SkillScores(),
    this.commitmentAccepted = false,
    this.policyAcceptedAt,
    this.createdAt,
  });

  bool get isLecturer => role == UserRole.lecturer;
  bool get hasAcceptedPolicy => policyAcceptedAt != null;

  /// BR-07: phai hoan thanh ho so (chon mon + tick cam ket) truoc khi vao Room hoac Apply.
  bool get isProfileComplete => courseCode != null && commitmentAccepted;

  String? get spaceId => courseCode == null ? null : spaceIdFor(AppConfig.currentTerm, courseCode!);

  static String spaceIdFor(String term, String courseCode) => '${term}_$courseCode';

  /// BR-04: tach MSSV tu email, vi du annvse180123@fpt.edu.vn -> SE180123.
  static String? studentCodeFromEmail(String email) {
    final local = email.split('@').first.toLowerCase();
    final match = RegExp(r'([a-z]{2})(\d{6})$').firstMatch(local);
    if (match == null) return null;
    return '${match.group(1)!.toUpperCase()}${match.group(2)}';
  }

  /// BR-04: nganh = 2 chu cai dau MSSV (SE, SS, SA...).
  static String? majorFromStudentCode(String? code) =>
      (code == null || code.length < 2) ? null : code.substring(0, 2);

  /// BR-04: khoa = K + 2 so dau phan so (SE18xxxx -> K18).
  static String? cohortFromStudentCode(String? code) =>
      (code == null || code.length < 4) ? null : 'K${code.substring(2, 4)}';

  AppUser copyWith({
    String? courseCode,
    SkillScores? skills,
    bool? commitmentAccepted,
    DateTime? policyAcceptedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      fullName: fullName,
      photoUrl: photoUrl,
      role: role,
      studentCode: studentCode,
      major: major,
      cohort: cohort,
      courseCode: courseCode ?? this.courseCode,
      skills: skills ?? this.skills,
      commitmentAccepted: commitmentAccepted ?? this.commitmentAccepted,
      policyAcceptedAt: policyAcceptedAt ?? this.policyAcceptedAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'email': email,
    'fullName': fullName,
    'photoUrl': photoUrl,
    'role': role.name,
    'studentCode': studentCode,
    'major': major,
    'cohort': cohort,
    'courseCode': courseCode,
    'skills': skills.toMap(),
    'commitmentAccepted': commitmentAccepted,
    'policyAcceptedAt': writeDate(policyAcceptedAt),
    'createdAt': writeDate(createdAt),
  };

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      // 'moderator' la gia tri cua phien ban cu, van coi la giang vien.
      role: (map['role'] == UserRole.lecturer.name || map['role'] == 'moderator')
          ? UserRole.lecturer
          : UserRole.student,
      studentCode: map['studentCode'] as String?,
      major: map['major'] as String?,
      cohort: map['cohort'] as String?,
      courseCode: map['courseCode'] as String?,
      skills: SkillScores.fromMap(map['skills'] as Map<String, dynamic>?),
      commitmentAccepted: map['commitmentAccepted'] as bool? ?? false,
      policyAcceptedAt: readDate(map['policyAcceptedAt']),
      createdAt: readDate(map['createdAt']),
    );
  }
}
