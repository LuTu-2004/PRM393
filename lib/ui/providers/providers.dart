import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_paths.dart';
import '../../core/config/app_settings.dart';
import '../../data/local/app_database.dart';
import '../../data/local/student_dao.dart';
import '../../data/roster_repository.dart';
import '../../data/session_repository.dart';
import '../../data/import/photo_store.dart';
import '../../domain/models.dart';

// ── Infrastructure (overridden in main / tests) ─────────────────────────────

final appPathsProvider = Provider<AppPaths>(
  (ref) => throw UnimplementedError('appPathsProvider must be overridden'),
);

final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => SettingsStore(ref.watch(appPathsProvider).settingsFile),
);

final initialSettingsProvider = Provider<AppSettings>(
  (ref) => const AppSettings(),
);

final rosterRepositoryProvider = Provider<RosterRepository>(
  (ref) => RosterRepository(
    db: ref.watch(databaseProvider).db,
    photos: PhotoStore(ref.watch(appPathsProvider).photosDir),
  ),
);

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SqliteSessionRepository(ref.watch(databaseProvider).db),
);

// ── Settings ────────────────────────────────────────────────────────────────

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(initialSettingsProvider);

  Future<void> update(AppSettings Function(AppSettings) change) async {
    state = change(state);
    await ref.read(settingsStoreProvider).save(state);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      update((s) => s.copyWith(themeMode: mode));
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

// ── Navigation ──────────────────────────────────────────────────────────────

enum AppSection { classes, attendance, history, settings }

class SectionNotifier extends Notifier<AppSection> {
  @override
  AppSection build() => AppSection.classes;

  void go(AppSection s) => state = s;
}

final sectionProvider = NotifierProvider<SectionNotifier, AppSection>(
  SectionNotifier.new,
);

/// Class opened in the "Lớp học" section; null shows the class list.
class OpenClassNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  void open(int classId) => state = classId;
  void close() => state = null;
}

final openClassProvider = NotifierProvider<OpenClassNotifier, int?>(
  OpenClassNotifier.new,
);

// ── Data ────────────────────────────────────────────────────────────────────

final classSummariesProvider = FutureProvider<List<ClassSummary>>(
  (ref) => ref.watch(rosterRepositoryProvider).classes.listSummaries(),
);

final classInfoProvider = FutureProvider.family<ClassInfo?, int>(
  (ref, id) => ref.watch(rosterRepositoryProvider).classes.getById(id),
);

final classStudentsProvider =
    FutureProvider.family<List<StudentWithStats>, int>(
      (ref, id) =>
          ref.watch(rosterRepositoryProvider).students.listWithStats(id),
    );

/// Refreshes every roster-derived provider after a write.
void invalidateRoster(WidgetRef ref, {int? classId}) {
  ref.invalidate(classSummariesProvider);
  if (classId != null) {
    ref.invalidate(classInfoProvider(classId));
    ref.invalidate(classStudentsProvider(classId));
  }
}

// ── Attendance navigation ───────────────────────────────────────────────────

enum AttendanceView { manual, qr, review, summary }

/// Which session the "Điểm danh" section shows, and in which view.
class AttendanceRoute {
  const AttendanceRoute(this.sessionId, this.view);

  final int sessionId;
  final AttendanceView view;
}

class AttendanceRouteNotifier extends Notifier<AttendanceRoute?> {
  @override
  AttendanceRoute? build() => null;

  void open(int sessionId, AttendanceView view) =>
      state = AttendanceRoute(sessionId, view);

  void close() => state = null;
}

final attendanceRouteProvider =
    NotifierProvider<AttendanceRouteNotifier, AttendanceRoute?>(
      AttendanceRouteNotifier.new,
    );

/// Opens [sessionId] in [view] inside the "Điểm danh" section.
void openAttendance(WidgetRef ref, int sessionId, AttendanceView view) {
  ref.read(attendanceRouteProvider.notifier).open(sessionId, view);
  ref.read(sectionProvider.notifier).go(AppSection.attendance);
}

final sessionOverviewsProvider = FutureProvider<List<SessionOverview>>(
  (ref) => ref.watch(sessionRepositoryProvider).overviews(),
);
