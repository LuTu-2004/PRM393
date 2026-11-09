import 'package:exe_matching/theme/app_colors.dart';
import 'package:exe_matching/theme/app_theme.dart';
import 'package:exe_matching/viewmodels/auth_viewmodel.dart';
import 'package:exe_matching/widgets/feedback.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// BR-34: dieu khoan giang vien duoc toan quyen dieu phoi, dong y o lan dang nhap dau.
class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  bool _agreed = false;
  bool _submitting = false;

  static const _terms = [
    'Giảng viên được toàn quyền điều phối sinh viên vào nhóm, kể cả phân phối cưỡng chế '
        'sinh viên chưa có nhóm khi hết hạn đăng ký.',
    'Sau khi giảng viên chốt sổ, bạn không thể tự vào hoặc rời nhóm. Muốn chuyển nhóm phải '
        'gửi yêu cầu để giảng viên duyệt.',
    'Ngành và khóa được lấy tự động từ mã số sinh viên và không chỉnh sửa được.',
    'Bạn chịu trách nhiệm với thông tin kỹ năng tự khai báo trong hồ sơ.',
  ];

  Future<void> _accept() async {
    setState(() => _submitting = true);
    final result = await context.read<AuthViewModel>().acceptPolicy();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.ok) showResult(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Điều khoản sử dụng'),
        actions: [
          TextButton(
            onPressed: () => context.read<AuthViewModel>().signOut(),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text('Trước khi bắt đầu, hãy đọc kỹ:', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                  for (final (i, term) in _terms.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${i + 1}. ', style: text.bodyLarge),
                          Expanded(child: Text(term, style: text.bodyLarge)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  CheckboxListTile(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Tôi đã đọc và đồng ý với các điều khoản trên'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _agreed && !_submitting ? _accept : null,
                      child: Text(_submitting ? 'Đang lưu...' : 'Đồng ý và tiếp tục'),
                    ),
                  ),
                  if (!_agreed)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Text(
                        'Cần tick đồng ý để tiếp tục.',
                        style: text.bodySmall?.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
