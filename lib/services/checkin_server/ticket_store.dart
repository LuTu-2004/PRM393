import 'dart:convert';
import 'dart:math';

/// Short-lived, single-use tickets issued when a valid QR is opened, so a
/// student can finish typing their roll number after the QR has rotated.
class TicketStore {
  TicketStore({
    this.ttl = const Duration(seconds: 90),
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _random = random ?? Random.secure();

  final Duration ttl;
  final DateTime Function() _clock;
  final Random _random;

  /// Ticket -> expiry time. Used tickets are removed.
  final Map<String, DateTime> _tickets = {};

  int get activeCount {
    _purge();
    return _tickets.length;
  }

  /// Issues a new ticket.
  String issue() {
    _purge();
    final bytes = List<int>.generate(18, (_) => _random.nextInt(256));
    final ticket = base64Url.encode(bytes);
    _tickets[ticket] = _clock().add(ttl);
    return ticket;
  }

  /// Seconds left on [ticket], or 0 when unknown or expired.
  int secondsLeft(String ticket) {
    final expiry = _tickets[ticket];
    if (expiry == null) return 0;
    final left = expiry.difference(_clock()).inMilliseconds;
    return left <= 0 ? 0 : (left / 1000).ceil();
  }

  /// Consumes [ticket]. True only once, and only before it expires.
  bool consume(String? ticket) {
    if (ticket == null) return false;
    final expiry = _tickets.remove(ticket);
    return expiry != null && _clock().isBefore(expiry);
  }

  void clear() => _tickets.clear();

  void _purge() {
    final now = _clock();
    _tickets.removeWhere((_, expiry) => !now.isBefore(expiry));
  }
}
