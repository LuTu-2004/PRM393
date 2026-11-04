import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/constants/collection_names.dart';
import 'package:exe_matching/core/models/models.dart';
import '../interfaces/invitation_repository.dart';

/// Firebase implementation cua InvitationRepository doc/ghi collection 'invitations'
/// Tuan thu BR-11, BR-16, BR-17 (Toi da 3 request pending), BR-20 (Het han 48h)
class FirebaseInvitationRepository implements InvitationRepository {
  final FirebaseFirestore _firestore;

  FirebaseInvitationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<InvitationModel>> getSentPendingRequests(String userId) async {
    // BR-17: Kiem tra cac request dang cho de kiem soat han muc toi da 3
    final snapshot = await _firestore
        .collection(CollectionNames.invitations)
        .where('fromUserId', isEqualTo: userId)
        .where('type', isEqualTo: 'request')
        .where('status', isEqualTo: 'pending')
        .get();

    return snapshot.docs
        .map((d) => InvitationModel.fromMap(d.data(), id: d.id))
        .where((inv) => !inv.isExpired)
        .toList();
  }

  @override
  Future<List<InvitationModel>> getSentRequests(String userId) async {
    final snapshot = await _firestore
        .collection(CollectionNames.invitations)
        .where('fromUserId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((d) => InvitationModel.fromMap(d.data(), id: d.id))
        .toList();
  }

  @override
  Future<List<InvitationModel>> getReceivedInvitations(String userId) async {
    final snapshot = await _firestore
        .collection(CollectionNames.invitations)
        .where('toUserId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((d) => InvitationModel.fromMap(d.data(), id: d.id))
        .where((inv) => !inv.isExpired)
        .toList();
  }

  @override
  Future<InvitationModel> sendJoinRequest({
    required String roomId,
    required String roomName,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    String? message,
  }) async {
    // BR-17: Kiem tra toi da 3 request pending
    final pending = await getSentPendingRequests(fromUserId);
    if (pending.length >= AppConfig.MAX_PENDING_REQUESTS) {
      throw StateError(
        'BR-17: Bạn chỉ được gửi tối đa ${AppConfig.MAX_PENDING_REQUESTS} yêu cầu đang chờ duyệt cùng lúc! Hãy hủy bớt yêu cầu cũ hoặc đợi phản hồi.',
      );
    }

    final alreadyPending = pending.any((r) => r.roomId == roomId);
    if (alreadyPending) {
      throw StateError('Bạn đã gửi yêu cầu gia nhập vào phòng này rồi!');
    }

    final now = DateTime.now();
    final docRef = _firestore.collection(CollectionNames.invitations).doc();

    final newRequest = InvitationModel(
      id: docRef.id,
      roomId: roomId,
      roomName: roomName,
      fromUserId: fromUserId,
      fromUserName: fromUserName,
      toUserId: toUserId,
      toUserName: toUserName,
      type: 'request',
      status: 'pending',
      message: message,
      createdAt: now,
      expiredAt: now.add(Duration(hours: AppConfig.REQUEST_EXPIRY_HOURS)), // BR-20: 48h
    );

    await docRef.set(newRequest.toMap());
    return newRequest;
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    // BR-17: Huy request giai phong slot
    await _firestore
        .collection(CollectionNames.invitations)
        .doc(requestId)
        .update({'status': 'cancelled'});
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
  }) async {
    await _firestore
        .collection(CollectionNames.invitations)
        .doc(requestId)
        .update({'status': accept ? 'accepted' : 'rejected'});
  }

  @override
  Future<InvitationModel> sendDirectInvite({
    required String roomId,
    required String roomName,
    required String leaderId,
    required String leaderName,
    required String targetStudentCodeOrEmail,
    String? message,
  }) async {
    // BR-11: Leader moi truc tiep qua MSSV / Email
    final normalized = targetStudentCodeOrEmail.trim();
    if (normalized.isEmpty) {
      throw StateError('Vui lòng nhập MSSV hoặc Email sinh viên hợp lệ!');
    }

    final now = DateTime.now();
    final docRef = _firestore.collection(CollectionNames.invitations).doc();

    final newInvite = InvitationModel(
      id: docRef.id,
      roomId: roomId,
      roomName: roomName,
      fromUserId: leaderId,
      fromUserName: leaderName,
      toUserId: 'uid_target_$normalized',
      toUserName: 'Sinh viên ($normalized)',
      type: 'invite',
      status: 'pending',
      message: message ?? 'Leader phòng "$roomName" mời bạn gia nhập nhóm khởi nghiệp EXE.',
      createdAt: now,
      expiredAt: now.add(Duration(hours: AppConfig.REQUEST_EXPIRY_HOURS)), // BR-20: 48h
    );

    await docRef.set(newInvite.toMap());
    return newInvite;
  }
}
