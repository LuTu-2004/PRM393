import 'package:equatable/equatable.dart';

/// Phien bo phieu kin danh gia thanh vien
/// Tuan thu BR-21 (Leader kich hoat), BR-22 (Thoi han 24h), BR-24 (An ket qua)
class VoteSessionModel extends Equatable {
  final String id;
  final String roomId;
  final String initiatedBy; // BR-21: Leader ID kich hoat
  final DateTime startedAt;
  final DateTime endedAt; // BR-22: startedAt + 24h
  final String status; // 'active' | 'ended'

  const VoteSessionModel({
    required this.id,
    required this.roomId,
    required this.initiatedBy,
    required this.startedAt,
    required this.endedAt,
    this.status = 'active',
  });

  /// BR-22: Kiem tra phien bo phieu da qua 24 gio chua
  bool get isExpired => DateTime.now().isAfter(endedAt);

  /// Kiem tra phien con dang mo hay khong
  bool get isActive => status == 'active' && !isExpired;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'initiatedBy': initiatedBy,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'status': isExpired ? 'ended' : status,
    };
  }

  factory VoteSessionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final started = map['startedAt'] != null
        ? DateTime.parse(map['startedAt'].toString())
        : DateTime.now();

    final ended = map['endedAt'] != null
        ? DateTime.parse(map['endedAt'].toString())
        : started.add(const Duration(hours: 24)); // BR-22: 24h

    return VoteSessionModel(
      id: id ?? map['id'] ?? '',
      roomId: map['roomId'] ?? '',
      initiatedBy: map['initiatedBy'] ?? '',
      startedAt: started,
      endedAt: ended,
      status: map['status'] ?? 'active',
    );
  }

  @override
  List<Object?> get props => [id, roomId, initiatedBy, status, endedAt];
}

/// Phieu bau thanh vien
/// Tuan thu BR-23 (Moi nguoi 1 phieu, khong tu bau cho minh), BR-27 (Tinh toan ven)
class VoteModel extends Equatable {
  final String id;
  final String sessionId;
  final String voterId; // Nguoi bo phieu
  final String? targetId; // Nguoi duoc bo phieu lam Leader (khac voterId - BR-23)
  final bool isApproved; // Dong y chot nhom hay khong (BR-26)
  final DateTime createdAt;

  const VoteModel({
    required this.id,
    required this.sessionId,
    required this.voterId,
    this.targetId,
    this.isApproved = true,
    required this.createdAt,
  });

  /// BR-23: Kiem tra phieu hop le (khong tu bau lam Leader cho ban than)
  bool get isValid => targetId == null || voterId != targetId;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'voterId': voterId,
      'targetId': targetId,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VoteModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return VoteModel(
      id: id ?? map['id'] ?? '',
      sessionId: map['sessionId'] ?? '',
      voterId: map['voterId'] ?? '',
      targetId: map['targetId'],
      isApproved: map['isApproved'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'].toString())
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, sessionId, voterId, targetId, isApproved];
}
