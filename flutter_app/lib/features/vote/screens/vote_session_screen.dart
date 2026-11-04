import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import '../bloc/vote_bloc.dart';
import '../bloc/vote_event.dart';
import '../bloc/vote_state.dart';

/// Man hinh Bo phieu kin chot nhom du an EXE
/// Tuan thu BR-21 (Leader mo vote), BR-22 (24h), BR-23 (Khong tu bau cho minh), BR-24 (1 phieu), BR-25 (An danh), BR-26 (Pass >= 75%), BR-27 (Khoa nhom)
class VoteSessionScreen extends StatefulWidget {
  final RoomModel room;
  final String currentUserId;

  const VoteSessionScreen({
    super.key,
    required this.room,
    this.currentUserId = 'uid_se_001',
  });

  @override
  State<VoteSessionScreen> createState() => _VoteSessionScreenState();
}

class _VoteSessionScreenState extends State<VoteSessionScreen> {
  bool _isApproved = true;
  String? _selectedLeaderCandidateId;

  @override
  void initState() {
    super.initState();
    context.read<VoteBloc>().add(LoadVoteSessionEvent(
          roomId: widget.room.id,
          totalMembers: widget.room.members.length,
        ));
  }

  void _submitVote(String sessionId) {
    context.read<VoteBloc>().add(CastVoteEvent(
          sessionId: sessionId,
          roomId: widget.room.id,
          totalMembers: widget.room.members.length,
          isApproved: _isApproved,
          leaderCandidateId: _selectedLeaderCandidateId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    // BR-23: Danh sach ung vien Leader loai tru ban than
    final eligibleCandidates = widget.room.members
        .where((m) => m.userId != widget.currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bỏ Phiếu Kín Chốt Nhóm'),
      ),
      body: BlocConsumer<VoteBloc, VoteState>(
        listener: (context, state) {
          if (state is VoteSessionLoadedState && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is VoteErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VoteLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is VoteSessionLoadedState) {
            final session = state.session;

            // Truong hop chua co phien vote nao
            if (session == null || !session.isActive) {
              return _buildNoActiveSessionView(context);
            }

            final result = state.result;
            final isCompleted = result?.isCompleted ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Session Header & 24h Countdown (BR-22)
                  _buildSessionHeader(session, result),
                  const SizedBox(height: 16),

                  // 2. Neu phien vote da hoan tat -> Hien thi ket qua BR-26, BR-27
                  if (isCompleted && result != null)
                    _buildResultView(result)
                  // 3. Neu user da vote -> Hien thi thong bao da bo phieu
                  else if (state.hasVoted)
                    _buildAlreadyVotedView(result)
                  // 4. Neu user chua vote -> Hien thi Form bo phieu kín (BR-23, BR-24)
                  else
                    _buildVotingForm(session.id, eligibleCandidates),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildNoActiveSessionView(BuildContext context) {
    final isLeader = widget.room.leaderId == widget.currentUserId;
    final canStartVote = widget.room.members.length >= 4 && widget.room.members.length <= 5;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.how_to_vote_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Chưa có phiên bỏ phiếu nào cho phòng "${widget.room.name}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              canStartVote
                  ? 'Phòng đã có ${widget.room.members.length} thành viên (đủ điều kiện từ 4-5 người).'
                  : 'Quy định: Phòng cần có đủ từ 4 đến 5 thành viên mới được mở phiên bỏ phiếu chốt nhóm (Hiện có: ${widget.room.members.length}/4).',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            if (isLeader && canStartVote)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<VoteBloc>().add(StartVoteSessionEvent(
                          roomId: widget.room.id,
                          totalMembers: widget.room.members.length,
                        ));
                  },
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  label: const Text('Mở Phiên Bỏ Phiếu Kín 24H', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader(VoteSessionModel session, dynamic result) {
    final totalVoted = result?.totalVoted ?? 0;
    final totalEligible = widget.room.members.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 18, color: Color(0xFF7C3AED)),
                  SizedBox(width: 6),
                  Text(
                    'Thời Hạn: 24 Giờ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Bỏ Phiếu Kín', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.room.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),

          // Progress bar tien do bo phieu (BR-24, BR-25: chi hien so luong, khong hien ten nguoi vote)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiến độ: $totalVoted/$totalEligible thành viên đã bỏ phiếu',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Text(
                '${((totalVoted / totalEligible) * 100).toInt()}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalEligible > 0 ? (totalVoted / totalEligible) : 0,
              minHeight: 8,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingForm(String sessionId, List<RoomMemberModel> eligibleCandidates) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phan 1: Tin nhiem chot nhom (BR-26: >= 75%)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.cardBorder)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Tín Nhiệm Chốt Nhóm Dự Án',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bạn có đồng ý chốt danh sách nhóm hiện tại để đăng ký chính thức với Giảng viên môn EXE không? (Yêu cầu >= 75% đồng thuận)',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isApproved = true),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isApproved ? const Color(0xFFDCFCE7) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _isApproved ? const Color(0xFF16A34A) : AppColors.cardBorder, width: _isApproved ? 1.8 : 1),
                          ),
                          alignment: Alignment.center,
                          child: const Text('👍 Đồng Ý (Chốt)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isApproved = false),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isApproved ? const Color(0xFFFEE2E2) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: !_isApproved ? const Color(0xFFDC2626) : AppColors.cardBorder, width: !_isApproved ? 1.8 : 1),
                          ),
                          alignment: Alignment.center,
                          child: const Text('👎 Chưa Đồng Ý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFB91C1C))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Phan 2: Bau Truong Nhom Chinh Thuc (BR-23: Khong duoc tu bau cho minh)
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.cardBorder)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '2. Bầu Trưởng Nhóm Chính Thức',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Quy định bỏ phiếu kín: Bạn không được tự bầu cho chính mình (Tên bạn đã được loại khỏi danh sách bầu bên dưới).',
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.3),
                ),
                const SizedBox(height: 12),
                if (eligibleCandidates.isEmpty)
                  const Text('Chưa có ứng viên khác trong nhóm.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                else
                  ...eligibleCandidates.map((c) {
                    final isSelected = _selectedLeaderCandidateId == c.userId;
                    return RadioListTile<String>(
                      title: Text(c.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: Text('${c.studentCode} • Chuyên ngành ${c.major}', style: const TextStyle(fontSize: 11)),
                      value: c.userId,
                      groupValue: _selectedLeaderCandidateId,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _selectedLeaderCandidateId = val),
                    );
                  }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Nut Xac Nhan Bo Phieu Kin
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => _submitVote(sessionId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Xác Nhận Bỏ Phiếu Kín',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlreadyVotedView(dynamic result) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, size: 52, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          const Text(
            'Bạn Đã Hoàn Tất Bỏ Phiếu Kín',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Phiếu bầu của bạn đã được ẩn danh an toàn. Kết quả chính thức (yêu cầu >= 75% đồng thuận) sẽ tự động mở khi 100% thành viên bỏ phiếu hoặc hết thời hạn 24 giờ.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF166534), height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(dynamic result) {
    final isPassed = result.isPassed;
    final ratePercent = (result.approvalRate * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPassed ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPassed ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          Icon(
            isPassed ? Icons.verified : Icons.warning_rounded,
            size: 56,
            color: isPassed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            isPassed ? '🎉 CHÚC MỪNG: NHÓM ĐÃ CHỐT THÀNH CÔNG!' : 'PHIÊN BỎ PHIẾU KHÔNG ĐẠT',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isPassed ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tỷ lệ đồng thuận đạt: $ratePercent% (${result.approvedCount}/${result.totalVoted} phiếu) — Tiêu chuẩn môn EXE >= 75%.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isPassed ? const Color(0xFF166534) : const Color(0xFF991B1B)),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isPassed
                  ? 'Phòng đã được chuyển sang trạng thái "Finalized". Danh sách nhóm chính thức đã sẵn sàng nộp cho Giảng viên hướng dẫn.'
                  : 'Do chưa đạt 75% đồng thuận, phòng tiếp tục ở trạng thái "Open" để bổ sung hoặc điều chỉnh thành viên.',
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
