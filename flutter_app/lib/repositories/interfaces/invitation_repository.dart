import 'package:exe_matching/core/models/invitation_model.dart';

/// Repository giao tiep du lieu Yeu cau & Loi moi tham gia phong
/// Tuan thu BR-11, BR-16, BR-17 (Toi da 3 request pending), BR-20 (Het han 48h)
abstract class InvitationRepository {
  /// Lay danh sach cac request dang cho (pending) ma sinh vien da gui di
  /// Dung de kiem tra gioi han BR-17 (toi da 3 request)
  Future<List<InvitationModel>> getSentPendingRequests(String userId);

  /// Lay tat ca request da gui (bao gom ca pending, accepted, rejected, cancelled)
  Future<List<InvitationModel>> getSentRequests(String userId);

  /// Lay danh sach yeu cau hoac loi moi nhan duoc
  Future<List<InvitationModel>> getReceivedInvitations(String userId);

  /// Sinh vien gui yeu cau xin gia nhap phong (BR-16)
  /// Phai kiem tra BR-17 truoc khi goi hoac nem ngoai le neu >= 3 pending
  Future<InvitationModel> sendJoinRequest({
    required String roomId,
    required String roomName,
    required String fromUserId,
    required String fromUserName,
    required String toUserId,
    required String toUserName,
    String? message,
  });

  /// Sinh vien huy yeu cau da gui (giai phong slot de gui phong khac - BR-17)
  Future<void> cancelRequest(String requestId);

  /// Leader phan hoi yeu cau: Chap nhan (accept) hoac Tu choi (reject)
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
  });

  /// Leader moi truc tiep sinh vien vao phong qua MSSV hoac Email (BR-11)
  Future<InvitationModel> sendDirectInvite({
    required String roomId,
    required String roomName,
    required String leaderId,
    required String leaderName,
    required String targetStudentCodeOrEmail,
    String? message,
  });
}
