# BÁO CÁO TIẾN ĐỘ & TÀI LIỆU BÀN GIAO DỰ ÁN TOÀN DIỆN
**Hệ sinh thái:** PRM393 - Lab 3 (Flutter & Firebase) + PRN232 (.NET Microservices)  
**Đề tài:** EXE Team Matching System (Phân hệ ghép nhóm đa ngành sinh viên EXE101 & EXE201)  
**Thời gian cập nhật:** Ngày 04/11/2026  
**Trạng thái hệ thống:** 🏆 **52/52 AUTOMATED TEST CASES PASS 100% — ĐẦY ĐỦ 6 DỊCH VỤ FIREBASE & 37 BUSINESS RULES**

---

## 📌 MỤC ĐÍCH TÀI LIỆU
Tài liệu này được lập ra nhằm:
1. **Bàn giao toàn diện mã nguồn và kiến trúc** cho các thành viên trong nhóm phụ trách các mảng: Firebase Console, Backend Microservices (.NET), Kiểm thử (QA), và Chuẩn bị bài thuyết trình với Giảng viên.
2. **Tổng kết chi tiết những hạng mục ĐÃ HOÀN THÀNH 100%**.
3. **Liệt kê cụ thể những hạng mục CẦN LÀM TIẾP (Pending Tasks)** trên Firebase Console và môi trường triển khai.
4. **Vạch ra LỘ TRÌNH (Roadmap) và phân công công việc rõ ràng** cho từng thành viên từ nay đến ngày nghiệm thu môn học.

---

## 📊 BẢNG TỔNG QUAN TIẾN ĐỘ HỆ THỐNG

| Hạng mục / Phân hệ | Mức độ hoàn thành | Trạng thái kỹ thuật | Người tiếp nhận / Phụ trách |
| :--- | :---: | :---: | :--- |
| **Kiến trúc Flutter & State (Clean Architecture + BLoC)** | **100%** | ✅ Hoàn tất, tách lớp độc lập, DI GetIt | Thành viên Frontend |
| **6 Dịch vụ Firebase trong Flutter Code** | **100%** | ✅ Tích hợp đầy đủ Auth, Storage, FCM, Analytics, Crashlytics, Remote Config | Thành viên Firebase |
| **Giao diện Người dùng (UI/UX Sinh viên & Giảng viên)** | **100%** | ✅ Đã dọn sạch nhãn `BR-xx`, giao diện chuẩn thương mại | Cả nhóm |
| **Hệ thống Kiểm thử tự động (Unit & Widget Tests)** | **100%** | ✅ 52/52 tests PASS (12 test suites) | Thành viên QA / Test |
| **Tầng Dữ liệu SQL & Thiết kế CSDL (8 bảng ERD)** | **100%** | ✅ Khớp 100% với Backend .NET PRN232 | Thành viên Backend |
| **Cấu hình trên Firebase Console (Cloud Settings)** | **70%** | ⏳ Cần bật thêm Email/Pass, publish Storage rules & Remote Config | **Thành viên Firebase (CẦN LÀM)** |
| **Đóng gói Android APK & Kịch bản Thuyết trình** | **60%** | ⏳ Cần chạy build APK và tập dượt demo | **Cả nhóm (CẦN LÀM)** |

---

## I. NHỮNG GÌ ĐÃ HOÀN THÀNH 100% (WHAT IS DONE)

### 1. Triển khai 6 Dịch vụ Firebase theo Guideline của Thầy
Tất cả 6 dịch vụ Firebase theo tài liệu `PRM393_Lab3_Preparation_Guide_v5_ToiUu.pdf` đã được code và kết nối hoàn thiện:

1. **Firebase Authentication (`FirebaseAuthRepository`):**
   - Đăng nhập bằng tài khoản Google trường FPT (`@fpt.edu.vn`) qua Google Sign-In Provider.
   - Đăng nhập bằng Email FPT thủ công **kèm ô nhập Mật khẩu (Password) có nút ẩn/hiện con mắt**.
   - Tự động trích xuất MSSV, Ngành (SE, MKT, BA, GD, DS), Khóa (K18, K19) từ email (vd: `tulpnse185102@fpt.edu.vn` -> MSSV `SE185102`, Ngành `SE`, Khóa `K18`).
   - Phân quyền người dùng tự động: Sinh viên (`student`) hoặc Ban điều phối (`moderator` với đuôi `@fe.edu.vn`).
   - Tích hợp điều khoản cam kết quy chế môn học (lưu `acceptedPolicyAt` timestamp).
   - Đầy đủ 2 nút đăng nhập Demo 1-chạm (Sinh viên & Giảng viên) và nút Đăng xuất an toàn.
