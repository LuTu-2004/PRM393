# Nhật ký dùng AI khi lập trình

Công cụ: **Claude Code** (Claude Opus 5.5). Prompt ghi nguyên văn, không dấu như lúc gõ.
Một prompt có thể tạo ra nhiều mục vì AI làm nhiều phần trong cùng phiên.

> **Bản nháp do AI soạn từ phiên làm việc.** Bạn đọc và sửa lại cho đúng cách bạn đã kiểm tra và
> quyết định, đồng thời thêm mọi công cụ AI khác nhóm đã dùng. Đề yêu cầu giải thích được mọi file.

## 1. Rà soát dự án
- **Prompt:** "gio coi folder prm du an dang thieu hay loi o dau"
- **Kết quả:** danh sách lỗi: đăng nhập không cần mật khẩu đúng, thiếu `firestore.rules`, PDF giả, Remote Config chỉ hiển thị, không có listener.
- **Kiểm tra:** chạy `flutter analyze`, `flutter test`, đọc code.
- **Quyết định:** chấp nhận.

## 2. Đối chiếu nghiệp vụ
- **Prompt:** "khong ban doi chieu voi file docx con 37 br tui cam giac no hoi sai nen ban so voi file docx"
- **Kết quả:** bảng 37 BR, phần lớn chưa có hoặc làm ngược.
- **Kiểm tra:** đọc code theo từng BR. Người dùng sửa BR-01: "khong co danh sach nen chi can kiem tra duoi la duoc".
- **Quyết định:** chỉnh sửa BR-01 theo quyết định của nhóm.

## 3. Nghiệp vụ Room, Apply, Leader (`group_service.dart`, `room_rules.dart`)
- **Prompt:** "cua lam theo file docx"
- **Kết quả:** viết lại nghiệp vụ bằng Firestore transaction.
- **Kiểm tra:** 26 test với `fake_cloud_firestore`.
- **Quyết định:** chỉnh sửa. Phát hiện lỗi ném exception trong transaction làm mất lệnh ghi Cancel; lỗi test thiếu `await` làm sai kết quả. Đã sửa cả hai.

## 4. Kiến trúc MVVM và theme (`viewmodels/`, `theme/`)
- **Prompt:** câu trả lời khi được hỏi kiến trúc: "MVVM + Provider (Recommended)", "Chỉ làm sinh viên (Recommended)"
- **Kết quả:** bỏ BLoC, GetIt, mock; Service là lớp duy nhất gọi Firebase; token màu và khoảng cách.
- **Kiểm tra:** `flutter analyze` sạch, build APK, chạy trên máy ảo.
- **Quyết định:** chấp nhận.

## 5. Firestore Security Rules (`firebase/firestore.rules`)
- **Prompt:** "cua lam theo file docx"
- **Kết quả:** rules theo email trường, chủ sở hữu, thành viên Room.
- **Kiểm tra:** đọc lại từng luồng ghi. **Chưa kiểm thử riêng rules**, cần xác nhận sau khi publish.
- **Quyết định:** chấp nhận có giới hạn: kiểm tra chi tiết vẫn ở client. `isDemoAdmin()` phải xóa trước khi nộp.

## 6. Thiết lập Android và Firebase
- **Prompt:** "da dang nhap bang gg duoc roi dung khong"
- **Kết quả:** phát hiện `google-services.json` không có `oauth_client`, hướng dẫn thêm SHA-1.
- **Kiểm tra:** so SHA-1 với keystore; đăng nhập thật trên máy ảo thành công.
- **Quyết định:** chấp nhận.

## 8. FCM token và server
- **Prompt:** "gio co nhung cong viec gi ban co the lam duoc ma khong nho tui gio tui co viec phai di"
- **Kết quả:** lưu token, lịch sử thông báo bền, banner khi bị từ chối quyền, `server/send_fcm.py`.
- **Kiểm tra:** 58 test, chạy app trên máy ảo. **Script server chưa chạy với service account thật.**
- **Quyết định:** chỉnh sửa. AI giữ `getToken` thay vì API mới được SDK đề xuất, vì API mới trả về FID. Bạn cần tự đọc và xác nhận.

## 9. Web giảng viên
- **Prompt:** "lam phan moderator luon"
- **Kết quả:** web Flutter: cấu hình môn, tạo Room, phân phối sinh viên lẻ, chốt sổ, chuyển nhóm, sự cố; `DistributionPlanner`, `AdminService`.
- **Kiểm tra:** 16 test mới, build web thành công. **Chưa đăng nhập chạy thử trên trình duyệt với Firestore thật.**
- **Quyết định:** chỉnh sửa. Bạn cần xem lại thuật toán chấm điểm trong `distribution_planner.dart` và giải thích được các hệ số.

## 7. Xuất PDF và dữ liệu demo (`report_pdf_builder.dart`, `file_storage_service.dart`)
- **Prompt:** "con chuc nang nao thi ban lam het di roi tui test mot lan"
- **Kết quả:** PDF tiếng Việt, upload Cloudinary, metadata, CRUD đơn Apply, nút demo.
- **Kiểm tra:** 54 test. **Chưa upload thật lên Cloudinary.**
- **Quyết định:** chỉnh sửa. Chạy thật phát hiện hộp xin quyền chặn khởi động app; đã sửa.
