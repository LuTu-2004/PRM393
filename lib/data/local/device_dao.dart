import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/models.dart';

class DeviceDao {
  DeviceDao(this._db);

  final Database _db;

  /// Records that [rollNumber] checked in from [deviceId] at [now].
  Future<void> touch(String rollNumber, String deviceId, DateTime now) async {
    final iso = now.toIso8601String();
    await _db.rawInsert(
      '''
      INSERT INTO devices (roll_number, device_id, first_seen, last_seen)
      VALUES (?, ?, ?, ?)
      ON CONFLICT (roll_number, device_id) DO UPDATE SET last_seen = excluded.last_seen
    ''',
      [rollNumber, deviceId, iso, iso],
    );
  }

  Future<List<Device>> listByRollNumber(String rollNumber) async {
    final rows = await _db.query(
      'devices',
      where: 'roll_number = ?',
      whereArgs: [rollNumber],
      orderBy: 'last_seen DESC',
    );
    return rows.map(Device.fromRow).toList();
  }
}
