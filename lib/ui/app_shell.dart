import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

import '../core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'screens/class_detail_screen.dart';
import 'screens/classes_screen.dart';
import 'screens/attendance/attendance_section.dart';
import 'screens/attendance/create_session_dialog.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/guarded_action.dart';
import 'widgets/sync_badge.dart';

/// Width below which the navigation rail collapses to icons.
const double _railCollapseWidth = 1200;

class _Destination {
  const _Destination(this.section, this.icon, this.label, this.shortcut);

  final AppSection section;
  final IconData icon;
  final String label;
  final String? shortcut;
}

const _destinations = [
  _Destination(AppSection.classes, LucideIcons.users, 'Lớp học', null),
  _Destination(
    AppSection.attendance,
    LucideIcons.clipboardCheck,
    'Điểm danh',
    'Ctrl+N',
  ),
  _Destination(AppSection.history, LucideIcons.history, 'Lịch sử', null),
  _Destination(AppSection.settings, LucideIcons.settings, 'Cài đặt', 'Ctrl+,'),
];

class ToggleFullScreenIntent extends Intent {
  const ToggleFullScreenIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class NewSessionIntent extends Intent {
  const NewSessionIntent();
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(sectionProvider);
    final c = context.colors;
    final wide = MediaQuery.sizeOf(context).width >= _railCollapseWidth;
    final selectedIndex = _destinations.indexWhere((d) => d.section == section);
    // The QR projection takes the whole window: no rail, no title bar.
    final projecting =
        section == AppSection.attendance &&
        ref.watch(attendanceRouteProvider)?.view == AttendanceView.qr;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.f11): ToggleFullScreenIntent(),
        SingleActivator(LogicalKeyboardKey.comma, control: true):
            OpenSettingsIntent(),
        SingleActivator(LogicalKeyboardKey.keyN, control: true):
            NewSessionIntent(),
      },
      child: Actions(
        actions: {
          ToggleFullScreenIntent: GuardedAction<ToggleFullScreenIntent>(
            onInvoke: (_) async {
              final full = await windowManager.isFullScreen();
              await windowManager.setFullScreen(!full);
              return null;
            },
          ),
          OpenSettingsIntent: GuardedAction<OpenSettingsIntent>(
            onInvoke: (_) =>
                ref.read(sectionProvider.notifier).go(AppSection.settings),
          ),
          NewSessionIntent: GuardedAction<NewSessionIntent>(
            onInvoke: (_) => showCreateSessionFlow(context, ref),
          ),
        },
        child: FocusScope(
          autofocus: true,
          child: projecting
              ? const AttendanceSection()
              : Scaffold(
                  body: Row(
                    children: [
                      NavigationRail(
                        extended: wide,
                        selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
                        onDestinationSelected: (i) => ref
                            .read(sectionProvider.notifier)
                            .go(_destinations[i].section),
                        labelType: wide ? null : NavigationRailLabelType.none,
                        leading: _Logo(extended: wide),
                        trailingAtBottom: true,
                        trailing: _LecturerTag(extended: wide),
                        destinations: [
                          for (final d in _destinations)
                            NavigationRailDestination(
                              icon: Tooltip(
                                message: d.shortcut == null
                                    ? d.label
                                    : '${d.label} (${d.shortcut})',
                                child: Icon(d.icon),
                              ),
                              label: Text(d.label),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                            ),
                        ],
                      ),
                      VerticalDivider(width: 1, color: c.gridLine),
                      Expanded(child: _SectionBody(section: section)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SectionBody extends ConsumerWidget {
  const _SectionBody({required this.section});

  final AppSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openClass = ref.watch(openClassProvider);
    final (String title, Widget body) = switch (section) {
      AppSection.classes when openClass != null => (
        'Chi tiết lớp',
        ClassDetailScreen(classId: openClass),
      ),
      AppSection.classes => ('Lớp học', const ClassesScreen()),
      AppSection.attendance => (
        attendanceTitle(ref.watch(attendanceRouteProvider)),
        const AttendanceSection(),
      ),
      AppSection.history => ('Lịch sử', const HistoryScreen()),
      AppSection.settings => ('Cài đặt', const SettingsScreen()),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TitleBar(
          title: title,
          onBack:
              section == AppSection.attendance &&
                  ref.watch(attendanceRouteProvider) != null
              ? () => ref.read(attendanceRouteProvider.notifier).close()
              : null,
        ),
        Expanded(child: body),
      ],
    );
  }
}

class _TitleBar extends ConsumerWidget {
  const _TitleBar({required this.title, this.onBack});

  final String title;

  /// Shows a back arrow to the list of sessions when set.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: Gaps.xl),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.gridLine)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            Tooltip(
              message: 'Về danh sách buổi điểm danh',
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(LucideIcons.arrowLeft),
              ),
            ),
            const SizedBox(width: Gaps.sm),
          ],
          Expanded(
            child: Text(
              title,
              style: context.text.screenTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Google Sheets sync arrives in stage 5.
          SyncBadge(
            state: SyncState.notConnected,
            onPressed: () =>
                ref.read(sectionProvider.notifier).go(AppSection.history),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final mark = Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: c.ink,
        borderRadius: BorderRadius.circular(Radii.button),
      ),
      alignment: Alignment.center,
      child: Icon(LucideIcons.notebookPen, color: c.onInk, size: 20),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gaps.md, Gaps.lg, Gaps.md, Gaps.xl),
      child: extended
          ? SizedBox(
              width: 196,
              child: Row(
                children: [
                  mark,
                  const SizedBox(width: Gaps.md),
                  Text('Sổ điểm danh', style: context.text.sectionTitle),
                ],
              ),
            )
          : mark,
    );
  }
}

class _LecturerTag extends ConsumerWidget {
  const _LecturerTag({required this.extended});

  final bool extended;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider.select((s) => s.lecturerName));
    final label = name.isEmpty ? 'Giảng viên' : name;
    final c = context.colors;
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: c.inkSoft,
      child: Icon(LucideIcons.userRound, size: 16, color: c.ink),
    );
    return Padding(
      padding: const EdgeInsets.all(Gaps.lg),
      child: Tooltip(
        message: 'GV: $label',
        child: extended
            ? SizedBox(
                width: 188,
                child: Row(
                  children: [
                    avatar,
                    const SizedBox(width: Gaps.sm),
                    Expanded(
                      child: Text(
                        'GV: $label',
                        style: context.text.caption.copyWith(color: c.text),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : avatar,
      ),
    );
  }
}
