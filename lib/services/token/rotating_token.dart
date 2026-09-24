import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// TOTP-like rotating token for one QR session.
///
///   window = floor(unix_millis / period)
///   token  = first 16 hex chars of HMAC-SHA256(secret, "sessionId:window")
///
/// The secret lives only in memory and dies with the session.
class RotatingToken {
  RotatingToken({
    required List<int> secret,
    required this.sessionId,
    this.period = const Duration(seconds: 5),
    DateTime Function()? clock,
  }) : _hmac = Hmac(sha256, secret),
       _clock = clock ?? DateTime.now {
    if (secret.length < 16) {
      throw ArgumentError('secret must be at least 16 bytes');
    }
  }

  static const int tokenLength = 16;

  final String sessionId;
  final Duration period;
  final Hmac _hmac;
  final DateTime Function() _clock;

  /// 32 random bytes from a cryptographically secure source.
  static List<int> newSecret() {
    final rng = Random.secure();
    return List<int>.generate(32, (_) => rng.nextInt(256));
  }

  int windowAt(DateTime t) => t.millisecondsSinceEpoch ~/ period.inMilliseconds;

  int get currentWindow => windowAt(_clock());

  String tokenForWindow(int window) => _hmac
      .convert(utf8.encode('$sessionId:$window'))
      .toString()
      .substring(0, tokenLength);

  String get current => tokenForWindow(currentWindow);

  /// Time left before the token changes.
  Duration get remaining {
    final ms = period.inMilliseconds;
    final now = _clock().millisecondsSinceEpoch;
    return Duration(milliseconds: ms - now % ms);
  }

  /// Accepts the current and the previous window (about two periods), so a
  /// scan right before the QR changes still works.
  bool verify(String? token) {
    if (token == null || token.length != tokenLength) return false;
    final w = currentWindow;
    // Evaluate both comparisons so timing does not reveal which one matched.
    final a = constantTimeEquals(token, tokenForWindow(w));
    final b = constantTimeEquals(token, tokenForWindow(w - 1));
    return a | b;
  }
}

/// Compares two strings in time that depends only on their length.
bool constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
