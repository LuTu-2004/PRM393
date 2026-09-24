/// Domain models shared by the data layer, services and UI.
library;

import 'package:flutter/foundation.dart';

enum SessionStatus { open, closed }

enum AttendanceStatus { present, absent, pending }

enum AttendanceMethod { manual, qr }

enum SyncStatus { pending, synced, error }

/// Reasons a record needs the lecturer's review.
enum AttendanceFlag {
  deviceMismatch('device_mismatch', 'Đổi thiết bị'),
  multiStudentDevice('multi_student_device', 'Thiết bị đã dùng cho người khác'),
  noDeviceCookie('no_device_cookie', 'Không nhận diện được thiết bị'),
  spotCheckFailed('spot_check_failed', 'Không có mặt khi gọi tên');

  const AttendanceFlag(this.code, this.label);

  /// Value stored in the database.
  final String code;

  /// Short Vietnamese reason shown in the UI.
  final String label;

  static AttendanceFlag? fromCode(String? code) {
    if (code == null) return null;
    for (final f in values) {
      if (f.code == code) return f;
    }
    return null;
  }
}

T _enumByName<T extends Enum>(List<T> values, String name) =>
    values.firstWhere((e) => e.name == name);

@immutable
class ClassInfo {
  const ClassInfo({
    this.id,
    required this.classCode,
    required this.subjectCode,
    required this.semester,
    this.sheetId,
  });

  final int? id;
  final String classCode;
  final String subjectCode;
  final String semester;
  final String? sheetId;

  /// e.g. "SE1801 · PRN211 · SP2026".
  String get displayName => '$classCode · $subjectCode · $semester';

  ClassInfo copyWith({
    int? id,
    String? classCode,
    String? subjectCode,
    String? semester,
    String? sheetId,
  }) => ClassInfo(
    id: id ?? this.id,
    classCode: classCode ?? this.classCode,
    subjectCode: subjectCode ?? this.subjectCode,
    semester: semester ?? this.semester,
    sheetId: sheetId ?? this.sheetId,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'class_code': classCode,
    'subject_code': subjectCode,
    'semester': semester,
    'sheet_id': sheetId,
  };

  factory ClassInfo.fromRow(Map<String, Object?> r) => ClassInfo(
    id: r['id'] as int,
    classCode: r['class_code'] as String,
    subjectCode: r['subject_code'] as String,
    semester: r['semester'] as String,
    sheetId: r['sheet_id'] as String?,
  );
}

/// A class with aggregated numbers for the class list screen.
@immutable
class ClassSummary {
  const ClassSummary({
    required this.info,
    required this.studentCount,
    required this.sessionCount,
  });

  final ClassInfo info;
  final int studentCount;
  final int sessionCount;
}

@immutable
class Student {
  const Student({
    this.id,
    required this.classId,
    required this.rollNumber,
    required this.fullName,
    this.imagePath,
    this.note = '',
  });

  final int? id;
  final int classId;

  /// Student ID (MSSV), normalized to uppercase.
  final String rollNumber;
  final String fullName;
  final String? imagePath;
  final String note;

  Student copyWith({
    int? id,
    int? classId,
    String? rollNumber,
    String? fullName,
    String? imagePath,
    bool clearImage = false,
    String? note,
  }) => Student(
    id: id ?? this.id,
    classId: classId ?? this.classId,
    rollNumber: rollNumber ?? this.rollNumber,
    fullName: fullName ?? this.fullName,
    imagePath: clearImage ? null : (imagePath ?? this.imagePath),
    note: note ?? this.note,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'class_id': classId,
    'roll_number': rollNumber,
    'full_name': fullName,
    'image_path': imagePath,
    'note': note,
  };

  factory Student.fromRow(Map<String, Object?> r) => Student(
    id: r['id'] as int,
    classId: r['class_id'] as int,
    rollNumber: r['roll_number'] as String,
    fullName: r['full_name'] as String,
    imagePath: r['image_path'] as String?,
    note: (r['note'] as String?) ?? '',
  );
}

@immutable
class Session {
  const Session({
    this.id,
    required this.classId,
    required this.date,
    required this.slot,
    this.status = SessionStatus.open,
    required this.createdAt,
    this.fapUpdated = false,
  });

  final int? id;
  final int classId;

