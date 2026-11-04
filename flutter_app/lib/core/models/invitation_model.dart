import 'package:equatable/equatable.dart';

/// Model Loi moi hoac Yeu cau tham gia phong
/// Tuan thu BR-11 (Moi truc tiep), BR-16 (Xin gia nhap), BR-17 (Toi da 3 request), BR-20 (Het han 48h)
/// Tuong thich OpenAPI InvitationResponse & JoinRequestResponse tu PRN232
class InvitationModel extends Equatable {
  final String id;
  final String roomId;
  final String roomName;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final String type; // 'request' (xin vao) | 'invite' (moi vao)
  final String status; // 'pending' | 'accepted' | 'rejected' | 'expired'
  final String? message;
  final DateTime createdAt;
  final DateTime expiredAt; // BR-20: 48h ke tu khi tao

  const InvitationModel({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.type,
    this.status = 'pending',
    this.message,
    required this.createdAt,
    required this.expiredAt,
  });

  /// BR-20: Kiem tra request da qua 48h chua
  bool get isExpired => DateTime.now().isAfter(expiredAt);

  /// Kiem tra request con hieu luc va dang cho phan hoi
  bool get isPending => status == 'pending' && !isExpired;

  bool get isRequest => type == 'request';
  bool get isInvite => type == 'invite';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'roomName': roomName,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'type': type,
      'status': isExpired ? 'expired' : status,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'expiredAt': expiredAt.toIso8601String(),
    };
  }

  factory InvitationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    final created = map['createdAt'] != null
        ? DateTime.parse(map['createdAt'].toString())
        : DateTime.now();

    final expired = map['expiredAt'] != null
        ? DateTime.parse(map['expiredAt'].toString())
        : created.add(const Duration(hours: 48)); // BR-20: Default 48h

    return InvitationModel(
      id: id ?? map['id'] ?? '',
      roomId: map['roomId'] ?? map['groupId'] ?? '',
      roomName: map['roomName'] ?? map['groupName'] ?? '',
      fromUserId: map['fromUserId'] ?? map['studentId'] ?? '',
      fromUserName: map['fromUserName'] ?? map['studentName'] ?? '',
      toUserId: map['toUserId'] ?? map['invitedBy'] ?? '',
      toUserName: map['toUserName'] ?? '',
      type: map['type'] ?? 'request',
      status: map['status'] ?? 'pending',
      message: map['message'],
      createdAt: created,
      expiredAt: expired,
    );
  }

  @override
  List<Object?> get props => [id, roomId, fromUserId, toUserId, type, status, expiredAt];
}
