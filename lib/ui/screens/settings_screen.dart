import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/config/app_settings.dart';
import '../../core/theme/app_theme.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    return ListView(
      padding: const EdgeInsets.all(Gaps.xl),
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SettingsCard(
                  icon: LucideIcons.palette,
                  title: 'Giao diện',
                  children: [
                    SegmentedButton<ThemeMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(LucideIcons.sun, size: 16),
                          label: Text('Sáng'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(LucideIcons.moon, size: 16),
                          label: Text('Tối'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(LucideIcons.monitor, size: 16),
                          label: Text('Theo hệ thống'),
                        ),
                      ],
                      selected: {s.themeMode},
                      onSelectionChanged: (v) => notifier.setThemeMode(v.first),
                    ),
                  ],
                ),
                const SizedBox(height: Gaps.lg),
                _SettingsCard(
                  icon: LucideIcons.userRound,
                  title: 'Giảng viên',
                  children: [
                    _CommitField(
                      label: 'Tên hiển thị',
                      initial: s.lecturerName,
                      hint: 'Ví dụ: Nguyễn Văn A',
                      onCommit: (v) {
                        notifier.update(
                          (x) => x.copyWith(lecturerName: v.trim()),
                        );
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: Gaps.lg),
                _SettingsCard(
                  icon: LucideIcons.clipboardCheck,
                  title: 'Điểm danh',
                  children: [
                    _CommitField(
                      label: 'Ngưỡng cảnh báo vắng (%)',
                      initial: '${(s.absenceThreshold * 100).round()}',
                      helper: 'Sinh viên vắng từ ngưỡng này trở lên được tô bút đỏ.',
                      digitsOnly: true,
                      width: 200,
                      onCommit: (v) {
                        final pct = int.tryParse(v);
                        if (pct == null || pct < 1 || pct > 100) {
                          return 'Nhập số từ 1 đến 100';
                        }
                        notifier.update(
                          (x) => x.copyWith(absenceThreshold: pct / 100),
                        );
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: Gaps.lg),
                _SettingsCard(
                  icon: LucideIcons.qrCode,
                  title: 'Điểm danh QR',
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tự động duyệt khi không có cờ',
                                style: context.text.bodyStrong,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Lượt quét QR hợp lệ được tính Có mặt ngay. Khi kết thúc '
                                '(QR hoặc thủ công), nếu không còn bản ghi cần xem thì buổi '
                                'được tự xác nhận và người chưa điểm danh được ghi Vắng. '
                                'Tắt để duyệt tay từng buổi.',
                                style: context.text.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: Gaps.lg),
                        Switch(
                          value: s.autoApprove,
                          onChanged: (v) => notifier.update(
                            (x) => x.copyWith(autoApprove: v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Gaps.md),
                    Wrap(
                      spacing: Gaps.lg,
                      runSpacing: Gaps.md,
                      children: [
                        _CommitField(
                          label: 'Cổng máy chủ',
                          initial: '${s.qrPort}',
                          digitsOnly: true,
                          width: 200,
                          onCommit: (v) {
                            final port = int.tryParse(v);
                            if (port == null || port < 1024 || port > 65535) {
                              return 'Cổng từ 1024 đến 65535';
                            }
                            notifier.update((x) => x.copyWith(qrPort: port));
                            return null;
                          },
                        ),
                        _CommitField(
                          label: 'Chu kỳ đổi mã (giây)',
                          initial: '${s.qrPeriodSeconds}',
                          digitsOnly: true,
                          width: 200,
                          onCommit: (v) {
                            final sec = int.tryParse(v);
                            if (sec == null ||
                                sec < AppSettings.minQrPeriodSeconds ||
                                sec > 60) {
                              return 'Từ ${AppSettings.minQrPeriodSeconds} đến 60 giây';
                            }
                            notifier.update(
                              (x) => x.copyWith(qrPeriodSeconds: sec),
                            );
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: Gaps.md),
                    Wrap(
                      spacing: Gaps.lg,
                      runSpacing: Gaps.md,
                      children: [
                        _CommitField(
                          label: 'Tên Wi-Fi hiện trên màn chiếu',
                          initial: s.wifiName,
                          hint: 'Ví dụ: DiemDanh-SE1801',
                          width: 300,
                          onCommit: (v) {
                            notifier.update(
                              (x) => x.copyWith(wifiName: v.trim()),
                            );
                            return null;
                          },
                        ),
                        _CommitField(
                          label: 'Mật khẩu Wi-Fi',
                          initial: s.wifiPassword,
                          helper: 'Để trống nếu không muốn chiếu mật khẩu.',
                          width: 300,
                          onCommit: (v) {
                            notifier.update(
                              (x) => x.copyWith(wifiPassword: v.trim()),
                            );
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: Gaps.sm),
                    Text(
                      'Khuyến nghị bật Mobile Hotspot của laptop: Wi-Fi trường thường chặn '
                      'các thiết bị thấy nhau. Card mạng/IP chọn ngay trên màn chiếu QR.',
                      style: context.text.caption,
                    ),
                  ],
                ),
                const SizedBox(height: Gaps.lg),
                _SettingsCard(
                  icon: LucideIcons.sheet,
                  title: 'Tài khoản Google & bảng tính',
                  children: [
                    Text(
                      'Đăng nhập Google và đồng bộ Google Sheets sẽ có ở bản sau. '
                      'Hiện dữ liệu chỉ lưu trên máy này.',
                      style: context.text.body.copyWith(
                        color: context.colors.pencilText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(Gaps.xl),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.gridLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: c.ink),
              const SizedBox(width: Gaps.sm),
              Text(title, style: context.text.sectionTitle),
            ],
          ),
          const SizedBox(height: Gaps.lg),
          ...children,
        ],
      ),
    );
  }
}

/// Text field that saves when the user presses Enter or leaves the field.
/// [onCommit] returns an error message, or null when the value was saved.
class _CommitField extends StatefulWidget {
  const _CommitField({
    required this.label,
    required this.initial,
    required this.onCommit,
    this.hint,
    this.helper,
    this.digitsOnly = false,
    this.width = 360,
  });

  final String label;
  final String initial;
  final String? Function(String) onCommit;
  final String? hint;
  final String? helper;
  final bool digitsOnly;
  final double width;

  @override
  State<_CommitField> createState() => _CommitFieldState();
}

class _CommitFieldState extends State<_CommitField> {
  late final _controller = TextEditingController(text: widget.initial);
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    if (_controller.text == widget.initial && _error == null) return;
    final error = widget.onCommit(_controller.text);
    setState(() => _error = error);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu "${widget.label}".'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onSubmitted: (_) => _commit(),
        inputFormatters: widget.digitsOnly
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          helperText: widget.helper,
          helperMaxLines: 2,
          errorText: _error,
        ),
      ),
    );
  }
}
