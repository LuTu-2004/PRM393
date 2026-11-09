# AI_GUIDELINES.md — Đọc trước khi sửa code

> File này dành cho mọi AI coding assistant (ChatGPT, Claude, Gemini, Copilot, Cursor...) và cho thành viên nhóm.

## 1. Nguồn nghiệp vụ

**Nguồn chuẩn duy nhất:** `EXE Team Matching - Tong hop nghiep vu.docx` (bản 30/10/2026, 37 BR, mỗi BR ghi rõ nguồn: thầy đã nói / nhóm đã chốt / nhóm đề xuất / chờ hỏi thầy).

Bộ 37 BR cũ từng nằm trong file này (sinh viên tự tạo phòng, luật 50% cùng ngành, vote 75% chốt nhóm, request hết hạn 48h, Leader kick, mời theo MSSV) **đã bỏ**. Không thêm lại các chức năng đó.

Quyết định đã chốt thêm:
- Không có danh sách FAP, nên BR-01 chỉ kiểm tra đuôi email: `@fpt.edu.vn` là sinh viên, `@fe.edu.vn` là giảng viên.
- App Android **chỉ dành cho sinh viên**; giảng viên đăng nhập app chỉ thấy màn thông báo. Giảng viên dùng web Flutter (`lib/main_admin.dart`, `AdminService`, `AdminViewModel`, `screens/admin/`): cấu hình môn, tạo Room, phân phối sinh viên lẻ, chốt sổ, duyệt chuyển nhóm, xem sự cố.
- Không có FAP nên sinh viên tự chọn môn (EXE101/EXE201) một lần trong hồ sơ.
- Nếu môn chưa được giảng viên tạo, app tự tạo Space mặc định và các Room theo BR-09 để demo (`GroupService.ensureSpace`).
- Crashlytics không có API đọc trực tiếp cho web, nên app ghi thêm bản tóm tắt vào `crash_logs`; web đọc từ đó.

## 2. Tóm tắt nghiệp vụ (theo docx)

| Khái niệm | Ý nghĩa |
|---|---|
| Space | Một môn trong một kỳ, ví dụ `FA26_EXE101`. Lưu cấu hình giảng viên: sĩ số tối đa, hệ số dự phòng, giới hạn Apply, hạn đăng ký, đã chốt sổ chưa (BR-08) |
| Room | Hệ thống tự tạo, số Room = làm tròn lên (sinh viên ÷ sĩ số × hệ số) (BR-09). Mã `FA26EXE101-01` (BR-11). Sinh viên không tự tạo nhóm (BR-12) |
| Ngưỡng | Hơn 50% sĩ số (5 → 3, 6 → 4) (BR-16) |
| Trạng thái Room | `empty` → `open` (dưới ngưỡng, vào thẳng) → `group` (đạt ngưỡng, chỉ Apply) → `closed` (đủ người hoặc Leader đóng tuyển) → `finalized` (chốt sổ) |
| Leader | Người vào Room trống đầu tiên (BR-15); chuyển quyền (BR-18); bầu Leader cần hơn 50%, hạn 24h (BR-19); Leader rời thì người vào sớm nhất lên thay (BR-20) |
| Apply | Chỉ người chưa có nhóm (BR-24), không vượt giới hạn (BR-22); Leader mở vote, mỗi thành viên một phiếu, Leader quyết định (BR-25) |
| Tự động | Vào được một nhóm thì đơn khác → Cancel (BR-26); nhóm đủ hoặc đóng tuyển thì đơn chờ → Reject (BR-28); Group rớt dưới ngưỡng thì quay về Room (BR-17) |
| Chốt sổ | Khóa cứng, không tự vào/rời (BR-33); sinh viên gửi yêu cầu chuyển nhóm cho giảng viên (BR-36, BR-37) |

Các luật thuần nằm trong `lib/domain/room_rules.dart`. Luật cần dữ liệu nằm trong `lib/services/group_service.dart` (chạy trong Firestore transaction).

## 3. Kiến trúc: MVVM + Provider (bắt buộc theo đề Lab 3)

