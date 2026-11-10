import 'package:exe_matching/domain/room_rules.dart';
import 'package:exe_matching/models/firestore_utils.dart';

/// 5 trang thai vong doi Room theo docx.
enum RoomStatus {
  empty('Trống'),
  open('Room – vào thẳng'),
  group('Group – chỉ Apply'),
  closed('Đã đủ / đóng tuyển'),
  finalized('Đã chốt sổ');

  final String label;
  const RoomStatus(this.label);

  static RoomStatus parse(String? value) =>
      RoomStatus.values.firstWhere((s) => s.name == value, orElse: () => RoomStatus.empty);
}

class RoomMember {
  final String uid;
  final String fullName;
  final String? studentCode;
  final String? major;
  final String? photoUrl;
  final DateTime joinedAt;

  const RoomMember({
    required this.uid,
    required this.fullName,
    this.studentCode,
    this.major,
    this.photoUrl,
    required this.joinedAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'fullName': fullName,
    'studentCode': studentCode,
    'major': major,
    'photoUrl': photoUrl,
    'joinedAt': writeDate(joinedAt),
  };

  factory RoomMember.fromMap(Map<String, dynamic> map) => RoomMember(
    uid: map['uid'] as String? ?? '',
    fullName: map['fullName'] as String? ?? '',
    studentCode: map['studentCode'] as String?,
    major: map['major'] as String?,
    photoUrl: map['photoUrl'] as String?,
    joinedAt: readDate(map['joinedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
  );
}

class Room {
  final String id; // = code, vi du FA26EXE101-01
  final String spaceId;
  final int number;
  final int maxGroupSize;
  final List<RoomMember> members;
  final String? leaderId;

  /// BR-28: Leader dong tuyen.
  final bool recruitmentClosed;

  /// BR-33: da chot so (dong bo tu Space khi giang vien chot).
  final bool finalized;

  const Room({
    required this.id,
    required this.spaceId,
    required this.number,
    required this.maxGroupSize,
    this.members = const [],
    this.leaderId,
    this.recruitmentClosed = false,
    this.finalized = false,
  });

  String get code => id;
  int get memberCount => members.length;
  int get freeSlots => (maxGroupSize - memberCount).clamp(0, maxGroupSize);
  int get threshold => RoomRules.groupThreshold(maxGroupSize);
  List<String> get memberIds => members.map((m) => m.uid).toList();

  RoomStatus get status => RoomRules.statusFor(
    memberCount: memberCount,
    maxGroupSize: maxGroupSize,
    recruitmentClosed: recruitmentClosed,
    finalized: finalized,
  );

  /// Trang thai khi biet them Space (Space da chot so thi moi Room deu khoa).
  RoomStatus statusIn({required bool spaceFinalized}) =>
      spaceFinalized ? RoomStatus.finalized : status;

  bool hasMember(String uid) => members.any((m) => m.uid == uid);
  bool isLeader(String uid) => leaderId == uid;

  RoomMember? get leader {
    for (final m in members) {
      if (m.uid == leaderId) return m;
    }
    return null;
  }

  Room copyWith({
    List<RoomMember>? members,
    String? leaderId,
    bool clearLeader = false,
    bool? recruitmentClosed,
  }) {
    return Room(
      id: id,
      spaceId: spaceId,
      number: number,
      maxGroupSize: maxGroupSize,
      members: members ?? this.members,
      leaderId: clearLeader ? null : (leaderId ?? this.leaderId),
      recruitmentClosed: recruitmentClosed ?? this.recruitmentClosed,
      finalized: finalized,
    );
  }

  Map<String, dynamic> toMap() => {
    'spaceId': spaceId,
    'number': number,
    'maxGroupSize': maxGroupSize,
    'members': members.map((m) => m.toMap()).toList(),
    // Luu rieng memberIds de query array-contains va de Security Rules kiem tra.
    'memberIds': memberIds,
    'memberCount': memberCount,
    'leaderId': leaderId,
    'recruitmentClosed': recruitmentClosed,
    'finalized': finalized,
    // Luu status de loc tren server (BR-13).
    'status': status.name,
  };

  factory Room.fromMap(String id, Map<String, dynamic> map) {
    final rawMembers = (map['members'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(RoomMember.fromMap)
        .toList();
    return Room(
      id: id,
      spaceId: map['spaceId'] as String? ?? '',
      number: (map['number'] as num?)?.toInt() ?? 0,
      maxGroupSize: (map['maxGroupSize'] as num?)?.toInt() ?? 5,
      members: rawMembers,
      leaderId: map['leaderId'] as String?,
      recruitmentClosed: map['recruitmentClosed'] as bool? ?? false,
      finalized: map['finalized'] as bool? ?? false,
    );
  }
}
