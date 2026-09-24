import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/services/checkin_server/checkin_service.dart';

/// In-memory [CheckinStore] for one session.
class FakeCheckinStore implements CheckinStore {
  FakeCheckinStore(List<Student> roster)
    : roster = {for (final s in roster) s.rollNumber: s};

  final Map<String, Student> roster;
  final Map<String, AttendanceRecord> records = {};

  /// roll -> device ids seen in earlier sessions.
  final Map<String, List<Device>> devices = {};

  @override
  Student? findStudent(String rollNumber) => roster[rollNumber];

  @override
  Future<AttendanceRecord?> findRecord(String rollNumber) async =>
      records[rollNumber];

  @override
  Future<AttendanceRecord?> findByDevice(String deviceId) async =>
      records.values.where((r) => r.deviceId == deviceId).firstOrNull;

  @override
  Future<List<Device>> devicesOf(String rollNumber) async =>
      devices[rollNumber] ?? [];

  @override
  Future<void> save(AttendanceRecord record) async =>
      records[record.rollNumber] = record;

  @override
  Future<void> touchDevice(
    String rollNumber,
    String deviceId,
    DateTime now,
  ) async {
    final list = devices.putIfAbsent(rollNumber, () => []);
    if (!list.any((d) => d.deviceId == deviceId)) {
      list.add(
        Device(
          rollNumber: rollNumber,
          deviceId: deviceId,
          firstSeen: now,
          lastSeen: now,
        ),
      );
    }
  }
}

const testRoster = [
  Student(id: 1, classId: 1, rollNumber: 'SE180001', fullName: 'Nguyễn Văn An'),
  Student(id: 2, classId: 1, rollNumber: 'SE180002', fullName: 'Trần Thị Bình'),
  Student(
    id: 3,
    classId: 1,
    rollNumber: 'SE180003',
    fullName: 'Lê <b>Hoàng</b> Cường',
  ),
];
