import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/domain/distribution_planner.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/models/space.dart';
import 'package:exe_matching/models/transfer_request.dart';
import 'package:exe_matching/services/admin_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 1);
  final afterDeadline = now.add(const Duration(days: 31));

  AppUser student(
    String id, {
    String major = 'SE',
    int tech = 0,
    int management = 0,
    int marketing = 0,
  }) => AppUser(
    uid: id,
    email: '$id@fpt.edu.vn',
    fullName: 'SV $id',
    role: UserRole.student,
    studentCode: 'SE18${id.hashCode.abs() % 9000 + 1000}',
    major: major,
    courseCode: 'EXE101',
    commitmentAccepted: true,
    skills: SkillScores(tech: tech, management: management, marketing: marketing),
  );

  group('Ke hoach phan phoi (BR-31, BR-32)', () {
    RoomProfile profile(int number, List<AppUser> members) => RoomProfile(
      Room(
        id: 'R$number',
        spaceId: 's',
        number: number,
        maxGroupSize: 5,
        leaderId: members.isEmpty ? null : members.first.uid,
        members: [
          for (final m in members) RoomMember(uid: m.uid, fullName: m.fullName, joinedAt: now),
        ],
      ),
      members,
    );

    DistributionPlan plan(List<AppUser> strays, List<RoomProfile> rooms) =>
        DistributionPlanner.plan(
          strayStudents: strays,
          rooms: rooms,
          maxGroupSize: 5,
          threshold: 3,
          roomCodeOf: (n) => 'R$n',
        );

    test('lap Room con thieu truoc, chua dung Room trong', () {
      final result = plan(
        [student('x'), student('y')],
        [
          profile(1, [student('a')]),
          profile(2, []),
        ],
      );
      expect(result.placements.single.roomId, 'R1');
      expect(result.placements.single.newLeaderId, isNull, reason: 'Leader giu nguyen');
    });

    test('con du moi dung Room trong, Leader la nguoi Management cao nhat', () {
      final result = plan(
        [student('x', management: 10), student('y', management: 90), student('z', management: 50)],
        [profile(1, [])],
      );
      final placement = result.placements.single;
      expect(placement.isExistingGroup, isFalse);
      expect(placement.newLeaderId, 'y');
      expect(result.newRoomIds, isEmpty);
    });

    test('het Room trong thi tao ma moi', () {
      final strays = [for (var i = 0; i < 6; i++) student('s$i')];
      final result = plan(strays, [profile(1, [])]);
      expect(result.placements.length, 2);
      expect(result.newRoomIds, ['R2']);
      expect(result.studentCount, 6);
    });

    test('moi sinh vien duoc xep dung mot lan, khong vuot si so', () {
      final strays = [for (var i = 0; i < 12; i++) student('s$i', tech: i * 8)];
      final result = plan(strays, [
        profile(1, [student('a'), student('b'), student('c'), student('d')]),
        profile(2, [student('e')]),
        profile(3, []),
      ]);
      final placed = [for (final p in result.placements) ...p.students.map((s) => s.uid)];
      expect(placed.toSet().length, 12);
      expect(placed.length, 12);
      final r1 = result.placements.firstWhere((p) => p.roomId == 'R1');
      expect(r1.students.length, 1);
    });

    test('uu tien nhom can dung ky nang', () {
      final result = plan(
        [student('mkt', major: 'SS', marketing: 90)],
        [
          profile(1, [student('a', marketing: 95), student('b'), student('c')]),
          profile(2, [student('d', tech: 90), student('e'), student('f')]),
        ],
      );
      expect(result.placements.single.roomId, 'R2');
    });

    test('bao nhom moi van duoi nguong', () {
      final result = plan([student('x')], [profile(1, [])]);
      expect(result.belowThresholdRoomIds, ['R1']);
    });
  });

  group('AdminService', () {
    late FakeFirebaseFirestore db;
    late AdminService admin;
    late GroupService groups;

    Future<Space> space([String id = 'FA26_EXE101']) async {
      final s = await db.collection(Collections.spaces).doc(id).get();
      return Space.fromMap(s.id, s.data()!);
    }

    Future<Room> room(String id) async {
      final s = await db.collection(Collections.rooms).doc(id).get();
      return Room.fromMap(s.id, s.data()!);
    }

    Future<String?> membershipRoom(String uid) async {
      final s = await db
          .collection(Collections.memberships)
          .doc(GroupService.membershipId('FA26_EXE101', uid))
          .get();
      return s.data()?['roomId'] as String?;
    }

    Future<void> createDefault() => admin.createSpace(
      term: 'FA26',
      courseCode: 'EXE101',
      maxGroupSize: 5,
      reservePercent: 120,
      applyLimit: 3,
      studentCount: 40,
      registrationDeadline: now.add(const Duration(days: 30)),
    );

    Future<void> saveUser(AppUser u) => db.collection(Collections.users).doc(u.uid).set(u.toMap());

    setUp(() {
      db = FakeFirebaseFirestore();
      // Sinh vien thao tac trong han dang ky, giang vien phan phoi va chot sau han (BR-30).
      admin = AdminService(firestore: db, clock: () => afterDeadline);
      groups = GroupService(firestore: db, clock: () => now);
    });

    test('BR-09: tao mon sinh dung so Room; tao trung bi chan', () async {
      await createDefault();
      expect((await db.collection(Collections.rooms).get()).docs.length, 10);
      await expectLater(createDefault, throwsA(isA<BusinessException>()));
    });

    test('BR-08: cau hinh sai bi chan', () async {
      await expectLater(
        () => admin.createSpace(
          term: 'FA26',
          courseCode: 'EXE101',
          maxGroupSize: 1,
          reservePercent: 120,
          applyLimit: 3,
          studentCount: 40,
          registrationDeadline: now,
        ),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-08: tang so sinh vien tao them Room, co nguoi thi khong doi si so', () async {
      await createDefault();
      final added = await admin.updateSpaceConfig(
        space: await space(),
        maxGroupSize: 5,
        reservePercent: 120,
        applyLimit: 4,
        studentCount: 50,
        registrationDeadline: now.add(const Duration(days: 30)),
      );
      expect(added.added, 2);
      expect((await space()).applyLimit, 4);

      await groups.joinRoom(student('a'), 'FA26EXE101-01');
      await expectLater(
        () async => admin.updateSpaceConfig(
          space: await space(),
          maxGroupSize: 6,
          reservePercent: 120,
          applyLimit: 4,
          studentCount: 50,
          registrationDeadline: now.add(const Duration(days: 30)),
        ),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-31, BR-26: phan phoi ghi nhom, membership va Cancel don dang cho', () async {
      await createDefault();
      for (final id in ['a', 'b', 'c']) {
        await groups.joinRoom(student(id), 'FA26EXE101-01');
      }
      final applicant = student('stray', management: 80);
      await saveUser(applicant);
      final app = await groups.applyToRoom(applicant, 'FA26EXE101-01');

      final plan = await admin.previewDistribution(await space(), [applicant]);
      await admin.applyDistribution(await space(), plan);

      expect(await membershipRoom('stray'), 'FA26EXE101-01');
      expect((await room('FA26EXE101-01')).memberCount, 4);
      final stored = await db.collection(Collections.applications).doc(app.id).get();
      expect(stored.data()!['status'], ApplicationStatus.cancelled.name);
    });

    test('phan phoi dung lai neu sinh vien vua tu co nhom', () async {
      await createDefault();
      final s = student('x');
      await saveUser(s);
      final plan = await admin.previewDistribution(await space(), [s]);
      await groups.joinRoom(s, 'FA26EXE101-05');
      await expectLater(
        () async => admin.applyDistribution(await space(), plan),
        throwsA(isA<BusinessException>()),
      );
    });

    test('BR-33: chot so khoa Room va Reject don dang cho', () async {
      await createDefault();
      for (final id in ['a', 'b', 'c']) {
        await groups.joinRoom(student(id), 'FA26EXE101-01');
      }
      final app = await groups.applyToRoom(student('d'), 'FA26EXE101-01');
      await admin.finalizeSpace(await space());

      expect((await space()).finalized, isTrue);
      expect((await room('FA26EXE101-01')).status, RoomStatus.finalized);
      final stored = await db.collection(Collections.applications).doc(app.id).get();
      expect(stored.data()!['status'], ApplicationStatus.rejected.name);
      await expectLater(
        () => groups.leaveRoom(student('a'), 'FA26EXE101-01'),
        throwsA(isA<BusinessException>()),
      );
    });

    group('Chot so va phan phoi (BR-30 - BR-33)', () {
      test('chua het han dang ky thi khong phan phoi, khong chot', () async {
        await createDefault();
        final early = AdminService(firestore: db, clock: () => now);
        final s = student('x');
        await saveUser(s);
        final matcher = throwsA(
          isA<BusinessException>().having((e) => e.message, 'message', contains('hạn đăng ký')),
        );
        await expectLater(() async => early.previewDistribution(await space(), [s]), matcher);
        await expectLater(() async => early.finalizeSpace(await space()), matcher);
      });

      test('con sinh vien le thi chot so bi chan', () async {
        await createDefault();
        await saveUser(student('x'));
        await expectLater(
          () async => admin.finalizeSpace(await space()),
          throwsA(
            isA<BusinessException>().having((e) => e.message, 'message', contains('phân phối')),
          ),
        );
        expect((await space()).finalized, isFalse);
      });

      test('phan phoi va chot: lap nhom chua du truoc, roi khoa', () async {
        await createDefault();
        for (final id in ['a', 'b', 'c']) {
          final u = student(id);
          await saveUser(u);
          await groups.joinRoom(u, 'FA26EXE101-01');
        }
        final strays = [student('x'), student('y')];
        for (final u in strays) {
          await saveUser(u);
        }
        expect((await admin.strayStudents(await space())).map((u) => u.uid).toSet(), {'x', 'y'});

        final plan = await admin.previewDistribution(await space(), strays);
        await admin.distributeAndFinalize(await space(), plan);

        expect(await membershipRoom('x'), 'FA26EXE101-01');
        expect(await membershipRoom('y'), 'FA26EXE101-01');
        expect((await room('FA26EXE101-01')).memberCount, 5);
        expect((await space()).finalized, isTrue);
        expect(await admin.strayStudents(await space()), isEmpty);
      });

      test('ke hoach cu (co nguoi vua tu vao nhom) thi khong chot gi', () async {
        await createDefault();
        final s = student('x');
        await saveUser(s);
        final plan = await admin.previewDistribution(await space(), [s]);
        await groups.joinRoom(s, 'FA26EXE101-05');
        await expectLater(
          () async => admin.distributeAndFinalize(await space(), plan),
          throwsA(isA<BusinessException>()),
        );
        expect((await space()).finalized, isFalse);
      });

      test('khong con sinh vien le thi chot duoc ngay', () async {
        await createDefault();
        final u = student('a');
        await saveUser(u);
        await groups.joinRoom(u, 'FA26EXE101-01');
        await admin.finalizeSpace(await space());
        expect((await space()).finalized, isTrue);
      });
    });

    group('Chuyen nhom', () {
      setUp(() async {
        await createDefault();
        for (final id in ['a', 'b', 'c']) {
          await groups.joinRoom(student(id), 'FA26EXE101-01');
        }
        // Da thanh Group nen nguoi thu 4 phai qua Apply.
        final app = await groups.applyToRoom(student('d'), 'FA26EXE101-01');
        await groups.openApplicationVote(student('a'), app.id);
        await groups.voteApplication(student('a'), app.id, true);
        await groups.voteApplication(student('b'), app.id, true);
        for (final id in ['e', 'f', 'g']) {
          await groups.joinRoom(student(id), 'FA26EXE101-02');
        }
      });

      test('chua chot so thi khong chuyen', () async {
        await expectLater(
          () async => admin.moveStudent(
            space: await space(),
            studentUid: 'd',
            fromRoomId: 'FA26EXE101-01',
            toRoomId: 'FA26EXE101-02',
          ),
          throwsA(isA<BusinessException>()),
        );
      });

      test('BR-35: chuyen truc tiep, Leader roi thi nguoi vao som nhat len thay', () async {
        await admin.finalizeSpace(await space());
        await admin.moveStudent(
          space: await space(),
          studentUid: 'a',
          fromRoomId: 'FA26EXE101-01',
          toRoomId: 'FA26EXE101-02',
        );
        expect((await room('FA26EXE101-01')).leaderId, 'b');
        expect((await room('FA26EXE101-02')).memberIds, contains('a'));
        expect(await membershipRoom('a'), 'FA26EXE101-02');
      });

      test('BR-37: nhom cu duoi nguong thi phai doi cheo', () async {
        await admin.finalizeSpace(await space());
        await expectLater(
          () async => admin.moveStudent(
            space: await space(),
            studentUid: 'e',
            fromRoomId: 'FA26EXE101-02',
            toRoomId: 'FA26EXE101-01',
          ),
          throwsA(isA<BusinessException>()),
        );
        await admin.moveStudent(
          space: await space(),
          studentUid: 'e',
          fromRoomId: 'FA26EXE101-02',
          toRoomId: 'FA26EXE101-01',
          swapWithUid: 'b',
        );
        expect(await membershipRoom('e'), 'FA26EXE101-01');
        expect(await membershipRoom('b'), 'FA26EXE101-02');
        expect((await room('FA26EXE101-02')).memberCount, 3);
      });

      test('BR-36: duyet va tu choi yeu cau', () async {
        await admin.finalizeSpace(await space());
        final request = await groups.requestTransfer(student('d'), 'FA26EXE101-02');
        await admin.approveTransfer(await space(), request);
        expect(await membershipRoom('d'), 'FA26EXE101-02');
        final stored = await db.collection(Collections.transferRequests).doc(request.id).get();
        expect(stored.data()!['status'], TransferStatus.approved.name);
        expect(stored.data()!['decidedAt'], isA<Timestamp>());

        await expectLater(
          () async => admin.approveTransfer(
            await space(),
            TransferRequest.fromMap(stored.id, stored.data()!),
          ),
          throwsA(isA<BusinessException>()),
        );
      });
    });
  });
}
