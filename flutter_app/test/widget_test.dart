import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exe_matching/main.dart';
import 'package:exe_matching/core/di/service_locator.dart';
import 'package:exe_matching/core/models/models.dart';
import 'package:exe_matching/features/room/widgets/major_diversity_banner.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  testWidgets('Chặng 4 UI: ExeMatchingApp khởi động và hiển thị Shell với BottomNavigation', (WidgetTester tester) async {
    // Build app
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(const ExeMatchingApp());
    // Cho phep animation va mock delay chay xong
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Kiem tra App Bar
    expect(find.text('EXE Team Matching'), findsOneWidget);

    // Kiem tra BottomNavigationBar co du 4 tab
    expect(find.text('Khám phá'), findsOneWidget);
    expect(find.text('Matching'), findsOneWidget);
    expect(find.text('Lời mời'), findsOneWidget);
    expect(find.text('Hồ sơ'), findsOneWidget);

    // Kiem tra cac phong mock data xuat hien tren man hinh
    expect(find.text('Nhóm 1 (Phòng 01)'), findsOneWidget);
    expect(find.text('Nhóm 2 (Phòng 02)'), findsOneWidget);
    expect(find.text('Nhóm 3 (Phòng 03)'), findsOneWidget);

    // Kiem tra canh bao BR-19 xuat hien tren Alpha Team
    expect(find.textContaining('Ngành SE chiếm 75%'), findsOneWidget);
  });

  testWidgets('Chặng 4 Widget: MajorDiversityBanner chỉ hiển thị khi tỷ lệ > 50%', (WidgetTester tester) async {
    final now = DateTime.now();

    // Phong khong vi pham (50% SE <= 50%)
    final roomOk = RoomModel(
      id: 'r_ok',
      name: 'Team OK',
      description: 'Desc',
      subjectCode: 'EXE101',
      semesterId: 'FALL2026',
      leaderId: 'u1',
      leaderName: 'Leader',
      members: [
        RoomMemberModel(userId: 'u1', fullName: 'SE 1', major: 'SE', joinedAt: now),
        RoomMemberModel(userId: 'u2', fullName: 'BA 1', major: 'BA', joinedAt: now),
      ],
      createdAt: now,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MajorDiversityBanner(room: roomOk)),
    ));
    expect(find.byType(MajorDiversityBanner), findsOneWidget);
    expect(find.textContaining('Cảnh báo'), findsNothing);

    // Phong vi pham (75% SE > 50%)
    final roomViolated = RoomModel(
      id: 'r_violated',
      name: 'Team Violated',
      description: 'Desc',
      subjectCode: 'EXE101',
      semesterId: 'FALL2026',
      leaderId: 'u1',
      leaderName: 'Leader',
      members: [
        RoomMemberModel(userId: 'u1', fullName: 'SE 1', major: 'SE', joinedAt: now),
        RoomMemberModel(userId: 'u2', fullName: 'SE 2', major: 'SE', joinedAt: now),
        RoomMemberModel(userId: 'u3', fullName: 'SE 3', major: 'SE', joinedAt: now),
        RoomMemberModel(userId: 'u4', fullName: 'BA 1', major: 'BA', joinedAt: now),
      ],
      createdAt: now,
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MajorDiversityBanner(room: roomViolated)),
    ));
    expect(find.textContaining('Cảnh báo Đa dạng Chuyên ngành'), findsOneWidget);
  });
}
