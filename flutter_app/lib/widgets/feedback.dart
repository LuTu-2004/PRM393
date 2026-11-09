import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/viewmodels/action_result.dart';
import 'package:flutter/material.dart';

/// Hien ket qua thao tac bang SnackBar (xanh = thanh cong, do = loi).
void showResult(BuildContext context, ActionResult result) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.ok ? AppColors.success : AppColors.error,
      ),
    );
}

/// Hop thoai xac nhan. [destructive] to mau do cho thao tac khong hoan tac duoc.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.error) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Hop thoai nhap loi nhan don Apply. Tra ve null neu bam Huy.
Future<String?> askApplicationMessage(
  BuildContext context, {
  required String title,
  required String confirmLabel,
  String? initial,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLength: AppConfig.applicationMessageMaxLength,
        maxLines: 4,
        minLines: 2,
        decoration: const InputDecoration(
          labelText: 'Lời nhắn cho nhóm (không bắt buộc)',
          hintText: 'Bạn mạnh về gì, muốn đóng góp gì cho nhóm?',
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
