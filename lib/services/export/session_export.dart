import 'package:csv/csv.dart';

import '../../domain/models.dart';

String statusLabel(AttendanceStatus? s) => switch (s) {
  AttendanceStatus.present => 'Có mặt',
  AttendanceStatus.absent => 'Vắng',
  AttendanceStatus.pending => 'Chờ duyệt',
  null => 'Chưa điểm danh',
};

String methodLabel(AttendanceMethod m) => switch (m) {
  AttendanceMethod.manual => 'Thủ công',
  AttendanceMethod.qr => 'QR',
};

String _time(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Absent roll numbers in roster order, one per line (for pasting into FAP).
String absentRollList(
  List<Student> roster,
  Map<String, AttendanceRecord> records,
) => roster
    .where((s) => records[s.rollNumber]?.status == AttendanceStatus.absent)
    .map((s) => s.rollNumber)
    .join('\n');

/// Session report as CSV with a UTF-8 BOM so Excel shows Vietnamese
/// correctly.
String sessionCsv({
  required ClassInfo classInfo,
  required Session session,
  required List<Student> roster,
  required Map<String, AttendanceRecord> records,
}) {
  final rows = <List<Object>>[
    [
      'STT',
      'Lớp',
      'Môn',
      'Ngày',
      'Slot',
      'MSSV',
      'Họ tên',
      'Trạng thái',
      'Cách điểm danh',
      'Giờ',
      'Cần xem',
    ],
    for (var i = 0; i < roster.length; i++)
      () {
        final s = roster[i];
        final r = records[s.rollNumber];
        return <Object>[
          i + 1,
          classInfo.classCode,
          classInfo.subjectCode,
          Session.dateKey(session.date),
          session.slot,
          s.rollNumber,
          s.fullName,
          statusLabel(r?.status),
          r == null ? '' : methodLabel(r.method),
          r == null ? '' : _time(r.timestamp),
          r?.flag?.label ?? '',
        ];
      }(),
  ];
  return '﻿${Csv(lineDelimiter: '\r\n').encode(rows)}';
}
