# Sổ điểm danh

Ứng dụng desktop (Flutter, Windows/macOS) giúp giảng viên điểm danh nhanh:
thủ công bằng bàn phím hoặc bằng QR động trong mạng LAN, lưu SQLite cục bộ,
đồng bộ Google Sheets.

## Chạy thử

```powershell
flutter pub get
flutter run -d windows
```

Yêu cầu trên Windows:

- Bật **Developer Mode** (`start ms-settings:developers`) – Flutter cần quyền
  tạo symlink khi build plugin.
- Cài **Visual Studio** kèm workload *Desktop development with C++*.
- Đường dẫn Flutter SDK **không được có dấu cách** (ví dụ dùng `C:\src\flutter`). Nếu SDK nằm ở thư mục có
  dấu cách, bước build native assets (sqlite3) sẽ lỗi
  `'D:\hoc' is not recognized...`. Cách nhanh: gắn ổ ảo rồi chạy từ đó
  (mất khi khởi động lại máy):

  ```powershell
  subst X: "D:\hoc tap\software code\flutter_windows_3.47.5-stable"
  subst Y: "D:\hoc tap\mon hoc\PRM\Desktop app"
  cd Y:\
  X:\flutter\bin\flutter.bat run -d windows
  ```

  Cách lâu dài: chuyển SDK sang ví dụ `C:\src\flutter`.

## Dữ liệu mẫu (giả)

```powershell
dart run tool/make_sample_data.dart
```

Tạo `sample_data/` gồm `SE1801_PRN211.xlsx` (bố cục kiểu FAP: tách Họ / Tên
đệm / Tên), `SE1802_PRN211.csv` và thư mục `photos/` ảnh thẻ dạng hình bóng.
Không dùng dữ liệu sinh viên thật trong repo.

## Điểm danh

Luồng hoạt động chi tiết (có sơ đồ): [docs/LUONG_HOAT_DONG.md](docs/LUONG_HOAT_DONG.md).

- **Tạo buổi:** `Ctrl+N` (hoặc nút *Điểm danh* trên thẻ lớp) → chọn lớp, ngày, slot →
  *Điểm danh thủ công* hoặc *Điểm danh bằng QR*.
- **Thủ công:** `P` có mặt, `A` vắng (tự sang người tiếp), `Space`/`↓` tiếp, `↑` trước,
  `/` hoặc `Ctrl+F` tìm, `F` chế độ tập trung, `Delete` xóa đánh dấu, `Ctrl+Z` hoàn tác,
  `Ctrl+Enter` hoàn tất. Click thẻ để xoay vòng Chưa → Có mặt → Vắng; chuột phải để ghi chú.
- **QR:** máy chủ LAN ở cổng 8080 (đổi trong Cài đặt). Sinh viên kết nối cùng mạng
  (khuyến nghị bật Mobile Hotspot của laptop), quét QR, nhập MSSV. Lần đầu Windows sẽ hỏi
  quyền tường lửa: chọn *Allow*. Mọi bản ghi QR ở trạng thái *Chờ duyệt* cho tới khi xác nhận.
- **Duyệt & chốt → Tổng hợp:** duyệt các bản ghi có cờ, `Ctrl+Enter` xác nhận, rồi
  *Copy danh sách vắng* (mỗi MSSV một dòng) hoặc *Xuất CSV* để nhập FAP.

Xem trước trang điện thoại mà không cần chạy app:

```powershell
dart run tool/dump_phone_pages.dart build/phone_pages
```

## Kiểm thử

```powershell
flutter test                      # unit + golden
flutter test --update-goldens     # chụp lại ảnh giao diện vào test/goldens/
```

Ảnh golden (sáng/tối, 1024×640 và 1920×1080) nằm ở `test/goldens/*.png`.

## Cấu trúc

```
lib/
  core/        theme "Sổ điểm danh", cấu hình, tiện ích tiếng Việt
  data/        SQLite (schema, DAO), nhập Excel/CSV, ảnh thẻ, dữ liệu giả
  domain/      model
  services/    (giai đoạn sau) máy chủ điểm danh QR, token, đồng bộ
  ui/          khung ứng dụng, màn hình, widget dùng chung
tool/          công cụ tạo dữ liệu mẫu
```

Dữ liệu thật lưu ở thư mục dữ liệu ứng dụng của người dùng
(`%APPDATA%\vn.edu.fpt\diem_danh` trên Windows).
