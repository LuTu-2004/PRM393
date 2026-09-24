import 'package:csv/csv.dart';
import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/services/export/session_export.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const info = ClassInfo(
    id: 1,
    classCode: 'SE1801',
    subjectCode: 'PRN211',
    semester: 'FA2026',
  );
  final session = Session(
    id: 1,
    classId: 1,
    date: DateTime(2026, 9, 23),
    slot: 2,
    createdAt: DateTime(2026, 9, 23),
  );
  const roster = [
    Student(classId: 1, rollNumber: 'SE180003', fullName: 'Lê Hoàng Cường'),
    Student(classId: 1, rollNumber: 'SE180001', fullName: 'Nguyễn Văn An'),
    Student(classId: 1, rollNumber: 'SE180002', fullName: 'Trần Thị Bình'),
  ];
  AttendanceRecord rec(
    String roll,
    AttendanceStatus s, {
    AttendanceFlag? flag,
  }) => AttendanceRecord(
    sessionId: 1,
    rollNumber: roll,
    status: s,
    method: AttendanceMethod.manual,
    flag: flag,
    timestamp: DateTime(2026, 9, 23, 9, 7),
  );

  final records = {
    'SE180003': rec('SE180003', AttendanceStatus.absent),
    'SE180001': rec('SE180001', AttendanceStatus.present),
    'SE180002': rec(
      'SE180002',
      AttendanceStatus.absent,
      flag: AttendanceFlag.spotCheckFailed,
    ),
  };

  test('absent list follows roster order, one roll number per line', () {
    expect(absentRollList(roster, records), 'SE180003\nSE180002');
    expect(absentRollList(roster, {}), '');
  });

  test('CSV has a BOM, a Vietnamese header and one row per student', () {
    final csv = sessionCsv(
      classInfo: info,
      session: session,
      roster: roster,
      records: records,
    );
    expect(csv.startsWith('﻿'), isTrue);
    final rows = Csv().decode(csv.substring(1));
    expect(rows.first.first, 'STT');
    expect(rows, hasLength(4));
    expect(rows[1], [
      '1',
      'SE1801',
      'PRN211',
      '2026-09-23',
      '2',
      'SE180003',
      'Lê Hoàng Cường',
      'Vắng',
      'Thủ công',
      '09:07',
      '',
    ]);
    expect(rows[3][7], 'Vắng');
    expect(rows[3][10], 'Không có mặt khi gọi tên');
  });
}
