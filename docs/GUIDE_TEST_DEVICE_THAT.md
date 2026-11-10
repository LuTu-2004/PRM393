# 📱 TÀI LIỆU HƯỚNG DẪN KIỂM THỬ TRÊN THIẾT BỊ ANDROID THẬT
**Hệ thống:** EXE Team Matching System (PRM393 - Lab 3)  
**Nhánh kiểm thử:** `feature/docx-business-mvvm`  
**Dành cho:** Thành viên phụ trách thiết bị Android thật và demo với Giảng viên  

---

## 📌 MỤC TIÊU KIỂM THỬ
Kiểm tra toàn diện 6 tính năng cốt lõi trên **điện thoại Android thật** theo yêu cầu chấm bài thực hành của Giảng viên:
1. Chạy ứng dụng trực tiếp trên điện thoại Android thật qua cáp USB.
2. Kiểm tra lưu trữ FCM Token và nhận thông báo đẩy thời gian thực từ Server Python.
3. Kích hoạt và theo dõi lỗi trên Firebase Crashlytics (Fatal Crash & Non-fatal Error).
4. Kiểm tra luồng bỏ phiếu kín duyệt thành viên vào nhóm (Quy tắc BR-25: cần $> 50\%$ thành viên đồng ý).
5. Xuất và tải lên biên bản báo cáo đề án dạng PDF (Cloudinary).
6. Đồng bộ trạng thái với trang Web Giảng viên (Web Moderator & Import danh sách FAP).

---

## ⚙️ BƯỚC 1: LẤY CODE MỚI NHẤT VÀ CHUẨN BỊ MÁY

### 1. Lấy mã nguồn mới nhất từ GitHub
Mở Terminal trên máy tính của bạn và chạy:
```bash
git fetch origin
git checkout feature/docx-business-mvvm
git pull origin feature/docx-business-mvvm
```

### 2. Cấu hình điện thoại Android
1. Mở **Cài đặt** trên điện thoại > **Thông tin điện thoại** > Nhấn **7 lần** vào mục **Số hiệu bản dựng (Build number)** để kích hoạt quyền Nhà phát triển.
2. Quay lại **Cài đặt** > **Tùy chọn nhà phát triển** > Gạt BẬT **Gỡ lỗi qua USB (USB Debugging)**.
3. Cắm cáp USB nối điện thoại vào máy tính.
4. Trên màn hình điện thoại sẽ hiện bảng hỏi *"Cho phép gỡ lỗi USB từ máy tính này?"* > Chọn **Luôn cho phép**.
5. Mở terminal gõ lệnh kiểm tra:
   ```bash
   flutter devices
   ```
   *(Thấy tên điện thoại Android của bạn xuất hiện trong danh sách là đã kết nối thành công)*.

---

## 🚀 BƯỚC 2: KHỞI CHẠY ỨNG DỤNG LÊN ĐIỆN THOẠI

Di chuyển vào thư mục `flutter_app` và chạy lệnh:
```bash
cd flutter_app
flutter pub get
flutter run
```
*(Nếu có kiểm thử tính năng Upload PDF Cloudinary, chạy kèm file cấu hình: `flutter run --dart-define-from-file=cloudinary.json`)*.

---

## 📋 CHECKLIST 6 HẠNG MỤC KIỂM THỬ TRÊN MÁY THẬT

### 🧪 TEST 1: Đăng nhập Google & Kiểm tra lưu FCM Token
- **Mục tiêu:** Sinh viên đăng nhập vào hệ thống và ứng dụng tự động lấy FCM token của thiết bị lưu lên Firestore.
- **Thao tác:**
  1. Trên điện thoại, mở ứng dụng vừa cài.
  2. Bấm nút **Đăng nhập bằng Google** > Chọn tài khoản email trường FPT (`...se...@fpt.edu.vn`).
  3. Hoàn tất khai báo hồ sơ (chọn môn `EXE101` hoặc `EXE201`, chọn kỹ năng, tick cam kết).
