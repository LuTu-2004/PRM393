import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/leader_election.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test nghiep vu theo file docx tren Firestore gia lap.
void main() {
  late FakeFirebaseFirestore db;
  late GroupService service;
  late DateTime now;
  const spaceId = 'FA26_EXE101';

  AppUser student(String id, {bool complete = true}) => AppUser(
    uid: id,
    email: '$id@fpt.edu.vn',
    fullName: 'SV $id',
    role: UserRole.student,
    studentCode: 'SE18${id.padLeft(4, '0')}',
    major: 'SE',
    courseCode: complete ? 'EXE101' : null,
    commitmentAccepted: complete,
  );

  Future<Room> room(String id) async {
    final snap = await db.collection(Collections.rooms).doc(id).get();
    return Room.fromMap(snap.id, snap.data()!);
  }

  Future<RoomApplication> application(String id) async {
    final snap = await db.collection(Collections.applications).doc(id).get();
    return RoomApplication.fromMap(snap.id, snap.data()!);
  }

  /// Dua Room 01 len thanh Group 3 nguoi: a (Leader), b, c.
  Future<void> makeGroup() async {
    for (final id in ['a', 'b', 'c']) {
      now = now.add(const Duration(minutes: 1));
      await service.joinRoom(student(id), 'FA26EXE101-01');
    }
  }

  /// Leader mo vote, ca nhom Room 01 vote nhan den khi co ket qua (BR-25).
  Future<void> admit(String applicationId) async {
    await service.openApplicationVote(student('a'), applicationId);
    final members = (await room('FA26EXE101-01')).memberIds;
    for (final uid in members) {
      final status = await service.voteApplication(student(uid), applicationId, true);
      if (status != ApplicationStatus.pending) return;
    }
  }

  setUp(() async {
    db = FakeFirebaseFirestore();
    now = DateTime(2026, 11, 1, 8);
    service = GroupService(firestore: db, clock: () => now);
    await service.ensureSpace('EXE101');
  });

  group('BR-09, BR-11: khoi tao Space', () {
    test('tao dung so Room theo cong thuc va dung ma Room', () async {
      // 40 sinh vien / 5 x 1,2 = 9,6 -> 10 Room
      final rooms = await db.collection(Collections.rooms).get();
      expect(rooms.docs.length, 10);
      expect(rooms.docs.map((d) => d.id), contains('FA26EXE101-01'));
      expect(rooms.docs.map((d) => d.id), contains('FA26EXE101-10'));
    });
  });

  group('Vao Room va nguong Group', () {
    test('BR-07: chua hoan thanh ho so thi khong vao duoc', () async {
      await expectLater(
        () => service.joinRoom(student('x', complete: false), 'FA26EXE101-01'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-14, BR-15: vao thang Room trong, nguoi dau tien lam Leader', () async {
      await service.joinRoom(student('a'), 'FA26EXE101-01');
      final r = await room('FA26EXE101-01');
      expect(r.memberIds, ['a']);
      expect(r.leaderId, 'a');
      expect(r.status, RoomStatus.open);
    });

    test('BR-16: du 3/5 nguoi thi thanh Group va khong vao thang duoc nua', () async {
      await makeGroup();
      expect((await room('FA26EXE101-01')).status, RoomStatus.group);
      await expectLater(
        () => service.joinRoom(student('d'), 'FA26EXE101-01'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-21: moi sinh vien chi o mot Room trong mot mon', () async {
      await service.joinRoom(student('a'), 'FA26EXE101-01');
      await expectLater(
        () => service.joinRoom(student('a'), 'FA26EXE101-02'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-30: het han dang ky thi khong vao duoc', () async {
      now = now.add(const Duration(days: 31));
      await expectLater(
        () => service.joinRoom(student('a'), 'FA26EXE101-01'),
        throwsA(isA<BusinessException>()),
      );
    });
  });

  group('Apply va vote', () {
    test('BR-16: Room duoi nguong thi khong can Apply', () async {
      await service.joinRoom(student('a'), 'FA26EXE101-01');
      await expectLater(
        () => service.applyToRoom(student('d'), 'FA26EXE101-01'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-24: da o trong nhom thi khong Apply duoc', () async {
      await makeGroup();
      await service.joinRoom(student('d'), 'FA26EXE101-02');
      await expectLater(
        () => service.applyToRoom(student('d'), 'FA26EXE101-01'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-22: khong vuot gioi han don dang cho', () async {
      // Tao 4 Group, sinh vien z Apply vao 3 Group, don thu 4 bi chan.
      for (var i = 1; i <= 4; i++) {
        final code = 'FA26EXE101-0$i';
        for (final m in ['a', 'b', 'c']) {
          await service.joinRoom(student('$m$i'), code);
        }
      }
      for (var i = 1; i <= 3; i++) {
        await service.applyToRoom(student('z'), 'FA26EXE101-0$i');
      }
      await expectLater(
        () => service.applyToRoom(student('z'), 'FA26EXE101-04'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-25: thanh vien vote mot lan sau khi Leader mo vote', () async {
      await makeGroup();
      final app = await service.applyToRoom(student('d'), 'FA26EXE101-01');

      await expectLater(
        () => service.voteApplication(student('b'), app.id, true),
        throwsA(isA<BusinessException>()),
        reason: 'Leader chua mo vote',
      );
      await expectLater(
        () => service.openApplicationVote(student('b'), app.id),
        throwsA(isA<BusinessException>()),
        reason: 'chi Leader mo vote',
      );
      await service.openApplicationVote(student('a'), app.id);
      expect(await service.voteApplication(student('b'), app.id, true), ApplicationStatus.pending);
      await expectLater(
        () => service.voteApplication(student('b'), app.id, false),
        throwsA(isA<BusinessException>()),
        reason: 'moi thanh vien mot phieu',
      );
      await expectLater(
        () => service.voteApplication(student('x'), app.id, true),
        throwsA(isA<BusinessException>()),
        reason: 'nguoi ngoai nhom khong vote',
      );
      expect((await application(app.id)).acceptVotes, 1);
    });

    test('BR-25: du hon 50% phieu nhan thi vao nhom, thanh vien thuong chot duoc', () async {
      await makeGroup();
      final app = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.openApplicationVote(student('a'), app.id);
      await service.voteApplication(student('b'), app.id, true);
      expect(await service.voteApplication(student('c'), app.id, true), ApplicationStatus.accepted);
      final stored = await application(app.id);
      expect(stored.status, ApplicationStatus.accepted);
      expect(stored.acceptVotes, 2, reason: 'phieu quyet dinh van duoc ghi');
      expect((await room('FA26EXE101-01')).memberIds, contains('d'));
      expect((await room('FA26EXE101-01')).leaderId, 'a', reason: 'Leader giu nguyen');
    });

    test('BR-25: khong con du phieu thi tu Reject, ke ca khi Leader vote nhan', () async {
      await makeGroup();
      final app = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.openApplicationVote(student('a'), app.id);
      await service.voteApplication(student('a'), app.id, true);
      await service.voteApplication(student('b'), app.id, false);
      expect(
        await service.voteApplication(student('c'), app.id, false),
        ApplicationStatus.rejected,
      );
      expect((await room('FA26EXE101-01')).memberIds, isNot(contains('d')));
    });

    test('BR-25: hoa 2-2 tren 4 nguoi la khong dat hon 50%', () async {
      await makeGroup();
      final first = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await admit(first.id);
      final app = await service.applyToRoom(student('e'), 'FA26EXE101-01');
      await service.openApplicationVote(student('a'), app.id);
      await service.voteApplication(student('a'), app.id, true);
      await service.voteApplication(student('b'), app.id, true);
      await service.voteApplication(student('c'), app.id, false);
      expect(
        await service.voteApplication(student('d'), app.id, false),
        ApplicationStatus.rejected,
      );
    });

    test('BR-25: nguoi roi nhom khong con tinh phieu, phai chot lai ket qua', () async {
      await makeGroup();
      final first = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await admit(first.id); // a, b, c, d
      final app = await service.applyToRoom(student('e'), 'FA26EXE101-01');
      await service.openApplicationVote(student('a'), app.id);
      await service.voteApplication(student('a'), app.id, true);
      await service.voteApplication(student('b'), app.id, true);
      await service.leaveRoom(student('d'), 'FA26EXE101-01');

      // Con a, b, c: 2 phieu nhan da hon 50% nhung khong co phieu moi de kich hoat.
      expect((await application(app.id)).status, ApplicationStatus.pending);
      expect(await service.settleApplicationVote(student('c'), app.id), ApplicationStatus.accepted);
      expect((await room('FA26EXE101-01')).memberIds, contains('e'));
    });

    test('BR-25: chot khi chua du ket qua thi khong doi gi', () async {
      await makeGroup();
      final app = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.openApplicationVote(student('a'), app.id);
      await service.voteApplication(student('a'), app.id, true);
      expect(await service.settleApplicationVote(student('b'), app.id), ApplicationStatus.pending);
      expect((await application(app.id)).acceptVotes, 1);
    });

    test('BR-25: het han dang ky thi khong vote duoc', () async {
      await makeGroup();
      final app = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.openApplicationVote(student('a'), app.id);
      now = now.add(const Duration(days: 31));
      await expectLater(
        () => service.voteApplication(student('a'), app.id, true),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-26: ung vien da vao nhom khac thi phieu quyet dinh chuyen don thanh Cancel', () async {
      await makeGroup();
      final app = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.openApplicationVote(student('a'), app.id);
      await service.voteApplication(student('a'), app.id, true);
      // Mo phong don chua kip chuyen Cancel khi ung vien vao thang nhom khac.
      await db.collection(Collections.memberships).doc('${spaceId}_d').set({
        'spaceId': spaceId,
        'uid': 'd',
        'roomId': 'FA26EXE101-02',
      });
      await expectLater(
        () => service.voteApplication(student('b'), app.id, true),
        throwsA(isA<BusinessException>()),
      );
      expect((await application(app.id)).status, ApplicationStatus.cancelled);
      expect((await room('FA26EXE101-01')).memberIds, isNot(contains('d')));
    });

    test('BR-26: duoc nhan vao mot nhom thi cac don khac chuyen Cancel', () async {
      await makeGroup();
      for (final m in ['x', 'y', 'w']) {
        await service.joinRoom(student(m), 'FA26EXE101-02');
      }
      final app1 = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      final app2 = await service.applyToRoom(student('d'), 'FA26EXE101-02');

      await admit(app1.id);

      expect((await application(app1.id)).status, ApplicationStatus.accepted);
      expect((await application(app2.id)).status, ApplicationStatus.cancelled);
      expect((await room('FA26EXE101-01')).memberIds, contains('d'));
    });

    test('BR-26: vao thang mot Room thi cac don dang cho chuyen Cancel', () async {
      await makeGroup();
      final app = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.joinRoom(student('d'), 'FA26EXE101-02');
      expect((await application(app.id)).status, ApplicationStatus.cancelled);
    });

    test('BR-27, BR-28: nhan them chua du thi giu don, du nguoi thi Reject het', () async {
      await makeGroup();
      final d = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      final e = await service.applyToRoom(student('e'), 'FA26EXE101-01');
      final f = await service.applyToRoom(student('f'), 'FA26EXE101-01');

      await admit(d.id); // 4/5
      expect((await application(e.id)).status, ApplicationStatus.pending); // BR-27

      await admit(e.id); // 5/5
      expect((await room('FA26EXE101-01')).status, RoomStatus.closed);
      expect((await application(f.id)).status, ApplicationStatus.rejected); // BR-28
    });

    test('BR-28: Leader dong tuyen thi don dang cho chuyen Reject', () async {
      await makeGroup();
      final d = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.closeRecruitment(student('a'), 'FA26EXE101-01');
      expect((await application(d.id)).status, ApplicationStatus.rejected);
      expect((await room('FA26EXE101-01')).status, RoomStatus.closed);
    });

    test('BR-24: sinh vien rut don dang cho', () async {
      await makeGroup();
      final d = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.withdrawApplication(student('d'), d.id);
      expect((await application(d.id)).status, ApplicationStatus.withdrawn);
    });
  });

  group('Roi nhom va Leader', () {
    test('BR-29: nhom da dong tuyen thanh vien van roi duoc', () async {
      await makeGroup();
      await service.closeRecruitment(student('a'), 'FA26EXE101-01');
      await service.leaveRoom(student('c'), 'FA26EXE101-01');
      expect((await room('FA26EXE101-01')).memberIds, ['a', 'b']);
    });

    test('BR-17: Group rot duoi nguong thi quay lai Room, don dang cho giu nguyen', () async {
      await makeGroup();
      final d = await service.applyToRoom(student('d'), 'FA26EXE101-01');
      await service.leaveRoom(student('c'), 'FA26EXE101-01');

      final r = await room('FA26EXE101-01');
      expect(r.status, RoomStatus.open);
      expect((await application(d.id)).status, ApplicationStatus.pending);
      // Mo lai cho vao thang.
      await service.joinRoom(student('e'), 'FA26EXE101-01');
    });

    test('BR-20: Leader roi thi quyen chuyen cho nguoi vao som nhat', () async {
      await makeGroup();
      await service.leaveRoom(student('a'), 'FA26EXE101-01');
      expect((await room('FA26EXE101-01')).leaderId, 'b');
    });

    test('BR-20: nguoi cuoi cung roi thi Room tro ve trong', () async {
      await service.joinRoom(student('a'), 'FA26EXE101-01');
      await service.leaveRoom(student('a'), 'FA26EXE101-01');
      final r = await room('FA26EXE101-01');
      expect(r.status, RoomStatus.empty);
      expect(r.leaderId, isNull);
      // Da roi thi vao Room khac duoc (BR-21).
      await service.joinRoom(student('a'), 'FA26EXE101-02');
    });

    test('BR-18: Leader chuyen quyen cho thanh vien khac', () async {
      await makeGroup();
      await service.transferLeadership(student('a'), 'FA26EXE101-01', 'c');
      expect((await room('FA26EXE101-01')).leaderId, 'c');
    });

    test('BR-19: bau Leader thong qua khi hon 50% dong y', () async {
      await makeGroup();
      final e = await service.startLeaderElection(student('b'), 'FA26EXE101-01', 'c');
      expect(
        await service.voteLeaderElection(student('b'), 'FA26EXE101-01', e.id, true),
        ElectionStatus.open,
      ); // 1/3
      expect(
        await service.voteLeaderElection(student('c'), 'FA26EXE101-01', e.id, true),
        ElectionStatus.passed,
      ); // 2/3 > 50%
      expect((await room('FA26EXE101-01')).leaderId, 'c');
    });

    test('BR-19: moi Room mot cuoc bau mot luc, het han sau 24 gio', () async {
      await makeGroup();
      final e = await service.startLeaderElection(student('b'), 'FA26EXE101-01', 'c');
      await expectLater(
        () => service.startLeaderElection(student('c'), 'FA26EXE101-01', 'b'),
        throwsA(isA<BusinessException>()),
      );
      now = now.add(const Duration(hours: 25));
      expect(
        await service.voteLeaderElection(student('b'), 'FA26EXE101-01', e.id, true),
        ElectionStatus.expired,
      );
      // Cuoc cu het han thi mo cuoc moi duoc.
      await service.startLeaderElection(student('c'), 'FA26EXE101-01', 'b');
    });
  });

  group('Chot so va chuyen nhom', () {
    Future<void> finalize() =>
        db.collection(Collections.spaces).doc(spaceId).update({'finalized': true});

    test('BR-33: chot so thi khong tu roi nhom duoc', () async {
      await makeGroup();
      await finalize();
      await expectLater(
        () => service.leaveRoom(student('c'), 'FA26EXE101-01'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-36: chua chot so thi chua gui yeu cau chuyen nhom', () async {
      await makeGroup();
      await expectLater(
        () => service.requestTransfer(student('c'), 'FA26EXE101-02'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-36, BR-37: gui yeu cau chuyen nhom, danh dau can doi cheo', () async {
      await makeGroup();
      await service.joinRoom(student('d'), 'FA26EXE101-02');
      await finalize();
      final req = await service.requestTransfer(student('c'), 'fa26exe101-02');
      expect(req.toRoomId, 'FA26EXE101-02');
      expect(req.needsSwap, isTrue, reason: 'nhom cu con 2 < nguong 3');
    });
  });
}
