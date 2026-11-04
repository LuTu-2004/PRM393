import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/theme/app_colors.dart';
import '../bloc/matching_bloc.dart';
import '../bloc/matching_event.dart';
import '../bloc/matching_state.dart';
import '../widgets/matching_card.dart';

/// Man hinh De xuat Ghep nhom (Matching Tab)
/// Tuan thu BR-14 (Cung mon hoc), BR-15 (Matching Score), BR-16 (Xin gia nhap), BR-17 (Toi da 3 request pending)
class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MatchingBloc>().add(const LoadMatchingRecommendationsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đề Xuất Ghép Nhóm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới gợi ý',
            onPressed: () {
              context.read<MatchingBloc>().add(const LoadMatchingRecommendationsEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<MatchingBloc, MatchingState>(
        listener: (context, state) {
          if (state is MatchingLoadedState && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MatchingLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MatchingErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MatchingBloc>().add(const LoadMatchingRecommendationsEvent());
                      },
                      child: const Text('Thử Lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is MatchingLoadedState) {
            final user = state.currentUser;
            final recommendations = state.recommendations;

            return RefreshIndicator(
              onRefresh: () async {
                context.read<MatchingBloc>().add(const LoadMatchingRecommendationsEvent());
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. User Profile Header Card
                  _buildUserHeaderCard(user, state.pendingCount),
                  const SizedBox(height: 16),

                  // 2. Banner BR-17: So luong request dang su dung
                  _buildRequestQuotaBanner(state.pendingCount, state.canSendMore),
                  const SizedBox(height: 16),

                  // 3. Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Phòng phù hợp với bạn',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${recommendations.length} phòng gợi ý',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4. Recommendation Cards List
                  if (recommendations.isEmpty)
                    _buildEmptyState()
                  else
                    ...recommendations.map((result) {
                      final isRequested = state.isRoomRequested(result.room.id);
                      return MatchingCard(
                        result: result,
                        isRequested: isRequested,
                        canSendMore: state.canSendMore,
                        onSendRequest: (message) {
                          context.read<MatchingBloc>().add(SendJoinRequestEvent(
                                roomId: result.room.id,
                                roomName: result.room.name,
                                leaderId: result.room.leaderId,
                                leaderName: result.room.leaderName,
                                message: message,
                              ));
                        },
                      );
                    }),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildUserHeaderCard(dynamic user, int pendingCount) {
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withOpacity(0.12),
            child: Text(
              user.major ?? 'SE',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        user.cohort ?? 'K18',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${user.studentCode ?? 'Chưa có MSSV'} • Chuyên ngành ${user.major ?? 'SE'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kỹ năng: ${user.skills.take(3).join(", ")}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestQuotaBanner(int pendingCount, bool canSendMore) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: canSendMore ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: canSendMore ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        children: [
          Icon(
            canSendMore ? Icons.check_circle_outline : Icons.info_outline,
            size: 20,
            color: canSendMore ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hạn mức yêu cầu: $pendingCount/3 đang chờ',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: canSendMore ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                  ),
                ),
                Text(
                  canSendMore
                      ? 'Bạn còn ${3 - pendingCount} lượt gửi yêu cầu gia nhập nhóm.'
                      : 'Đã dùng hết 3 lượt gửi. Vui lòng đợi Leader phản hồi hoặc hủy yêu cầu ở tab Lời mời.',
                  style: TextStyle(
                    fontSize: 11,
                    color: canSendMore ? const Color(0xFF166534) : const Color(0xFF991B1B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.search_off_outlined, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'Chưa có phòng nào phù hợp trong học kỳ này',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 4),
          Text(
            'Hãy thử tạo một phòng mới để thu hút thành viên cùng chí hướng!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
