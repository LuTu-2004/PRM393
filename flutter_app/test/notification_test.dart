import 'package:exe_matching/services/notification_service.dart';
import 'package:exe_matching/services/user_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  AppNotification item(String id, {String? roomId}) => AppNotification(
    id: id,
    title: 'Tiêu đề $id',
    body: 'Nội dung',
    data: {'roomId': ?roomId},
    receivedAt: DateTime(2026, 11, 8),
  );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('Lich su thong bao', () {
    test('luu lai du lieu qua lan mo sau, khong trung, moi nhat truoc', () async {
      final store = NotificationHistoryStore();
      await store.add(item('a', roomId: 'FA26EXE101-01'));
      await store.add(item('b'));
      await store.add(item('a', roomId: 'FA26EXE101-01'));

      final loaded = await NotificationHistoryStore().load();
      expect(loaded.map((n) => n.id), ['b', 'a']);
      expect(loaded.last.roomId, 'FA26EXE101-01');
    });

    test('giu toi da so thong bao quy dinh', () async {
      final store = NotificationHistoryStore();
      for (var i = 0; i < NotificationHistoryStore.maxItems + 5; i++) {
        await store.add(item('$i'));
      }
      expect((await store.load()).length, NotificationHistoryStore.maxItems);
    });

    test('service nap lai lich su va trang thai da doc, dang xuat thi xoa', () async {
      final store = NotificationHistoryStore();
      await store.add(item('a'));
      await store.saveReadIds({'a'});

      final service = NotificationService(store: store);
      await service.reloadHistory();
      expect(service.history.single.id, 'a');
      expect(service.isRead(service.history.single), isTrue);

      await service.clearHistory();
      expect(service.history, isEmpty);
      expect(await store.load(), isEmpty);
    });
  });

  test('FCM token: luu theo nguoi dung, khong trung, xoa duoc', () async {
    final db = FakeFirebaseFirestore();
    final users = UserService(firestore: db);
    await users.saveFcmToken('me', 'token-1');
    await users.saveFcmToken('me', 'token-1');

    final tokens = db.collection('users').doc('me').collection('fcm_tokens');
    expect((await tokens.get()).docs.map((d) => d.id), ['token-1']);

    await users.deleteFcmToken('me', 'token-1');
    expect((await tokens.get()).docs, isEmpty);
  });
}
