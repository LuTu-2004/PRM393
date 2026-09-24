import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models.dart';
import '../../providers/providers.dart';
import '../../providers/qr_controller.dart';
import '../../providers/session_controller.dart';
import '../../widgets/counter_chip.dart';
import '../../widgets/notebook_grid.dart';
import '../../widgets/state_views.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/status_mark.dart';
import '../../widgets/student_photo.dart';
import 'attendance_dialogs.dart';
import 'random_call_dialog.dart';

/// Projected QR screen. Always light, readable from the back of the room.
class QrProjectionScreen extends ConsumerStatefulWidget {
  const QrProjectionScreen({super.key, required this.sessionId});

  final int sessionId;

  @override
  ConsumerState<QrProjectionScreen> createState() => _QrProjectionScreenState();
}

class _QrProjectionScreenState extends ConsumerState<QrProjectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(qrControllerProvider.notifier).start(widget.sessionId);
      }
    });
  }

  Future<void> _finish() async {
    await ref.read(qrControllerProvider.notifier).stop();
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    await ref
        .read(sessionControllerProvider(widget.sessionId).notifier)
        .reloadRecords();
    if (!mounted) return;
    await finishSession(context, ref, widget.sessionId);
  }

  Future<void> _toManual() async {
    await ref.read(qrControllerProvider.notifier).stop();
    if (await windowManager.isFullScreen()) {
      await windowManager.setFullScreen(false);
    }
    ref
        .read(attendanceRouteProvider.notifier)
        .open(widget.sessionId, AttendanceView.manual);
  }

  @override
  Widget build(BuildContext context) {
    // Projection is always light: projectors wash out dark themes and the QR
    // must sit on white.
    return Theme(
      data: AppTheme.light(),
      child: Builder(
        builder: (context) {
          final qr = ref.watch(qrControllerProvider);
          final session = ref.watch(
            sessionControllerProvider(widget.sessionId),
          );
          return Scaffold(
            body: NotebookGrid(
              background: context.colors.projectionPaper,
              child: session.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: 'Không mở được buổi điểm danh.',
                  hint: '$e',
                ),
                data: (s) => switch (qr.phase) {
                  QrPhase.error => _errorView(qr),
                  QrPhase.idle || QrPhase.starting => const LoadingView(
                    message: 'Đang mở máy chủ điểm danh…',
                  ),
                  _ => _running(context, qr, s),
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _errorView(QrRunState qr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 260,
            child: ErrorView(
              message: qr.error ?? 'Không bắt đầu được điểm danh QR.',
              onRetry: () => ref
                  .read(qrControllerProvider.notifier)
                  .start(widget.sessionId),
            ),
          ),
          TextButton.icon(
            onPressed: _toManual,
            icon: const Icon(LucideIcons.keyboard, size: 16),
            label: const Text('Chuyển sang điểm danh thủ công'),
          ),
        ],
      ),
    );
  }

  Widget _running(BuildContext context, QrRunState qr, SessionState s) {
    final settings = ref.watch(settingsProvider);
    final hideList = settings.hideListWhenProjecting;
    final t = context.text;
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.all(Gaps.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top: how to connect + counter + controls ──────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.wifiName.isEmpty
                          ? 'Kết nối cùng Wi-Fi với máy giảng viên'
                          : 'Kết nối Wi-Fi: "${settings.wifiName}"',
                      style: t.screenTitle.copyWith(fontSize: 30),
                    ),
                    if (settings.wifiPassword.isNotEmpty)
                      Text(
                        'Mật khẩu: ${settings.wifiPassword}',
                        style: t.screenTitle.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: Gaps.xs),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Gaps.sm,
                      children: [
                        Text(
                          s.title,
                          style: t.body.copyWith(color: c.pencilText),
                        ),
                        _AddressPicker(qr: qr),
                        TextButton(
                          onPressed: () => showConnectionHelp(context),
                          child: const Text('Điện thoại không vào được?'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Gaps.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  BigCounter(
                    value: s.checkedIn,
                    total: s.students.length,
                    caption: 'đã điểm danh',
                    huge: true,
                  ),
                  const SizedBox(height: Gaps.sm),
                  Wrap(
                    spacing: Gaps.sm,
                    children: [
                      Tooltip(
                        message: hideList
                            ? 'Hiện danh sách'
                            : 'Ẩn danh sách khi chiếu',
                        child: IconButton(
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .update(
                                (x) => x.copyWith(
                                  hideListWhenProjecting: !hideList,
                                ),
                              ),
                          icon: Icon(
                            hideList ? LucideIcons.eye : LucideIcons.eyeOff,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Toàn màn hình (F11)',
                        child: IconButton(
                          onPressed: () async => windowManager.setFullScreen(
                            !await windowManager.isFullScreen(),
                          ),
                          icon: const Icon(LucideIcons.maximize),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: qr.phase == QrPhase.paused
                            ? ref.read(qrControllerProvider.notifier).resume
                            : ref.read(qrControllerProvider.notifier).pause,
                        icon: Icon(
                          qr.phase == QrPhase.paused
                              ? LucideIcons.play
                              : LucideIcons.pause,
                          size: 18,
                        ),
                        label: Text(
                          qr.phase == QrPhase.paused ? 'Tiếp tục' : 'Tạm dừng',
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _finish,
                        icon: const Icon(LucideIcons.square, size: 16),
                        label: const Text('Kết thúc & duyệt'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: Gaps.lg),
          // ── Body: QR + live list ──────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: hideList ? 1 : 58,
                  child: _QrPanel(
                    qr: qr,
                    controller: ref.read(qrControllerProvider.notifier),
                  ),
                ),
                if (!hideList) ...[
                  const SizedBox(width: Gaps.xl),
                  Expanded(
                    flex: 42,
                    child: _LivePanel(
                      entries: qr.live,
                      records: s.records,
                      onRandomCall: () => showRandomCallDialog(
                        context,
                        ref
                            .read(sessionControllerProvider(widget.sessionId))
                            .value,
                        widget.sessionId,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (hideList)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: Gaps.md),
                child: OutlinedButton.icon(
                  onPressed: () => showRandomCallDialog(
                    context,
                    ref.read(sessionControllerProvider(widget.sessionId)).value,
                    widget.sessionId,
                  ),
                  icon: const Icon(LucideIcons.shuffle, size: 18),
                  label: const Text('Gọi ngẫu nhiên'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddressPicker extends ConsumerWidget {
  const _AddressPicker({required this.qr});

  final QrRunState qr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.text;
    return MenuAnchor(
      builder: (context, controller, _) => Tooltip(
        message: 'Chọn card mạng / địa chỉ IP',
        child: TextButton.icon(
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(LucideIcons.wifi, size: 16),
          label: Text(
            qr.hostPort ?? '—',
            style: t.rollNumber.copyWith(
              color: context.colors.ink,
              fontSize: 15,
            ),
          ),
        ),
      ),
      menuChildren: [
        for (final a in qr.addresses)
          MenuItemButton(
            leadingIcon: Icon(
              a.ip == qr.address?.ip ? LucideIcons.check : LucideIcons.dot,
              size: 16,
            ),
            onPressed: () =>
                ref.read(qrControllerProvider.notifier).selectAddress(a),
            child: Text(a.isWindowsHotspot ? '${a.label} – hotspot' : a.label),
          ),
      ],
    );
  }
}

/// White QR tile with a generous quiet zone and the rotation countdown.
class _QrPanel extends StatelessWidget {
  const _QrPanel({required this.qr, required this.controller});

  final QrRunState qr;
  final QrController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final paused = qr.phase == QrPhase.paused;
    return LayoutBuilder(
      builder: (context, box) {
        final size = (box.maxHeight - 64).clamp(160.0, box.maxWidth);
        return Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF), // QR must sit on pure white.
                borderRadius: BorderRadius.circular(Radii.dialog),
                border: Border.all(color: c.gridLine),
              ),
              padding: EdgeInsets.all(size * 0.06),
              child: paused || qr.url == null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.pause, size: 64, color: c.pencil),
                          const SizedBox(height: Gaps.md),
                          Text(
                            'Đang tạm dừng',
                            style: t.screenTitle.copyWith(fontSize: 34),
                          ),
                        ],
                      ),
                    )
                  : Semantics(
                      label: 'Mã QR điểm danh',
                      child: QrImageView(
                        data: qr.url!,
                        version: QrVersions.auto,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                        backgroundColor: const Color(0xFFFFFFFF),
                        padding: EdgeInsets.zero,
                        gapless: true,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF000000),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF000000),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: Gaps.md),
            if (!paused)
              SizedBox(
                width: size,
                child: _Countdown(controller: controller, period: qr.period),
              ),
          ],
        );
      },
    );
  }
}

/// Progress bar + "Đổi mã sau Ns", repainted every frame from the token clock.
class _Countdown extends StatefulWidget {
  const _Countdown({required this.controller, required this.period});

  final QrController controller;
  final Duration period;

  @override
  State<_Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<_Countdown>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}))..start();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.controller.remaining;
    final fraction = (left.inMilliseconds / widget.period.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final seconds = (left.inMilliseconds / 1000).ceil();
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: fraction, minHeight: 8),
          ),
        ),
        const SizedBox(width: Gaps.md),
        SizedBox(
          width: 150,
          child: Text(
            'Đổi mã sau ${seconds}s',
            style: context.text.bodyStrong.copyWith(
              fontSize: 20,
              fontFeatures: context.text.rollNumber.fontFeatures,
            ),
          ),
        ),
      ],
    );
  }
}

