# Ca kiểm thử lỗi theo từng dịch vụ

Preparation Guide yêu cầu mỗi dịch vụ có ca kiểm thử lỗi. **Cột Kết quả chỉ điền sau khi chạy thật trên thiết bị, kèm ảnh chụp.**

| # | Dịch vụ | Cách tạo lỗi | Kết quả mong đợi | Kết quả |
|---|---|---|---|---|
| 1 | Auth | Bấm đăng nhập rồi hủy ở bước chọn tài khoản | Màn Login báo "Bạn đã hủy đăng nhập Google." | Chưa chạy |
| 2 | Auth | Đăng nhập bằng Gmail ngoài trường | Bị đăng xuất, báo chỉ chấp nhận email trường | Chưa chạy |
| 3 | Auth | Bật chế độ máy bay rồi đăng nhập | Báo không có kết nối mạng | Chưa chạy |
| 4 | Firestore | Hai tài khoản cùng vào chỗ cuối của Room | Một người vào được; người kia báo Room đã đổi trạng thái | Chưa chạy |
| 5 | Firestore | Sinh viên A sửa dữ liệu `users` của B từ công cụ ngoài | Rules từ chối (`permission-denied`) | Chưa chạy |
| 6 | Firestore | Gửi đơn thứ 4 khi đã có 3 đơn chờ | Báo vượt giới hạn; rút một đơn thì gửi lại được | Chưa chạy |
| 7 | Cloudinary | Chạy app không có `cloudinary.json` rồi xuất PDF | Báo chưa cấu hình, app không crash | Chưa chạy |
| 8 | Cloudinary | Bật chế độ máy bay rồi xuất PDF | Báo không có mạng, không lưu metadata | Chưa chạy |
| 9 | FCM | Từ chối quyền thông báo trên Android 13+ | Trung tâm thông báo hiện banner hướng dẫn bật lại | Chưa chạy |
| 10 | FCM | Gửi tới token đã hết hạn bằng `send_fcm.py` | Script báo token hết hiệu lực và xóa token | Chưa chạy |
| 11 | Analytics | Bật chế độ máy bay, thao tác, rồi có mạng lại | App không lỗi; sự kiện đến DebugView sau khi có mạng | Chưa chạy |
| 12 | Crashlytics | Bấm "Ghi lỗi có xử lý" | App không dừng; lỗi non-fatal lên Console | Chưa chạy |
| 13 | Crashlytics | Bấm "Gây crash thử nghiệm", mở lại app | Có báo cáo fatal kèm user ID và khóa tùy chỉnh | Chưa chạy |
| 14 | Remote Config | Xóa dữ liệu app, tắt mạng, mở app | Dùng giá trị mặc định (50 Room, không banner) | Chưa chạy |
