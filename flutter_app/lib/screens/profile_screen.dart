import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/screens/report_section.dart';
import 'package:exe_matching/services/demo_seed_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/remote_config_service.dart';
import 'package:exe_matching/services/user_service.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/auth_viewmodel.dart';
import 'package:exe_matching/viewmodels/profile_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ho so sinh vien. [setupMode] = lan dau, chua co tab (BR-07 bat buoc hoan thanh).
class ProfileScreen extends StatelessWidget {
  final bool setupMode;
  const ProfileScreen({super.key, this.setupMode = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (ctx) => ProfileViewModel(
        currentUser: () => auth.user!,
        users: ctx.read<UserService>(),
        groups: ctx.read<GroupService>(),
        demoSeed: ctx.read<DemoSeedService>(),
        remoteConfig: ctx.read<RemoteConfigService>(),
        analytics: ctx.read<AnalyticsService>(),
        crashlytics: ctx.read<CrashlyticsService>(),
      ),
      child: _ProfileView(setupMode: setupMode),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final bool setupMode;
  const _ProfileView({required this.setupMode});

  Future<void> _save(BuildContext context) async {
    final result = await context.read<ProfileViewModel>().save();
    if (context.mounted) showResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final user = vm.user;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(setupMode ? 'Hoàn thành hồ sơ' : 'Hồ sơ'),
        actions: [
          if (setupMode)
            TextButton(
              onPressed: () => context.read<AuthViewModel>().signOut(),
              child: const Text('Đăng xuất'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (setupMode)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'Bạn cần chọn môn, tự đánh giá kỹ năng và tick cam kết trước khi vào Room hoặc Apply.',
                style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          _IdentityCard(user: user),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle('Môn đang học'),
          SegmentedButton<String>(
            segments: [for (final c in vm.courses) ButtonSegment(value: c, label: Text(c))],
            emptySelectionAllowed: true,
            selected: {if (vm.courseCode != null) vm.courseCode!},
            onSelectionChanged: vm.canChangeCourse
                ? (s) {
                    if (s.isNotEmpty) vm.setCourse(s.first);
                  }
                : null,
          ),
          if (!vm.canChangeCourse)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                'Môn đã chọn không đổi được.',
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle('Tự đánh giá kỹ năng (0–100)'),
          for (final entry in SkillScores.labels.entries)
            _SkillSlider(
              label: entry.value,
              value: vm.skills.valueOf(entry.key),
              onChanged: (v) => vm.setSkill(entry.key, v),
            ),
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            value: vm.commitment,
            onChanged: (v) => vm.setCommitment(v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Tôi cam kết chịu trách nhiệm với thông tin đã khai báo'),
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton(
            onPressed: vm.canSave ? () => _save(context) : null,
            child: Text(vm.saving ? 'Đang lưu...' : 'Lưu hồ sơ'),
          ),
          if (!vm.canSave && !vm.saving)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                vm.courseCode == null ? 'Hãy chọn môn đang học.' : 'Cần tick ô cam kết để lưu.',
                style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          if (!setupMode) ...[
            const SizedBox(height: AppSpacing.xxl),
            const ReportSection(),
            const SizedBox(height: AppSpacing.xl),
            const _RemoteConfigSection(),
            const SizedBox(height: AppSpacing.xl),
            const _CrashlyticsSection(),
            if (vm.canSeedDemo) ...[
              const SizedBox(height: AppSpacing.xl),
              const _DemoSeedSection(),
            ],
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthViewModel>().signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

/// Thong tin lay tu email va MSSV, chi doc (BR-04).
class _IdentityCard extends StatelessWidget {
  final AppUser user;
  const _IdentityCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  foregroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: text.titleMedium, overflow: TextOverflow.ellipsis),
                      Text(
                        user.email,
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            _readOnly(context, 'MSSV', user.studentCode),
            _readOnly(context, 'Ngành', user.major),
            _readOnly(context, 'Khóa', user.cohort),
          ],
        ),
      ),
    );
  }

  Widget _readOnly(BuildContext context, String label, String? value) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(child: Text(value ?? 'Không xác định từ email', style: text.bodyMedium)),
          const Icon(
            Icons.lock_outline,
            size: 16,
            color: AppColors.textSecondary,
            semanticLabel: 'Không sửa được',
          ),
        ],
      ),
    );
  }
}

class _SkillSlider extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _SkillSlider({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 120, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            max: 100,
            divisions: 20,
            label: '$value',
            semanticFormatterCallback: (v) => '$label ${v.round()} trên 100',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.end)),
      ],
    );
  }
}

/// Hien gia tri Remote Config dang dung (de demo thay doi tren console).
class _RemoteConfigSection extends StatelessWidget {
  const _RemoteConfigSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final values = vm.remoteValues;
    final last = vm.remoteLastFetch;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionTitle('Remote Config')),
            IconButton(
              tooltip: 'Tải lại cấu hình',
              onPressed: vm.refreshRemoteConfig,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                title: const Text('room_list_limit'),
                subtitle: const Text('Số Room tối đa hiển thị trên danh sách'),
                trailing: Text('${values.roomListLimit}'),
              ),
              ListTile(
                title: const Text('announcement_banner'),
                subtitle: Text(
                  values.announcementBanner.isEmpty
                      ? '(trống – ẩn banner)'
                      : values.announcementBanner,
                ),
              ),
              if (last != null)
                ListTile(
                  dense: true,
                  title: Text('Tải lần cuối: ${TimeOfDay.fromDateTime(last).format(context)}'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Demo Crashlytics: mot loi da xu ly va mot crash thu nghiem.
class _CrashlyticsSection extends StatelessWidget {
  const _CrashlyticsSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Kiểm tra Crashlytics (demo)'),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await vm.recordHandledError();
            if (context.mounted) showResult(context, result);
          },
          icon: const Icon(Icons.bug_report_outlined),
          label: const Text('Ghi lỗi có xử lý'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
          onPressed: () async {
            final ok = await confirm(
              context,
              title: 'Crash thử nghiệm?',
              message:
                  'Ứng dụng sẽ bị đóng ngay để gửi báo cáo crash lên Crashlytics. '
                  'Mở lại app để báo cáo được gửi đi.',
              confirmLabel: 'Crash ngay',
              destructive: true,
            );
            if (ok) vm.triggerTestCrash();
          },
          icon: const Icon(Icons.warning_amber_outlined),
          label: const Text('Gây crash thử nghiệm'),
        ),
      ],
    );
  }
}

/// Chi hien o ban debug: tao du lieu de mot nguoi test duoc luong nhieu nguoi.
class _DemoSeedSection extends StatelessWidget {
  const _DemoSeedSection();

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ProfileViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionTitle('Dữ liệu demo (bản debug)'),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await vm.seedDemo();
            if (context.mounted) showResult(context, result);
          },
          icon: const Icon(Icons.dataset_outlined),
          label: const Text('Tạo Room và đơn Apply demo'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await vm.fillMyRoomDemo();
            if (context.mounted) showResult(context, result);
          },
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Thêm thành viên demo cho nhóm đủ ngưỡng'),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () async {
            final result = await vm.demoMembersAccept();
            if (context.mounted) showResult(context, result);
          },
          icon: const Icon(Icons.how_to_vote_outlined),
          label: const Text('Thành viên demo đồng ý các đơn đang vote'),
        ),
      ],
    );
  }
}