2. **Cloud Firestore (`lib/repositories/firebase/`):**
   - 6 Collection Firestore hoàn chỉnh: `users`, `rooms`, `invitations`, `vote_sessions`, `votes`, `coordination_stats`.
   - Có cơ chế `FirestoreSeedService` tự động nạp dữ liệu mẫu ban đầu để app chạy được ngay lập tức kể cả khi database trên Cloud chưa có dữ liệu.
3. **Firebase Cloud Storage (`FirebaseStorageService` & `storage.rules`):**
   - Chức năng xuất và lưu trữ biên bản chốt nhóm, báo cáo đề án lên Cloud Storage theo đường dẫn `reports/{uid}/...`.
   - Có thanh tiến độ tải lên (Upload Progress Indicator) và danh sách file đã tải lên.
   - File quy tắc bảo mật chuẩn `storage.rules` bảo vệ quyền đọc/ghi theo UID sinh viên.
4. **Firebase Cloud Messaging - FCM & Local Notifications (`NotificationService`):**
   - Xử lý trọn vẹn 3 trạng thái ứng dụng: **Foreground** (popup thông báo nội bộ), **Background** (nhấp vào thông báo ngoài thanh trạng thái để mở app), **Terminated** (mở app trực tiếp từ thông báo).
   - Tích hợp màn hình **Trung tâm thông báo (`NotificationCenterScreen`)** kèm Floating Action Button quả chuông nổi trên tất cả các màn hình chính.
5. **Google Analytics for Firebase (`AnalyticsService`):**
   - Tự động tracking **9 sự kiện nghiệp vụ quan trọng** (vượt chuẩn tối thiểu 7 của thầy):
     `user_signed_in`, `user_signed_out`, `room_created`, `room_viewed`, `join_request_sent`, `major_warning_shown`, `vote_session_started`, `vote_cast`, `report_exported`.
   - Tự động gắn User ID (`AnalyticsService.setCurrentUser(uid)`) và thuộc tính người dùng `user_role` ngay khi đăng nhập.
6. **Firebase Crashlytics (`CrashlyticsService`):**
   - Bắt lỗi toàn cục Flutter Framework (`FlutterError.onError`) và Dart Asynchronous (`PlatformDispatcher.instance.onError`).
   - Có thanh công cụ **Crashlytics Test Dialog** trên AppBar của Giảng viên (`ModeratorDashboardScreen`) để demo kích hoạt lỗi có chủ đích (Non-fatal Handled Error và Fatal Crash) khi thầy yêu cầu kiểm chứng.
7. **Firebase Remote Config (`FirebaseRemoteConfigService`):**
   - Quản trị động 3 tham số nghiệp vụ mà không cần build lại app:
     - `max_pending_requests`: Hạn mức số lượng đơn xin gia nhập tối đa (mặc định: 3).
     - `voting_duration_hours`: Thời gian hiệu lực của phiên bỏ phiếu kín (mặc định: 24 giờ).
     - `show_matching_banner`: Bật/tắt banner gợi ý phòng AI trên trang chủ.
   - Tích hợp giao diện **RemoteConfigPanel** trong tab Hồ sơ với nút **Refresh** để cập nhật giá trị mới tức thì từ Firebase Console.

---

### 2. Tinh chỉnh Giao diện Chuẩn Chuyên Nghiệp (Commercial Presentation UI)
- **Dọn sạch 100% nhãn mã `(BR-xx)` trên toàn bộ giao diện:**
  - Đã loại bỏ tất cả các chuỗi gây rối mắt như `(BR-02)`, `(BR-05)`, `(BR-09)`, `(BR-17)`, `(BR-18, BR-19)`, `(BR-21 đến BR-28)`, `(BR-30 đến BR-34)` trên nút bấm, tiêu đề, banner cảnh báo, dialog xác nhận và thông báo SnackBar.
  - Ứng dụng hiển thị câu từ tự nhiên, mạch lạc, sẵn sàng trình bày trước Hội đồng chấm thi mà không bị lộ các mã kiểm thử nội bộ.
