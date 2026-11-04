import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/profile/bloc/profile_bloc.dart';
import 'package:exe_matching/features/profile/screens/profile_screen.dart';
import 'package:exe_matching/repositories/interfaces/user_repository.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  group('Chặng 7: Unit Test Profile & Business Rules (BR-02, BR-04, BR-05)', () {
    test('BR-05: Cập nhật hồ sơ kỹ năng và định hướng thành công', () async {
      final userRepo = getIt<UserRepository>();
      final currentUser = await userRepo.getCurrentUser();
      expect(currentUser, isNotNull);

      // Cap nhat bo sung ky nang moi
      final updated = currentUser!.copyWith(
        skills: ['Mobile Development (Flutter)', 'Figma', 'Pitching', 'Agile Scrum'],
        orientation: 'EdTech',
      );

      final result = await userRepo.updateProfile(updated);
      expect(result.skills.contains('Pitching'), isTrue);
      expect(result.orientation, equals('EdTech'));
      expect(result.isProfileComplete, isTrue); // BR-05
    });

    test('BR-04: Tự động trích xuất Ngành và Khóa từ mã số sinh viên FPT', () {
      expect(UserModel.extractMajorFromCode('SE180123'), equals('SE'));
      expect(UserModel.extractMajorFromCode('MKT190456'), equals('MKT'));
      expect(UserModel.extractMajorFromCode('BA180789'), equals('BA'));

      expect(UserModel.extractCohortFromCode('SE180123'), equals('K18'));
      expect(UserModel.extractCohortFromCode('MKT190456'), equals('K19'));
    });
  });

  group('Chặng 7: Widget Test ProfileScreen UI', () {
    Widget buildTestWidget(ProfileBloc bloc) {
      return MaterialApp(
        home: BlocProvider.value(
          value: bloc,
          child: const ProfileScreen(),
        ),
      );
    }

    testWidgets('ProfileScreen: Hiển thị đầy đủ thông tin sinh viên, email FPT, banner BR-05 và nút lưu', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final profileBloc = ProfileBloc(userRepository: getIt<UserRepository>());

      await tester.pumpWidget(buildTestWidget(profileBloc));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Kiem tra App Bar
      expect(find.text('Hồ Sơ Sinh Viên'), findsOneWidget);

      // Kiem tra Header thong tin sinh vien (BR-02, BR-04)
      expect(find.text('Nguyễn Văn An'), findsWidgets);
      expect(find.text('se001@fpt.edu.vn'), findsOneWidget);
      expect(find.text('K18'), findsOneWidget);
      expect(find.textContaining('MSSV: SE180123'), findsOneWidget);

      // Kiem tra Banner hoan thien ho so (BR-05)
      expect(find.textContaining('Hồ sơ đã sẵn sàng ghép nhóm'), findsOneWidget);

      // Kiem tra Nut Luu Ho So
      expect(find.text('Lưu Hồ Sơ'), findsOneWidget);

      // Cuon xuong nut luu va bam luu
      await tester.ensureVisible(find.text('Lưu Hồ Sơ'));
      await tester.tap(find.text('Lưu Hồ Sơ'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Kiem tra SnackBar thong bao thanh cong
      expect(find.textContaining('Hồ sơ của bạn đã được cập nhật thành công!'), findsOneWidget);
    });
  });
}
