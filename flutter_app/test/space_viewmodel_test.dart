import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/services/analytics_service.dart';
import 'package:exe_matching/services/crashlytics_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/remote_config_service.dart';
import 'package:exe_matching/viewmodels/space_viewmodel.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late GroupService groups;
  late SpaceViewModel vm;
  final now = DateTime(2026, 11, 1);

  AppUser student(String id) => AppUser(
    uid: id,
    email: '$id@fpt.edu.vn',
    fullName: 'SV $id',
    role: UserRole.student,
    courseCode: 'EXE101',
    commitmentAccepted: true,
  );

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  setUp(() async {
    groups = GroupService(firestore: FakeFirebaseFirestore(), clock: () => now);
    await groups.ensureSpace('EXE101');
    vm = SpaceViewModel(
      groups: groups,
      remoteConfig: RemoteConfigService.disabled(),
      analytics: AnalyticsService.disabled(),
      crashlytics: CrashlyticsService.disabled(),
    );
  });

  tearDown(() => vm.dispose());

  test('tai Space va danh sach Room theo thu tu', () async {
    vm.bind(student('me'));
    await settle();
    expect(vm.isLoading, isFalse);
    expect(vm.space?.id, 'FA26_EXE101');
    expect(vm.visibleRooms.length, 10);
    expect(vm.visibleRooms.first.code, 'FA26EXE101-01');
  });

  test('BR-07: ho so chua xong thi khong tai Space', () async {
    vm.bind(const AppUser(uid: 'x', email: 'x@fpt.edu.vn', fullName: 'X', role: UserRole.student));
    await settle();
    expect(vm.space, isNull);
  });

  test('BR-13: loc theo trang thai va so cho con trong', () async {
    for (final id in ['a', 'b', 'c']) {
      await groups.joinRoom(student(id), 'FA26EXE101-01');
    }
    await groups.joinRoom(student('d'), 'FA26EXE101-02');

    vm.bind(student('me'));
    await settle();

    vm.setFilter(RoomFilter.applyable);
    expect(vm.visibleRooms.map((r) => r.code), ['FA26EXE101-01']);

    vm.setFilter(RoomFilter.joinable);
    expect(vm.visibleRooms.length, 9);
    expect(vm.visibleRooms.every((r) => vm.statusOf(r) != RoomStatus.group), isTrue);
  });

  test('nhom cua toi va don dang cho cap nhat real-time', () async {
    for (final id in ['a', 'b', 'c']) {
      await groups.joinRoom(student(id), 'FA26EXE101-01');
    }
    vm.bind(student('me'));
    await settle();
    expect(vm.hasRoom, isFalse);

    final result = await vm.apply('FA26EXE101-01');
    expect(result.ok, isTrue);
    await settle();
    expect(vm.pendingApplicationCount, 1);

    await vm.join('FA26EXE101-02');
    await settle();
    expect(vm.myRoomId, 'FA26EXE101-02');
    expect(vm.pendingApplicationCount, 0, reason: 'BR-26: don khac chuyen Cancel');
  });

  test('loi nghiep vu tra ve thong diep, khong nem loi ra View', () async {
    await groups.joinRoom(student('me'), 'FA26EXE101-01');
    vm.bind(student('me'));
    await settle();
    final result = await vm.join('FA26EXE101-02');
    expect(result.ok, isFalse);
    expect(result.message, contains('một nhóm'));
  });
}
