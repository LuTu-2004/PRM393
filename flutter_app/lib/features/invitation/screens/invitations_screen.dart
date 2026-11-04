import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import '../bloc/invitation_bloc.dart';
import '../bloc/invitation_event.dart';
import '../bloc/invitation_state.dart';
import '../widgets/received_invitation_card.dart';
import '../widgets/sent_request_card.dart';

/// Man hinh Quan ly Yeu cau & Loi moi (Invitations Tab)
/// Tuan thu BR-16 (Xin vao), BR-17 (Toi da 3 request pending), BR-18 & BR-19 (Canh bao da dang nganh), BR-20 (48h)
class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<InvitationBloc>().add(const LoadInvitationsEvent());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDiversityWarningDialog(BuildContext context, DiversityWarningPromptState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cảnh Báo Đa Dạng Ngành',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                'Ứng viên "${state.pendingEvent.applicantName}" thuộc chuyên ngành ${state.pendingEvent.applicantMajor}. '
                'Nếu bạn duyệt bạn này vào nhóm, tỷ lệ ngành ${state.pendingEvent.applicantMajor} sẽ đạt ${(state.projectedRatio * 100).toInt()}% (vượt ngưỡng 50% quy định môn EXE).',
                style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quy định môn EXE khuyến khích các nhóm có sự kết hợp đa ngành (SE, MKT, BA, GD, DS) để hoàn thiện dự án khởi nghiệp tốt nhất.\n\nBạn có chắc chắn vẫn muốn duyệt ứng viên này không?',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<InvitationBloc>().add(const LoadInvitationsEvent());
            },
            child: const Text('Hủy Bỏ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<InvitationBloc>().add(RespondInvitationEvent(
                requestId: state.pendingEvent.requestId,
                accept: true,
                roomId: state.pendingEvent.roomId,
                applicantId: state.pendingEvent.applicantId,
                applicantName: state.pendingEvent.applicantName,
                applicantMajor: state.pendingEvent.applicantMajor,
                studentCode: state.pendingEvent.studentCode,
                forceAccept: true,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Vẫn Duyệt (Xác Nhận)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InvitationBloc, InvitationState>(
      listener: (context, state) {
        if (state is DiversityWarningPromptState) {
          _showDiversityWarningDialog(context, state);
        } else if (state is InvitationLoadedState && state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is InvitationErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        int sentPendingCount = 0;
        int receivedPendingCount = 0;

        if (state is InvitationLoadedState) {
          sentPendingCount = state.pendingSentCount;
          receivedPendingCount = state.pendingReceivedCount;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Yêu Cầu & Lời Mời'),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã Gửi', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$sentPendingCount/3',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Hộp Thư Đến', style: TextStyle(fontWeight: FontWeight.bold)),
                      if (receivedPendingCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$receivedPendingCount',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: state is InvitationLoadingState
              ? const Center(child: CircularProgressIndicator())
              : state is InvitationLoadedState
                  ? TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: Sent Requests
                        _buildSentTab(state),
                        // Tab 2: Received Invitations (Leader view)
                        _buildReceivedTab(state),
                      ],
                    )
                  : const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildSentTab(InvitationLoadedState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InvitationBloc>().add(const LoadInvitationsEvent());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner thong tin han muc BR-17
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bạn có tối đa 3 yêu cầu đang chờ cùng lúc. Đã dùng: ${state.pendingSentCount}/3. Nếu muốn xin vào phòng khác, bạn có thể hủy bớt yêu cầu cũ bên dưới.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (state.sentRequests.isEmpty)
            _buildEmptyState(
              icon: Icons.send_outlined,
              title: 'Bạn chưa gửi yêu cầu xin gia nhập nào',
              subtitle: 'Hãy sang tab "Matching" hoặc "Khám phá" để tìm và xin vào các phòng phù hợp nhé!',
            )
          else
            ...state.sentRequests.map((req) {
              return SentRequestCard(
                request: req,
                onCancel: () {
                  context.read<InvitationBloc>().add(CancelSentRequestEvent(req.id));
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildReceivedTab(InvitationLoadedState state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<InvitationBloc>().add(const LoadInvitationsEvent());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: Color(0xFF475569), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Góc Trưởng Nhóm: Danh sách các bạn sinh viên gửi đơn xin vào nhóm của bạn. Bạn có 48 giờ để xét duyệt.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (state.receivedInvitations.isEmpty)
            _buildEmptyState(
              icon: Icons.inbox_outlined,
              title: 'Hộp thư đến đang trống',
              subtitle: 'Chưa có ứng viên nào gửi yêu cầu xin gia nhập phòng của bạn.',
            )
          else
            ...state.receivedInvitations.map((inv) {
              // Trich xuat major tu student name / id hoac mac dinh
              final major = inv.fromUserId.contains('mkt')
                  ? 'MKT'
                  : inv.fromUserId.contains('se')
                      ? 'SE'
                      : inv.fromUserId.contains('ba')
                          ? 'BA'
                          : 'SE';

              return ReceivedInvitationCard(
                invitation: inv,
                onAccept: () {
                  context.read<InvitationBloc>().add(RespondInvitationEvent(
                        requestId: inv.id,
                        accept: true,
                        roomId: inv.roomId,
                        applicantId: inv.fromUserId,
                        applicantName: inv.fromUserName,
                        applicantMajor: major,
                      ));
                },
                onReject: () {
                  context.read<InvitationBloc>().add(RespondInvitationEvent(
                        requestId: inv.id,
                        accept: false,
                        roomId: inv.roomId,
                        applicantId: inv.fromUserId,
                        applicantName: inv.fromUserName,
                        applicantMajor: major,
                      ));
                },
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }
}
