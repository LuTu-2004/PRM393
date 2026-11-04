# 🚀 EXE Team Matching System — PRM393 Lab 3

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-6%20Services-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Tests](https://img.shields.io/badge/Automated%20Tests-52%2F52%20PASS%20(100%25)-success)](file:///docs/03_test_cases.md)
[![Business Rules](https://img.shields.io/badge/Business%20Rules-37%20Rules%20Compliant-blueviolet)](file:///AI_GUIDELINES.md)

> **Hệ thống ghép nhóm sinh viên đa ngành cho các môn khởi nghiệp thực chiến EXE (EXE101 & EXE201) tại Đại học FPT.**  
> Dự án môn học: **PRM393 — Lập trình Di động (Mobile Programming)**.

---

## 📌 1. Tổng Quan Dự Án (Project Overview)

Trong các môn học **EXE101** và **EXE201**, sinh viên bắt buộc phải thành lập các đội nhóm liên ngành (Công nghệ thông tin - SE, Quản trị kinh doanh - BA, Tiếp thị - MKT, Thiết kế đồ họa - GD, Khoa học dữ liệu - DS). Việc kết nối nhóm truyền thống qua mạng xã hội thường gặp nhiều bất cập: không kiểm soát được số lượng thành viên, tỷ lệ trùng chuyên ngành quá cao, hoặc thành viên bỏ nhóm giữa chừng.

**EXE Team Matching** giải quyết triệt để vấn đề này với:
- 📱 **Ứng dụng di động Flutter**: Giao diện tối ưu cho Sinh viên (tìm nhóm, tạo phòng, bỏ phiếu) và Giảng viên / Moderator (quản lý, giám sát, phê duyệt).
- 🔥 **Tích hợp đầy đủ 6 dịch vụ Firebase**: Auth, Firestore, Cloud Storage, Cloud Messaging (FCM), Remote Config, Analytics & Crashlytics.
- 🎯 **Tuân thủ nghiêm ngặt 37 Quy tắc Nghiệp vụ (Business Rules - BR)**: Đảm bảo cân bằng tỷ lệ chuyên ngành, giới hạn số thành viên (4-5 người), quy trình bầu chọn ẩn danh và chốt nhóm minh bạch.
- 🧪 **52/52 Automated Tests (Unit & Widget Test)** đạt tỉ lệ vượt qua **100%**.

---

## 📚 2. Bản Đồ Tài Liệu & Nghiệp Vụ (Documentation Hub)

Để mọi thành viên trong nhóm, giảng viên hoặc người kế thừa có thể nhanh chóng nắm bắt dự án, toàn bộ tài liệu đã được chuẩn hóa chi tiết:

| Tài liệu | Mô tả chi tiết | Đường dẫn |
| :--- | :--- | :---: |
| **Báo cáo Tiến độ & Bàn giao** | **Quan trọng nhất.** Tổng hợp 100% việc đã làm, bảng phân công nhiệm vụ, các việc cần làm tiếp trên Firebase Console & lịch trình bảo vệ. | [`PROGRESS_AND_HANDOVER.md`](PROGRESS_AND_HANDOVER.md) |
| **Quy chuẩn & Nguyên tắc cốt lõi** | Quy tắc bắt buộc khi code, danh mục 37 Business Rules, kiến trúc BLoC + Repository, công tắc Mock/Firebase, danh mục package được duyệt. | [`AI_GUIDELINES.md`](AI_GUIDELINES.md) |
| **Kiến trúc Hệ thống** | Chi tiết luồng dữ liệu, Clean Architecture, Feature-First, State Management (BLoC/Cubit) và Dependency Injection. | [`docs/01_architecture.md`](docs/01_architecture.md) |
| **Kế hoạch Analytics** | Danh mục các sự kiện đo lường hành vi người dùng (Firebase Analytics Events), Funnel phân tích và thông số tracking. | [`docs/02_analytics_plan.md`](docs/02_analytics_plan.md) |
| **Danh mục Test Cases** | Ma trận 52 test cases tự động (Unit test, Widget test, Firebase mocks, Repository tests) phủ kín 12 test suites. | [`docs/03_test_cases.md`](docs/03_test_cases.md) |
| **Ánh xạ Business Rules** | Bảng đối chiếu chi tiết từ 37 quy tắc nghiệp vụ (BR-01 đến BR-37) tới từng file mã nguồn cụ thể trong dự án. | [`docs/04_business_rules_mapping.md`](docs/04_business_rules_mapping.md) |
| **Đánh giá Mã nguồn (Code Review)** | Phân tích chất lượng mã nguồn, độ an toàn bảo mật, tính nhất quán kiến trúc. | [`docs/05_ai_code_review.md`](docs/05_ai_code_review.md) |
| **Thiết kế Cơ sở Dữ liệu** | 8 bảng ERD quan hệ, scripts di chuyển dữ liệu (Migrations), queries kiểm tra độ đa dạng nhóm và bộ dữ liệu hạt giống (Seeds). | [`database/README.md`](database/README.md) |

---

## 👥 3. Nhóm Thực Hiện & Phân Công Nhiệm Vụ

**Nhóm 4 — PRM393 — Lab 3**

| Thành viên / Vai trò | Mảng phụ trách | Nhiệm vụ chính |
| :--- | :--- | :--- |
| **Frontend Lead** | Flutter UI/UX & State Management | - Triển khai kiến trúc Feature-First, BLoC/Cubit và Repository Pattern.<br>- Hoàn thiện các luồng màn hình: Auth, Profile, Room, Matching, Voting, Moderator Dashboard. |
| **Firebase Specialist** | Firebase Backend & Cloud Config | - Tích hợp và cấu hình 6 dịch vụ Firebase trong Flutter code.<br>- Quản trị Firebase Console: kích hoạt Google Sign-In & Email/Pass, cấu hình Storage rules, Remote Config. |
| **QA / Tester** | Automated Testing & Quality | - Thiết kế và bảo trì hệ thống kiểm thử tự động (52 unit & widget tests).<br>- Lập kịch bản kiểm thử biên dịch và kiểm thử hồi quy cho 37 Business Rules. |
| **Backend & Data Lead** | Database & Ecosystem Sync | - Thiết kế CSDL quan hệ 8 bảng ERD đồng bộ với Backend Microservices .NET (PRN232).<br>- Viết SQL queries kiểm tra tính hợp lệ nhóm, độ đa dạng chuyên ngành và kết quả bầu cử. |

---

## 📊 4. Bảng Tổng Quan Trạng Thái Hệ Thống

| Hạng mục / Phân hệ | Tiến độ | Trạng thái kỹ thuật |
| :--- | :---: | :--- |
| **Kiến trúc Flutter & State (BLoC + GetIt)** | **100%** | ✅ Hoàn tất, tách lớp độc lập, DI GetIt |
| **6 Dịch vụ Firebase tích hợp trong App** | **100%** | ✅ Auth, Firestore, Storage, FCM, Analytics, Crashlytics, Remote Config |
| **Giao diện Người dùng (Sinh viên & Giảng viên)** | **100%** | ✅ Đầy đủ 6 phân hệ giao diện thực tế |
| **Hệ thống Kiểm thử tự động (52/52 tests)** | **100%** | ✅ 52/52 tests PASS 100% (12 test suites) |
| **Thiết kế Cơ sở Dữ liệu (8 bảng ERD & SQL)** | **100%** | ✅ Khớp 100% với Backend .NET PRN232 |
| **Cấu hình trên Firebase Console** | **70%** | ⏳ Cần xuất bản Storage rules & kích hoạt Remote Config trên Cloud |
| **Đóng gói Android APK & Video Demo** | **60%** | ⏳ Chạy lệnh `flutter build apk` và quay video thuyết trình |

*(Chi tiết từng hạng mục xem tại [`PROGRESS_AND_HANDOVER.md`](PROGRESS_AND_HANDOVER.md))*

---

## 🏛️ 5. Kiến Trúc Hệ Thống (Architecture)

Ứng dụng tuân theo mô hình **Feature-First + Repository Pattern + BLoC/Cubit**, kết hợp chuyển đổi linh hoạt giữa dữ liệu Mock và Firebase thật:

```
[UI Screens / Widgets]
       │
       ▼ (Dispatch Events / Listen States)
  [BLoC / Cubit]
       │
       ▼ (Call Repository Interface)
[Repository Interface] ───────────────┐
       │ (Tuỳ chọn cấu hình)           │
       ├─────────────────┐             ▼
       ▼                 ▼     [Firebase Services]
[Mock Repository]  [Firebase Repo]   - Auth, Firestore, Storage
   (Offline UI)       (Online)       - Messaging, Remote Config, Analytics
```

### Công tắc Chuyển đổi Dữ liệu (`AppConfig.USE_MOCK_DATA`)
Nằm tại `flutter_app/lib/core/config/app_config.dart`:
- `USE_MOCK_DATA = true`: App chạy offline hoàn toàn bằng mock repository, không phụ thuộc internet/Firebase (tối ưu khi demo trên lớp).
- `USE_MOCK_DATA = false`: App kết nối trực tiếp với Cloud Firestore và các dịch vụ Firebase thật.

---

## ⚙️ 6. 37 Business Rules (BR) Cốt Lõi

Toàn bộ logic nghiệp vụ được giám sát chặt chẽ:
1. **Xác thực & Hồ sơ (BR-01 → BR-06):** Giới hạn sinh viên EXE, đăng nhập email `@fpt.edu.vn`, tự trích xuất MSSV/Ngành/Khóa từ email, mỗi sinh viên chỉ tham gia 1 nhóm trong cùng học kỳ.
2. **Quản lý Phòng & Nhóm (BR-07 → BR-13):** Quy định số lượng thành viên từ 4 đến 5 người, chế độ Public/Private, quyền mời/kick thành viên của Trưởng nhóm.
3. **Ghép nhóm & Thuật toán Đa dạng (BR-14 → BR-20):** Lọc theo môn/kỳ/kỹ năng, gợi ý nhóm thông minh, giới hạn tối đa 3 yêu cầu đang chờ, **tỷ lệ cùng chuyên ngành không vượt quá 50% (BR-18)** kèm cảnh báo trực quan.
4. **Bầu chọn & Chốt nhóm (BR-21 → BR-28):** Bỏ phiếu kín thời hạn 24h, mỗi người 1 phiếu và không tự bầu chính mình, ẩn kết quả trước khi phiên kết thúc, kiểm tra toàn vẹn phiếu.
5. **Điều phối & Giảng viên (BR-29 → BR-33):** Dashboard cho Moderator, can thiệp duyệt nhóm đặc cách, cấu hình hạn chót học kỳ, gửi thông báo cảnh báo nhóm thiếu người.
6. **Bảo mật & Kiểm toán (BR-34 → BR-37):** Lưu cam kết điều khoản, phân quyền Firestore Security Rules, ghi log kiểm toán các hành vi quan trọng, tuyệt đối không lưu mật khẩu thô.

*(Chi tiết ánh xạ mã nguồn từng BR xem tại [`docs/04_business_rules_mapping.md`](docs/04_business_rules_mapping.md))*

---

## 📂 7. Cấu Trúc Thư Mục Dự Án

```
Lab 3/
├── AI_GUIDELINES.md                 # Quy chuẩn cốt lõi cho AI & Dev team (bắt buộc đọc)
├── PROGRESS_AND_HANDOVER.md         # Báo cáo tiến độ & tài liệu bàn giao toàn diện
├── README.md                        # Hướng dẫn tổng quan dự án
├── database/                        # Cơ sở dữ liệu quan hệ (ERD & SQL scripts)
│   ├── README.md                    # Hướng dẫn chạy SQL & cấu trúc bảng
│   ├── erd/                         # exe_matching.dbml (8 bảng quan hệ)
│   ├── migrations/                  # Scripts tạo bảng và ràng buộc chỉ mục
│   ├── queries/                     # Queries kiểm tra nghiệp vụ & độ đa dạng
│   └── seeds/                       # Dữ liệu mẫu ban đầu
├── docs/                            # Tài liệu chuyên sâu
│   ├── 01_architecture.md           # Kiến trúc hệ thống & State flow
│   ├── 02_analytics_plan.md         # Kế hoạch đo lường Firebase Analytics
│   ├── 03_test_cases.md             # Danh mục 52 test cases kiểm thử
│   ├── 04_business_rules_mapping.md # Ánh xạ 37 BR vào từng file code
│   └── 05_ai_code_review.md         # Báo cáo rà soát chất lượng mã nguồn
├── exe-team-matching-develop/       # Phân hệ Backend Microservices .NET (PRN232)
├── flutter_app/                     # Mã nguồn ứng dụng di động Flutter
│   ├── lib/
│   │   ├── core/                    # Config, theme, constants, DI GetIt
│   │   ├── features/                # 6 phân hệ: auth, profile, room, matching, voting, coordination
│   │   ├── models/                  # Các thực thể dữ liệu (User, Room, Invitation, Vote...)
│   │   ├── repositories/            # Interfaces, Mock repositories & Firebase repositories
│   │   └── services/                # Analytics, Crashlytics, Storage, Messaging, RemoteConfig...
│   ├── test/                        # 12 test suites (52 automated test cases pass 100%)
│   └── pubspec.yaml                 # Dependencies đã được kiểm duyệt
└── submission/                      # Sản phẩm nộp bài nghiệm thu
    ├── report/                      # Báo cáo Word / PDF
    ├── slides/                      # Slide thuyết trình
    └── video/                       # Video demo ứng dụng
```

---

## 🚀 8. Hướng Dẫn Cài Đặt & Khởi Chạy (Quick Start)

### Yêu cầu Môi trường:
- Flutter SDK `>= 3.19.0`
- Dart SDK `>= 3.3.0`
- Android Studio / VS Code có cài đặt Flutter extension

### Bước 1: Di chuyển vào thư mục ứng dụng Flutter
```bash
cd flutter_app
```

### Bước 2: Tải các gói thư viện
```bash
flutter pub get
```

### Bước 3: Chạy ứng dụng

#### 🔹 Cách 1: Chế độ Mock Data (Khuyên dùng khi chấm bài hoặc demo offline)
Không cần cấu hình Firebase, ứng dụng sẵn sàng chạy ngay:
1. Mở file `lib/core/config/app_config.dart`.
2. Đảm bảo `static const bool USE_MOCK_DATA = true;`.
3. Chạy lệnh:
   ```bash
   flutter run
   ```
*(Ứng dụng có sẵn 2 nút đăng nhập nhanh 1-chạm: **"Demo Sinh viên"** và **"Demo Giảng viên"**)*.

#### 🔹 Cách 2: Chế độ Firebase Thật (Cloud Online)
1. Tạo dự án trên [Firebase Console](https://console.firebase.google.com).
2. Thêm file cấu hình:
   - Android: Đặt `google-services.json` vào `flutter_app/android/app/`
   - iOS: Đặt `GoogleService-Info.plist` vào `flutter_app/ios/Runner/`
3. Trong `lib/core/config/app_config.dart`, đặt `USE_MOCK_DATA = false`.
4. Chạy lệnh:
   ```bash
   flutter run
   ```

---

## 🧪 9. Kiểm Thử Tự Động (Automated Testing)

Toàn bộ 52 test cases tự động đã được lập trình sẵn trong thư mục `flutter_app/test/`. Để chạy toàn bộ test suite:

```bash
cd flutter_app
flutter test
```

Kết quả mong đợi:
```text
00:04 +52: All tests passed!
```
Bao gồm: `auth_test.dart`, `profile_test.dart`, `create_room_test.dart`, `room_management_test.dart`, `matching_test.dart`, `vote_test.dart`, `coordination_test.dart`, `firebase_services_test.dart`, `models_test.dart`, `repositories_test.dart`, `invitations_test.dart`, `widget_test.dart`.

---

## 📋 10. Các Công Việc Cần Tiếp Tục Thực Hiện (Pending Tasks)

Theo lộ trình bàn giao tại [`PROGRESS_AND_HANDOVER.md`](PROGRESS_AND_HANDOVER.md):

1. **Firebase Console:** Kích hoạt Authentication Providers (Email/Password & Google Sign-In), xuất bản `storage.rules`, cấu hình parameters trên Remote Config.
2. **Build APK:** Thực hiện lệnh `flutter build apk --release` để lấy file cài đặt nộp bài.
3. **Tài liệu nộp bài:** Hoàn thiện slide thuyết trình vào `submission/slides/` và quay video demo vào `submission/video/`.

---

*© 2026 Nhóm 4 — PRM393 — FPT University.*
