import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/attendance_dao.dart';
import '../../data/local/device_dao.dart';
import '../../domain/models.dart';
import '../../services/checkin_server/checkin_server.dart';
import '../../services/checkin_server/checkin_service.dart';
import '../../services/checkin_server/html_pages.dart';
import '../../services/checkin_server/lan_addresses.dart';
import '../../services/checkin_server/ticket_store.dart';
import '../../services/token/rotating_token.dart';
import 'providers.dart';
import 'session_controller.dart';

enum QrPhase { idle, starting, running, paused, error }

/// One line of the live "Vừa điểm danh" list.
class LiveEntry {
  const LiveEntry({
    required this.id,
    required this.time,
    required this.rollNumber,
    this.student,
    this.flagLabel,
    this.rejected = false,
    this.otherStudent,
  });

  final int id;
  final DateTime time;
  final String rollNumber;
  final Student? student;

  /// Why this entry needs attention, if it does.
  final String? flagLabel;

  /// A refused attempt (e.g. a phone reused for a second student).
  final bool rejected;
  final Student? otherStudent;
}

class QrRunState {
  const QrRunState({
    this.sessionId,
    this.phase = QrPhase.idle,
    this.error,
    this.addresses = const [],
    this.address,
    this.port = 8080,
    this.token = '',
    this.period = const Duration(seconds: 5),
    this.live = const [],
  });

  final int? sessionId;
  final QrPhase phase;
  final String? error;
  final List<LanAddress> addresses;
  final LanAddress? address;
  final int port;
  final String token;
  final Duration period;
  final List<LiveEntry> live;

  /// Address students type if scanning fails, e.g. "192.168.137.1:8080".
  String? get hostPort => address == null ? null : '${address!.ip}:$port';

  String? get url => hostPort == null || token.isEmpty
      ? null
      : 'http://$hostPort/checkin?t=$token';

  bool get isActive => phase == QrPhase.running || phase == QrPhase.paused;

  QrRunState copyWith({
    int? sessionId,
    QrPhase? phase,
    String? error,
    List<LanAddress>? addresses,
    LanAddress? address,
    int? port,
    String? token,
    Duration? period,
    List<LiveEntry>? live,
  }) => QrRunState(
    sessionId: sessionId ?? this.sessionId,
    phase: phase ?? this.phase,
    error: error,
    addresses: addresses ?? this.addresses,
    address: address ?? this.address,
    port: port ?? this.port,
    token: token ?? this.token,
    period: period ?? this.period,
    live: live ?? this.live,
  );
}

/// Owns the QR check-in server for at most one session at a time.
class QrController extends Notifier<QrRunState> {
  CheckinServer? _server;
  RotatingToken? _token;
  Timer? _rotation;
  int _nextEntryId = 0;

  /// Exposed for the countdown bar.
  Duration get remaining => _token?.remaining ?? Duration.zero;

  @override
  QrRunState build() {
    ref.onDispose(_shutdown);
    return const QrRunState();
  }

  Future<void> start(int sessionId) async {
    if (state.sessionId == sessionId && state.isActive) return;
    await stop();
    final settings = ref.read(settingsProvider);
    state = QrRunState(
      sessionId: sessionId,
      phase: QrPhase.starting,
      port: settings.qrPort,
      period: Duration(seconds: settings.qrPeriodSeconds),
    );

    try {
      final bundle = await ref.read(sessionRepositoryProvider).load(sessionId);
      final db = ref.read(databaseProvider).db;
      final token = RotatingToken(
        secret: RotatingToken.newSecret(),
        sessionId: '$sessionId',
        period: state.period,
      );
      final d = bundle.session.date;
      final server = CheckinServer(
        token: token,
        tickets: TicketStore(),
        service: CheckinService(
          sessionId: sessionId,
          autoApprove: settings.autoApprove,
          store: SqliteCheckinStore(
            sessionId: sessionId,
            roster: bundle.students,
            attendance: AttendanceDao(db),
            devices: DeviceDao(db),
          ),
        ),
        info: PageInfo(
          classLine:
              '${bundle.classInfo.classCode} · ${bundle.classInfo.subjectCode}',
          sessionLine:
              'Slot ${bundle.session.slot} · '
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
        ),
        onEvent: _onEvent,
      );
      await server.start(settings.qrPort);
      _server = server;
      _token = token;

      final addresses = await listLanAddresses();
      final preferred = addresses
          .where((a) => a.ip == settings.preferredIp)
          .firstOrNull;
      state = state.copyWith(
        phase: QrPhase.running,
        addresses: addresses,
        address: preferred ?? addresses.firstOrNull,
        token: token.current,
      );
      if (addresses.isEmpty) {
        state = state.copyWith(
          phase: QrPhase.error,
          error:
              'Máy chưa kết nối mạng nào. Hãy bật Wi-Fi hoặc Mobile Hotspot '
              'rồi bấm Thử lại.',
        );
        await _stopServer();
        return;
      }
      _scheduleRotation();
    } on SocketException catch (e) {
      await _stopServer();
      state = state.copyWith(
        phase: QrPhase.error,
        error: _portInUse(e)
            ? 'Cổng ${settings.qrPort} đang được ứng dụng khác sử dụng. '
                  'Đổi cổng trong Cài đặt → Điểm danh QR rồi thử lại.'
            : 'Không mở được máy chủ điểm danh: ${e.message}',
      );
    } catch (e) {
      await _stopServer();
      state = state.copyWith(
        phase: QrPhase.error,
        error: 'Không bắt đầu được điểm danh QR: $e',
      );
    }
  }