  /// Calendar date only (time part ignored).
  final DateTime date;
  final int slot;
  final SessionStatus status;
  final DateTime createdAt;

  /// Lecturer ticked "Đã cập nhật lên FAP".
  final bool fapUpdated;

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Session copyWith({SessionStatus? status, bool? fapUpdated}) => Session(
    id: id,
    classId: classId,
    date: date,
    slot: slot,
    status: status ?? this.status,
    createdAt: createdAt,
    fapUpdated: fapUpdated ?? this.fapUpdated,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'class_id': classId,
    'date': dateKey(date),
    'slot': slot,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'fap_updated': fapUpdated ? 1 : 0,
  };

  factory Session.fromRow(Map<String, Object?> r) => Session(
    id: r['id'] as int,
    classId: r['class_id'] as int,
    date: DateTime.parse(r['date'] as String),
    slot: r['slot'] as int,
    status: _enumByName(SessionStatus.values, r['status'] as String),
    createdAt: DateTime.parse(r['created_at'] as String),
    fapUpdated: (r['fap_updated'] as int? ?? 0) == 1,
  );
}

@immutable
class AttendanceRecord {
  const AttendanceRecord({
    this.id,
    required this.sessionId,
    required this.rollNumber,
    required this.status,
    required this.method,
    this.deviceId,
    this.flag,
    required this.timestamp,
    this.syncStatus = SyncStatus.pending,
  });

  final int? id;
  final int sessionId;
  final String rollNumber;
  final AttendanceStatus status;
  final AttendanceMethod method;
  final String? deviceId;
  final AttendanceFlag? flag;
  final DateTime timestamp;
  final SyncStatus syncStatus;

  /// Checked in (present or awaiting confirmation).
  bool get isCheckedIn =>
      status == AttendanceStatus.present || status == AttendanceStatus.pending;

  /// Pending with a flag: must be resolved before the session is confirmed.
  bool get needsReview => status == AttendanceStatus.pending && flag != null;

  AttendanceRecord copyWith({
    AttendanceStatus? status,
    AttendanceMethod? method,
    AttendanceFlag? flag,
    bool clearFlag = false,
    DateTime? timestamp,
  }) => AttendanceRecord(
    id: id,
    sessionId: sessionId,
    rollNumber: rollNumber,
    status: status ?? this.status,
    method: method ?? this.method,
    deviceId: deviceId,
    flag: clearFlag ? null : (flag ?? this.flag),
    timestamp: timestamp ?? this.timestamp,
    syncStatus: syncStatus,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'session_id': sessionId,
    'roll_number': rollNumber,
    'status': status.name,
    'method': method.name,
    'device_id': deviceId,
    'flag': flag?.code,
    'timestamp': timestamp.toIso8601String(),
    'sync_status': syncStatus.name,
  };

  factory AttendanceRecord.fromRow(Map<String, Object?> r) => AttendanceRecord(
    id: r['id'] as int,
    sessionId: r['session_id'] as int,
    rollNumber: r['roll_number'] as String,
    status: _enumByName(AttendanceStatus.values, r['status'] as String),
    method: _enumByName(AttendanceMethod.values, r['method'] as String),
    deviceId: r['device_id'] as String?,
    flag: AttendanceFlag.fromCode(r['flag'] as String?),
    timestamp: DateTime.parse(r['timestamp'] as String),
    syncStatus: _enumByName(SyncStatus.values, r['sync_status'] as String),
  );
}

/// Binding between a student and a phone across sessions.
@immutable
class Device {
  const Device({
    required this.rollNumber,
    required this.deviceId,
    required this.firstSeen,
    required this.lastSeen,
  });

  final String rollNumber;
  final String deviceId;
  final DateTime firstSeen;
  final DateTime lastSeen;

  Map<String, Object?> toRow() => {
    'roll_number': rollNumber,
    'device_id': deviceId,
    'first_seen': firstSeen.toIso8601String(),
    'last_seen': lastSeen.toIso8601String(),
  };

  factory Device.fromRow(Map<String, Object?> r) => Device(
    rollNumber: r['roll_number'] as String,
    deviceId: r['device_id'] as String,
    firstSeen: DateTime.parse(r['first_seen'] as String),
    lastSeen: DateTime.parse(r['last_seen'] as String),
  );
}
