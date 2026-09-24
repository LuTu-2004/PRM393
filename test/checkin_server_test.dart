import 'dart:io';

import 'package:diem_danh/domain/models.dart';
import 'package:diem_danh/services/checkin_server/checkin_server.dart';
import 'package:diem_danh/services/checkin_server/checkin_service.dart';
import 'package:diem_danh/services/checkin_server/html_pages.dart';
import 'package:diem_danh/services/checkin_server/ticket_store.dart';
import 'package:diem_danh/services/token/rotating_token.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shelf/shelf.dart';

import 'helpers/fake_checkin_store.dart';

void main() {
  late DateTime now;
  late FakeCheckinStore store;
  late CheckinServer server;
  late Handler handler;
  final events = <CheckinEvent>[];

  setUp(() {
    now = DateTime(2026, 9, 23, 9, 30);
    events.clear();
    store = FakeCheckinStore(testRoster);
    server = CheckinServer(
      token: RotatingToken(
        secret: List<int>.generate(32, (i) => i * 7),
        sessionId: '1',
        clock: () => now,
      ),
      tickets: TicketStore(clock: () => now),
      service: CheckinService(sessionId: 1, store: store, clock: () => now),
      info: const PageInfo(
        classLine: 'SE1801 · PRN211',
        sessionLine: 'Slot 2 · 23/09',
      ),
      onEvent: events.add,
      clock: () => now,
    );
    handler = server.handler;
  });

  Future<Response> get(String path, {String? cookie}) async => await handler(
    Request(
      'GET',
      Uri.parse('http://192.168.137.1:8080$path'),
      headers: {HttpHeaders.cookieHeader: ?cookie},
    ),
  );

  Future<Response> post(Map<String, String> form, {String? cookie}) async =>
      await handler(
        Request(
          'POST',
          Uri.parse('http://192.168.137.1:8080/checkin'),
          body: Uri(queryParameters: form).query,
          headers: {
            HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded',
            HttpHeaders.cookieHeader: ?cookie,
          },
        ),
      );

  String ticketIn(String html) =>
      RegExp(r'name="ticket" value="([^"]+)"').firstMatch(html)!.group(1)!;

  String cookieFrom(Response r) =>
      r.headers[HttpHeaders.setCookieHeader]!.split(';').first;

  /// Opens the QR link like a phone would; returns (ticket, cookie).
  Future<(String, String)> scan({String? cookie}) async {
    final r = await get('/checkin?t=${server.token.current}', cookie: cookie);
    expect(r.statusCode, 200);
    return (ticketIn(await r.readAsString()), cookie ?? cookieFrom(r));
  }

  test('valid QR shows the form with a ticket and sets a long-lived HttpOnly device cookie', () async {
    final r = await get('/checkin?t=${server.token.current}');
    final html = await r.readAsString();
    expect(r.statusCode, 200);
    expect(r.headers['content-type'], contains('text/html'));
    expect(html, contains('name="roll_number"'));
    expect(html, contains('Còn 90 giây'));
    expect(html, isNot(contains('http://')), reason: 'no external resources');
    final cookie = r.headers[HttpHeaders.setCookieHeader]!;
    expect(cookie, startsWith('device_id='));
    expect(cookie, contains('HttpOnly'));
    expect(cookie, contains('Max-Age='));
  });

  test('a returning phone keeps its cookie', () async {
    final r = await get(
      '/checkin?t=${server.token.current}',
      cookie: 'device_id=0123456789abcdef0123',
    );
    expect(r.headers[HttpHeaders.setCookieHeader], isNull);
  });

  test('expired or wrong token shows the "rescan" page', () async {
    final old = server.token.current;
    now = now.add(const Duration(seconds: 15));
    final r = await get('/checkin?t=$old');
    expect(r.statusCode, 410);
    final html = await r.readAsString();
    expect(html, contains('Mã QR đã hết hạn'));
    expect(html, contains('quét lại'));
    expect((await get('/checkin?t=bogus')).statusCode, 410);
    expect((await get('/checkin')).statusCode, 410);
  });

  test('typing slowly works: the ticket outlives the QR rotation', () async {
    final (ticket, cookie) = await scan();
    now = now.add(const Duration(seconds: 60)); // QR changed many times.
    final r = await post({
      'ticket': ticket,
      'roll_number': 'se180001',
    }, cookie: cookie);
    final html = await r.readAsString();
    expect(r.statusCode, 200);
    expect(html, contains('Đã ghi nhận – Nguyễn Văn An'));
    expect(store.records['SE180001']!.status, AttendanceStatus.pending);
    expect(events.single.outcome, isA<CheckinAccepted>());
  });

  test('ticket expires after 90 seconds', () async {
    final (ticket, cookie) = await scan();
    now = now.add(const Duration(seconds: 91));
    final r = await post({
      'ticket': ticket,
      'roll_number': 'SE180001',
    }, cookie: cookie);
    expect(r.statusCode, 410);
    expect(await r.readAsString(), contains('quét lại'));
    expect(store.records, isEmpty);
  });

  test('ticket is single-use', () async {
    final (ticket, cookie) = await scan();
    await post({'ticket': ticket, 'roll_number': 'SE180001'}, cookie: cookie);
    final r = await post({
      'ticket': ticket,
      'roll_number': 'SE180002',
    }, cookie: 'device_id=another-phone-1234567');
    expect(r.statusCode, 410);
    expect(store.records.containsKey('SE180002'), isFalse);
  });

  test('forged ticket is rejected', () async {
    final r = await post({'ticket': 'forged', 'roll_number': 'SE180001'});
    expect(r.statusCode, 410);
  });

  test('roll number not in the class', () async {
    final (ticket, cookie) = await scan();
    final r = await post({
      'ticket': ticket,
      'roll_number': 'SE999999',
    }, cookie: cookie);
    expect(r.statusCode, 422);
    expect(await r.readAsString(), contains('không có trong lớp'));
  });

  test(
    'one phone, two students: second is refused and the lecturer is warned',
    () async {
      final (t1, cookie) = await scan();
      await post({'ticket': t1, 'roll_number': 'SE180001'}, cookie: cookie);
      final (t2, _) = await scan(cookie: cookie);
      final r = await post({
        'ticket': t2,
        'roll_number': 'SE180002',
      }, cookie: cookie);
      expect(r.statusCode, 409);
      expect(await r.readAsString(), contains('sinh viên khác'));
      expect(store.records.containsKey('SE180002'), isFalse);
      final warning = events.last.outcome as CheckinRejected;
      expect(warning.reason, RejectReason.deviceUsedByOther);
    },
  );

  test('already checked in', () async {
    final (t1, cookie) = await scan();
    await post({'ticket': t1, 'roll_number': 'SE180001'}, cookie: cookie);
    final (t2, _) = await scan(cookie: cookie);
    final r = await post({
      'ticket': t2,
      'roll_number': 'SE180001',
    }, cookie: cookie);
    expect(await r.readAsString(), contains('Bạn đã điểm danh rồi'));
  });

  test('student names are HTML-escaped', () async {
    final (ticket, cookie) = await scan();
    final r = await post({
      'ticket': ticket,
      'roll_number': 'SE180003',
    }, cookie: cookie);
    final html = await r.readAsString();
    expect(html, contains('Lê &lt;b&gt;Hoàng&lt;&#47;b&gt; Cường'));
    expect(html, isNot(contains('<b>Hoàng</b>')));
  });

  test(
    'tampered cookies are ignored (treated as no cookie -> flagged)',
    () async {
      final (ticket, _) = await scan();
      await post({
        'ticket': ticket,
        'roll_number': 'SE180001',
      }, cookie: 'device_id="><script>');
      expect(store.records['SE180001']!.flag, AttendanceFlag.noDeviceCookie);
    },
  );

  test('paused server refuses check-ins', () async {
    server.paused = true;
    final r = await get('/checkin?t=${server.token.current}');
    expect(r.statusCode, 503);
    expect(await r.readAsString(), contains('tạm dừng'));
  });

  test('unknown paths get the landing page', () async {
    final r = await get('/admin');
    expect(r.statusCode, 404);
    expect(await r.readAsString(), contains('quét mã QR'));
  });

  test('responses are not cached and lock down resources', () async {
    final r = await get('/');
    expect(r.headers['cache-control'], 'no-store');
    expect(
      r.headers['content-security-policy'],
      contains("default-src 'none'"),
    );
  });

  test('real HTTP round trip on a local port', () async {
    await server.start(0);
    addTearDown(server.stop);
    final client = HttpClient();
    addTearDown(client.close);
    final req = await client.get(
      '127.0.0.1',
      server.port!,
      '/checkin?t=${server.token.current}',
    );
    final res = await req.close();
    final body = await res.transform(const SystemEncoding().decoder).join();
    expect(res.statusCode, 200);
    expect(body, contains('name="ticket"'));
    await server.stop();
    expect(server.isRunning, isFalse);
  });
}