- **Kết quả kỳ vọng (PASS):**
  - Vào được màn hình chính ứng dụng mượt mà.
  - Mở [Firebase Console](https://console.firebase.google.com/) > **Firestore Database** > `users` > `<uid_cua_ban>` > sub-collection `fcm_tokens`: **Có 1 document token thiết bị được ghi nhận với platform `'android'`**.

---

### 🧪 TEST 2: Nhận thông báo đẩy FCM từ Server Python
- **Mục tiêu:** Điện thoại nhận thông báo đẩy thời gian thực từ server thông qua Firebase Admin SDK (không hardcode key trong app).
- **Thao tác:**
  1. Trên máy tính, lấy UID tài khoản của bạn (xem trong Firebase Auth hoặc trên Firestore).
  2. Đặt biến môi trường trỏ tới file service account Firebase:
     ```powershell
     # Trên Windows PowerShell:
     $env:GOOGLE_APPLICATION_CREDENTIALS="C:\duong\dan\file-service-account.json"
     ```
  3. Chạy script bắn thông báo trực tiếp xuống điện thoại:
     ```powershell
     cd server
     python send_fcm.py --uid <UID_CUA_BAN> --title "Nhắc hạn ghép nhóm" --body "Hạn chót ghép nhóm còn 3 ngày, hãy hoàn tất hồ sơ!"
     ```
  4. Thử ở 3 trạng thái:
     - **Foreground:** Đang mở app trên màn hình (hiện banner/chuông thông báo).
     - **Background:** Bấm nút Home để app chạy ngầm (thanh thông báo Android nảy pop-up).
     - **Terminated:** Vuốt tắt hẳn app (thanh thông báo Android vẫn nhận và bấm vào sẽ mở đúng app).
  5. Thử chạy listener tự động lắng nghe Firestore:
     ```powershell
     python notify_events.py
     ```
     *(Khi có sinh viên gửi đơn xin vào nhóm hoặc Leader mở vote, script sẽ tự bắt sự kiện và bắn thông báo tới các thành viên)*.
- **Kết quả kỳ vọng (PASS):** Điện thoại nảy thông báo chuông/rung và nội dung hiển thị chính xác.

---

### 🧪 TEST 3: Kiểm thử Firebase Crashlytics (Demo sự cố cho Giảng viên)
- **Mục tiêu:** Chứng minh ứng dụng đã tích hợp Crashlytics bắt lỗi tự động cả lỗi có chủ đích (non-fatal) lẫn văng ứng dụng (fatal crash).
- **Thao tác:**
  1. Mở app trên điện thoại > Chuyển sang tab **Hồ sơ (Profile)**.
  2. Cuộn xuống khu vực **Kiểm tra Crashlytics (demo)**:
     - **Test 3.1 (Lỗi đã xử lý - Handled Error):** Bấm nút **Ghi lỗi thử nghiệm** -> App hiện SnackBar *"Đã gửi lỗi thử nghiệm lên Crashlytics"*.
     - **Test 3.2 (Gây crash thật - Fatal Crash):** Bấm nút **Gây crash thử nghiệm** > Popup xác nhận hiện ra > Bấm **Crash ngay**.
  3. Ứng dụng trên điện thoại sẽ lập tức bị đóng (văng ra ngoài màn hình chính).
  4. **Mở lại ứng dụng** (bước này quan trọng vì Crashlytics SDK sẽ đóng gói báo cáo crash của lần chạy trước và gửi lên server khi app khởi động lại).
- **Kết quả kỳ vọng (PASS):**
  - Vào [Firebase Console](https://console.firebase.google.com/) > **Crashlytics** (chờ 5-10 phút để Firebase Dashboard tổng hợp sự cố).
  - Hoặc mở trang Web Giảng viên (Web Moderator) > mục **Sự cố hệ thống**: Thấy bản ghi crash vừa kích hoạt hiển thị với UID sinh viên.

---

### 🧪 TEST 4: Luồng Bỏ phiếu kín duyệt thành viên vào nhóm (Quy tắc BR-25)
- **Quy tắc nghiệp vụ (BR-25):** 
  - Khi phòng đã đủ ngưỡng thành Group (từ 3 người trở lên), ứng viên mới nộp đơn phải qua bỏ phiếu kín.
  - Đơn được duyệt tự động khi **có hơn 50% thành viên trong nhóm đồng ý** ($yes \times 2 > memberCount$).
- **Kịch bản test (Cần 2-3 tài khoản sinh viên):**
  1. Phòng A đang có **3 thành viên** (Ngưỡng đậu: $3 / 2 + 1 = 2$ phiếu đồng ý).
  2. Tài khoản thứ 4 (Ứng viên) tìm phòng A và bấm **Xin gia nhập (Apply)** > Điền lời nhắn > Gửi đơn.
  3. **Trưởng nhóm (Leader)** mở chi tiết phòng A > mục **Đơn xin gia nhập** > Bấm **Mở vote** cho ứng viên.
  4. Các thành viên trong nhóm vào xem đơn và tiến hành bỏ phiếu:
     - Thành viên 1 bấm: **Đồng ý**. (Lúc này: 1/3 phiếu -> Đơn vẫn đang chờ).
     - Thành viên 2 bấm: **Đồng ý**. (Lúc này: 2/3 phiếu -> Vượt quá 50%!).
- **Kết quả kỳ vọng (PASS):**
  - Hệ thống tự động chuyển trạng thái đơn sang **`accepted`**.
  - Ứng viên thứ 4 tự động trở thành **Thành viên chính thức** trong danh sách thành viên của phòng A mà không cần thao tác thủ công nào khác.
  - *(Trường hợp ngược lại: Nếu số phiếu Từ chối khiến không thể đạt quá 50%, đơn tự động chuyển sang `rejected`)*.

---

### 🧪 TEST 5: Xuất & Tải lên báo cáo đề án PDF (Cloudinary)
- **Chuẩn bị:** Tạo file `flutter_app/cloudinary.json` với Cloud name và Upload preset (loại Unsigned) từ tài khoản Cloudinary.
- **Thao tác:**
  1. Vào chi tiết một phòng đã chốt nhóm hoặc mục **Báo cáo đề án** trong tab Profile.
  2. Bấm nút **Xuất & Tải lên biên bản PDF**.
  3. App sẽ hiển thị thanh tiến độ đang render và tải file lên mây.
- **Kết quả kỳ vọng (PASS):**
  - App tải lên thành công và trả về đường link HTTPS trực tiếp tới file PDF trên Cloudinary.
  - Bấm vào link xem được nội dung biên bản đề án đầy đủ chữ ký và danh sách thành viên.

---

### 🧪 TEST 6: Web Quản trị của Giảng viên & Import danh sách FAP (CSV/Excel)
- **Thao tác:**
  1. Chạy bản Web trên máy tính:
     ```powershell
     cd flutter_app
     flutter run -d chrome --web-port 5050 -t lib/main_admin.dart --dart-define=DEMO_ADMIN_EMAIL=trongtmse185045@fpt.edu.vn
     ```
  2. Đăng nhập bằng Google tài khoản Giảng viên / Admin.
  3. Chọn môn `FA26 - EXE101` (hoặc tạo môn mới).
  4. Tìm mục **Import danh sách FAP**: Chọn file mẫu có sẵn tại [`docs/fap-roster-sample.csv`](file:///e:/PRM/Test%201/PRM393/docs/fap-roster-sample.csv).
  5. Bấm Import.
- **Kết quả kỳ vọng (PASS):**
  - Bảng danh sách sinh viên được nạp lên Firestore.
  - Web tự động so khớp: Sinh viên nào đã đăng nhập, sinh viên nào chưa có nhóm (sinh viên lẻ), và gợi ý phân bổ cân bằng chuyên ngành vào các phòng còn thiếu người.

---

## ⚠️ NHỮNG LƯU Ý SỐNG CÒN KHI TRÌNH BÀY VỚI THẦY

1. **Firestore Rules:** Đảm bảo toàn bộ nội dung file [`flutter_app/firebase/firestore.rules`](file:///e:/PRM/Test%201/PRM393/flutter_app/firebase/firestore.rules) đã được **Publish** trên Firebase Console để tránh bị lỗi `PERMISSION_DENIED`.
2. **Bảo mật:** Không bao giờ commit file `service-account.json` (chứa private key của Firebase) hoặc file `cloudinary.json` lên Git.
3. **Mạng Internet:** Giữ điện thoại Android và máy tính cùng kết nối mạng Wifi ổn định (hoặc phát 4G từ điện thoại cho máy tính) để thông báo FCM và Firestore đồng bộ tức thì.
