import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/constants/collection_names.dart';
import 'package:exe_matching/core/models/vote_model.dart';
import '../interfaces/vote_repository.dart';

/// Firebase implementation cua VoteRepository doc/ghi collection 'vote_sessions' va 'votes'
/// Tuan thu BR-21 (Leader mo vote), BR-22 (24h), BR-23 (Khong tu bau), BR-24 (1 phieu/nguoi), BR-26 (Pass >= 75%), BR-27
class FirebaseVoteRepository implements VoteRepository {
  final FirebaseFirestore _firestore;

  FirebaseVoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<VoteSessionModel?> getActiveSession(String roomId) async {
    final snapshot = await _firestore
        .collection(CollectionNames.voteSessions)
        .where('roomId', isEqualTo: roomId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return VoteSessionModel.fromMap(snapshot.docs.first.data(), id: snapshot.docs.first.id);
  }

  @override
  Future<VoteSessionModel> createVoteSession({
    required String roomId,
    required String leaderId,
  }) async {
    // BR-21 & BR-22: Leader mo phien bo phieu 24 gio
    final now = DateTime.now();
    final docRef = _firestore.collection(CollectionNames.voteSessions).doc();

    final session = VoteSessionModel(
      id: docRef.id,
      roomId: roomId,
      initiatedBy: leaderId,
      startedAt: now,
      endedAt: now.add(Duration(hours: AppConfig.VOTING_DURATION_HOURS)), // 24h
      status: 'active',
    );

    await docRef.set(session.toMap());
    return session;
  }

  @override
  Future<bool> hasUserVoted({
    required String sessionId,
    required String userId,
  }) async {
    // BR-24: 1 phieu duy nhat cho moi thanh vien
    final snapshot = await _firestore
        .collection(CollectionNames.votes)
        .where('sessionId', isEqualTo: sessionId)
        .where('voterId', isEqualTo: userId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<VoteModel> castVote({
    required String sessionId,
    required String voterId,
    required bool isApproved,
    String? leaderCandidateId,
  }) async {
    // BR-24: Kiem tra da bo phieu chua
    final alreadyVoted = await hasUserVoted(sessionId: sessionId, userId: voterId);
    if (alreadyVoted) {
      throw StateError('BR-24: Bạn đã thực hiện bỏ phiếu trong phiên này rồi!');
    }

    // BR-23: Khong duoc tu bau cho chinh minh
    if (leaderCandidateId != null && leaderCandidateId == voterId) {
      throw StateError('BR-23: Không được tự bỏ phiếu bầu chức vụ Leader cho chính bản thân mình!');
    }

    final docRef = _firestore.collection(CollectionNames.votes).doc();
    final vote = VoteModel(
      id: docRef.id,
      sessionId: sessionId,
      voterId: voterId,
      targetId: leaderCandidateId,
      isApproved: isApproved,
      createdAt: DateTime.now(),
    );

    await docRef.set(vote.toMap());
    return vote;
  }

  @override
  Future<VoteResultModel> getSessionResult({
    required String sessionId,
    required int totalMembers,
  }) async {
    // BR-24, BR-25, BR-26, BR-27: Tong hop ket qua
    final snapshot = await _firestore
        .collection(CollectionNames.votes)
        .where('sessionId', isEqualTo: sessionId)
        .get();

    final votes = snapshot.docs
        .map((d) => VoteModel.fromMap(d.data(), id: d.id))
        .toList();

    final totalVoted = votes.length;
    final approvedCount = votes.where((v) => v.isApproved).length;
    final rejectedCount = totalVoted - approvedCount;

    final approvalRate = totalMembers > 0 ? (approvedCount / totalMembers) : 0.0;
    final isPassed = approvalRate >= 0.75; // BR-26: >= 75%

    // Tinh phieu bau Leader
    final leaderTally = <String, int>{};
    for (final v in votes) {
      if (v.targetId != null && v.targetId!.isNotEmpty) {
        leaderTally[v.targetId!] = (leaderTally[v.targetId!] ?? 0) + 1;
      }
    }

    String? topLeaderId;
    int topVotes = 0;
    leaderTally.forEach((targetId, count) {
      if (count > topVotes) {
        topVotes = count;
        topLeaderId = targetId;
      }
    });

    final isCompleted = totalMembers > 0 && totalVoted >= totalMembers;

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
