import 'package:diem_danh/services/checkin_server/ticket_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var now = DateTime(2026, 9, 23, 9);
  late TicketStore store;

  setUp(() {
    now = DateTime(2026, 9, 23, 9);
    store = TicketStore(clock: () => now);
  });

  test('a ticket can be used exactly once', () {
    final t = store.issue();
    expect(store.consume(t), isTrue);
    expect(store.consume(t), isFalse);
  });

  test('tickets live 90 seconds', () {
    final t = store.issue();
    expect(store.secondsLeft(t), 90);
    now = now.add(const Duration(seconds: 89));
    expect(store.secondsLeft(t), 1);
    final u = store.issue();
    now = now.add(const Duration(seconds: 1));
    expect(store.consume(t), isFalse, reason: 'expired at 90s');
    expect(store.consume(u), isTrue);
  });

  test('unknown or missing tickets are rejected', () {
    expect(store.consume(null), isFalse);
    expect(store.consume('nope'), isFalse);
  });

  test('tickets are unique and clear() forgets them', () {
    final a = store.issue();
    final b = store.issue();
    expect(a, isNot(b));
    store.clear();
    expect(store.consume(a), isFalse);
    expect(store.activeCount, 0);
  });
}
