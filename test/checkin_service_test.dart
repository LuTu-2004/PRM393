import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/services/checkin_server/checkin_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_checkin_store.dart';

void main() {
  late FakeCheckinStore store;
  late CheckinService service;

  setUp(() {
    store = FakeCheckinStore(testRoster);
    service = CheckinService(sessionId: 1, store: store);
  });

  Future<CheckinOutcome> submit(String roll, String? device) =>
      service.submit(rawRollNumber: roll, deviceId: device);

  test('accepted check-ins are pending, via QR, normalized and bound to the device', () async {
    final o = await submit(' se180001 ', 'phone-aaaaaaaaaaaaaaaa');
    expect(o, isA<CheckinAccepted>());
    final r = store.records['SE180001']!;
    expect(r.status, AttendanceStatus.pending);
    expect(r.method, AttendanceMethod.qr);
    expect(r.flag, isNull);
    expect(
      store.devices['SE180001']!.single.deviceId,
      'phone-aaaaaaaaaaaaaaaa',
    );
  });

  test(
    'auto-approve: clean check-ins are present, flagged ones pending',
    () async {
      final auto = CheckinService(
        sessionId: 1,
        store: store,
        autoApprove: true,
      );
      await auto.submit(rawRollNumber: 'SE180001', deviceId: 'phone-a');
      await auto.submit(rawRollNumber: 'SE180002', deviceId: null);
      expect(store.records['SE180001']!.status, AttendanceStatus.present);
      expect(store.records['SE180002']!.status, AttendanceStatus.pending);
      expect(store.records['SE180002']!.flag, AttendanceFlag.noDeviceCookie);

      // Reusing phone A sends the already-present first student back to review.
      await auto.submit(rawRollNumber: 'SE180003', deviceId: 'phone-a');
      final first = store.records['SE180001']!;
      expect(first.status, AttendanceStatus.pending);
      expect(first.flag, AttendanceFlag.multiStudentDevice);
      expect(store.records.containsKey('SE180003'), isFalse);
    },
  );

  test('unknown roll number is rejected', () async {
    final o = await submit('SE999999', 'phone-a');
    expect((o as CheckinRejected).reason, RejectReason.unknownRoll);
    expect(store.records, isEmpty);
  });

  test('second check-in of the same student is rejected', () async {
    await submit('SE180001', 'phone-a');
    final o = await submit('SE180001', 'phone-b');
    expect((o as CheckinRejected).reason, RejectReason.alreadyCheckedIn);
  });

  test(
    'one phone cannot check in a second student; the first gets flagged',
    () async {
      await submit('SE180001', 'phone-a');
      final o = await submit('SE180002', 'phone-a') as CheckinRejected;
      expect(o.reason, RejectReason.deviceUsedByOther);
      expect(o.otherStudent!.rollNumber, 'SE180001');
      expect(store.records.containsKey('SE180002'), isFalse);
      expect(
        store.records['SE180001']!.flag,
        AttendanceFlag.multiStudentDevice,
      );
    },
  );

  test('concurrent requests from one phone cannot both pass', () async {
    final results = await Future.wait([
      submit('SE180001', 'phone-a'),
      submit('SE180002', 'phone-a'),
    ]);
    expect(results.whereType<CheckinAccepted>(), hasLength(1));
    expect(results.whereType<CheckinRejected>(), hasLength(1));
  });

  test(
    'a different phone than in earlier sessions is accepted but flagged',
    () async {
      store.devices['SE180001'] = [
        Device(
          rollNumber: 'SE180001',
          deviceId: 'old-phone',
          firstSeen: DateTime(2026, 9, 1),
          lastSeen: DateTime(2026, 9, 16),
        ),
      ];
      final o = await submit('SE180001', 'new-phone');
      expect(o, isA<CheckinAccepted>());
      expect(store.records['SE180001']!.flag, AttendanceFlag.deviceMismatch);
    },
  );

  test('the same phone as before is not flagged', () async {
    store.devices['SE180001'] = [
      Device(
        rollNumber: 'SE180001',
        deviceId: 'phone-a',
        firstSeen: DateTime(2026, 9, 1),
        lastSeen: DateTime(2026, 9, 16),
      ),
    ];
    await submit('SE180001', 'phone-a');
    expect(store.records['SE180001']!.flag, isNull);
  });

  test('no device cookie is accepted but flagged', () async {
    final o = await submit('SE180001', null);
    expect(o, isA<CheckinAccepted>());
    expect(store.records['SE180001']!.flag, AttendanceFlag.noDeviceCookie);
  });

  test('a student marked absent manually can still check in', () async {
    store.records['SE180001'] = AttendanceRecord(
      sessionId: 1,
      rollNumber: 'SE180001',
      status: AttendanceStatus.absent,
      method: AttendanceMethod.manual,
      timestamp: DateTime(2026, 9, 23, 9),
    );
    expect(await submit('SE180001', 'phone-a'), isA<CheckinAccepted>());
  });

  test('a student who failed a spot check cannot scan back in', () async {
    store.records['SE180001'] = AttendanceRecord(
      sessionId: 1,
      rollNumber: 'SE180001',
      status: AttendanceStatus.absent,
      method: AttendanceMethod.qr,
      flag: AttendanceFlag.spotCheckFailed,
      timestamp: DateTime(2026, 9, 23, 9),
    );
    final o = await submit('SE180001', 'phone-z');
    expect((o as CheckinRejected).reason, RejectReason.alreadyCheckedIn);
  });
}
