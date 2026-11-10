import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/firestore_utils.dart';

/// Trang thai don Apply.
enum ApplicationStatus {
  pending('Đang chờ'),
  accepted('Được nhận'),
  rejected('Bị từ chối'),
  cancelled('Tự hủy vì đã vào nhóm khác'), // BR-26
  withdrawn('Đã rút'); // BR-24

  final String label;
  const ApplicationStatus(this.label);

  static ApplicationStatus parse(String? value) => ApplicationStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => ApplicationStatus.pending,
  );
}

/// Don Apply vao mot Group (BR-22 - BR-28).
class RoomApplication {
  final String id;
  final String roomId;
  final String spaceId;
  final String applicantId;
  final String applicantName;
  final String? applicantStudentCode;
  final String? applicantMajor;
  final SkillScores applicantSkills;

  /// Loi nhan ung vien gui kem, sua duoc khi don con cho.
  final String? message;
  final ApplicationStatus status;

  /// BR-25: Leader mo vote cho tung ung vien.
  final bool voteOpen;

  /// BR-25: moi thanh vien mot phieu, true = nhan, false = bo.
  final Map<String, bool> votes;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const RoomApplication({
    required this.id,
    required this.roomId,
    required this.spaceId,
    required this.applicantId,
    required this.applicantName,
    this.applicantStudentCode,
    this.applicantMajor,
    this.applicantSkills = const SkillScores(),
    this.message,
    this.status = ApplicationStatus.pending,
    this.voteOpen = false,
    this.votes = const {},
    required this.createdAt,
    this.decidedAt,
  });

  bool get isPending => status == ApplicationStatus.pending;
  int get acceptVotes => votes.values.where((v) => v).length;
  int get rejectVotes => votes.values.where((v) => !v).length;
  bool hasVoted(String uid) => votes.containsKey(uid);

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'spaceId': spaceId,
    'applicantId': applicantId,
    'applicantName': applicantName,
    'applicantStudentCode': applicantStudentCode,
    'applicantMajor': applicantMajor,
    'applicantSkills': applicantSkills.toMap(),
    'message': message,
    'status': status.name,
    'voteOpen': voteOpen,
    'votes': votes,
    'createdAt': writeDate(createdAt),
    'decidedAt': writeDate(decidedAt),
  };

  factory RoomApplication.fromMap(String id, Map<String, dynamic> map) {
    final rawVotes = (map['votes'] as Map<String, dynamic>?) ?? const {};
    return RoomApplication(
      id: id,
      roomId: map['roomId'] as String? ?? '',
      spaceId: map['spaceId'] as String? ?? '',
      applicantId: map['applicantId'] as String? ?? '',
      applicantName: map['applicantName'] as String? ?? '',
      applicantStudentCode: map['applicantStudentCode'] as String?,
      applicantMajor: map['applicantMajor'] as String?,
      applicantSkills: SkillScores.fromMap(map['applicantSkills'] as Map<String, dynamic>?),
      message: map['message'] as String?,
      status: ApplicationStatus.parse(map['status'] as String?),
      voteOpen: map['voteOpen'] as bool? ?? false,
      votes: rawVotes.map((k, v) => MapEntry(k, v == true)),
      createdAt: readDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      decidedAt: readDate(map['decidedAt']),
    );
  }
}