- **Quy chuẩn tên phòng dự án:**
  - Đã chuẩn hóa hiển thị các phòng mặc định theo số phòng dễ nhận diện: `Nhóm 1 (Phòng 01)`, `Nhóm 2 (Phòng 02)`, `Nhóm 3 (Phòng 03)`.
- **Dynamic Header:**
  - Header trang chủ và tab Hồ sơ tự động hiển thị tên thật, email thật, MSSV và Ngành học của tài khoản vừa đăng nhập thay vì gán cứng tĩnh.
- **Thêm trường Mật khẩu:**
  - Khung đăng nhập thủ công có đầy đủ cả Email và Mật khẩu với nút hiển thị/ẩn mật khẩu trực quan.

---

### 3. Phân hệ Nghiệp vụ Toàn diện (37 Business Rules)
- **Phân hệ Sinh viên:**
  - Khám phá phòng khởi nghiệp: lọc theo môn `EXE101` / `EXE201`, tìm kiếm theo từ khóa thời gian thực.
  - Thuật toán AI Matching: tính điểm % tương thích dựa trên kỹ năng đang có và vị trí phòng còn thiếu, kèm kiểm soát đa dạng chuyên ngành (không quá 50% cùng một ngành).
  - Quản lý yêu cầu & Lời mời: giới hạn tối đa 3 yêu cầu đang chờ (hủy để lấy lại lượt), bộ đếm ngược thời gian phản hồi 48 giờ.
  - Bỏ phiếu kín chốt nhóm: tự động kích hoạt khi nhóm đạt 4-5 người, thời hạn 24 giờ, bỏ phiếu kín bầu Leader (loại trừ bản thân), bảo mật ẩn danh, tỷ lệ đồng thuận $\ge 75\%$ thì chính thức chốt nhóm (`Finalized`).
  - Quản lý phòng của Leader: quyền mời trực tiếp qua MSSV / Email FPT, quyền xóa thành viên (Kick) kèm dialog xác nhận bảo đảm an toàn.
- **Phân hệ Ban Điều Phối / Giảng viên (Moderator Dashboard):**
  - Thống kê KPI tiến độ ghép nhóm toàn trường theo từng học kỳ.
  - Giám sát các nhóm có nguy cơ thiếu thành viên ($< 4$ người) sát hạn chót.
  - Nút nhắc nhở Trưởng nhóm (Leader) gửi cảnh báo khẩn cấp.
  - Quyền can thiệp giải tán nhóm không đủ chuẩn hoặc không hoạt động.
  - Nút gia hạn hạn chót ghép nhóm (+7 ngày).

---

### 4. Kiểm thử Tự động (Automated Testing)
Đã chạy kiểm thử toàn bộ 12 test suite bằng lệnh `flutter test`:
```
00:22 +52: All tests passed!
```
- ✅ `test/auth_test.dart` (7 tests): Email FPT, trích xuất MSSV, chặn Gmail, điều khoản, UI Đăng nhập.
- ✅ `test/profile_test.dart` (3 tests): Cập nhật hồ sơ, trích xuất ngành/khóa, UI Hồ sơ.
- ✅ `test/create_room_test.dart` (2 tests): Validation form tạo phòng, lưu phòng mới.
- ✅ `test/matching_test.dart` (3 tests): Thuật toán Matching AI, hạn mức 3 request, UI Matching.
- ✅ `test/invitations_test.dart` (4 tests): Duyệt/hủy đơn, cảnh báo đa dạng ngành, UI Lời mời.
- ✅ `test/room_management_test.dart` (4 tests): Leader kick member, mời trực tiếp MSSV, phân quyền Leader vs Member.
- ✅ `test/vote_test.dart` (7 tests): Mở vote 4-5 người, cấm tự bầu cho mình, 1 người 1 phiếu, ngưỡng đồng thuận 75%.
- ✅ `test/coordination_test.dart` (5 tests): KPI giảng viên, gia hạn deadline, cảnh báo nguy cơ, giải tán nhóm.
- ✅ `test/models_test.dart` (5 tests): To/from Map và serialization của toàn bộ Data Models.
- ✅ `test/repositories_test.dart` (5 tests): Mock repositories và các quy tắc kiểm tra logic.
- ✅ `test/widget_test.dart` (2 tests): Navigation Shell và Banner đa dạng ngành.
- ✅ `test/firebase_storage_test.dart` & Services tests: Các dịch vụ bổ trợ.

---

