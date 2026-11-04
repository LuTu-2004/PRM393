import 'package:flutter_test/flutter_test.dart';
import 'package:exe_matching/core/config/app_config.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/repositories/mock/mock_room_repository.dart';
import 'package:exe_matching/repositories/mock/mock_user_repository.dart';

void main() {
  group('Chặng 3: Unit Test Mock Repositories & Business Logic', () {
    late MockRoomRepository roomRepo;
    late MockUserRepository userRepo;

    setUp(() {
      roomRepo = MockRoomRepository();
      userRepo = MockUserRepository();
    });

    test('RoomRepo: Lấy danh sách phòng và lọc theo môn học (BR-14)', () async {
      final allRooms = await roomRepo.getRooms();
      expect(allRooms.length, equals(3));

      final exe101Rooms = await roomRepo.getRooms(subjectCode: 'EXE101');
      expect(exe101Rooms.length, equals(2));
      expect(exe101Rooms.every((r) => r.subjectCode == 'EXE101'), isTrue);

      final exe201Rooms = await roomRepo.getRooms(subjectCode: 'EXE201');
      expect(exe201Rooms.length, equals(1));
      expect(exe201Rooms.first.name, equals('EcoPackaging Solutions'));
    });

    test('RoomRepo: Tìm kiếm phòng theo từ khóa', () async {
      final searchResults = await roomRepo.getRooms(searchKeyword: 'fintech');
      expect(searchResults.length, equals(1));
      expect(searchResults.first.name, equals('Beta Startup'));
    });

    test('RoomRepo & BR-18, BR-19: Cảnh báo khi thêm thành viên vượt ngưỡng 50% cùng ngành', () async {
      // room_001 (Alpha Team) dang co 4 nguoi: 3 SE + 1 BA
      // Neu them 1 SE nua -> 4 SE tren 5 nguoi (80%) -> Phai canh bao
      final willExceed = await roomRepo.willExceedMajorDiversity('room_001', 'SE');
      expect(willExceed, isTrue);

      // Neu them 1 MKT -> 3 SE, 1 BA, 1 MKT -> 3/5 = 60% van la > 50%
      // Thu test voi room_002 (Beta Startup: 1 BA + 1 MKT, tong 2 nguoi)
      // Neu them 1 SE -> 1 SE / 3 nguoi = 33.3% <= 50% -> Khong vuot
      final willExceedInBeta = await roomRepo.willExceedMajorDiversity('room_002', 'SE');
      expect(willExceedInBeta, isFalse);
    });

    test('RoomRepo & BR-08: Thêm thành viên vào phòng và chặn khi đã đủ Max 5', () async {
      final newMember = RoomMemberModel(
        userId: 'uid_test_001',
        fullName: 'Test Member',
        major: 'GD',
        joinedAt: DateTime.now(),
      );

      // room_001 hien co 4 nguoi, them 1 nguoi nua thanh 5 nguoi (Max)
      final success = await roomRepo.joinRoom('room_001', newMember);
      expect(success, isTrue);

      final updatedRoom = await roomRepo.getRoomById('room_001');
      expect(updatedRoom?.memberCount, equals(5));
      expect(updatedRoom?.isFull, isTrue);

      // Thu them nguoi thu 6 -> Phai nem ngoai le vi pham BR-08
      final extraMember = RoomMemberModel(
        userId: 'uid_test_002',
        fullName: 'Extra Member',
        major: 'MKT',
        joinedAt: DateTime.now(),
      );

      expect(
        () async => await roomRepo.joinRoom('room_001', extraMember),
        throwsA(isA<Exception>()),
      );
    });

    test('UserRepo & BR-02: Đăng nhập bắt buộc email trường @fpt.edu.vn', () async {
      // Email dung mien truong -> Dang nhap thanh cong
      final user = await userRepo.loginWithGoogle('se001@fpt.edu.vn');
      expect(user.email, equals('se001@fpt.edu.vn'));
      expect(user.fullName, equals('Nguyễn Văn An'));

      // Email gmail ngoai -> Bi chan boi BR-02
      expect(
        () async => await userRepo.loginWithGoogle('hacker@gmail.com'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
