# Báo cáo kiểm thử MobAI

> **Chưa chạy.** Các file `.mob` là bản nháp chưa được chạy trên MobAI; không điền kết quả khi chưa chạy thật.

## Trạng thái bắt đầu
- Máy ảo Android có Google Play, đã thêm tài khoản test riêng. **Không commit email và mật khẩu**; truyền email qua tham số `test_email` của `test_run`.
- Rules đã publish. Đăng nhập, đồng ý điều khoản, chọn EXE101, tick cam kết.
- Hồ sơ → **Tạo Room và đơn Apply demo**. Room 05, 06, 08, 09 là Group; 07 là Room; 10 đã đủ.
- **Đặt lại:** rời nhóm, rút đơn. Đơn demo đã xử lý: xóa trên Firestore Console rồi bấm tạo demo lại.

## Kết quả
| # | File | Kiểm tra | Bắt đầu | Kết quả |
|---|---|---|---|---|
| 1 | `01_google_sign_in` | Vào màn chính | Chưa đăng nhập | Chưa chạy |
| 2 | `02_flow1_join_room` | Vào Room, có nút Rời nhóm | Chưa có nhóm | Chưa chạy |
| 3 | `03_flow2_apply_group` | Đơn được gửi | Chưa có nhóm | Chưa chạy |
| 4 | `04_flow3_vote_decides` | Vote đủ phiếu thì ứng viên vào nhóm, 2/5 | Leader Room 01, một mình trong nhóm, có đơn demo | Chưa chạy |
| 5 | `05_error_apply_limit` | Báo lỗi đơn thứ 4, khôi phục | Có 3 đơn chờ | Chưa chạy |
| 6 | `06_crud_application` | Tạo, sửa, rút đơn | Chưa có nhóm | Chưa chạy |
| 7 | `07_navigate_top_level` | Nội dung từng tab | Đã đăng nhập | Chưa chạy |
| 8 | `08_profile_remote_config` | Hồ sơ, giá trị Remote Config | Đã đăng nhập | Chưa chạy |
| 9 | `09_pdf_export` | Upload thành công, có file | Có Cloudinary | Chưa chạy |
| 10 | `10_sign_out` | Về màn Login | Đã đăng nhập | Chưa chạy |

## Việc phải làm khi có MobAI
- Đọc `mobai://reference/testing`, sửa lệnh cho đúng cú pháp và xử lý các dòng `TODO`.
- `07` giả định đã có nhóm; `Thành viên` chỉ hiện khi có nhóm.

## Bài tập healing
Chưa làm. Gợi ý: đổi nhãn `Gửi đơn Apply`, chạy `03`, ghi lại bản vá; đánh giá bản vá chỉ đổi cách tìm phần tử hay làm yếu phần kiểm tra.

## Bài tập bắt lỗi thật
Chưa làm. Gợi ý: cho `applyToRoom` trả về mà không ghi Firestore, chạy `03` để thấy fail, bỏ lỗi rồi chạy lại để pass. Lưu bằng chứng cả hai lần.
