import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/models/invitation_model.dart';
import '../interfaces/invitation_repository.dart';

/// Mock implementation cua InvitationRepository phuc vu offline & unit test
/// Tuan thu BR-16, BR-17 (Toi da 3 request pending), BR-20 (Het han 48h)
class MockInvitationRepository implements InvitationRepository {
  final List<InvitationModel> _invitations = [];

  MockInvitationRepository({List<InvitationModel>? initialData}) {
    if (initialData != null) {
      _invitations.addAll(initialData);
    } else {
      _initMockData();
    }
  }

  void _initMockData() {
    final now = DateTime.now();
    _invitations.addAll([
      InvitationModel(
        id: 'req_001',
        roomId: 'room_002',
        roomName: 'SmartEdu - AI Hoc Tieng Anh',
        fromUserId: 'uid_se_001',
        fromUserName: 'Nguyễn Văn An',
        toUserId: 'uid_mkt_002',
        toUserName: 'Doan Van Giang',
        type: 'request',
        status: 'pending',
        message: 'Em muon tham gia lap trinh Mobile Flutter cho du an a.',
        createdAt: now.subtract(const Duration(hours: 12)),
        expiredAt: now.add(const Duration(hours: 36)), // Con 36h
      ),
      InvitationModel(
        id: 'req_002',
        roomId: 'room_003',
        roomName: 'FinLife - Quan Ly Tai Chinh Ca Nhan',
        fromUserId: 'uid_se_001',
        fromUserName: 'Nguyễn Văn An',
        toUserId: 'uid_se_004',
        toUserName: 'Phan Quoc Khanh',
        type: 'request',
        status: 'pending',
        message: 'Xin chao Leader, minh co kinh nghiem lam backend API .NET.',
        createdAt: now.subtract(const Duration(hours: 24)),
        expiredAt: now.add(const Duration(hours: 24)), // Con 24h
      ),
      // Don xin vao nhom cua ung vien gui den Leader Nguyen Van An (room_001 Alpha Team)
      InvitationModel(
        id: 'req_rec_001',
        roomId: 'room_001',
        roomName: 'Alpha Team (EXE Startup)',
        fromUserId: 'uid_mkt_001',
        fromUserName: 'Võ Thị Phương',
        toUserId: 'uid_se_001',
        toUserName: 'Nguyễn Văn An',
        type: 'request',
        status: 'pending',
        message: 'Chào Leader, em là sinh viên MKT K18, rất muốn phụ trách nghiên cứu thị trường và Go-to-market plan cho dự án!',
        createdAt: now.subtract(const Duration(hours: 6)),
        expiredAt: now.add(const Duration(hours: 42)), // Con 42h
      ),
      InvitationModel(
        id: 'req_rec_002',
        roomId: 'room_001',
        roomName: 'Alpha Team (EXE Startup)',
        fromUserId: 'uid_se_002',
        fromUserName: 'Trần Thị Bích',
        toUserId: 'uid_se_001',
        toUserName: 'Nguyễn Văn An',
        type: 'request',
        status: 'pending',
        message: 'Mình có kinh nghiệm làm giao diện Flutter và UI/UX Figma, xin phép vào team cùng phát triển sản phẩm nhé.',
        createdAt: now.subtract(const Duration(hours: 18)),
        expiredAt: now.add(const Duration(hours: 30)), // Con 30h
      ),
    ]);
  }

  @override
  Future<List<InvitationModel>> getSentPendingRequests(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _invitations
        .where((inv) =>
            inv.fromUserId == userId &&
            inv.type == 'request' &&
            inv.isPending)
        .toList();
  }

  @override
  Future<List<InvitationModel>> getSentRequests(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _invitations
        .where((inv) => inv.fromUserId == userId)
        .toList();
  }

  @override
  Future<List<InvitationModel>> getReceivedInvitations(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _invitations
        .where((inv) => inv.toUserId == userId && !inv.isExpired)
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
    await Future.delayed(const Duration(milliseconds: 150));

    // BR-17: Kiem tra so luong request dang cho (toi da 3)
    final pendingRequests = await getSentPendingRequests(fromUserId);
    if (pendingRequests.length >= AppConfig.MAX_PENDING_REQUESTS) {
      throw StateError(
        'BR-17: Bạn chỉ được gửi tối đa ${AppConfig.MAX_PENDING_REQUESTS} yêu cầu đang chờ duyệt cùng lúc! Hãy đợi Leader phản hồi hoặc hủy bớt yêu cầu cũ.',
      );
    }

    // Kiem tra da gui vao phong nay chua
    final alreadyPending = pendingRequests.any((r) => r.roomId == roomId);
    if (alreadyPending) {
      throw StateError('Bạn đã gửi yêu cầu gia nhập vào phòng này rồi!');
    }

    final now = DateTime.now();
    final newRequest = InvitationModel(
      id: 'req_${now.millisecondsSinceEpoch}',
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

    _invitations.add(newRequest);
    return newRequest;
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _invitations.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final old = _invitations[index];
      _invitations[index] = InvitationModel(
        id: old.id,
        roomId: old.roomId,
        roomName: old.roomName,
        fromUserId: old.fromUserId,
        fromUserName: old.fromUserName,
        toUserId: old.toUserId,
        toUserName: old.toUserName,
        type: old.type,
        status: 'cancelled',
        message: old.message,
        createdAt: old.createdAt,
        expiredAt: old.expiredAt,
      );
    }
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required bool accept,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _invitations.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final old = _invitations[index];
      _invitations[index] = InvitationModel(
        id: old.id,
        roomId: old.roomId,
        roomName: old.roomName,
        fromUserId: old.fromUserId,
        fromUserName: old.fromUserName,
        toUserId: old.toUserId,
        toUserName: old.toUserName,
        type: old.type,
        status: accept ? 'accepted' : 'rejected',
        message: old.message,
        createdAt: old.createdAt,
        expiredAt: old.expiredAt,
      );
    }
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
    await Future.delayed(const Duration(milliseconds: 150));

    final normalized = targetStudentCodeOrEmail.trim();
    if (normalized.isEmpty) {
      throw StateError('Vui lòng nhập MSSV hoặc Email sinh viên hợp lệ!');
    }

    final now = DateTime.now();
    final newInvite = InvitationModel(
      id: 'invite_${now.millisecondsSinceEpoch}',
      roomId: roomId,
      roomName: roomName,
      fromUserId: leaderId,
      fromUserName: leaderName,
      toUserId: 'uid_target_$normalized',
      toUserName: 'Sinh viên ($normalized)',
      type: 'invite', // BR-11: Leader gui loi moi
      status: 'pending',
      message: message ?? 'Leader phòng "$roomName" mời bạn gia nhập nhóm khởi nghiệp EXE.',
      createdAt: now,
      expiredAt: now.add(Duration(hours: AppConfig.REQUEST_EXPIRY_HOURS)), // BR-20: 48h
    );

    _invitations.add(newInvite);
    return newInvite;
  }
}
