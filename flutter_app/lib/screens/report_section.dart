import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/file_storage_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/report_pdf_builder.dart';
import 'package:exe_matching/services/report_service.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/auth_viewmodel.dart';
import 'package:exe_matching/viewmodels/report_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Khu xuat bao cao PDF trong man Ho so.
class ReportSection extends StatelessWidget {
  const ReportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthViewModel>();
    return ChangeNotifierProvider(
      create: (ctx) => ReportViewModel(
        currentUser: () => auth.user!,
        groups: ctx.read<GroupService>(),
        reports: ctx.read<ReportService>(),
        storage: ctx.read<FileStorageService>(),
        builder: ctx.read<ReportPdfBuilder>(),
        analytics: ctx.read<AnalyticsService>(),
        crashlytics: ctx.read<CrashlyticsService>(),
      ),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatelessWidget {
  const _ReportView();

  Future<void> _export(BuildContext context) async {
    final result = await context.read<ReportViewModel>().export();
    if (context.mounted) showResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ReportViewModel>();
    final text = Theme.of(context).textTheme;
    final date = DateFormat('HH:mm dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Báo cáo PDF', style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        FilledButton.icon(
          onPressed: vm.exporting ? null : () => _export(context),
          icon: vm.exporting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: Text(vm.progress ?? 'Xuất báo cáo PDF'),
        ),
        if (!vm.storageConfigured)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              'Chưa cấu hình Cloudinary nên chưa upload được.',
              style: text.bodySmall?.copyWith(color: AppColors.warning),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        if (vm.loadError != null)
          Text(vm.loadError!, style: text.bodyMedium?.copyWith(color: AppColors.error))
        else if (vm.isLoading)
          const LinearProgressIndicator()
        else if (vm.items.isEmpty)
          Text(
            'Chưa có báo cáo nào.',
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          Card(
            child: Column(
              children: [
                for (final report in vm.items)
                  ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: AppColors.primary),
                    title: Text(report.fileName, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${date.format(report.createdAt)} · '
                      '${(report.sizeBytes / 1024).toStringAsFixed(0)} KB',
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () async {
                      final result = await vm.open(report);
                      if (!result.ok && context.mounted) showResult(context, result);
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
