# EXE Team Matching — PRM393 Lab 3

Ứng dụng Flutter giúp sinh viên FPT ghép nhóm môn EXE101/EXE201 theo từng kỳ. Nghiệp vụ theo file
`EXE Team Matching - Tong hop nghiep vu.docx`; quy ước code trong [`AI_GUIDELINES.md`](AI_GUIDELINES.md).

- **Figma Lab 2:** không có, theo nhóm thầy đã yêu cầu bỏ Lab 2 (cần xác nhận với thầy).
- **Kiến trúc:** MVVM + Provider. Code trong `flutter_app/lib`.
- **Backend:** Firebase Auth, Firestore, FCM, Remote Config, Crashlytics, Analytics; PDF lưu trên Cloudinary.
- **Phạm vi:** app Android cho sinh viên; web cho giảng viên (`lib/main_admin.dart`), dùng chung Firestore.

## Chạy app
```
cd flutter_app
flutter pub get
copy cloudinary.example.json cloudinary.json   (rồi điền cloud name và preset)
flutter run --dart-define-from-file=cloudinary.json
```
Mỗi máy phải thêm SHA-1 debug vào Firebase project và tải lại `google-services.json`.

## Chạy web giảng viên
```
cd flutter_app
flutter run -d chrome -t lib/main_admin.dart
```
Đăng nhập bằng email `@fe.edu.vn`. Nhóm không có email này thì chạy thêm `--dart-define=DEMO_ADMIN_EMAIL=<email demo>`, email phải khớp `isDemoAdmin()` trong Rules.

Đưa lên mạng: `flutter build web -t lib/main_admin.dart`, rồi `firebase deploy --only hosting`.

## Thiết lập Firebase và lưu trữ
1. Bật đăng nhập Google, thêm SHA-1.
2. Publish `flutter_app/firebase/firestore.rules`.
3. Remote Config: `room_list_limit` (Number), `announcement_banner` (String).
4. Cloudinary: unsigned preset chỉ cho `pdf`, giới hạn dung lượng; bật phân phối PDF. Không đưa API secret vào app.

## Gửi thông báo FCM
Dùng Firebase Console, hoặc script server (cần service account, không commit):
```
pip install -r server/requirements.txt
set GOOGLE_APPLICATION_CREDENTIALS=C:\duong\dan\service-account.json
python server/send_fcm.py --uid <uid> --title "Nhắc hạn" --body "Còn 3 ngày" --room-id FA26EXE101-01
```

Để tự gửi khi có đơn Apply mới, mở vote, có kết quả vote hoặc kết quả chuyển nhóm, chạy một bản duy nhất trong lúc demo. Thay đổi xảy ra khi script đang tắt sẽ không được gửi.
```
python server/notify_events.py
```

## Kiểm tra
```
cd flutter_app
flutter analyze
flutter test
```

## Tài liệu
| File | Nội dung |
|---|---|
| `docs/architecture.md` | Kiến trúc và phụ thuộc |
| `docs/firebase-error-cases.md` | Ca lỗi từng dịch vụ |
| `docs/design-change-log.md` | Thay đổi thiết kế |
| `docs/analytics-plan.md` | Kế hoạch sự kiện |
| `docs/implementation-ai-log.md` | Nhật ký dùng AI |
| `docs/test-report.md`, `mobai_tests/` | Kiểm thử MobAI |
| `docs/code-review.md` | AI code review |
