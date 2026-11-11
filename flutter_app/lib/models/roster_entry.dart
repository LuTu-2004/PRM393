/// Mot sinh vien trong danh sach FAP cua mot mon (BR-01), luu o `enrollments/{spaceId}_{MSSV}`.
/// [className] la lop trong FAP (vi du SE1919). Mot mon co nhieu lop, moi file FAP la mot lop.
class RosterEntry {
  final String studentCode;
  final String fullName;
  final String? email;
  final String? className;

  const RosterEntry({
    required this.studentCode,
    required this.fullName,
    this.email,
    this.className,
  });

  static String idFor(String spaceId, String studentCode) => '${spaceId}_$studentCode';

  bool sameAs(RosterEntry other) =>
      studentCode == other.studentCode &&
      fullName == other.fullName &&
      email == other.email &&
      className == other.className;

  Map<String, dynamic> toMap(String spaceId) => {
    'spaceId': spaceId,
    'studentCode': studentCode,
    'fullName': fullName,
    'email': email,
    'className': className,
  };

  factory RosterEntry.fromMap(Map<String, dynamic> map) => RosterEntry(
    studentCode: map['studentCode'] as String? ?? '',
    fullName: map['fullName'] as String? ?? '',
    email: map['email'] as String?,
    className: map['className'] as String?,
  );
}
