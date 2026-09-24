import 'dart:io';
import 'dart:math';

import 'package:diem_danh/core/config/app_settings.dart';
import 'package:diem_danh/data/demo/fake_roster.dart';
import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/main.dart';
import 'package:diem_danh/services/checkin_server/lan_addresses.dart';
import 'package:diem_danh/ui/providers/providers.dart';
import 'package:diem_danh/ui/providers/qr_controller.dart';
import 'package:diem_danh/ui/providers/session_controller.dart';
import 'package:diem_danh/ui/screens/attendance/random_call_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_session_repository.dart';
import 'golden_helpers.dart';

/// QR controller frozen in a "running" state: no real server in goldens.
class FrozenQrController extends QrController {
  FrozenQrController(this.frozen);

  final QrRunState frozen;

  @override
  QrRunState build() => frozen;

  @override
  Future<void> start(int sessionId) async {}

  @override
  Future<void> stop() async {}

  @override
  Duration get remaining => const Duration(milliseconds: 2400);
}

void main() {
  late Directory tmp;
  late Map<String, String> photos;

  setUpAll(() async {
    await loadAppFonts();
    tmp = Directory.systemTemp.createTempSync('diem_danh_golden2');
    photos = writeDemoPhotos(tmp);
  });

  tearDownAll(() => tmp.deleteSync(recursive: true));

  /// 35-student session with a realistic mix of marks and flags.
  Future<(FakeSessionRepository, int)> seeded({bool flags = true}) async {
    final repo = FakeSessionRepository(
      students: [
        for (var i = 0; i < fakeRoster.length; i++)
          Student(
            id: i + 1,
            classId: 1,
            rollNumber: fakeRoster[i].rollNumber,
            fullName: fakeRoster[i].fullName,
            imagePath: photos[fakeRoster[i].rollNumber],
          ),
      ],
    );
    final (s, _) = await repo.findOrCreate(1, DateTime(2026, 9, 23), 2);
    final id = s.id!;
    for (var i = 0; i < 22; i++) {
      final roll = fakeRoster[i].rollNumber;
      final qr = i.isOdd;
      AttendanceFlag? flag;
      if (flags && i == 5) flag = AttendanceFlag.deviceMismatch;
      if (flags && i == 9) flag = AttendanceFlag.multiStudentDevice;
      if (flags && i == 13) flag = AttendanceFlag.noDeviceCookie;
      await repo.upsert(
        AttendanceRecord(
          sessionId: id,
          rollNumber: roll,
          status: i == 2 || i == 7
              ? AttendanceStatus.absent
              : (qr ? AttendanceStatus.pending : AttendanceStatus.present),
          method: qr ? AttendanceMethod.qr : AttendanceMethod.manual,
          flag: flag,
          timestamp: DateTime(2026, 9, 23, 9, 30 + i),
        ),
      );
    }
    return (repo, id);
  }

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required Brightness b,
    required Size size,
    required FakeSessionRepository repo,
    required AttendanceRoute route,
    QrRunState? qr,
    bool hideList = false,
  }) async {
    setSurface(tester, size);
    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(repo),
        initialSettingsProvider.overrideWithValue(
          AppSettings(
            themeMode: b == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
            lecturerName: 'Trần Minh Khoa',
            wifiName: 'DiemDanh-SE1801',
            wifiPassword: '12345678',
            hideListWhenProjecting: hideList,
          ),
        ),
        classSummariesProvider.overrideWith((ref) async => demoSummaries()),
        if (qr != null)
          qrControllerProvider.overrideWith(() => FrozenQrController(qr)),
      ],
    );
    addTearDown(container.dispose);
    container.read(sectionProvider.notifier).go(AppSection.attendance);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const DiemDanhApp(),
      ),
    );
    await settle(tester);
    await precacheImages(tester, photos.values.map((p) => FileImage(File(p))));
    container
        .read(attendanceRouteProvider.notifier)
        .open(route.sessionId, route.view);
    if (route.view == AttendanceView.qr) {
      // The countdown bar repaints every frame and never settles.
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    } else {
      await settle(tester);
    }
    return container;
  }

  for (final b in Brightness.values) {
    for (final e in {
      'small': const Size(1024, 640),
      'large': const Size(1920, 1080),
    }.entries) {
      testWidgets('manual grid ${e.key} ${b.name}', (tester) async {
        final (repo, id) = await seeded();
        await pump(
          tester,
          b: b,
          size: e.value,
          repo: repo,
          route: AttendanceRoute(id, AttendanceView.manual),
        );
        // Select a few students down the list.
        for (var i = 0; i < 6; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
        }
        await settle(tester);
        await expectLater(
          find.byType(DiemDanhApp),
          matchesGoldenFile('manual_grid_${e.key}_${b.name}.png'),
        );
      });
    }

    testWidgets('manual table ${b.name}', (tester) async {
      final (repo, id) = await seeded();
      await pump(
        tester,
        b: b,
        size: const Size(1024, 640),
        repo: repo,
        route: AttendanceRoute(id, AttendanceView.manual),
      );
      await tester.tap(find.text('Bảng'));
      await settle(tester);
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('manual_table_${b.name}.png'),
      );
    });

    testWidgets('manual focus ${b.name}', (tester) async {
      final (repo, id) = await seeded();
      await pump(
        tester,
        b: b,
        size: const Size(1024, 640),
        repo: repo,
        route: AttendanceRoute(id, AttendanceView.manual),
      );
      for (var i = 0; i < 5; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await settle(tester);
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('manual_focus_${b.name}.png'),
      );
    });

    testWidgets('review ${b.name}', (tester) async {
      final (repo, id) = await seeded();
      await pump(
        tester,
        b: b,
        size: const Size(1024, 640),
        repo: repo,
        route: AttendanceRoute(id, AttendanceView.review),
      );
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('review_${b.name}.png'),
      );
    });

    testWidgets('summary ${b.name}', (tester) async {
      final (repo, id) = await seeded(flags: false);
      final container = await pump(
        tester,
        b: b,
        size: const Size(1280, 800),
        repo: repo,
        route: AttendanceRoute(id, AttendanceView.summary),
      );
      final ctl = container.read(sessionControllerProvider(id).notifier);
      await ctl.markUnmarkedAbsent();
      await ctl.confirm();
      await settle(tester);
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('summary_${b.name}.png'),
      );
    });

    testWidgets('create session dialog ${b.name}', (tester) async {
      final (repo, _) = await seeded();
      await pump(
        tester,
        b: b,
        size: const Size(1024, 640),
        repo: repo,
        route: const AttendanceRoute(1, AttendanceView.review),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(DiemDanhApp)),
      );
      container.read(attendanceRouteProvider.notifier).close();
      await settle(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      await expectLater(
        find.byType(DiemDanhApp),
        matchesGoldenFile('create_session_${b.name}.png'),
      );
    });
  }

  final qrState = QrRunState(
    sessionId: 1,
    phase: QrPhase.running,
    addresses: const [
      LanAddress(
        interfaceName: 'Local Area Connection* 10',
        ip: '192.168.137.1',
      ),
    ],
    address: const LanAddress(
      interfaceName: 'Local Area Connection* 10',
      ip: '192.168.137.1',
    ),
    port: 8080,
    token: '3f9a1c07be52d4e8',
    live: [
      for (var i = 0; i < 9; i++)
        LiveEntry(
          id: i,
          time: DateTime(2026, 9, 23, 9, 40 - i),
          rollNumber: fakeRoster[i * 2 + 1].rollNumber,
          student: Student(
            classId: 1,
            rollNumber: fakeRoster[i * 2 + 1].rollNumber,
            fullName: fakeRoster[i * 2 + 1].fullName,
            imagePath: null,
          ),
          flagLabel: i == 1
              ? AttendanceFlag.deviceMismatch.label
              : (i == 3 ? AttendanceFlag.multiStudentDevice.label : null),
          rejected: i == 3,
          otherStudent: i == 3
              ? Student(
                  classId: 1,
                  rollNumber: fakeRoster[0].rollNumber,
                  fullName: fakeRoster[0].fullName,
                )
              : null,
        ),
    ],
  );

  for (final e in {
    'small': const Size(1024, 640),
    'large': const Size(1920, 1080),
  }.entries) {
    for (final b in Brightness.values) {
      testWidgets('qr projection ${e.key} ${b.name}', (tester) async {
        final (repo, id) = await seeded();
        await pump(
          tester,
          b: b,
          size: e.value,
          repo: repo,
          route: AttendanceRoute(id, AttendanceView.qr),
          qr: qrState,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await expectLater(
          find.byType(DiemDanhApp),
          matchesGoldenFile('qr_${e.key}_${b.name}.png'),
        );
      });
    }
  }

  testWidgets('qr projection hidden list', (tester) async {
    final (repo, id) = await seeded();
    await pump(
      tester,
      b: Brightness.light,
      size: const Size(1920, 1080),
      repo: repo,
      route: AttendanceRoute(id, AttendanceView.qr),
      qr: qrState,
      hideList: true,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await expectLater(
      find.byType(DiemDanhApp),
      matchesGoldenFile('qr_hidden_list.png'),
    );
  });

  testWidgets('random call dialog', (tester) async {
    final (repo, id) = await seeded();
    final container = await pump(
      tester,
      b: Brightness.light,
      size: const Size(1280, 800),
      repo: repo,
      route: AttendanceRoute(id, AttendanceView.manual),
    );
    final context = tester.element(find.byType(Scaffold).last);
    showRandomCallDialog(
      context,
      container.read(sessionControllerProvider(id)).value,
      id,
      random: Random(4),
    );
    await settle(tester);
    await expectLater(
      find.byType(DiemDanhApp),
      matchesGoldenFile('random_call.png'),
    );
  });
}