  static bool _portInUse(SocketException e) {
    final code = e.osError?.errorCode;
    // 10048 = WSAEADDRINUSE (Windows), 48 = EADDRINUSE (macOS), 98 (Linux).
    // Dart itself refuses a second bind in the same process (code -1).
    return code == 10048 ||
        code == 48 ||
        code == 98 ||
        (e.osError?.message.contains('binding multiple times') ?? false);
  }

  void _scheduleRotation() {
    _rotation?.cancel();
    final t = _token;
    if (t == null) return;
    // Fire just after the window boundary so the new token is ready.
    _rotation = Timer(t.remaining + const Duration(milliseconds: 20), () {
      if (_token == null) return;
      state = state.copyWith(
        token: _token!.current,
        phase: state.phase,
        error: state.error,
      );
      _scheduleRotation();
    });
  }

  void _onEvent(CheckinEvent e) {
    final entry = switch (e.outcome) {
      CheckinAccepted(:final student, :final record) => LiveEntry(
        id: _nextEntryId++,
        time: e.time,
        rollNumber: student.rollNumber,
        student: student,
        flagLabel: record.flag?.label,
      ),
      CheckinRejected(reason: RejectReason.deviceUsedByOther) &&
          final CheckinRejected r =>
        LiveEntry(
          id: _nextEntryId++,
          time: e.time,
          rollNumber: r.rollNumber ?? '',
          student: r.student,
          otherStudent: r.otherStudent,
          flagLabel: AttendanceFlag.multiStudentDevice.label,
          rejected: true,
        ),
      // Typos and repeats are shown to the student only.
      CheckinRejected() => null,
    };
    if (entry != null) {
      state = state.copyWith(
        live: [entry, ...state.live].take(200).toList(),
        phase: state.phase,
        error: state.error,
      );
    }
    final id = state.sessionId;
    if (id != null) {
      ref.read(sessionControllerProvider(id).notifier).reloadRecords();
    }
  }

  void pause() {
    _server?.paused = true;
    if (state.phase == QrPhase.running) {
      state = state.copyWith(phase: QrPhase.paused);
    }
  }

  void resume() {
    _server?.paused = false;
    if (state.phase == QrPhase.paused) {
      state = state.copyWith(phase: QrPhase.running);
    }
  }

  Future<void> selectAddress(LanAddress a) async {
    state = state.copyWith(address: a, phase: state.phase, error: state.error);
    await ref
        .read(settingsProvider.notifier)
        .update((s) => s.copyWith(preferredIp: a.ip));
  }

  /// Stops the server and discards the secret and all tickets.
  Future<void> stop() async {
    await _stopServer();
    state = const QrRunState();
  }

  Future<void> _stopServer() async {
    _rotation?.cancel();
    _rotation = null;
    _token = null;
    final s = _server;
    _server = null;
    await s?.stop();
  }

  void _shutdown() {
    _rotation?.cancel();
    _server?.stop();
  }
}

final qrControllerProvider = NotifierProvider<QrController, QrRunState>(
  QrController.new,
);
