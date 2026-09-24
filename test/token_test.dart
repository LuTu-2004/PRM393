import 'package:diem_danh/services/token/rotating_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final secret = List<int>.generate(32, (i) => i);
  var now = DateTime.fromMillisecondsSinceEpoch(1_000_000_002_000);

  RotatingToken make({String sessionId = '7', List<int>? key}) => RotatingToken(
    secret: key ?? secret,
    sessionId: sessionId,
    clock: () => now,
  );

  setUp(() => now = DateTime.fromMillisecondsSinceEpoch(1_000_000_002_000));

  test('token is 16 lowercase hex chars and stable within a window', () {
    final t = make();
    final a = t.current;
    expect(a, matches(RegExp(r'^[0-9a-f]{16}$')));
    now = now.add(const Duration(milliseconds: 2900));
    expect(t.current, a);
  });

  test('window = floor(unix_millis / 5000)', () {
    final t = make();
    expect(t.currentWindow, 1_000_000_002_000 ~/ 5000);
  });

  test('accepts the current window', () {
    final t = make();
    expect(t.verify(t.current), isTrue);
  });

  test('accepts the previous window', () {
    final t = make();
    final old = t.current;
    now = now.add(const Duration(seconds: 5));
    expect(t.current, isNot(old));
    expect(t.verify(old), isTrue);
  });

  test('rejects tokens two windows old (> ~10s)', () {
    final t = make();
    final old = t.current;
    now = now.add(const Duration(seconds: 10));
    expect(t.verify(old), isFalse);
  });

  test('rejects a token 15 seconds old', () {
    final t = make();
    final old = t.current;
    now = now.add(const Duration(seconds: 15));
    expect(t.verify(old), isFalse);
  });

  test('rejects wrong, empty, malformed and future tokens', () {
    final t = make();
    expect(t.verify(null), isFalse);
    expect(t.verify(''), isFalse);
    expect(t.verify('0000000000000000'), isFalse);
    expect(t.verify('${t.current}00'), isFalse);
    expect(t.verify(t.tokenForWindow(t.currentWindow + 1)), isFalse);
  });

  test('tokens are bound to the session and the secret', () {
    final a = make(sessionId: '7');
    final b = make(sessionId: '8');
    final c = make(key: List<int>.generate(32, (i) => 255 - i));
    expect(b.verify(a.current), isFalse);
    expect(c.verify(a.current), isFalse);
  });

  test('remaining counts down to the next window', () {
    final t = make();
    // 1_000_000_002_000 % 5000 == 2000 -> 3s left.
    expect(t.remaining, const Duration(seconds: 3));
  });

  test('newSecret returns 32 random bytes', () {
    final a = RotatingToken.newSecret();
    final b = RotatingToken.newSecret();
    expect(a, hasLength(32));
    expect(a, isNot(b));
  });

  test('constantTimeEquals', () {
    expect(constantTimeEquals('abc', 'abc'), isTrue);
    expect(constantTimeEquals('abc', 'abd'), isFalse);
    expect(constantTimeEquals('abc', 'ab'), isFalse);
  });
}
