import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/room/bloc/room_bloc.dart';
import 'package:exe_matching/features/room/screens/create_room_screen.dart';
import 'package:exe_matching/repositories/interfaces/room_repository.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  Widget buildTestWidget(RoomBloc roomBloc) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: roomBloc,
                    child: const CreateRoomScreen(),
                  ),
                ),
              );
            },
            child: const Text('Open Create Room'),
          ),
        ),
      ),
    );
  }

  testWidgets('CreateRoomScreen: Hiển thị form và validate không được để trống (BR-09)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final roomBloc = RoomBloc(roomRepository: getIt<RoomRepository>());

    await tester.pumpWidget(buildTestWidget(roomBloc));
    await tester.tap(find.text('Open Create Room'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo Phòng Dự Án EXE'), findsOneWidget);
    expect(find.text('EXE101'), findsOneWidget);
    expect(find.text('EXE201'), findsOneWidget);

    // Bam nut tao phong khi chua nhap gi
    await tester.ensureVisible(find.text('Hoàn Tất Tạo Phòng'));
    await tester.tap(find.text('Hoàn Tất Tạo Phòng'));
    await tester.pumpAndSettle();

    // Phai bao loi validation
    expect(find.text('Vui lòng nhập tên phòng dự án'), findsOneWidget);
    expect(find.text('Vui lòng nhập mô tả ý tưởng dự án'), findsOneWidget);
  });

  testWidgets('CreateRoomScreen: Tạo phòng thành công và thêm vào danh sách (BR-09, BR-10)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final roomBloc = RoomBloc(roomRepository: getIt<RoomRepository>());

    await tester.pumpWidget(buildTestWidget(roomBloc));
    await tester.tap(find.text('Open Create Room'));
    await tester.pumpAndSettle();

    // Nhap ten phong hop le
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'GreenTech AI Logistics',
    );

    // Nhap mo ta du an hop le
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'Giai phap toi uu hoa van tai xanh cho cac doanh nghiep khoi nghiep logistics',
    );

    // Chon mon EXE201
    await tester.tap(find.text('EXE201'));
    await tester.pumpAndSettle();

    // Bam nut tao phong
    await tester.ensureVisible(find.text('Hoàn Tất Tạo Phòng'));
    await tester.tap(find.text('Hoàn Tất Tạo Phòng'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Kiem tra phong moi da duoc them vao RoomRepository
    List<RoomModel>? rooms;
    await tester.runAsync(() async {
      rooms = await getIt<RoomRepository>().getRooms();
    });
    expect(rooms, isNotNull);
    expect(rooms!.any((r) => r.name == 'GreenTech AI Logistics'), isTrue);
    final created = rooms!.firstWhere((r) => r.name == 'GreenTech AI Logistics');
    expect(created.subjectCode, equals('EXE201'));
    expect(created.leaderName, equals('Nguyễn Văn An'));
  });
}
