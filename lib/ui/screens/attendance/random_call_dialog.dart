import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models.dart';
import '../../providers/session_controller.dart';
import '../../widgets/status_mark.dart';
import '../../widgets/student_photo.dart';

/// Picks 3–5 checked-in students (QR check-ins first) at random.
List<Student> pickRandomStudents(SessionState s, Random rng) {
  final checked = s.students.where(
    (st) => s.records[st.rollNumber]?.isCheckedIn ?? false,
  );
  final viaQr = checked
      .where((st) => s.records[st.rollNumber]!.method == AttendanceMethod.qr)
      .toList();
  final pool = (viaQr.isNotEmpty ? viaQr : checked.toList())..shuffle(rng);
  final count = min(pool.length, 3 + rng.nextInt(3));
  return pool.take(count).toList();
}

/// Spot check: the lecturer calls these names; anyone missing is marked
/// absent with a flag. [random] is injectable for tests.
Future<void> showRandomCallDialog(
  BuildContext context,
  SessionState? s,
  int sessionId, {
  Random? random,
}) async {
  if (s == null) return;
  final picked = pickRandomStudents(s, random ?? Random());
  if (picked.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chưa có sinh viên nào điểm danh để gọi.')),
    );
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (_) => _RandomCallDialog(sessionId: sessionId, students: picked),
  );
}

class _RandomCallDialog extends ConsumerStatefulWidget {
  const _RandomCallDialog({required this.sessionId, required this.students});

  final int sessionId;
  final List<Student> students;

  @override
  ConsumerState<_RandomCallDialog> createState() => _RandomCallDialogState();
}

class _RandomCallDialogState extends ConsumerState<_RandomCallDialog> {
  late List<Student> _students = widget.students;

  Future<void> _present(Student st) => ref
      .read(sessionControllerProvider(widget.sessionId).notifier)
      .mark(st.rollNumber, AttendanceStatus.present);

  Future<void> _missing(Student st) => ref
      .read(sessionControllerProvider(widget.sessionId).notifier)
      .mark(
        st.rollNumber,
        AttendanceStatus.absent,
        flag: AttendanceFlag.spotCheckFailed,
      );

  void _again() {
    final s = ref.read(sessionControllerProvider(widget.sessionId)).value;
    if (s == null) return;
    setState(() => _students = pickRandomStudents(s, Random()));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionControllerProvider(widget.sessionId)).value;
    final t = context.text;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(LucideIcons.shuffle),
          const SizedBox(width: Gaps.sm),
          Expanded(
            child: Text('Gọi ngẫu nhiên – ${_students.length} sinh viên'),
          ),
        ],
      ),
      content: SizedBox(
        width: 1000,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gọi tên từng người. Ai không có mặt thì bấm "Không có mặt": bản ghi '
                'chuyển sang Vắng và được gắn cờ.',
                style: t.body,
              ),
              const SizedBox(height: Gaps.lg),
              Wrap(
                spacing: Gaps.lg,
                runSpacing: Gaps.lg,
                children: [
                  for (final st in _students)
                    _CallCard(
                      student: st,
                      record: s?.records[st.rollNumber],
                      onPresent: () => _present(st),
                      onMissing: () => _missing(st),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _again,
          icon: const Icon(LucideIcons.refreshCw, size: 16),
          label: const Text('Gọi lượt khác'),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Xong'),
        ),
      ],
    );
  }
}

class _CallCard extends StatelessWidget {
  const _CallCard({
    required this.student,
    required this.record,
    required this.onPresent,
    required this.onMissing,
  });

  final Student student;
  final AttendanceRecord? record;
  final VoidCallback onPresent;
  final VoidCallback onMissing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final missing = record?.status == AttendanceStatus.absent;
    final confirmed = record?.status == AttendanceStatus.present;
    final nameStyle = t.bodyStrong.copyWith(fontSize: 18, height: 1.3);
    return Container(
      width: 180,
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: missing ? c.redPenSoft : c.surface,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(
          color: confirmed ? c.ink : (missing ? c.redPen : c.gridLine),
          width: confirmed || missing ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: StudentPhoto(
                  fullName: student.fullName,
                  photo: photoProviderFor(student.imagePath),
                  desaturate: missing,
                ),
              ),
              if (missing || confirmed)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                    ),
                    child: StatusMark(
                      kind: missing ? MarkKind.absent : MarkKind.present,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gaps.sm),
          SizedBox(
            // Two lines of the name style, so cards line up.
            height: nameStyle.fontSize! * nameStyle.height! * 2 + 4,
            child: Text(
              student.fullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: nameStyle,
            ),
          ),
          Text(student.rollNumber, style: t.rollNumber),
          const SizedBox(height: Gaps.sm),
          FilledButton(
            onPressed: confirmed ? null : onPresent,
            child: const Text('Có mặt'),
          ),
          const SizedBox(height: Gaps.xs),
          OutlinedButton(
            onPressed: missing ? null : onMissing,
            style: OutlinedButton.styleFrom(foregroundColor: c.redPen),
            child: const Text('Không có mặt'),
          ),
        ],
      ),
    );
  }
}
