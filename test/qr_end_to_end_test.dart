import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:diem_danh/core/config/app_paths.dart';
import 'package:diem_danh/core/config/app_settings.dart';
import 'package:diem_danh/data/import/roster_parser.dart';
import 'package:diem_danh/data/local/app_database.dart';
import 'package:diem_danh/data/local/attendance_dao.dart';
import 'package:diem_danh/data/session_repository.dart';
import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/ui/providers/providers.dart';
import 'package:diem_danh/ui/providers/qr_controller.dart';
import 'package:diem_danh/ui/providers/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Minimal phone: keeps cookies like a browser would.
class Phone {
  Phone(this.port);

  final int port;
  final _client = HttpClient();
  String? cookie;

  void _withCookie(HttpClientRequest req) {
    if (cookie != null) req.headers.set(HttpHeaders.cookieHeader, cookie!);
  }

  Future<(int, String)> _send(HttpClientRequest req) async {
    final res = await req.close();
    final set = res.headers[HttpHeaders.setCookieHeader];
    if (set != null && set.isNotEmpty) cookie = set.first.split(';').first;
    return (res.statusCode, await res.transform(utf8.decoder).join());
  }

  Future<(int, String)> open(String pathAndQuery) async {
    final req = await _client.get('127.0.0.1', port, pathAndQuery);
    _withCookie(req);
    return _send(req);
  }

  Future<(int, String)> submit(String ticket, String roll) async {
    final req = await _client.post('127.0.0.1', port, '/checkin');
    _withCookie(req);
    req.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    req.write(
      Uri(queryParameters: {'ticket': ticket, 'roll_number': roll}).query,
    );
    return _send(req);
  }

  /// Scans the current QR and returns the ticket from the form.
  Future<String> scan(String token) async {
    final (status, html) = await open('/checkin?t=$token');
    expect(status, 200, reason: html);
    return RegExp(r'name="ticket" value="([^"]+)"').firstMatch(html)!.group(1)!;
  }

  void close() => _client.close(force: true);
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late int sessionId;
  late int port;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await AppDatabase.open(inMemoryDatabasePath);
    port = 20000 + Random().nextInt(20000);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        appPathsProvider.overrideWithValue(AppPaths(Directory.systemTemp.path)),
        initialSettingsProvider.overrideWithValue(
          AppSettings(
            qrPort: port,
            qrPeriodSeconds: AppSettings.minQrPeriodSeconds,
          ),
        ),
      ],
    );
    final roster = container.read(rosterRepositoryProvider);
    final imported = await roster.importRoster(
      const ClassInfo(
        classCode: 'SE1801',
        subjectCode: 'PRN211',
        semester: 'FA2026',
      ),
      const [
        ParsedStudent(
          rowNumber: 2,
          rollNumber: 'SE180001',
          fullName: 'Nguyễn Văn An',
        ),
        ParsedStudent(
          rowNumber: 3,
          rollNumber: 'SE180002',
          fullName: 'Trần Thị Bình',
        ),
        ParsedStudent(
          rowNumber: 4,
          rollNumber: 'SE180003',
          fullName: 'Lê Hoàng Cường',
        ),
      ],
    );
    final (s, _) = await container
        .read(sessionRepositoryProvider)
        .findOrCreate(imported.classInfo.id!, DateTime(2026, 9, 23), 2);
    sessionId = s.id!;
    // Keep the session controller alive like the open screen does.
    container.listen(sessionControllerProvider(sessionId), (_, _) {});
    await container.read(sessionControllerProvider(sessionId).future);
  });

  tearDown(() async {
    await container.read(qrControllerProvider.notifier).stop();
    container.dispose();
    await db.close();
  });

  QrRunState qr() => container.read(qrControllerProvider);

  test(
    'phones on the LAN check in; lecturer sees names; anti-cheating works',
    () async {
      await container.read(qrControllerProvider.notifier).start(sessionId);
      expect(qr().phase, QrPhase.running, reason: qr().error);
      expect(qr().url, startsWith('http://'));
      expect(qr().url, contains(':$port/checkin?t='));

      final phoneA = Phone(port);
      final phoneB = Phone(port);
      addTearDown(phoneA.close);
      addTearDown(phoneB.close);

      // Phone A checks in An.
      var ticket = await phoneA.scan(qr().token);
      var (status, html) = await phoneA.submit(ticket, 'se180001');
      expect(status, 200);
      expect(html, contains('Đã ghi nhận – Nguyễn Văn An'));
      expect(phoneA.cookie, startsWith('device_id='));

      // The lecturer's live list and counters update.
      await pumpEventQueue();
      expect(qr().live.first.student!.fullName, 'Nguyễn Văn An');
      final s = await container.read(
        sessionControllerProvider(sessionId).future,
      );
      expect(s.present, 1, reason: 'auto-approve is on by default');

      // Phone A tries to check in Bình too: refused + warning on screen.
      ticket = await phoneA.scan(qr().token);
      (status, html) = await phoneA.submit(ticket, 'SE180002');
      expect(status, 409);
      expect(html, contains('sinh viên khác'));
      await pumpEventQueue();
      expect(qr().live.first.rejected, isTrue);
      expect(
        qr().live.first.flagLabel,
        AttendanceFlag.multiStudentDevice.label,
      );
      final att = AttendanceDao(db.db);
      expect(await att.find(sessionId, 'SE180002'), isNull);
      final an = (await att.find(sessionId, 'SE180001'))!;
      expect(an.flag, AttendanceFlag.multiStudentDevice);
      expect(an.status, AttendanceStatus.pending, reason: 'back to review');

      // Phone B checks in Bình properly.
      ticket = await phoneB.scan(qr().token);
      (status, html) = await phoneB.submit(ticket, 'SE180002');
      expect(status, 200);

      // Pausing blocks new scans.
      container.read(qrControllerProvider.notifier).pause();
      expect((await phoneB.open('/checkin?t=${qr().token}')).$1, 503);
      container.read(qrControllerProvider.notifier).resume();

      // Stopping closes the port.
      await container.read(qrControllerProvider.notifier).stop();
      final fresh = Phone(port);
      addTearDown(fresh.close);
      await expectLater(fresh.open('/'), throwsA(isA<SocketException>()));

      final overview = (await SqliteSessionRepository(
        db.db,
      ).overviews()).single;
      expect(overview.pending, 1); // An: flagged, waits for the lecturer.
      expect(overview.present, 1); // Bình: clean, auto-approved.
    },
  );

  test('a link opened after it expired shows "hết hạn"', () async {
    await container.read(qrControllerProvider.notifier).start(sessionId);
    final oldToken = qr().token;
    final phone = Phone(port);
    addTearDown(phone.close);
    // Period is 3s; current + previous window cover at most 6s.
    await Future<void>.delayed(const Duration(seconds: 7));
    final (status, html) = await phone.open('/checkin?t=$oldToken');
    expect(status, 410);
    expect(html, contains('Mã QR đã hết hạn'));
    expect(qr().token, isNot(oldToken), reason: 'the QR rotated');
  }, timeout: const Timeout(Duration(seconds: 30)));

  test('port already in use gives a clear error', () async {
    final blocker = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    addTearDown(blocker.close);
    await container.read(qrControllerProvider.notifier).start(sessionId);
    expect(qr().phase, QrPhase.error);
    expect(qr().error, contains('Cổng $port đang được ứng dụng khác sử dụng'));
  });
}
