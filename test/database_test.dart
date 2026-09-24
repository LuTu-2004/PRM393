import 'dart:io';

import 'package:diem_danh/data/import/photo_store.dart';
import 'package:diem_danh/data/import/roster_parser.dart';
import 'package:diem_danh/data/local/app_database.dart';
import 'package:diem_danh/data/local/attendance_dao.dart';
import 'package:diem_danh/data/local/device_dao.dart';
import 'package:diem_danh/data/local/session_dao.dart';
import 'package:diem_danh/data/roster_repository.dart';
import 'package:diem_danh/data/session_repository.dart';
import 'package:diem_danh/services/checkin_server/checkin_service.dart';
import 'package:diem_danh/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late Directory tmp;
  late RosterRepository repo;
  late SessionDao sessions;
  late AttendanceDao attendance;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(inMemoryDatabasePath);
    tmp = await Directory.systemTemp.createTemp('diem_danh_test');
    repo = RosterRepository(
      db: database.db,
      photos: PhotoStore(p.join(tmp.path, 'photos')),
    );
    sessions = SessionDao(database.db);
    attendance = AttendanceDao(database.db);
  });

  tearDown(() async {
    await database.close();
    await tmp.delete(recursive: true);
  });

  const info = ClassInfo(
    classCode: 'SE1801',
    subjectCode: 'PRN211',
    semester: 'FA2026',
  );

  List<ParsedStudent> parsed(Map<String, String> m) => [
    for (final e in m.entries)
      ParsedStudent(rowNumber: 0, rollNumber: e.key, fullName: e.value),
  ];

  test('importRoster creates the class, then merges on re-import', () async {
    final first = await repo.importRoster(
      info,
      parsed({'SE180001': 'Nguyễn Văn An', 'SE180002': 'Trần Thị Bình'}),
    );
    expect(first.createdClass, isTrue);
    expect(first.inserted, 2);

    final second = await repo.importRoster(
      info,
      parsed({'SE180002': 'Trần Thị Bình (sửa)', 'SE180003': 'Lê Hoàng Cường'}),
    );
    expect(second.createdClass, isFalse);
    expect(second.classInfo.id, first.classInfo.id);
    expect(second.inserted, 1);
    expect(second.updated, 1);

    final students = await repo.students.listByClass(first.classInfo.id!);
    expect(students.map((s) => s.fullName), [
      'Nguyễn Văn An',
      'Trần Thị Bình (sửa)',
      'Lê Hoàng Cường',
    ]);

    final summaries = await repo.classes.listSummaries();
    expect(summaries.single.studentCount, 3);
    expect(summaries.single.sessionCount, 0);
  });

  test('roll number is unique within a class', () async {
    final c = await repo.classes.insert(info);
    await repo.students.insert(
      Student(classId: c.id!, rollNumber: 'SE180001', fullName: 'A'),
    );
    await expectLater(
      repo.students.insert(
        Student(classId: c.id!, rollNumber: 'SE180001', fullName: 'B'),
      ),
      throwsA(isA<DatabaseException>()),
    );
    final b = await repo.students.insert(
      Student(classId: c.id!, rollNumber: 'SE180002', fullName: 'B'),
    );
    await expectLater(
      repo.updateStudent(b.copyWith(rollNumber: 'SE180001')),
      throwsA(isA<StateError>()),
    );
  });

  test(
    'one attendance record per (session, roll number); edits reset sync',
    () async {
      final c = await repo.classes.insert(info);
      final s = await sessions.insert(
        Session(
          classId: c.id!,
          date: DateTime(2026, 9, 23),
          slot: 2,
          createdAt: DateTime(2026, 9, 23, 9),
        ),
      );
      expect(
        await sessions.find(c.id!, DateTime(2026, 9, 23, 15), 2),
        isNotNull,
      );

      AttendanceRecord rec(AttendanceStatus st) => AttendanceRecord(
        sessionId: s.id!,
        rollNumber: 'SE180001',
        status: st,
        method: AttendanceMethod.manual,
        timestamp: DateTime(2026, 9, 23, 9, 5),
      );
      await attendance.upsert(rec(AttendanceStatus.present));
      await attendance.setSyncStatus(s.id!, SyncStatus.synced);
      await attendance.upsert(rec(AttendanceStatus.absent));

      final all = await attendance.listBySession(s.id!);
      expect(all, hasLength(1));
      expect(all.single.status, AttendanceStatus.absent);
      expect(all.single.syncStatus, SyncStatus.pending);

      await expectLater(
        sessions.insert(
          Session(
            classId: c.id!,
            date: DateTime(2026, 9, 23),
            slot: 2,
            createdAt: DateTime.now(),
          ),
        ),
        throwsA(isA<DatabaseException>()),
      );
    },
  );

  test('flags round-trip through the database', () async {
    final c = await repo.classes.insert(info);
    final s = await sessions.insert(
      Session(
        classId: c.id!,
        date: DateTime(2026, 9, 23),
        slot: 1,
        createdAt: DateTime.now(),
      ),
    );
    await attendance.upsert(
      AttendanceRecord(
        sessionId: s.id!,
        rollNumber: 'SE180001',
        status: AttendanceStatus.pending,
        method: AttendanceMethod.qr,
        deviceId: 'dev-1',
        flag: AttendanceFlag.deviceMismatch,
        timestamp: DateTime.now(),
      ),
    );
    final r = await attendance.find(s.id!, 'SE180001');
    expect(r!.flag, AttendanceFlag.deviceMismatch);
    expect(r.method, AttendanceMethod.qr);
    expect(r.deviceId, 'dev-1');
  });

  test('absence rate counts only closed sessions', () async {
    final c = await repo.classes.insert(info);
    await repo.students.insert(
      Student(classId: c.id!, rollNumber: 'SE180001', fullName: 'A'),
    );
    for (var slot = 1; slot <= 5; slot++) {
      final s = await sessions.insert(
        Session(
          classId: c.id!,
          date: DateTime(2026, 9, slot),
          slot: slot,
          createdAt: DateTime.now(),
          status: slot == 5 ? SessionStatus.open : SessionStatus.closed,
        ),
      );
      await attendance.upsert(
        AttendanceRecord(
          sessionId: s.id!,
          rollNumber: 'SE180001',
          status: slot == 1 || slot == 5
              ? AttendanceStatus.absent
              : AttendanceStatus.present,
          method: AttendanceMethod.manual,
          timestamp: DateTime.now(),
        ),
      );
    }
    final stats = await repo.students.listWithStats(c.id!);
    expect(stats.single.closedSessionCount, 4);
    expect(stats.single.absentCount, 1);
    expect(stats.single.absenceRate, 0.25);
  });

  test('deleting a class cascades and removes its photos', () async {
    final c = await repo.classes.insert(info);
    final st = await repo.students.insert(
      Student(classId: c.id!, rollNumber: 'SE180001', fullName: 'A'),
    );
    final src = File(p.join(tmp.path, 'SE180001.jpg'))
      ..writeAsBytesSync([1, 2, 3]);
    await repo.setStudentPhoto(st, src.path);
    final stored = (await repo.students.listByClass(c.id!)).single.imagePath!;
    expect(File(stored).existsSync(), isTrue);
    expect(p.isWithin(p.join(tmp.path, 'photos'), stored), isTrue);

    final s = await sessions.insert(
      Session(
        classId: c.id!,
        date: DateTime(2026, 9, 23),
        slot: 1,
        createdAt: DateTime.now(),
      ),
    );
    await attendance.upsert(
      AttendanceRecord(
        sessionId: s.id!,
        rollNumber: 'SE180001',
        status: AttendanceStatus.present,
        method: AttendanceMethod.manual,
        timestamp: DateTime.now(),
      ),
    );

    await repo.deleteClass(c.id!);
    expect(await repo.classes.listSummaries(), isEmpty);
    expect(await repo.students.listByClass(c.id!), isEmpty);
    expect(await attendance.listBySession(s.id!), isEmpty);
    expect(File(stored).existsSync(), isFalse);
  });

  test('attachPhotosFromDirectory copies matching photos', () async {
    final result = await repo.importRoster(
      info,
      parsed({'SE180001': 'A', 'SE180002': 'B', 'SE180003': 'C'}),
    );
    final dir = Directory(p.join(tmp.path, 'src'))..createSync();
    File(p.join(dir.path, 'SE180001.jpg')).writeAsBytesSync([1]);
    File(p.join(dir.path, 'se180002_ten.png')).writeAsBytesSync([2]);
    File(p.join(dir.path, 'SE999999.jpg')).writeAsBytesSync([3]);

    final r = await repo.attachPhotosFromDirectory(
      result.classInfo.id!,
      dir.path,
    );
    expect(r.attached, 2);
    expect(r.studentsWithoutPhoto, 1);
    expect(r.unusedFiles, 1);

    // Deleting the original folder does not break the stored photos.
    await dir.delete(recursive: true);
    final students = await repo.students.listByClass(result.classInfo.id!);
    expect(
      students
          .where((s) => s.imagePath != null)
          .every((s) => File(s.imagePath!).existsSync()),
      isTrue,
    );
  });

  test('device bindings are upserted', () async {
    final devices = DeviceDao(database.db);
    await devices.touch('SE180001', 'dev-1', DateTime(2026, 9, 1));
    await devices.touch('SE180001', 'dev-1', DateTime(2026, 9, 8));
    await devices.touch('SE180001', 'dev-2', DateTime(2026, 9, 15));
    final list = await devices.listByRollNumber('SE180001');
    expect(list.map((d) => d.deviceId), ['dev-2', 'dev-1']);
    expect(list.last.firstSeen, DateTime(2026, 9, 1));
    expect(list.last.lastSeen, DateTime(2026, 9, 8));
  });

  test(
    'session repository: findOrCreate is idempotent and overviews count',
    () async {
      final imported = await repo.importRoster(
        info,
        parsed({'SE180001': 'A', 'SE180002': 'B', 'SE180003': 'C'}),
      );
      final sessionRepo = SqliteSessionRepository(database.db);
      final (s1, existed1) = await sessionRepo.findOrCreate(
        imported.classInfo.id!,
        DateTime(2026, 9, 23, 14, 5),
        2,
      );
      final (s2, existed2) = await sessionRepo.findOrCreate(
        imported.classInfo.id!,
        DateTime(2026, 9, 23),
        2,
      );
      expect(existed1, isFalse);
      expect(existed2, isTrue);
      expect(s2.id, s1.id);

      AttendanceRecord rec(String roll, AttendanceStatus st) =>
          AttendanceRecord(
            sessionId: s1.id!,
            rollNumber: roll,
            status: st,
            method: AttendanceMethod.manual,
            timestamp: DateTime(2026, 9, 23, 9),
          );
      await sessionRepo.upsert(rec('SE180001', AttendanceStatus.present));
      await sessionRepo.upsert(rec('SE180002', AttendanceStatus.pending));

      final o = (await sessionRepo.overviews()).single;
      expect(o.total, 3);
      expect(o.present, 1);
      expect(o.pending, 1);
      expect(o.absent, 0);
      expect(o.unmarked, 1);
      expect(o.classInfo.classCode, 'SE1801');

      final bundle = await sessionRepo.load(s1.id!);
      expect(bundle.students, hasLength(3));
      expect(bundle.records, hasLength(2));

      await sessionRepo.setStatus(s1.id!, SessionStatus.closed);
      expect(await sessionRepo.overviews(openOnly: true), isEmpty);
    },
  );

  test(
    'SQLite check-in store enforces one phone per student end to end',
    () async {
      final imported = await repo.importRoster(
        info,
        parsed({'SE180001': 'A', 'SE180002': 'B'}),
      );
      final sessionRepo = SqliteSessionRepository(database.db);
      final (s, _) = await sessionRepo.findOrCreate(
        imported.classInfo.id!,
        DateTime(2026, 9, 23),
        1,
      );
      final service = CheckinService(
        sessionId: s.id!,
        store: SqliteCheckinStore(
          sessionId: s.id!,
          roster: await repo.students.listByClass(imported.classInfo.id!),
          attendance: attendance,
          devices: DeviceDao(database.db),
        ),
      );
      expect(
        await service.submit(
          rawRollNumber: 'SE180001',
          deviceId: 'phone-aaaaaaaaaaaa',
        ),
        isA<CheckinAccepted>(),
      );
      final second = await service.submit(
        rawRollNumber: 'SE180002',
        deviceId: 'phone-aaaaaaaaaaaa',
      );
      expect(
        (second as CheckinRejected).reason,
        RejectReason.deviceUsedByOther,
      );
      final first = await attendance.find(s.id!, 'SE180001');
      expect(first!.flag, AttendanceFlag.multiStudentDevice);
      expect(await attendance.find(s.id!, 'SE180002'), isNull);
    },
  );
}
