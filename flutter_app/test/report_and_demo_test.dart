import 'dart:convert';
import 'dart:typed_data';

import 'package:exe_matching/config/app_config.dart';
import 'package:exe_matching/models/app_user.dart';
import 'package:exe_matching/models/application.dart';
import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/services/demo_seed_service.dart';
import 'package:exe_matching/services/file_storage_service.dart';
import 'package:exe_matching/services/group_service.dart';
import 'package:exe_matching/services/report_pdf_builder.dart';
import 'package:exe_matching/services/report_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppUser student(String id) => AppUser(
    uid: id,
    email: '$id@fpt.edu.vn',
    fullName: 'Nguyễn Văn Ánh',
    role: UserRole.student,
    studentCode: 'SE185045',
    major: 'SE',
    cohort: 'K18',
    courseCode: 'EXE101',
    commitmentAccepted: true,
  );

  group('Bao cao PDF', () {
    test('tao file PDF that, co ca nhom va don Apply', () async {
      final bytes = await ReportPdfBuilder().build(
        ReportData(
          user: student('me'),
          space: null,
          room: Room(
            id: 'FA26EXE101-01',
            spaceId: 'FA26_EXE101',
            number: 1,
            maxGroupSize: 5,
            leaderId: 'me',
            members: [RoomMember(uid: 'me', fullName: 'Ánh', joinedAt: DateTime(2026))],
          ),
          applications: [
            RoomApplication(
              id: 'a',
              roomId: 'FA26EXE101-02',
              spaceId: 'FA26_EXE101',
              applicantId: 'me',
              applicantName: 'Ánh',
              status: ApplicationStatus.cancelled,
              createdAt: DateTime(2026),
            ),
          ],
          generatedAt: DateTime(2026, 11, 8),
        ),
      );
      expect(String.fromCharCodes(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
    });

    test('luu va doc metadata theo thu tu moi nhat truoc', () async {
      final service = ReportService(firestore: FakeFirebaseFirestore());
      await service.save(
        ownerId: 'me',
        fileName: 'cu.pdf',
        url: 'https://x/cu.pdf',
        sizeBytes: 10,
        createdAt: DateTime(2026, 1, 1),
      );
      await service.save(
        ownerId: 'me',
        fileName: 'moi.pdf',
        url: 'https://x/moi.pdf',
        sizeBytes: 10,
        createdAt: DateTime(2026, 2, 1),
      );
      final items = await service.watchReports('me').first;
      expect(items.map((r) => r.fileName), ['moi.pdf', 'cu.pdf']);
      expect(items.first.ownerId, 'me');
    });
  });

  group('Upload Cloudinary', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    test('chua cau hinh thi bao loi ro rang', () async {
      final service = FileStorageService(cloudName: '', uploadPreset: '');
      expect(service.isConfigured, isFalse);
      await expectLater(
        () => service.uploadPdf(bytes: bytes, fileName: 'a.pdf', folder: 'f'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('thanh cong tra ve secure_url va gui dung preset', () async {
      late http.BaseRequest sent;
      final service = FileStorageService(
        cloudName: 'demo',
        uploadPreset: 'preset',
        client: MockClient((request) async {
          sent = request;
          return http.Response(jsonEncode({'secure_url': 'https://res/a.pdf'}), 200);
        }),
      );
      final url = await service.uploadPdf(bytes: bytes, fileName: 'a.pdf', folder: 'f');
      expect(url, 'https://res/a.pdf');
      expect(sent.url.path, '/v1_1/demo/auto/upload');
    });

    test('Cloudinary tu choi thi hien loi cua server', () async {
      final service = FileStorageService(
        cloudName: 'demo',
        uploadPreset: 'preset',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'message': 'Upload preset not found'},
            }),
            400,
          ),
        ),
      );
      await expectLater(
        () => service.uploadPdf(bytes: bytes, fileName: 'a.pdf', folder: 'f'),
        throwsA(
          isA<BusinessException>().having(
            (e) => e.message,
            'message',
            contains('Upload preset not found'),
          ),
        ),
      );
    });
  });

  group('Sua loi nhan don Apply', () {
    late GroupService groups;

    setUp(() async {
      groups = GroupService(firestore: FakeFirebaseFirestore(), clock: () => DateTime(2026, 11, 1));
      await groups.ensureSpace('EXE101');
      for (final id in ['a', 'b', 'c']) {
        await groups.joinRoom(student(id), 'FA26EXE101-01');
      }
    });

    test('chi chu don sua duoc, va chi khi don con cho', () async {
      final app = await groups.applyToRoom(student('d'), 'FA26EXE101-01', message: ' Xin chào ');
      expect(app.message, 'Xin chào');

      await groups.updateApplicationMessage(student('d'), app.id, 'Đã sửa');
      await expectLater(
        () => groups.updateApplicationMessage(student('e'), app.id, 'x'),
        throwsA(isA<BusinessException>()),
      );

      await groups.withdrawApplication(student('d'), app.id);
      await expectLater(
        () => groups.updateApplicationMessage(student('d'), app.id, 'x'),
        throwsA(isA<BusinessException>()),
      );
    });

    test('loi nhan qua dai bi tu choi', () async {
      await expectLater(
        () => groups.applyToRoom(
          student('d'),
          'FA26EXE101-01',
          message: 'x' * (AppConfig.applicationMessageMaxLength + 1),
        ),
        throwsA(isA<BusinessException>()),
      );
    });
  });

  group('Du lieu demo', () {
    test('tao du trang thai Room, don vao nhom cua toi, goi lai khong trung', () async {
      final db = FakeFirebaseFirestore();
      final now = DateTime(2026, 11, 1);
      final groups = GroupService(firestore: db, clock: () => now);
      final seeder = DemoSeedService(firestore: db, clock: () => now);
      final me = student('me');

      await groups.ensureSpace('EXE101');
      await groups.joinRoom(me, 'FA26EXE101-01');
      await seeder.seed(me);
      await seeder.seed(me);

      final rooms = await groups.watchRooms('FA26_EXE101').first;
      Room byNumber(int n) => rooms.firstWhere((r) => r.number == n);
      expect(byNumber(7).status, RoomStatus.open);
      expect(byNumber(8).status, RoomStatus.group);
      expect(byNumber(9).status, RoomStatus.group);
      expect(byNumber(10).status, RoomStatus.closed);

      final pending = await groups.watchPendingApplications('FA26EXE101-01').first;
      expect(pending.length, 3);

      // Leader nhan ung vien demo: thanh vien tang, don khac van giu (BR-27).
      await groups.decideApplication(me, pending.first.id, true);
      final mine = rooms.firstWhere((r) => r.number == 1);
      expect(mine.memberIds, ['me']);
      final after = await groups.watchRoom('FA26EXE101-01').first;
      expect(after?.memberCount, 2);
      expect((await groups.watchPendingApplications('FA26EXE101-01').first).length, 2);
    });
  });
}
