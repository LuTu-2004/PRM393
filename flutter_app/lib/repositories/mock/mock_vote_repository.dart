import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/models/vote_model.dart';
import '../interfaces/vote_repository.dart';

/// Mock implementation cua VoteRepository phuc vu offline & test
/// Tuan thu BR-21, BR-22, BR-23, BR-24, BR-25, BR-26, BR-27, BR-28
class MockVoteRepository implements VoteRepository {
  final List<VoteSessionModel> _sessions = [];
  final List<VoteModel> _votes = [];

  MockVoteRepository({
    List<VoteSessionModel>? initialSessions,
    List<VoteModel>? initialVotes,
  }) {
    if (initialSessions != null) _sessions.addAll(initialSessions);
    if (initialVotes != null) _votes.addAll(initialVotes);
  }

  @override
  Future<VoteSessionModel?> getActiveSession(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _sessions.firstWhere((s) => s.roomId == roomId && s.isActive);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<VoteSessionModel> createVoteSession({
    required String roomId,
    required String leaderId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final existing = await getActiveSession(roomId);
    if (existing != null) return existing;

    final now = DateTime.now();
    final newSession = VoteSessionModel(
      id: 'session_${now.millisecondsSinceEpoch}',
      roomId: roomId,
      initiatedBy: leaderId,
      startedAt: now,
      endedAt: now.add(const Duration(hours: AppConfig.VOTING_DURATION_HOURS)), // BR-22: 24h
      status: 'active',
    );

    _sessions.add(newSession);
    return newSession;
  }

  @override
  Future<bool> hasUserVoted({
    required String sessionId,
    required String userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _votes.any((v) => v.sessionId == sessionId && v.voterId == userId);
  }

  @override
  Future<VoteModel> castVote({
    required String sessionId,
    required String voterId,
    required bool isApproved,
    String? leaderCandidateId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 150));

    // BR-23: Khong duoc tu bau lam Leader cho chinh minh
    if (leaderCandidateId != null && leaderCandidateId == voterId) {
      throw StateError('BR-23: Bạn không được tự bầu làm Trưởng nhóm cho chính mình!');
    }

    // BR-24: Moi thanh vien chi bo phieu 1 lan
    final alreadyVoted = await hasUserVoted(sessionId: sessionId, userId: voterId);
    if (alreadyVoted) {
      throw StateError('BR-24: Bạn đã bỏ phiếu trong phiên này rồi, mỗi thành viên chỉ bỏ phiếu 1 lần duy nhất!');
    }

    final newVote = VoteModel(
      id: 'vote_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      voterId: voterId,
      targetId: leaderCandidateId,
      isApproved: isApproved,
      createdAt: DateTime.now(),
    );

    _votes.add(newVote);
    return newVote;
  }

  @override
  Future<VoteResultModel> getSessionResult({
    required String sessionId,
    required int totalMembers,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    final sessionVotes = _votes.where((v) => v.sessionId == sessionId).toList();
    final totalVoted = sessionVotes.length;
    final approvedCount = sessionVotes.where((v) => v.isApproved).length;
    final rejectedCount = totalVoted - approvedCount;

    // BR-26: Ty le dong y chot nhom >= 75%
    final double approvalRate = totalVoted > 0 ? approvedCount / totalVoted : 0.0;
    final bool isPassed = totalVoted >= 3 && approvalRate >= 0.75;

    // Dem phieu bau Leader
    final candidateVotes = <String, int>{};
    for (final v in sessionVotes) {
      if (v.targetId != null) {
        candidateVotes[v.targetId!] = (candidateVotes[v.targetId!] ?? 0) + 1;
      }
    }

    String? topLeaderId;
    int maxLeaderVotes = 0;
    candidateVotes.forEach((candidateId, count) {
      if (count > maxLeaderVotes) {
        maxLeaderVotes = count;
        topLeaderId = candidateId;
      }
    });

    final bool isCompleted = totalVoted >= totalMembers && totalMembers > 0;

    return VoteResultModel(
      sessionId: sessionId,
      totalEligibleMembers: totalMembers,
      totalVoted: totalVoted,
      approvedCount: approvedCount,
      rejectedCount: rejectedCount,
      approvalRate: approvalRate,
      isPassed: isPassed,
      electedLeaderId: topLeaderId,
      isCompleted: isCompleted,
    );
  }
}
