# 03 - Test Cases — EXE Team Matching

## Test Cases theo Business Rules

### Group 1: Xac thuc & Ho so

| ID | BR | Mo ta | Input | Expected |
|----|-----|-------|-------|----------|
| TC-01 | BR-02 | Dang nhap email sai ten mien | email: abc@gmail.com | Hien thong bao loi |
| TC-02 | BR-02 | Dang nhap email dung | email: abc@fpt.edu.vn | Chuyen man hinh chinh |
| TC-03 | BR-05 | Tham gia phong khi chua hoan thien ho so | Ho so chua co ky nang | Bi chan, hien nhac hoan thien ho so |
| TC-04 | BR-06 | Tham gia 2 phong cung 1 hoc ky | Da trong phong A, gui request vao phong B | Bi chan voi thong bao ro rang |

### Group 2: Quan ly Phong

| ID | BR | Mo ta | Input | Expected |
|----|-----|-------|-------|----------|
| TC-05 | BR-07 | Phong khong dong cu khi chua du 4 nguoi | 3 thanh vien, qua deadline | Phong tu dong dong (status = 'closed') |
| TC-06 | BR-08 | Khong the them nguoi khi phong da du 5 | 5 thanh vien, them 1 | Bi chan |
| TC-07 | BR-10 | Tim kiem chi hien thi phong Public | Phong Private khong co trong ket qua tim kiem | Pass |
| TC-08 | BR-13 | Leader kick member khi con 4 nguoi | Leader kick 1 trong 4 nguoi | Bi chan (khong du min) |

### Group 3: Ghep nhom

| ID | BR | Mo ta | Input | Expected |
|----|-----|-------|-------|----------|
| TC-09 | BR-17 | Gui request thu 4 bi chan | Da co 3 pending requests | Thong bao "Da dat toi da 3 yeu cau cho" |
| TC-10 | BR-18 | Them thanh vien cung nganh vuot 50% | Phong 2 SE/4 nguoi, them 1 SE | Hien canh bao BR-19, hoi xac nhan truoc khi them |
| TC-11 | BR-19 | Canh bao hien khi ty le > 50% | Phong 3 SE / 5 nguoi (60%) | Banner canh bao hien ro |
| TC-12 | BR-20 | Request tu het han sau 48h | Request tao luc T, xem luc T+49h | Status = 'expired' |

### Group 4: Bo Phieu

| ID | BR | Mo ta | Input | Expected |
|----|-----|-------|-------|----------|
| TC-13 | BR-22 | Het han bo phieu sau 24h | Session bat dau T, xem T+25h | Session tu dong dong |
| TC-14 | BR-23 | Khong the bau cho chinh minh | Chon ten chinh minh | Bi chan |
| TC-15 | BR-27 | Toan ven phieu: 4 nguoi bo phieu = 4 phieu | 4 nguoi bo phieu | Tong = 4, hop le |
| TC-16 | BR-24 | Ket qua an trong khi session con active | Xem ket qua khi session = 'active' | An ket qua |

## Test Widget (Flutter)

```dart
// Vi du test man hinh RoomList
testWidgets('Hien thi canh bao BR-19 khi ty le nganh > 50%', (tester) async {
  // Arrange: phong co 3 SE trong 4 nguoi
  final mockRoom = MockRoom(majorRatio: {'SE': 0.75});
  
  // Act
  await tester.pumpWidget(RoomDetailScreen(room: mockRoom));
  
  // Assert
  expect(find.byKey(Key('major_warning_banner')), findsOneWidget);
  expect(find.text('Canh bao: Ty le chuyen nganh SE vuot 50%'), findsOneWidget);
});
```