class _LivePanel extends StatelessWidget {
  const _LivePanel({
    required this.entries,
    required this.records,
    required this.onRandomCall,
  });

  final List<LiveEntry> entries;
  final Map<String, AttendanceRecord> records;
  final VoidCallback onRandomCall;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: c.gridLine),
      ),
      padding: const EdgeInsets.all(Gaps.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Vừa điểm danh', style: t.sectionTitle.copyWith(fontSize: 22)),
          const SizedBox(height: Gaps.md),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Chưa có ai điểm danh.\nSinh viên quét mã để bắt đầu.',
                      textAlign: TextAlign.center,
                      style: t.body.copyWith(color: c.pencilText, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (_, i) => _SlideIn(
                      key: ValueKey(entries[i].id),
                      child: _LiveRow(
                        entry: entries[i],
                        record: records[entries[i].rollNumber],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: Gaps.md),
          OutlinedButton.icon(
            onPressed: onRandomCall,
            icon: const Icon(LucideIcons.shuffle, size: 18),
            label: const Text('Gọi ngẫu nhiên'),
          ),
        ],
      ),
    );
  }
}

class _LiveRow extends StatelessWidget {
  const _LiveRow({required this.entry, required this.record});

  final LiveEntry entry;
  final AttendanceRecord? record;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final student = entry.student;
    // The current record wins: a spot check may have changed it since.
    final flag = entry.rejected
        ? entry.flagLabel
        : (record?.flag?.label ?? entry.flagLabel);
    final mark = entry.rejected
        ? MarkKind.absent
        : switch (record?.status) {
            AttendanceStatus.absent => MarkKind.absent,
            AttendanceStatus.present => MarkKind.present,
            _ => MarkKind.pending,
          };
    return Container(
      margin: const EdgeInsets.only(bottom: Gaps.sm),
      padding: const EdgeInsets.all(Gaps.sm),
      decoration: BoxDecoration(
        color: flag != null
            ? Color.alphaBlend(c.highlighter.withValues(alpha: 0.55), c.surface)
            : c.paper,
        borderRadius: BorderRadius.circular(Radii.button),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            height: 56,
            child: StudentPhoto(
              fullName: student?.fullName ?? entry.rollNumber,
              photo: photoProviderFor(student?.imagePath),
              initialsSize: 15,
            ),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student?.fullName ?? entry.rollNumber,
                  style: t.bodyStrong.copyWith(fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (flag != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: ReviewTagContent(
                      reason: entry.rejected && entry.otherStudent != null
                          ? '$flag (đã dùng cho ${entry.otherStudent!.fullName})'
                          : flag,
                    ),
                  )
                else
                  Text(entry.rollNumber, style: t.rollNumber),
              ],
            ),
          ),
          const SizedBox(width: Gaps.sm),
          StatusMark(kind: mark, size: 28),
        ],
      ),
    );
  }
}

