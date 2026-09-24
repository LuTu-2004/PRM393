import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/ui/providers/providers.dart';
import 'package:diem_danh/ui/providers/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_session_repository.dart';

void main() {
  late FakeSessionRepository repo;
  late ProviderContainer container;
  late int sessionId;

  setUp(() async {
    repo = FakeSessionRepository(
      students: FakeSessionRepository.defaultStudents(5),
    );
    container = ProviderContainer(
      overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    sessionId = (await repo.findOrCreate(1, DateTime(2026, 9, 23), 2)).$1.id!;
  });

  SessionController ctl() =>
      container.read(sessionControllerProvider(sessionId).notifier);
  Future<SessionState> state() =>
      container.read(sessionControllerProvider(sessionId).future);

  test('mark, counts and persistence', () async {
    await state();
    await ctl().mark('SE180001', AttendanceStatus.present);
    await ctl().mark('SE180002', AttendanceStatus.absent);
    final s = await state();
    expect(s.present, 1);
    expect(s.absent, 1);
    expect(s.unmarked, 3);
    expect(s.title, 'SE1801 · PRN211 · Slot 2 · 23/09');
    expect(
      repo.stored[sessionId]!['SE180001']!.method,
      AttendanceMethod.manual,
    );
  });

  test('undo restores the previous state, including "not marked"', () async {
    await state();
    await ctl().mark('SE180001', AttendanceStatus.present);
    await ctl().mark('SE180001', AttendanceStatus.absent);
    expect(await ctl().undo(), 'SE180001');
    expect(
      (await state()).records['SE180001']!.status,
      AttendanceStatus.present,
    );
    await ctl().undo();
    expect((await state()).records.containsKey('SE180001'), isFalse);
    expect(repo.stored[sessionId]!.containsKey('SE180001'), isFalse);
    expect((await state()).canUndo, isFalse);
    expect(await ctl().undo(), isNull);
  });

  test('manual change keeps QR method, device and flag', () async {
    await repo.upsert(
      AttendanceRecord(
        sessionId: sessionId,
        rollNumber: 'SE180001',
        status: AttendanceStatus.pending,
        method: AttendanceMethod.qr,
        deviceId: 'dev',
        flag: AttendanceFlag.deviceMismatch,
        timestamp: DateTime(2026, 9, 23, 9, 1),
      ),
    );
    await state();
    await ctl().mark('SE180001', AttendanceStatus.present);
    final r = (await state()).records['SE180001']!;
    expect(r.method, AttendanceMethod.qr);
    expect(r.deviceId, 'dev');
    expect(r.flag, AttendanceFlag.deviceMismatch);
    expect(r.needsReview, isFalse, reason: 'approved by the lecturer');
  });

  test('confirm is blocked while flagged pending records remain', () async {
    await repo.upsert(
      AttendanceRecord(
        sessionId: sessionId,
        rollNumber: 'SE180001',
        status: AttendanceStatus.pending,
        method: AttendanceMethod.qr,
        flag: AttendanceFlag.noDeviceCookie,
        timestamp: DateTime(2026, 9, 23, 9, 1),
      ),
    );
    expect((await state()).unresolvedFlags, 1);
    await expectLater(ctl().confirm(), throwsStateError);
  });

  test('confirm: pending -> present, rest absent, session closed', () async {
    await repo.upsert(
      AttendanceRecord(
        sessionId: sessionId,
        rollNumber: 'SE180001',
        status: AttendanceStatus.pending,
        method: AttendanceMethod.qr,
        timestamp: DateTime(2026, 9, 23, 9, 1),
      ),
    );
    await state();
    await ctl().markUnmarkedAbsent();
    await ctl().confirm();
    final s = await state();
    expect(s.isClosed, isTrue);
    expect(s.present, 1);
    expect(s.absent, 4);
    expect(s.unmarked, 0);
    expect(repo.sessions[sessionId]!.status, SessionStatus.closed);

    await ctl().reopen();
    expect((await state()).isClosed, isFalse);
  });

  test('autoConfirmIfClean confirms only when nothing is flagged', () async {
    await repo.upsert(
      AttendanceRecord(
        sessionId: sessionId,
        rollNumber: 'SE180001',
        status: AttendanceStatus.pending,
        method: AttendanceMethod.qr,
        flag: AttendanceFlag.deviceMismatch,
        timestamp: DateTime(2026, 9, 23, 9, 1),
      ),
    );
    await repo.upsert(
      AttendanceRecord(
        sessionId: sessionId,
        rollNumber: 'SE180002',
        status: AttendanceStatus.present,
        method: AttendanceMethod.qr,
        timestamp: DateTime(2026, 9, 23, 9, 2),
      ),
    );
    await state();
    expect(await ctl().autoConfirmIfClean(), isFalse);
    expect((await state()).isClosed, isFalse);
    expect((await state()).unmarked, 3, reason: 'nothing changed');

    await ctl().mark('SE180001', AttendanceStatus.present);
    expect(await ctl().autoConfirmIfClean(), isTrue);
    final s = await state();
    expect(s.isClosed, isTrue);
    expect(s.present, 2);
    expect(s.absent, 3);
  });

  test('reloadRecords picks up check-ins written by the server', () async {
    await state();
    await repo.upsert(
      AttendanceRecord(
        sessionId: sessionId,
        rollNumber: 'SE180003',
        status: AttendanceStatus.pending,
        method: AttendanceMethod.qr,
        timestamp: DateTime(2026, 9, 23, 9, 2),
      ),
    );
    await ctl().reloadRecords();
    expect((await state()).pending, 1);
  });

  test('spot check failure marks absent with a flag', () async {
    await state();
    await ctl().mark(
      'SE180002',
      AttendanceStatus.absent,
      flag: AttendanceFlag.spotCheckFailed,
    );
    final r = (await state()).records['SE180002']!;
    expect(r.status, AttendanceStatus.absent);
    expect(r.flag, AttendanceFlag.spotCheckFailed);
  });
}