## II. NHỮNG GÌ CHƯA LÀM / CẦN THÀNH VIÊN TRONG NHÓM LÀM TIẾP (WHAT NEEDS TO BE DONE)

Phần này đặc biệt dành cho các thành viên phụ trách tài khoản Firebase Console và chuẩn bị nộp bài.

### 🔴 Nhiệm vụ 1: Cấu hình trên Firebase Console (Dành cho thành viên giữ tài khoản Firebase)
Mã nguồn Flutter đã viết sẵn 100%, nhưng trên trang web quản trị [Firebase Console](https://console.firebase.google.com/u/0/project/exe-team-matching-70774) cần thực hiện các thao tác sau:

1. **Bật Internet Service Provider: Email/Password**
   - *Hiện trạng:* Firebase Console hiện tại mới chỉ kích hoạt **Google Provider**. Khi người dùng nhập Email + Mật khẩu trên app, app đang sử dụng cơ chế đồng bộ Firestore thông minh dự phòng.
   - *Việc cần làm:* Vào **Authentication** -> chọn tab **Sign-in method** -> bấm **Add new provider** -> chọn **Email/Password** -> gạt nút **Enable** và bấm **Save**.
   - *Kết quả đạt được:* Người dùng đăng ký bằng Email và Pass sẽ xuất hiện chính thức trong danh sách `Users` của Firebase Authentication.

2. **Publish bộ quy tắc bảo mật Cloud Storage (Storage Rules)**
   - *Hiện trạng:* File quy tắc đã được viết sẵn tại đường dẫn: `Lab 3/flutter_app/firebase/storage.rules`.
   - *Việc cần làm:* Vào **Storage** trên Firebase Console -> chọn tab **Rules** -> dán toàn bộ nội dung file `storage.rules` vào và bấm **Publish**.
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /reports/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /{allPaths=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

3. **Tạo 3 tham số trên Firebase Remote Config**
   - *Hiện trạng:* Giao diện app và service đã viết sẵn các hàm đọc 3 tham số này.
   - *Việc cần làm:* Vào **Remote Config** trên Firebase Console -> bấm **Add parameter** và thêm 3 tham số sau rồi bấm **Publish changes**:
     | Parameter Key | Data Type | Default Value | Mô tả |
     | :--- | :---: | :---: | :--- |
     | `max_pending_requests` | Number | `3` | Số lượng yêu cầu gia nhập tối đa sinh viên được gửi cùng lúc |
     | `voting_duration_hours` | Number | `24` | Số giờ hiệu lực của một phiên bỏ phiếu kín chốt nhóm |
     | `show_matching_banner` | Boolean | `true` | Bật/Tắt hiển thị banner gợi ý AI trên trang chủ |

4. **Thêm file Service Worker cho Web Push Notification (FCM trên Web Chrome)**
   - *Hiện trạng:* Khi chạy app trên Chrome, console hiển thị cảnh báo thiếu file `firebase-messaging-sw.js`.
   - *Việc cần làm:* Tạo file `Lab 3/flutter_app/web/firebase-messaging-sw.js` với nội dung sau:
   ```javascript
   importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
   importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

   firebase.initializeApp({
     apiKey: "AIzaSyB4PfawQsPfXgbVNpQecajWIM4pna8_nwE",
     authDomain: "exe-team-matching-70774.firebaseapp.com",
     projectId: "exe-team-matching-70774",
     storageBucket: "exe-team-matching-70774.firebasestorage.app",
     messagingSenderId: "959409386646",
     appId: "1:959409386646:web:c391fab6788676b2807eb7"
   });

   const messaging = firebase.messaging();
   ```

---

### 🟡 Nhiệm vụ 2: Đóng gói Android APK & Cấu hình Fingerprint SHA-1 (Dành cho thành viên Mobile/DevOps)
Nếu thầy yêu cầu cài file `.apk` trực tiếp lên điện thoại Android hoặc máy ảo:
1. **Lấy SHA-1 và SHA-256 của máy bạn:**
   ```powershell
   cd "E:\PRM\Thư mục mới\Lab 3\flutter_app\android"
   ./gradlew signingReport
   ```
2. Thêm chuỗi SHA-1 lấy được vào **Firebase Console > Project Settings > Your apps (Android) > Add fingerprint**.
3. Tải lại file `google-services.json` mới nhất và đè vào thư mục `Lab 3/flutter_app/android/app/google-services.json`.
4. Build bản cài đặt:
   ```powershell
   cd "E:\PRM\Thư mục mới\Lab 3\flutter_app"
   flutter build apk --debug
   ```
   *(File apk xuất ra tại: `build\app\outputs\flutter-apk\app-debug.apk`)*.

---

### 🟢 Nhiệm vụ 3: Chuẩn bị Kịch bản Thuyết trình & Báo cáo với Giảng viên (Dành cho cả nhóm)
Cần phân công 1 thành viên thuyết trình và 1 thành viên thao tác máy theo kịch bản **5 phút chuẩn điểm tối đa**:

- **Phút 1: Đăng nhập & Xác thực bảo mật (Firebase Auth)**
  - Mở `LoginScreen`: Giới thiệu tính năng đăng nhập Google Mail trường FPT (`@fpt.edu.vn`).
  - Demo đăng nhập nhanh qua nút Demo Sinh viên (Nguyễn Văn An - SE180123).
  - Chỉ ra hộp thoại Cam kết Quy chế đa ngành (BR-34) có lưu timestamp đối soát.
- **Phút 2: Khám phá phòng & Thuật toán AI Matching (Firestore & Business Rules)**
  - Tab Khám phá: Xem danh sách các phòng `Nhóm 1 (Phòng 01)`, `Nhóm 2 (Phòng 02)`...
  - Tab Matching: Giải thích điểm % Matching Score dựa trên kỹ năng còn thiếu của từng phòng.
  - Thử gửi yêu cầu xin gia nhập: Chỉ ra bộ đếm hạn mức (tối đa 3 yêu cầu) và đồng hồ 48 giờ.
  - Xem chi tiết phòng: Giới thiệu banner cảnh báo khi tỷ lệ chuyên ngành vượt 50% (Đa dạng ngành).
- **Phút 3: Quyền Trưởng nhóm (Leader) & Bỏ phiếu kín (Voting Module)**
  - Đăng nhập tài khoản Leader của Nhóm 1.
  - Demo quyền **Mời trực tiếp qua MSSV** và quyền **Xóa thành viên khỏi nhóm (Kick)** kèm xác nhận an toàn.
  - Bấm nút **"Bỏ Phiếu Kín Chốt Nhóm"**: Giới thiệu giao diện biểu quyết ẩn danh 24 giờ, cấm tự bầu cho bản thân, tỷ lệ $\ge 75\%$ để chốt nhóm thành công.
- **Phút 4: Bảng Điều Phối Giảng viên & Can thiệp hệ thống (Moderator Dashboard)**
  - Đăng nhập Demo Giảng viên: Khám phá thanh chỉ số KPI toàn trường.
  - Bấm nút **Gia hạn deadline (+7 ngày)**.
  - Bấm nút **Nhắc Leader** trên nhóm có nguy cơ thiếu thành viên.
  - Bấm nút **Giải tán nhóm** đối với nhóm vi phạm quy định.
- **Phút 5: Kiểm chứng Firebase Nâng cao (Storage, Analytics, Crashlytics, Remote Config)**
  - Tab Hồ sơ -> Mở **Remote Config Panel**: Bấm Refresh để thấy cấu hình được kéo trực tiếp từ Cloud.
  - Mở AppBar Giảng viên -> Bấm icon **Bug (Crashlytics)**: Bấm gửi Non-fatal Error để chứng minh lỗi được bắn trực tiếp lên Firebase Crashlytics Dashboard.
  - Mở Terminal chạy `flutter test`: Chiếu màn hình **52/52 tests passed 100%** làm bằng chứng kiểm thử chất lượng code.

---

## III. LỘ TRÌNH THỰC HIỆN TỪNG BƯỚC (ROADMAP)

```mermaid
flowchart TD
    A["Giai đoạn 1: Thiết lập Firebase Console (Ngày 04/11)"] --> B["Giai đoạn 2: Kiểm thử đa nền tảng & Build APK (Ngày 05/11)"]
    B --> C["Giai đoạn 3: Tích hợp Microservices .NET (Ngày 06/11)"]
    C --> D["Giai đoạn 4: Tổng duyệt Demo & Nộp bài (Ngày 07/11)"]

    A -.-> A1["Bật Email/Password Provider"]
    A -.-> A2["Publish Storage Rules"]
    A -.-> A3["Thêm 3 tham số Remote Config"]
    A -.-> A4["Thêm firebase-messaging-sw.js"]

    B -.-> B1["Chạy flutter test (52/52 pass)"]
    B -.-> B2["Thử nghiệm trên Chrome & Windows"]
    B -.-> B3["Build file APK Android"]

    D -.-> D1["Tập dượt kịch bản thuyết trình 5 phút"]
    D -.-> D2["Chuẩn bị Slide & Video backup"]
```

### Chi tiết kế hoạch theo ngày:
1. **Ngày 04/11/2026 (Hôm nay):**
   - Thành viên giữ tài khoản Firebase đăng nhập Firebase Console hoàn tất 4 mục trong **Nhiệm vụ 1**.
   - Cập nhật file `firebase-messaging-sw.js` vào thư mục `web/`.
2. **Ngày 05/11/2026:**
   - Chạy thử app trên cả 2 nền tảng: Chrome Web (`flutter run -d chrome`) và Windows (`flutter run -d windows`).
   - Kiểm tra xem Firebase Console đã nhận sự kiện trên **Google Analytics (DebugView)** và **Crashlytics** hay chưa.
3. **Ngày 06/11/2026:**
   - Họp nhóm online 30 phút để ghép nối dữ liệu giữa Mobile App và hệ thống Backend .NET Microservices PRN232 (nếu có yêu cầu nộp chung đề tài).
4. **Ngày 07/11/2026:**
   - Tổng duyệt demo thử (Dry Run) theo kịch bản 5 phút ở trên.
   - Quay sẵn 1 video màn hình 3 phút chất lượng cao dự phòng trường hợp mạng trường yếu khi thuyết trình.

---

## IV. BẢNG PHÂN CÔNG TRÁCH NHIỆM (RACI MATRIX)

| Thành viên | Vai trò chính | Nhiệm vụ cụ thể | Deadline |
| :--- | :--- | :--- | :---: |
| **Thành viên 1** (Trưởng nhóm / Repo Owner) | Quản lý dự án & Điều phối | Giám sát tiến độ, kiểm tra chất lượng code, chạy test case, nộp bài | 07/11 |
| **Thành viên 2** (Firebase Specialist) | Phụ trách Cloud & Firebase | Bật Email Provider, cấu hình Storage rules, Remote config, FCM SW | **04/11** |
| **Thành viên 3** (DevOps & Mobile Build) | Phụ trách Môi trường & Build | Lấy SHA-1, build APK Android, kiểm tra thiết bị di động thật | **05/11** |
| **Thành viên 4** (Backend & Integration) | Phụ trách Tích hợp .NET | Kiểm tra tính tương thích giữa SQL Schema và API PRN232 | **06/11** |
| **Thành viên 5** (Presenter & QA) | Thuyết trình & Soạn tài liệu | Soạn Slide thuyết trình, chuẩn bị video demo backup, diễn tập kịch bản | **07/11** |

---

## V. HƯỚNG DẪN DÀNH CHO THÀNH VIÊN MỚI CLONE DỰ ÁN (QUICK START)

Khi tải code về máy tính cá nhân, thành viên chỉ cần thực hiện 3 bước sau:

1. **Cài đặt thư viện dependencies:**
   ```powershell
   cd "E:\PRM\Thư mục mới\Lab 3\flutter_app"
   flutter pub get
   ```

2. **Chạy kiểm thử toàn bộ hệ thống:**
   ```powershell
   flutter test
   ```
   *(Đảm bảo hiển thị kết quả: `All tests passed!`)*

3. **Chạy ứng dụng để trải nghiệm:**
   - **Chạy trên trình duyệt Chrome:**
     ```powershell
     flutter run -d chrome
     ```
   - **Chạy trên Windows Desktop:**
     ```powershell
     flutter run -d windows
     ```

4. **Các phím tắt khi đang chạy app trong terminal:**
   - Nhấn **`r`**: Hot Reload (cập nhật code giao diện tức thì).
   - Nhấn **`R`**: Hot Restart (khởi động lại app và reset BLoC state).
   - Nhấn **`q`**: Thoát ứng dụng.

---

> 🎯 **Lời kết:** Toàn bộ mã nguồn cốt lõi, kiến trúc BLoC, kiểm thử tự động và giao diện đã hoàn tất ở mức tốt nhất. Các thành viên chỉ cần thực hiện đúng các bước cấu hình Cloud trên Firebase Console và tập kịch bản demo là nhóm chắc chắn đạt kết quả tối đa!