```
flutter_app/lib/
  main.dart              Khởi tạo Firebase, Provider, AuthGate
  config/                Hằng số, tên collection
  theme/                 Token màu, khoảng cách, bo góc, ThemeData
  models/                Class Dart thuần + toMap/fromMap Firestore
  domain/                Luật nghiệp vụ thuần (không Firebase), dễ unit test
  services/              LỚP DUY NHẤT gọi Firebase (Auth, Firestore, Analytics, Crashlytics, Remote Config, FCM)
  viewmodels/            ChangeNotifier: giữ state, gọi service, trả ActionResult cho View
  screens/               Màn hình: chỉ render state và chuyển thao tác cho ViewModel
  widgets/               Component dùng chung (StatusChip, RoomCard, LoadingView/EmptyView/ErrorView...)
```

Quy tắc:
- Screen/Widget **không** import `cloud_firestore`, `firebase_*` và không gọi service trực tiếp. Mọi thao tác đi qua ViewModel.
- ViewModel không import `package:flutter/material.dart`.
- Dùng `provider` (`ChangeNotifierProvider`, `context.watch/read`). Không dùng BLoC, GetIt.
- Màu, khoảng cách, bo góc lấy từ `theme/` (`AppColors`, `AppSpacing`, `AppRadius`). Không hard-code `Color(0x...)` trong screen.
- Không có chế độ mock data trong app. Test dùng `fake_cloud_firestore` và các factory `.disabled()` của service.
- Lỗi nghiệp vụ ném `BusinessException(message tiếng Việt)`. ViewModel bắt lỗi qua `runAction` và trả `ActionResult`.
- Đăng nhập chỉ bằng Google (không mật khẩu, không nút demo).

## 4. Firestore

| Collection | Nội dung |
|---|---|
| `users/{uid}` | Hồ sơ, 5 kỹ năng 0–100, cam kết, đồng ý điều khoản |
| `spaces/{term_course}` | Cấu hình môn trong kỳ |
| `rooms/{roomCode}` | Thành viên, `memberIds`, `leaderId`, `recruitmentClosed`, `status` |
| `rooms/{roomCode}/elections/{id}` | Cuộc bầu Leader |
| `memberships/{spaceId_uid}` | Sinh viên đang ở Room nào (khóa BR-21) |
| `applications/{id}` | Đơn Apply, votes |
| `transfer_requests/{id}` | Yêu cầu chuyển nhóm |
| `users/{uid}/reports/{id}` | Metadata báo cáo PDF (file nằm trên Cloudinary) |

FCM token nằm ở `users/{uid}/fcm_tokens/{token}`; phía server là `server/send_fcm.py`, khóa service account không bao giờ commit. Dự án cố ý dùng `getToken` đã deprecated vì API `register()` mới trả về FID, không phải registration token.

Đơn Apply là main entity cho yêu cầu CRUD của Lab 3: tạo đơn, xem danh sách và chi tiết, sửa lời nhắn, rút đơn. Lời nhắn không có trong docx, chỉ thêm để đáp ứng đề.

Cloudinary chạy với `flutter run --dart-define-from-file=cloudinary.json` (mẫu: `cloudinary.example.json`, không commit file thật).

Nút "Tạo Room và đơn Apply demo" chỉ có ở bản debug. Rules có hàm `isDemoAdmin()` ghi cứng một email để nút này ghi được dữ liệu giả: **xóa hàm này trước khi nộp bài** nếu không còn cần demo.

Security Rules: `flutter_app/firebase/firestore.rules` (deploy bằng `firebase deploy --only firestore:rules` trong thư mục `flutter_app`).

## 5. Kiểm tra trước khi commit

```
cd flutter_app
dart format --line-length 100 lib test
flutter analyze      # phải "No issues found!"
flutter test
```

## 6. Prompt mẫu

```
Tôi đang làm dự án EXE Team Matching (Flutter + Firebase, MVVM + Provider).
Hãy đọc AI_GUIDELINES.md trước. Nghiệp vụ theo file docx, không theo bộ BR cũ.
Task: [mô tả]
BR liên quan: [BR-xx theo docx]
Yêu cầu: logic Firebase đặt trong services/, state trong viewmodels/, screen không gọi Firebase.
```
