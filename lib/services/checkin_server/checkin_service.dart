import 'dart:async';

import '../../core/utils/text_utils.dart';
import '../../data/local/attendance_dao.dart';
import '../../data/local/device_dao.dart';
import '../../domain/models.dart';

/// Data access needed by [CheckinService], scoped to one session.
abstract class CheckinStore {
  Student? findStudent(String rollNumber);
  Future<AttendanceRecord?> findRecord(String rollNumber);
  Future<AttendanceRecord?> findByDevice(String deviceId);
  Future<List<Device>> devicesOf(String rollNumber);
  Future<void> save(AttendanceRecord record);
  Future<void> touchDevice(String rollNumber, String deviceId, DateTime now);
}

enum RejectReason {
  /// Roll number is not on this class's roster.
  unknownRoll,

  /// This student is already checked in for the session.
  alreadyCheckedIn,

  /// This phone already checked in another student in this session.
  deviceUsedByOther,
}

sealed class CheckinOutcome {
  const CheckinOutcome();
}

class CheckinAccepted extends CheckinOutcome {
  const CheckinAccepted(this.student, this.record);

  final Student student;
  final AttendanceRecord record;
}

class CheckinRejected extends CheckinOutcome {
  const CheckinRejected(
    this.reason, {
    this.rollNumber,
    this.student,
    this.otherStudent,
  });

  final RejectReason reason;
  final String? rollNumber;
  final Student? student;

  /// For [RejectReason.deviceUsedByOther]: who already used this phone.
  final Student? otherStudent;
}

/// Anti-cheating rules for QR check-in (spec §5.4). Accepted check-ins are
/// pending until the lecturer confirms, unless [autoApprove] is on and the
/// check-in has no flag.
class CheckinService {
  CheckinService({
    required this.sessionId,
    required this.store,
    this.autoApprove = false,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final int sessionId;
  final CheckinStore store;

  /// When true, check-ins without a flag are stored as present instead of
  /// pending; flagged ones still wait for the lecturer.
  final bool autoApprove;
  final DateTime Function() _clock;

  /// Serializes submissions so two quick requests from the same phone cannot
  /// both pass the "one phone, one student" check.
  Future<void> _lock = Future.value();

  Future<CheckinOutcome> submit({
    required String rawRollNumber,
    required String? deviceId,
  }) {
    final result = _lock.then((_) => _submit(rawRollNumber, deviceId));
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<CheckinOutcome> _submit(String rawRollNumber, String? deviceId) async {
    final roll = normalizeRollNumber(rawRollNumber);
    final student = store.findStudent(roll);
    if (student == null) {
      return CheckinRejected(RejectReason.unknownRoll, rollNumber: roll);
    }

    final existing = await store.findRecord(roll);
    // A student found absent during a spot check may not re-scan themselves
    // back in; only the lecturer can change that record.
    if (existing != null &&
        (existing.isCheckedIn ||
            existing.flag == AttendanceFlag.spotCheckFailed)) {
      return CheckinRejected(
        RejectReason.alreadyCheckedIn,
        rollNumber: roll,
        student: student,
      );
    }

    AttendanceFlag? flag;
    if (deviceId == null) {
      // Cookies blocked or private browsing: accept, but ask for review.
      flag = AttendanceFlag.noDeviceCookie;
    } else {
      final sameDevice = await store.findByDevice(deviceId);
      if (sameDevice != null && sameDevice.rollNumber != roll) {
        // The first check-in from this phone becomes suspicious too: it may
        // have been made on someone else's behalf.
        // With auto-approve it may already count as present: send it back
        // to review.
        if (sameDevice.isCheckedIn &&
            sameDevice.flag != AttendanceFlag.multiStudentDevice) {
          await store.save(
            sameDevice.copyWith(
              status: AttendanceStatus.pending,
              flag: AttendanceFlag.multiStudentDevice,
            ),
          );
        }
        return CheckinRejected(
          RejectReason.deviceUsedByOther,
          rollNumber: roll,
          student: student,
          otherStudent: store.findStudent(sameDevice.rollNumber),
        );
      }
      final known = await store.devicesOf(roll);
      if (known.isNotEmpty && !known.any((d) => d.deviceId == deviceId)) {
        // New phone or cleared cookies: accept, but flag it.
        flag = AttendanceFlag.deviceMismatch;
      }
    }

    final now = _clock();
    final record = AttendanceRecord(
      sessionId: sessionId,
      rollNumber: roll,
      status: autoApprove && flag == null
          ? AttendanceStatus.present
          : AttendanceStatus.pending,
      method: AttendanceMethod.qr,
      deviceId: deviceId,
      flag: flag,
      timestamp: now,
    );
    await store.save(record);
    if (deviceId != null) await store.touchDevice(roll, deviceId, now);
    return CheckinAccepted(student, record);
  }
}

/// [CheckinStore] backed by SQLite, with the roster cached in memory.
class SqliteCheckinStore implements CheckinStore {
  SqliteCheckinStore({
    required this.sessionId,
    required List<Student> roster,
    required this.attendance,
    required this.devices,
  }) : _roster = {for (final s in roster) s.rollNumber: s};

  final int sessionId;
  final Map<String, Student> _roster;
  final AttendanceDao attendance;
  final DeviceDao devices;

  @override
  Student? findStudent(String rollNumber) => _roster[rollNumber];

  @override
  Future<AttendanceRecord?> findRecord(String rollNumber) =>
      attendance.find(sessionId, rollNumber);

  @override
  Future<AttendanceRecord?> findByDevice(String deviceId) =>
      attendance.findByDevice(sessionId, deviceId);

  @override
  Future<List<Device>> devicesOf(String rollNumber) =>
      devices.listByRollNumber(rollNumber);

  @override
  Future<void> save(AttendanceRecord record) => attendance.upsert(record);

  @override
  Future<void> touchDevice(String rollNumber, String deviceId, DateTime now) =>
      devices.touch(rollNumber, deviceId, now);
}
