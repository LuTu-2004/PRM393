import 'package:exe_matching/models/firestore_utils.dart';

enum ElectionStatus { open, passed, failed, expired }

/// BR-19: cuoc bau Leader cho mot ung vien, han 24 gio.
class LeaderElection {
  final String id;
  final String roomId;
  final String candidateId;
  final String candidateName;
  final String initiatorId;
  final List<String> yes;
  final List<String> no;
  final ElectionStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  const LeaderElection({
    required this.id,
    required this.roomId,
    required this.candidateId,
    required this.candidateName,
    required this.initiatorId,
    this.yes = const [],
    this.no = const [],
    this.status = ElectionStatus.open,
    required this.createdAt,
    required this.expiresAt,
  });

  bool hasVoted(String uid) => yes.contains(uid) || no.contains(uid);
  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  /// Cuoc bau con hieu luc (dang mo va chua het han).
  bool isActive(DateTime now) => status == ElectionStatus.open && !isExpired(now);

  Map<String, dynamic> toMap() => {
    'roomId': roomId,
    'candidateId': candidateId,
    'candidateName': candidateName,
    'initiatorId': initiatorId,
    'yes': yes,
    'no': no,
    'status': status.name,
    'createdAt': writeDate(createdAt),
    'expiresAt': writeDate(expiresAt),
  };

  factory LeaderElection.fromMap(String id, Map<String, dynamic> map) {
    return LeaderElection(
      id: id,
      roomId: map['roomId'] as String? ?? '',
      candidateId: map['candidateId'] as String? ?? '',
      candidateName: map['candidateName'] as String? ?? '',
      initiatorId: map['initiatorId'] as String? ?? '',
      yes: List<String>.from(map['yes'] as List<dynamic>? ?? const []),
      no: List<String>.from(map['no'] as List<dynamic>? ?? const []),
      status: ElectionStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => ElectionStatus.open,
      ),
      createdAt: readDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      expiresAt: readDate(map['expiresAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
