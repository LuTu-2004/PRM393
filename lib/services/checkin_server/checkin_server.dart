import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import '../token/rotating_token.dart';
import 'checkin_service.dart';
import 'html_pages.dart';
import 'ticket_store.dart';

/// Something the lecturer's screen should show.
class CheckinEvent {
  const CheckinEvent({required this.time, required this.outcome});

  final DateTime time;
  final CheckinOutcome outcome;
}

/// LAN web server that students' phones talk to (spec §5.1–5.5).
///
/// `GET /checkin?t=TOKEN`: valid token -> single-use ticket + roll form
/// `POST /checkin`: ticket + roll_number -> [CheckinService]
class CheckinServer {
  CheckinServer({
    required this.token,
    required this.tickets,
    required this.service,
    required this.info,
    this.onEvent,
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  static const deviceCookie = 'device_id';
  static const _maxBodyBytes = 4096;
  static final _deviceIdPattern = RegExp(r'^[A-Za-z0-9-]{16,64}$');

  final RotatingToken token;
  final TicketStore tickets;
  final CheckinService service;
  final PageInfo info;
  final void Function(CheckinEvent event)? onEvent;
  final DateTime Function() _clock;
  final Random _random;

  /// While paused the server answers every request with "tạm dừng".
  bool paused = false;

  HttpServer? _server;

  bool get isRunning => _server != null;

  /// Port actually bound (useful when started on port 0).
  int? get port => _server?.port;

  /// Starts listening on all IPv4 interfaces. Throws [SocketException] when
  /// the port is already in use.
  Future<void> start(int port) async {
    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    _server!.autoCompress = true;
  }

  /// Stops the server and forgets every ticket.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    tickets.clear();
  }

  Handler get handler {
    final router = Router()
      ..get('/', (Request r) => _html(landingPage()))
      ..get('/checkin', _get)
      ..post('/checkin', _post);
    return const Pipeline()
        .addMiddleware(_pauseGate())
        .addHandler((r) async => await router.call(r));
  }

  Middleware _pauseGate() =>
      (inner) => (request) async {
        if (paused && request.url.path == 'checkin') {
          return _html(pausedPage(), status: 503);
        }
        final response = await inner(request);
        // shelf_router answers unknown routes with a plain 404.
        return response.statusCode == 404
            ? _html(landingPage(), status: 404)
            : response;
      };

  Future<Response> _get(Request request) async {
    if (!token.verify(request.url.queryParameters['t'])) {
      return _html(expiredPage(), status: 410);
    }
    final ticket = tickets.issue();
    final headers = <String, String>{};
    if (_deviceIdOf(request) == null) {
      headers[HttpHeaders.setCookieHeader] =
          '$deviceCookie=${_newDeviceId()}; Max-Age=${60 * 60 * 24 * 400}; '
          'Path=/; HttpOnly; SameSite=Lax';
    }
    return _html(
      formPage(info, ticket: ticket, secondsLeft: tickets.secondsLeft(ticket)),
      headers: headers,
    );
  }

  Future<Response> _post(Request request) async {
    final length = request.contentLength;
    if (length != null && length > _maxBodyBytes) {
      return _html(ticketInvalidPage(), status: 413);
    }
    final body = await request.readAsString();
    if (body.length > _maxBodyBytes) {
      return _html(ticketInvalidPage(), status: 413);
    }

    final Map<String, String> form;
    try {
      form = Uri.splitQueryString(body);
    } on FormatException {
      return _html(ticketInvalidPage(), status: 400);
    }
    if (!tickets.consume(form['ticket'])) {
      return _html(ticketInvalidPage(), status: 410);
    }

    final outcome = await service.submit(
      rawRollNumber: form['roll_number'] ?? '',
      deviceId: _deviceIdOf(request),
    );
    final now = _clock();
    onEvent?.call(CheckinEvent(time: now, outcome: outcome));

    return switch (outcome) {
      CheckinAccepted(:final student, :final record) => _html(
        successPage(
          info,
          fullName: student.fullName,
          rollNumber: student.rollNumber,
          time: _hhmm(record.timestamp),
        ),
      ),
      CheckinRejected(reason: RejectReason.unknownRoll, :final rollNumber) =>
        _html(
          errorPage(
            reason: (rollNumber ?? '').isEmpty
                ? 'Chưa nhập MSSV'
                : 'MSSV $rollNumber không có trong lớp ${info.classLine}',
            hint: 'Kiểm tra lại MSSV. $rescanHint',
          ),
          status: 422,
        ),
      CheckinRejected(reason: RejectReason.alreadyCheckedIn, :final student) =>
        _html(
          errorPage(
            reason:
                'Bạn đã điểm danh rồi${student == null ? '' : ' – ${student.fullName}'}',
            hint:
                'Không cần điểm danh lại. Nếu có sai sót, hãy báo giảng viên.',
          ),
          status: 409,
        ),
      CheckinRejected(reason: RejectReason.deviceUsedByOther) => _html(
        errorPage(
          reason: 'Điện thoại này đã được dùng để điểm danh cho sinh viên khác',
          hint:
              'Mỗi sinh viên phải dùng điện thoại của mình. '
              'Giảng viên đã nhận được cảnh báo.',
        ),
        status: 409,
      ),
    };
  }

  String? _deviceIdOf(Request request) {
    final header = request.headers[HttpHeaders.cookieHeader];
    if (header == null) return null;
    for (final part in header.split(';')) {
      final i = part.indexOf('=');
      if (i < 0) continue;
      if (part.substring(0, i).trim() == deviceCookie) {
        final value = part.substring(i + 1).trim();
        return _deviceIdPattern.hasMatch(value) ? value : null;
      }
    }
    return null;
  }

  /// Random UUID v4.
  String _newDeviceId() {
    final b = List<int>.generate(16, (_) => _random.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static Response _html(
    String body, {
    int status = 200,
    Map<String, String> headers = const {},
  }) => Response(
    status,
    body: body,
    headers: {
      HttpHeaders.contentTypeHeader: 'text/html; charset=utf-8',
      HttpHeaders.cacheControlHeader: 'no-store',
      'X-Content-Type-Options': 'nosniff',
      'Referrer-Policy': 'no-referrer',
      'Content-Security-Policy':
          "default-src 'none'; "
          "style-src 'unsafe-inline'; script-src 'unsafe-inline'; "
          "img-src data:; form-action 'self'; frame-ancestors 'none'",
      ...headers,
    },
  );
}
