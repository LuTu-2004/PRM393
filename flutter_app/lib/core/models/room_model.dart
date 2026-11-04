import 'package:equatable/equatable.dart';
import 'package:exe_matching/core/config/app_config.dart';

/// Thanh vien trong phong
class RoomMemberModel extends Equatable {
  final String userId;
  final String fullName;
  final String? studentCode;
  final String major; // Chuyen nganh (SE, BA, MKT...)
  final String role; // 'Leader' | 'Member'
  final DateTime joinedAt;

  const RoomMemberModel({
    required this.userId,
    required this.fullName,
    this.studentCode,
    required this.major,
    this.role = 'Member',
    required this.joinedAt,
  });

  bool get isLeader => role == 'Leader';

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'studentCode': studentCode,
      'major': major,
      'role': role,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory RoomMemberModel.fromMap(Map<String, dynamic> map) {
    return RoomMemberModel(
      userId: map['userId'] ?? '',
      fullName: map['fullName'] ?? '',
      studentCode: map['studentCode'],
      major: map['major'] ?? '',
      role: map['role'] ?? 'Member',
      joinedAt: map['joinedAt'] != null
          ? DateTime.parse(map['joinedAt'].toString())
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, major, role];
}

/// Model Phong ghep nhom EXE
/// Tuan thu BR-07 (Min 4), BR-08 (Max 5), BR-09, BR-10, BR-18, BR-19
/// Tuong thich OpenAPI GroupDetailResponse tu PRN232
class RoomModel extends Equatable {
  final String id;
  final String name; // BR-09: Ten phong
  final String description; // BR-09: Mo ta y tuong du an
  final String subjectCode; // BR-09: Mon hoc ('EXE101' | 'EXE201')
  final String semesterId; // BR-09: Hoc ky (e.g. 'FALL2026')
  final String leaderId;
  final String leaderName;
  final bool isPublic; // BR-10: Cong khai hay Rieng tu
  final String status; // 'open' | 'full' | 'closed' | 'confirmed'
  final int maxMembers; // BR-08: Toi da 5 nguoi
  final int minMembers; // BR-07: Toi thieu 4 nguoi
  final List<RoomMemberModel> members;
  final DateTime createdAt;

  const RoomModel({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectCode,
    required this.semesterId,
    required this.leaderId,
    required this.leaderName,
    this.isPublic = true,
    this.status = 'open',
    this.maxMembers = AppConfig.TEAM_MAX_MEMBERS,
    this.minMembers = AppConfig.TEAM_MIN_MEMBERS,
    this.members = const [],
    required this.createdAt,
  });

  int get memberCount => members.length;

  /// Quy tac "Chia Chuong": Ma chuong chuan hoa [Mã học kỳ][Mã môn]-[Số thứ tự] (VD: FA26EXE101-01)
  String get roomCode {
    if (id.startsWith('FA26') || id.startsWith('SP26') || id.startsWith('SU26')) {
      return id;
    }
    final sem = semesterId.replaceAll('FALL20', 'FA').replaceAll('SPRING20', 'SP').replaceAll('SUMMER20', 'SU').replaceAll('FALL', 'FA');
    final numStr = id.replaceAll(RegExp(r'[^0-9]'), '');
    final paddedNum = numStr.isNotEmpty ? numStr.padLeft(2, '0') : '01';
    return '$sem$subjectCode-$paddedNum';
  }

  /// Ten nhan biet phong theo so thu tu de dang nhan dien (VD: Nhóm 1, Nhóm 2...)
  String get displayGroupName {
    if (name.startsWith('Nhóm ') || name.startsWith('Phòng ')) {
      return name;
    }
    if (id == 'room_001' || name.contains('Alpha Team')) {
      return 'Nhóm 1 (Phòng 01)';
    }
    if (id == 'room_002' || name.contains('Beta Startup')) {
      return 'Nhóm 2 (Phòng 02)';
    }
    if (id == 'room_003' || name.contains('EcoPackaging')) {
      return 'Nhóm 3 (Phòng 03)';
    }
    return name;
  }

  /// Kiem tra phong co phai la chuong trong chua co ai nhan hay khong
  bool get isEmptyRoom => members.isEmpty;

  /// BR-08: Kiem tra phong da du thanh vien toi da (5 nguoi) chua
  bool get isFull => memberCount >= maxMembers;

