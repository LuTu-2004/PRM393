import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dang nhap Google bang email truong (BR-02). Man hinh duy nhat khi chua dang nhap.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.groups_2_outlined, size: 72, color: AppColors.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'EXE Team Matching',
                    style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ghép nhóm môn EXE101 / EXE201 theo từng học kỳ',
                    style: text.bodyLarge?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  FilledButton.icon(
                    onPressed: vm.signingIn ? null : vm.signIn,
                    icon: vm.signingIn
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(vm.signingIn ? 'Đang đăng nhập...' : 'Đăng nhập bằng Google'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Dùng email trường: @fpt.edu.vn (sinh viên) hoặc @fe.edu.vn (giảng viên).',
                    style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  if (vm.error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.error),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              vm.error!,
                              style: text.bodyMedium?.copyWith(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
