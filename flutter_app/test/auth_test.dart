import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/auth/bloc/auth_bloc.dart';
import 'package:exe_matching/features/auth/bloc/auth_event.dart';
import 'package:exe_matching/features/auth/bloc/auth_state.dart';
import 'package:exe_matching/features/auth/screens/login_screen.dart';
import 'package:exe_matching/repositories/interfaces/auth_repository.dart';
import 'package:exe_matching/repositories/mock/mock_auth_repository.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  group('Chặng 10: Unit Test Phân Hệ Xác Thực & Phân Quyền (BR-01, BR-02, BR-34, BR-37)', () {
    test('BR-02: Kiểm tra định dạng Email FPT (@fpt.edu.vn hoặc @fe.edu.vn)', () {
      expect(MockAuthRepository.isValidFptEmail('annvse180123@fpt.edu.vn'), isTrue);
      expect(MockAuthRepository.isValidFptEmail('tulpnse185102@fpt.edu.vn'), isTrue);
      expect(MockAuthRepository.isValidFptEmail('thaydieuphoi@fe.edu.vn'), isTrue);
      expect(MockAuthRepository.isValidFptEmail('sinhvien@gmail.com'), isFalse);
      expect(MockAuthRepository.isValidFptEmail('hacker@yahoo.com'), isFalse);
    });

    test('BR-02 & BR-04: Đăng nhập bằng Email FPT tùy chọn tự động trích xuất MSSV, Ngành và Khóa', () async {
      final repo = MockAuthRepository(startLoggedIn: false);
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(() => bloc.close());

      // Đăng nhập với email sinh viên cụ thể
      bloc.add(const SignInWithFptEmailEvent('tulpnse185102@fpt.edu.vn'));
      await bloc.stream.firstWhere((s) => s is AuthenticatedState);

      expect(bloc.state, isA<AuthenticatedState>());
      final authed = bloc.state as AuthenticatedState;
      expect(authed.user.email, equals('tulpnse185102@fpt.edu.vn'));
      expect(authed.user.studentCode, equals('SE185102')); // BR-04
      expect(authed.user.major, equals('SE')); // BR-04
      expect(authed.user.cohort, equals('K18')); // BR-04
      expect(authed.isStudent, isTrue);
    });

    test('BR-02: Chặn đăng nhập khi nhập email ngoài trường FPT', () async {
      final repo = MockAuthRepository(startLoggedIn: false);
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(() => bloc.close());

      // Cố tình đăng nhập bằng Gmail cá nhân
      bloc.add(const SignInWithFptEmailEvent('sinhvien@gmail.com'));
      await bloc.stream.firstWhere((s) => s is UnauthenticatedState && s.errorMessage != null);

      expect(bloc.state, isA<UnauthenticatedState>());
      final unauthed = bloc.state as UnauthenticatedState;
      expect(unauthed.errorMessage, contains('BR-02: Chỉ chấp nhận tài khoản email trường Đại học FPT'));
    });

    test('BR-34: Sinh viên chưa chấp nhận điều khoản thì yêu cầu hiển thị popup cam kết quy chế', () async {
      final unacceptedUser = UserModel(
        id: 'new_student_001',
        email: 'newbie@fpt.edu.vn',
        fullName: 'Sinh Viên Mới',
        role: 'student',
        studentCode: 'SE180999',
        major: 'SE',
        acceptedPolicyAt: null, // Chưa chấp nhận điều khoản
        createdAt: DateTime.now(),
      );

      final repo = MockAuthRepository(initialUser: unacceptedUser);
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(() => bloc.close());

      bloc.add(CheckAuthStatusEvent());
      await bloc.stream.firstWhere((s) => s is NeedsTermsAcceptanceState);

      expect(bloc.state, isA<NeedsTermsAcceptanceState>());
      final state = bloc.state as NeedsTermsAcceptanceState;
      expect(state.user.id, equals('new_student_001'));
      expect(state.user.acceptedPolicyAt, isNull);

      // Sinh viên xác nhận đồng ý điều khoản BR-34
      bloc.add(AcceptTermsEvent('new_student_001'));
      await bloc.stream.firstWhere((s) => s is AuthenticatedState);

      expect(bloc.state, isA<AuthenticatedState>());
      final authed = bloc.state as AuthenticatedState;
      expect(authed.user.acceptedPolicyAt, isNotNull);
    });

    test('Phân quyền Role: Sinh viên vs Giảng viên (Moderator)', () async {
      final repo = MockAuthRepository(startLoggedIn: false);
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(() => bloc.close());

      // 1. Đăng nhập vai trò Sinh viên
      bloc.add(const SignInDemoEvent(role: 'student'));
      await bloc.stream.firstWhere((s) => s is AuthenticatedState);

      final studentState = bloc.state as AuthenticatedState;
      expect(studentState.isStudent, isTrue);
      expect(studentState.isModerator, isFalse);
      expect(studentState.user.studentCode, equals('SE180123'));

      // 2. Đăng nhập vai trò Giảng viên (Moderator)
      bloc.add(const SignInDemoEvent(role: 'moderator'));
      await bloc.stream.firstWhere((s) => s is AuthenticatedState && s.isModerator);

      final modState = bloc.state as AuthenticatedState;
      expect(modState.isModerator, isTrue);
      expect(modState.isStudent, isFalse);
      expect(modState.user.studentCode, isNull); // Giảng viên không có MSSV
    });

    test('Đăng xuất (Sign Out): Xóa phiên làm việc và trở về trạng thái Unauthenticated', () async {
      final repo = MockAuthRepository(startLoggedIn: true);
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(() => bloc.close());

      bloc.add(CheckAuthStatusEvent());
      await bloc.stream.firstWhere((s) => s is AuthenticatedState);
      expect(bloc.state, isA<AuthenticatedState>());

      // Thực hiện đăng xuất
      bloc.add(SignOutEvent());
      await bloc.stream.firstWhere((s) => s is UnauthenticatedState);

      expect(bloc.state, isA<UnauthenticatedState>());
      final currentUser = await repo.getCurrentUser();
      expect(currentUser, isNull);
    });
  });

  group('Chặng 10: Widget Test Giao Diện Màn Hình Đăng Nhập (LoginScreen UI)', () {
    testWidgets('LoginScreen: Hiển thị đầy đủ thương hiệu FPT, khung nhập email FPT, nút Google và 2 nút Demo', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = MockAuthRepository(startLoggedIn: false);
      final bloc = AuthBloc(authRepository: repo);
      addTearDown(() => bloc.close());

      await tester.pumpWidget(
        BlocProvider<AuthBloc>.value(
          value: bloc,
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Kiểm tra tiêu đề thương hiệu FPT
      expect(find.textContaining('FPT UNIVERSITY'), findsOneWidget);
      expect(find.text('EXE Team Matching'), findsOneWidget);

      // Kiểm tra khung nhập email FPT (BR-02, BR-04)
      expect(find.text('Đăng Nhập Bằng Email FPT'), findsOneWidget);
      expect(find.text('Xác Thực Email & Đăng Nhập'), findsOneWidget);

      // Kiểm tra nút đăng nhập Google
      expect(find.text('Đăng nhập với Google (@fpt.edu.vn)'), findsOneWidget);

      // Kiểm tra 2 nút demo
      expect(find.textContaining('Đăng Nhập Demo: Sinh Viên'), findsOneWidget);
      expect(find.textContaining('Đăng Nhập Demo: Giảng Viên'), findsOneWidget);

      // Kiểm tra footer an toàn BR-37
      expect(find.textContaining('Xác thực an toàn'), findsOneWidget);
    });
  });
}
