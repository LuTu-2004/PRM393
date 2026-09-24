import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models.dart';

class AttendanceDao {
  AttendanceDao(this._db);

  final Database _db;

  /// Inserts or replaces the single record of (session, roll number).
  ///
  /// Any change resets the sync status to pending so the new value is synced.
  Future<void> upsert(AttendanceRecord r) async {
    final row = r.toRow()
      ..remove('id')
      ..['sync_status'] = SyncStatus.pending.name;
    await _db.insert(
      'attendance',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<AttendanceRecord>> listBySession(int sessionId) async {
    final rows = await _db.query(
      'attendance',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp',
    );
    return rows.map(AttendanceRecord.fromRow).toList();
  }

  Future<AttendanceRecord?> find(int sessionId, String rollNumber) async {
    final rows = await _db.query(
      'attendance',
      where: 'session_id = ? AND roll_number = ?',
      whereArgs: [sessionId, rollNumber],
    );
    return rows.isEmpty ? null : AttendanceRecord.fromRow(rows.first);
  }

  /// The record created from [deviceId] in this session, if any.
  Future<AttendanceRecord?> findByDevice(int sessionId, String deviceId) async {
    final rows = await _db.query(
      'attendance',
      where: 'session_id = ? AND device_id = ?',
      whereArgs: [sessionId, deviceId],
      limit: 1,
    );
    return rows.isEmpty ? null : AttendanceRecord.fromRow(rows.first);
  }

  /// Removes a record, returning the student to "not marked".
  Future<void> delete(int sessionId, String rollNumber) => _db.delete(
    'attendance',
    where: 'session_id = ? AND roll_number = ?',
    whereArgs: [sessionId, rollNumber],
  );

  Future<void> setSyncStatus(int sessionId, SyncStatus status) => _db.update(
    'attendance',
    {'sync_status': status.name},
    where: 'session_id = ?',
    whereArgs: [sessionId],
  );
}
