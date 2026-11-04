import 'package:exe_matching/core/models/vote_model.dart';

/// Ket qua tong hop phien bo phieu chot nhom
/// Tuan thu BR-24 (An danh), BR-26 (Ty le dong thuan >= 75%), BR-27 (Khoa nhom)
class VoteResultModel {
  final String sessionId;
  final int totalEligibleMembers;
  final int totalVoted;
  final int approvedCount;
  final int rejectedCount;
  final double approvalRate; // 0.0 - 1.0
  final bool isPassed; // BR-26: approvalRate >= 0.75
  final String? electedLeaderId;
  final String? electedLeaderName;
  final bool isCompleted;

  const VoteResultModel({
    required this.sessionId,
    required this.totalEligibleMembers,
    required this.totalVoted,
    required this.approvedCount,
    required this.rejectedCount,
    required this.approvalRate,
    required this.isPassed,
    this.electedLeaderId,
    this.electedLeaderName,
    this.isCompleted = false,
  });
}

/// Repository quan ly phien bo phieu kin
/// Tuan thu BR-21 (Leader mo vote), BR-22 (24h), BR-23 (Khong tu bau), BR-24 (1 phieu/nguoi), BR-26 (Pass >= 75%)
abstract class VoteRepository {
  /// Lay phien bo phieu dang dien ra cua phong
  Future<VoteSessionModel?> getActiveSession(String roomId);

  /// Leader mo phien bo phieu kin khi phong co tu 4-5 nguoi (BR-21, BR-22)
  Future<VoteSessionModel> createVoteSession({
    required String roomId,
    required String leaderId,
  });

  /// Kiem tra sinh vien da bo phieu chua (BR-24: 1 phieu duy nhat)
  Future<bool> hasUserVoted({
    required String sessionId,
    required String userId,
  });

  /// Sinh vien thuc hien bo phieu (BR-23)
  Future<VoteModel> castVote({
    required String sessionId,
    required String voterId,
    required bool isApproved,
    String? leaderCandidateId,
  });

  /// Lay ket qua phien bo phieu
  Future<VoteResultModel> getSessionResult({
    required String sessionId,
    required int totalMembers,
  });
}
