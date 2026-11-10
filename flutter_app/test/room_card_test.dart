import 'package:exe_matching/models/room.dart';
import 'package:exe_matching/widgets/room_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Room room(int count) => Room(
    id: 'FA26EXE101-01',
    spaceId: 'FA26_EXE101',
    number: 1,
    maxGroupSize: 5,
    leaderId: 'u0',
    members: [
      for (var i = 0; i < count; i++)
        RoomMember(uid: 'u$i', fullName: 'Thanh vien $i', joinedAt: DateTime(2026, 1, i + 1)),
    ],
  );

  Future<void> pump(WidgetTester tester, Room r, {bool isMine = false}) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RoomCard(room: r, status: r.status, isMine: isMine, onTap: () {}),
      ),
    ),
  );

  testWidgets('hien so cho va trang thai Group', (tester) async {
    await pump(tester, room(3));
    expect(find.text('FA26EXE101-01'), findsOneWidget);
    expect(find.text('3/5 thành viên · còn 2 chỗ'), findsOneWidget);
    expect(find.text(RoomStatus.group.label), findsOneWidget);
    expect(find.text('Leader: Thanh vien 0'), findsOneWidget);
  });

  testWidgets('BR-13: Room da du thi an thong tin voi nguoi ngoai', (tester) async {
    await pump(tester, room(5));
    expect(find.text(RoomStatus.closed.label), findsOneWidget);
    expect(find.textContaining('Leader:'), findsNothing);
  });

  testWidgets('BR-13: thanh vien van thay thong tin nhom minh', (tester) async {
    await pump(tester, room(5), isMine: true);
    expect(find.text('Leader: Thanh vien 0'), findsOneWidget);
    expect(find.text('Nhóm của bạn'), findsOneWidget);
  });
}