  /// BR-07: Kiem tra phong da dat so luong toi thieu (4 nguoi) de dong nhom chua
  bool get isQualified => memberCount >= minMembers;

  /// BR-18: Tinh ty le % thanh vien thuoc chuyen nganh [major]
  double getMajorRatio(String major) {
    if (members.isEmpty) return 0.0;
    final count = members
        .where((m) => m.major.trim().toUpperCase() == major.trim().toUpperCase())
        .length;
    return count / members.length;
  }

  /// BR-18 & BR-19: Kiem tra xem phong co vuot nguong 50% cung chuyen nganh khong
  bool isMajorDiversityExceeded() {
    if (members.isEmpty) return false;
    final counts = <String, int>{};
    for (final m in members) {
      final maj = m.major.trim().toUpperCase();
      counts[maj] = (counts[maj] ?? 0) + 1;
    }
    for (final cnt in counts.values) {
      if (cnt / members.length > AppConfig.MAX_SAME_MAJOR_RATIO) {
        return true;
      }
    }
    return false;
  }

  /// Tra ve chuyen nganh chiem ty le cao nhat va ty le do (dung cho UI canh bao)
  MapEntry<String, double>? getDominantMajor() {
    if (members.isEmpty) return null;
    final counts = <String, int>{};
    for (final m in members) {
      final maj = m.major.trim().toUpperCase();
      counts[maj] = (counts[maj] ?? 0) + 1;
    }
    String topMajor = '';
    int topCount = 0;
    counts.forEach((maj, cnt) {
      if (cnt > topCount) {
        topCount = cnt;
        topMajor = maj;
      }
    });
    return MapEntry(topMajor, topCount / members.length);
  }

  RoomModel copyWith({
    String? id,
    String? name,
    String? description,
    String? subjectCode,
    String? semesterId,
    String? leaderId,
    String? leaderName,
    bool? isPublic,
    String? status,
    int? maxMembers,
    int? minMembers,
    List<RoomMemberModel>? members,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subjectCode: subjectCode ?? this.subjectCode,
      semesterId: semesterId ?? this.semesterId,
      leaderId: leaderId ?? this.leaderId,
      leaderName: leaderName ?? this.leaderName,
      isPublic: isPublic ?? this.isPublic,
      status: status ?? this.status,
      maxMembers: maxMembers ?? this.maxMembers,
      minMembers: minMembers ?? this.minMembers,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subjectCode': subjectCode,
      'semesterId': semesterId,
      'leaderId': leaderId,
      'leaderName': leaderName,
      'isPublic': isPublic,
      'status': status,
      'maxMembers': maxMembers,
      'minMembers': minMembers,
      'members': members.map((m) => m.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final memberList = map['members'] != null
        ? (map['members'] as List)
            .map((m) => RoomMemberModel.fromMap(Map<String, dynamic>.from(m)))
            .toList()
        : <RoomMemberModel>[];

    final effectiveId = id ?? map['id'] ?? map['groupId'] ?? '';
    final rawName = map['name'] as String? ?? '';
    String effectiveName = rawName;
    if (effectiveId == 'room_001' || rawName.contains('Alpha Team')) {
      effectiveName = 'Nhóm 1 (Phòng 01)';
    } else if (effectiveId == 'room_002' || rawName.contains('Beta Startup')) {
      effectiveName = 'Nhóm 2 (Phòng 02)';
    } else if (effectiveId == 'room_003' || rawName.contains('EcoPackaging')) {
      effectiveName = 'Nhóm 3 (Phòng 03)';
    }

    return RoomModel(
      id: effectiveId,
      name: effectiveName,
      description: map['description'] ?? '',
      subjectCode: map['subjectCode'] ?? 'EXE101',
      semesterId: map['semesterId'] ?? 'FALL2026',
      leaderId: map['leaderId'] ?? '',
      leaderName: map['leaderName'] ?? '',
      isPublic: map['isPublic'] ?? true,
      status: map['status'] ?? 'open',
      maxMembers: map['maxMembers'] ?? AppConfig.TEAM_MAX_MEMBERS,
      minMembers: map['minMembers'] ?? AppConfig.TEAM_MIN_MEMBERS,
      members: memberList,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        subjectCode,
        semesterId,
        leaderId,
        status,
        members,
      ];
}