/// Newest entries slide in from the top (180ms), unless motion is reduced.
class _SlideIn extends StatefulWidget {
  const _SlideIn({super.key, required this.child});

  final Widget child;

  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final d = Motion.of(context, Motion.listInsert);
    if (d == Duration.zero) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c
        ..duration = d
        ..forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.3),
            end: Offset.zero,
          ).animate(curve),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Short troubleshooting guide for phones that cannot open the link.
Future<void> showConnectionHelp(BuildContext context) {
  final t = context.text;
  Widget step(String n, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: Gaps.md),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 28, child: Text(n, style: t.bodyStrong)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.bodyStrong),
              Text(body, style: t.body),
            ],
          ),
        ),
      ],
    ),
  );
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Điện thoại không mở được trang điểm danh?'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              step(
                '1',
                'Dùng hotspot của laptop (khuyến nghị)',
                'Wi-Fi của trường thường chặn các thiết bị thấy nhau. Mở Settings → '
                    'Network & internet → Mobile hotspot, bật lên và cho sinh viên kết nối vào. '
                    'Nhập tên và mật khẩu hotspot trong Cài đặt → Điểm danh QR để hiện lên màn chiếu.',
              ),
              step(
                '2',
                'Cho phép qua tường lửa',
                'Lần đầu bắt đầu điểm danh QR, Windows hỏi quyền truy cập mạng cho '
                    '"Sổ điểm danh". Hãy tích cả Private và Public rồi bấm Allow. Nếu lỡ bấm '
                    'Cancel: Windows Security → Firewall → Allow an app through firewall.',
              ),
              step(
                '3',
                'Chọn đúng địa chỉ IP',
                'Máy có nhiều card mạng thì bấm vào địa chỉ trên màn chiếu và chọn card đang '
                    'phát hotspot (thường là 192.168.137.1).',
              ),
              step(
                '4',
                'Kiểm tra từ điện thoại',
                'Trên điện thoại đã kết nối, mở trình duyệt và gõ địa chỉ IP:cổng. Nếu thấy trang '
                    '"Chưa có mã điểm danh" là kết nối đã thông.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Đã hiểu'),
        ),
      ],
    ),
  );
}
