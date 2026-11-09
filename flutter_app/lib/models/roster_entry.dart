/// Mot sinh vien trong danh sach FAP cua mot mon (BR-01), luu o `enrollments/{spaceId}_{MSSV}`.
class RosterEntry {
  final String studentCode;
  final String fullName;
  final String? email;

  const RosterEntry({required this.studentCode, required this.fullName, this.email});

  static String idFor(String spaceId, String studentCode) => '${spaceId}_$studentCode';

  bool sameAs(RosterEntry other) =>
      studentCode == other.studentCode && fullName == other.fullName && email == other.email;

  Map<String, dynamic> toMap(String spaceId) => {
    'spaceId': spaceId,
    'studentCode': studentCode,
    'fullName': fullName,
    'email': email,
  };

  factory RosterEntry.fromMap(Map<String, dynamic> map) => RosterEntry(
    studentCode: map['studentCode'] as String? ?? '',
    fullName: map['fullName'] as String? ?? '',
    email: map['email'] as String?,
  );
}
