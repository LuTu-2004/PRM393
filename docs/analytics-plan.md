# Kế hoạch Analytics

Tên sự kiện: chữ thường, số, gạch dưới, tối đa 40 ký tự. Không ghi email hoặc họ tên vào tham số.
Bằng chứng DebugView: **chưa chụp**.

Ba luồng: **L1** vào thẳng Room, **L2** Apply vào Group, **L3** Leader xử lý đơn.

| Sự kiện | Khi nào ghi | Tham số | Luồng |
|---|---|---|---|
| `login` | Đăng nhập Google thành công | `method` | Tất cả |
| `logout` | Bấm Đăng xuất | không | Tất cả |
| `screen_view` | Mở màn hình hoặc đổi tab | `screen_name` | Tất cả |
| `complete_profile` | Lưu hồ sơ thành công | `course_code` | Tất cả |
| `view_room` | Mở chi tiết Room | `item_id`, `room_status` | L1, L2 |
| `join_room` | Vào thẳng Room | `item_id` | L1 |
| `leave_room` | Rời nhóm | `item_id` | L1 |
| `view_application` | Mở chi tiết đơn | `item_id` | L2 |
| `create_application` | Gửi đơn thành công | `item_id` | L2 |
| `update_application` | Sửa lời nhắn | `item_id` | L2 |
| `delete_application` | Rút đơn | `item_id` | L2 |
| `vote_application` | Thành viên vote ứng viên | `item_id`, `accept` | L3 |
| `decide_application` | Leader nhận hoặc từ chối | `item_id`, `accept` | L3 |
| `close_recruitment` | Leader đóng tuyển | `item_id` | L3 |
| `transfer_leader` | Leader chuyển quyền | `item_id` | L3 |
| `start_leader_election` | Mở bầu Leader | `item_id` | L3 |
| `vote_leader_election` | Bỏ phiếu bầu Leader | `item_id`, `agree` | L3 |
| `create_transfer_request` | Gửi yêu cầu chuyển nhóm | `from_room`, `to_room` | Sau chốt sổ |
| `export_pdf` | Xuất và upload báo cáo | `item_count` | Báo cáo |

## Kiểu tham số và câu hỏi sản phẩm
| Tham số | Kiểu |
|---|---|
| `method`, `screen_name`, `course_code`, `item_id`, `room_status`, `from_room`, `to_room` | String |
| `accept`, `agree` | Number (1 hoặc 0) |
| `item_count` | Number |

| Sự kiện | Câu hỏi sản phẩm |
|---|---|
| `join_room`, `create_application` | Sinh viên vào thẳng hay Apply nhiều hơn? |
| `decide_application` | Tỷ lệ đơn được nhận là bao nhiêu? |
| `delete_application` | Sinh viên có hay rút đơn không? |
| `leave_room` | Nhóm có hay mất người trước khi chốt sổ không? |
| `start_leader_election`, `transfer_leader` | Leader đầu tiên có thường bị đổi không? |
| `export_pdf` | Báo cáo có được dùng không? |

`item_id` là mã Room. Main entity là đơn Apply vì sinh viên không được tạo Room (BR-12).
