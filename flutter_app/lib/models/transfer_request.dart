import 'package:exe_matching/models/firestore_utils.dart';

enum TransferStatus {
  pending('Chờ giảng viên duyệt'),
  approved('Đã duyệt'),
  rejected('Bị từ chối');

  final String label;
  const TransferStatus(this.label);
}

/// BR-36: sinh vien xin chuyen nhom sau khi chot so, giang vien duyet tren Web.
class TransferRequest {
  final String id;
  final String spaceId;
  final String studentId;
  final String studentName;
  final String fromRoomId;
  final String toRoomId;
  final String? reason;

  /// BR-37: nhom cu sau khi chuyen co rot duoi nguong khong (giang vien can doi cheo).
  final bool needsSwap;
  final TransferStatus status;
  final DateTime createdAt;

  const TransferRequest({
    required this.id,
    required this.spaceId,
    required this.studentId,
    required this.studentName,
    required this.fromRoomId,
    required this.toRoomId,
    this.reason,
    this.needsSwap = false,
    this.status = TransferStatus.pending,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'spaceId': spaceId,
    'studentId': studentId,
    'studentName': studentName,
    'fromRoomId': fromRoomId,
    'toRoomId': toRoomId,
    'reason': reason,
    'needsSwap': needsSwap,
    'status': status.name,
    'createdAt': writeDate(createdAt),
  };

  factory TransferRequest.fromMap(String id, Map<String, dynamic> map) {
    return TransferRequest(
      id: id,
      spaceId: map['spaceId'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      fromRoomId: map['fromRoomId'] as String? ?? '',
      toRoomId: map['toRoomId'] as String? ?? '',
      reason: map['reason'] as String?,
      needsSwap: map['needsSwap'] as bool? ?? false,
      status: TransferStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => TransferStatus.pending,
      ),
      createdAt: readDate(map['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
