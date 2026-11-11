import os
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.enum.shapes import MSO_SHAPE

# ─────────────────────────────────────────────────────────────
# PALETTE & STYLES (Guideline V11 Theme)
# ─────────────────────────────────────────────────────────────
COLOR_PURPLE = RGBColor(90, 40, 160)
COLOR_ORANGE = RGBColor(220, 80, 20)
COLOR_DARK = RGBColor(30, 30, 30)
COLOR_MUTED = RGBColor(90, 90, 90)
COLOR_LIGHT_BG = RGBColor(248, 248, 250)
COLOR_WHITE = RGBColor(255, 255, 255)
COLOR_GREEN = RGBColor(30, 130, 60)
FONT_NAME = "Calibri"

def set_para(p, text, size=11, bold=False, italic=False, color=COLOR_DARK, space_after=2, space_before=0, align=PP_ALIGN.LEFT):
    p.text = text
    p.font.name = FONT_NAME
    p.font.size = Pt(size)
    p.font.bold = bold
    p.font.italic = italic
    p.font.color.rgb = color
    p.space_after = Pt(space_after)
    p.space_before = Pt(space_before)
    p.alignment = align

def safe_replace_runs(p, old, new):
    for r in p.runs:
        if old in r.text:
            r.text = r.text.replace(old, new)

def safe_replace_shape(shape, old, new):
    if shape.has_text_frame:
        for p in shape.text_frame.paragraphs:
            safe_replace_runs(p, old, new)
    elif shape.has_table:
        for row in shape.table.rows:
            for cell in row.cells:
                for p in cell.text_frame.paragraphs:
                    safe_replace_runs(p, old, new)

# ─────────────────────────────────────────────────────────────
# SLIDE 1: Title & Group 5 Info
# ─────────────────────────────────────────────────────────────
def update_slide_1(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "Nhóm 3" in txt:
                    p.text = p.text.replace("Nhóm 3", "Nhóm 5")
                if "PRN232" in txt:
                    p.text = p.text.replace("PRN232", "PRM393")
                if "Phan Thị Thảo Vy" in txt or "Phạm Đinh Gia Phú" in txt:
                    pass
                if "Kiến trúc .NET 8" in txt or "Flutter & Firebase" in txt:
                    p.text = "Flutter 3.x (Dart) · MVVM + Provider Architecture"
                elif "Microservices" in txt or "Thuật toán Phân phối" in txt:
                    p.text = "Android Mobile App (Sinh viên) & Flutter Web (Admin Giảng viên)"
                elif "Cloud Firestore & FCM" in txt or "Matching Engine" in txt:
                    p.text = "Google Firebase: Auth · Cloud Firestore · FCM HTTP v1 · Crashlytics"
                elif "Flutter Android App · Flutter Web" in txt or "6 REST" in txt or "6 SQL" in txt:
                    p.text = "Cloudinary CDN (PDF Storage) · 102 Automated Tests Pass 100%"
                elif "Firebase Platform" in txt or "YARP" in txt or "Redis" in txt:
                    p.text = "Chuẩn hóa 100% theo 37 Business Rules (BR-01 → BR-37) môn PRM393"

    # Update Group Members table if present
    for s in slide.shapes:
        if s.has_table:
            table = s.table
            # Check if it's the members table
            if len(table.rows) >= 5 and "Phan Thị Thảo Vy" in table.rows[1].cells[1].text:
                # Row 1: Leader Tú
                table.rows[1].cells[0].text = "01"
                table.rows[1].cells[1].text = "Lữ Phước Nhật Tú"
                table.rows[1].cells[2].text = "SE185102"
                # Row 2: Member Trọng
                table.rows[2].cells[0].text = "02"
                table.rows[2].cells[1].text = "Tăng Minh Trọng"
                table.rows[2].cells[2].text = "SE185045"
                # Row 3 & 4: Clear or note roles
                table.rows[3].cells[0].text = "—"
                table.rows[3].cells[1].text = "Lập trình Flutter Mobile & Backend Firebase"
                table.rows[3].cells[2].text = "Leader"
                table.rows[4].cells[0].text = "—"
                table.rows[4].cells[1].text = "Kiểm thử Thiết bị Android thật & Viết tài liệu"
                table.rows[4].cells[2].text = "Member"

# ─────────────────────────────────────────────────────────────
# SLIDE 4 & 5: Student Mobile App & Admin Web
# ─────────────────────────────────────────────────────────────
def update_slide_4(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "Không gian Web App" in txt or "Student Portal" in txt:
                    p.text = "Ứng dụng Di động Android dành cho Sinh viên (Flutter Mobile App)"
                elif "Khám phá Phòng & Nhóm" in txt:
                    p.text = "Khám phá Phòng Realtime & Nộp đơn: 5 trạng thái vòng đời, Vào thẳng (<3) và Apply (≥3)"
                elif "Hồ sơ 5 Kỹ năng:" in txt:
                    p.text = "• Hồ sơ 5 Kỹ năng: Đăng nhập Google @fpt.edu.vn, kéo 5 thanh trượt năng lực (Tech, Mgt, Design, Mkt, Sale) và biểu đồ Radar (BR-04, BR-05)."
                elif "Vào thẳng & Apply:" in txt:
                    p.text = "• Vào thẳng & Apply: Phòng <3 vào ngay qua runTransaction; phòng ≥3 nộp đơn kèm tin nhắn, giới hạn tối đa 3 đơn chờ (BR-17)."
                elif "Bỏ phiếu kín" in txt or "Peer Voting" in txt or "Biểu quyết" in txt:
                    p.text = "• Bỏ phiếu kín (Peer Voting): Nổ chuông thông báo FCM; thành viên bỏ phiếu Duyệt/Từ chối; đa số phiếu kích hoạt gia nhập (BR-25)."
                elif "Xuất Báo cáo" in txt or "Cloudinary" in txt or "PDF" in txt:
                    p.text = "• Xuất Đề án PDF: Biên dịch tài liệu nhóm dạng PDF trong app, tải lên Cloudinary lấy link bảo mật nộp cho Giảng viên."

def update_slide_5(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "Trung tâm Điều phối" in txt and "Moderator" in txt:
                    p.text = "Cổng Web Quản trị Giảng viên & Điều phối (Flutter Web - main_admin.dart)"
                elif "Quản lý Không gian Môn học" in txt:
                    p.text = "Quản trị Môn học (Space): Cấu hình kỳ học FA26, ngưỡng chốt, sĩ số 3-5, hạn đăng ký"
                elif "Đồng bộ FAP & Sinh phòng:" in txt or "Import CSV" in txt:
                    p.text = "• Đồng bộ Danh sách FAP: Import file danh sách từ FAP (.csv, .xlsx, .xls XML), đối soát sinh viên chưa có nhóm, tự động tạo phòng còn thiếu (BR-01, BR-09)."
                elif "Điều phối Thuật toán" in txt or "Phân bổ 8 SV" in txt:
                    p.text = "• Thuật toán Phân phối SV lẻ: Chạy DistributionPlanner tối ưu hóa 5 trục kỹ năng, tự động bầu Leader theo điểm Quản lý và chốt sổ học kỳ (BR-31–36)."
                elif "Sự cố" in txt or "Crash" in txt:
                    p.text = "• Giám sát Sự cố (Crash Logs): Đọc danh sách crash_logs từ Firestore gửi về từ thiết bị di động, xem chi tiết lỗi và stacktrace."

# ─────────────────────────────────────────────────────────────
# SLIDE 6: Main Actors Table
# ─────────────────────────────────────────────────────────────
def update_slide_6(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                if "JWT Role Claims" in p.text:
                    p.text = p.text.replace("JWT Role Claims", "Firebase Authentication & Firestore Security Rules")
                if "gRPC" in p.text or "Cổng 5005" in p.text:
                    p.text = "Distribution Planner (Thuật toán cân bằng 5 kỹ năng)"
                if "MailHog" in p.text:
                    p.text = "Firebase Cloud Messaging (FCM HTTP v1)"
        if s.has_table:
            table = s.table
            if len(table.rows) >= 4:
                # Row 1: Student
                table.rows[1].cells[0].text = "Sinh viên\n(Student)"
                table.rows[1].cells[1].text = "Thiết bị Di động Android (Flutter App)"
                table.rows[1].cells[2].text = "Đăng nhập Google @fpt.edu.vn, hoàn thiện 5 kỹ năng, tìm phòng, vào thẳng / nộp đơn apply, bỏ phiếu bầu thành viên, xuất PDF báo cáo."
                table.rows[1].cells[3].text = "Firebase Auth (ID Token Google) · Firestore Rules: auth.token.email.matches('.*@fpt.edu.vn') · Chỉ sửa profile chính chủ."
                
                # Row 2: Leader
                table.rows[2].cells[0].text = "Trưởng nhóm\n(Leader)"
                table.rows[2].cells[1].text = "Thiết bị Di động Android (Flutter App)"
                table.rows[2].cells[2].text = "Đại diện nhóm, mở đợt biểu quyết duyệt ứng viên, chốt nhóm sớm khi đủ từ 3 thành viên trở lên, đại diện nộp đề án."
                table.rows[2].cells[3].text = "Firestore Rules: request.auth.uid == room.leaderId · Thực thi atomic runTransaction khi chốt nhóm hoặc duyệt đơn."
                
                # Row 3: Lecturer / Moderator
                table.rows[3].cells[0].text = "Giảng viên &\nĐiều phối viên"
                table.rows[3].cells[1].text = "Cổng Web Quản trị (Flutter Web)"
                table.rows[3].cells[2].text = "Tạo môn học (Space), import danh sách FAP (.csv/.xlsx/.xls), chạy phân phối sinh viên lẻ cân bằng kỹ năng, duyệt đổi nhóm, xem Crash Logs."
                table.rows[3].cells[3].text = "Firebase Auth @fe.edu.vn hoặc role == 'admin' · Quyền ghi toàn bộ collection spaces, enrollments và duyệt transfer_requests."

# ─────────────────────────────────────────────────────────────
# SLIDE 7: Main Features
# ─────────────────────────────────────────────────────────────
def update_slide_7(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "Actor: Moderator & Hệ thống (Auth, Group, FCM Notification)" in txt or "Actor: Moderator & Hệ thống (Auth, Group, MailHog)" in txt:
                    p.text = "• Actor: Giảng viên / Moderator (Flutter Web) & Firebase Backend"
                elif "Actor: Sinh viên nộp đơn, Thành viên & Leader" in txt:
                    p.text = "• Actor: Sinh viên ứng tuyển & Trưởng nhóm (Flutter Android App)"
                elif "Actor: Moderator, Group Service & Matching gRPC" in txt or "Actor: Moderator" in txt and "Distribution Planner" in txt:
                    p.text = "• Actor: Giảng viên (Flutter Web) & DistributionPlanner (Thuật toán tham lam)"
                elif "Actor: Sinh viên yêu cầu, Moderator & Giảng viên" in txt:
                    p.text = "• Actor: Sinh viên (Mobile App) & Giảng viên (Web Admin)"
                elif "gRPC" in txt:
                    p.text = p.text.replace("gRPC", "Distribution Planner")

# ─────────────────────────────────────────────────────────────
# SLIDE 9: State Machine
# ─────────────────────────────────────────────────────────────
def update_slide_9(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "Chuyển không hợp lệ trả 409;" in txt or "Group.Services.Tests" in txt:
                    p.text = "Chuyển trạng thái được bảo vệ bằng runTransaction và RoomRules; kiểm thử 100% trong group_service_test.dart."
                elif "Trạng thái nghiệp vụ lưu ở Group Service (DB)" in txt:
                    p.text = "Trạng thái phòng lưu tập trung tại Cloud Firestore (rooms/{roomId}), đồng bộ tức thì hai chiều qua snapshots()."

# ─────────────────────────────────────────────────────────────
# SLIDE 10: System Architecture
# ─────────────────────────────────────────────────────────────
def update_slide_10(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "Web App → Gateway" in txt:
                    p.text = "Mobile Client (Android App) & Web Client (Flutter Web) kết nối trực tiếp Firebase Cloud Platform."
                elif "Đồng bộ: REST" in txt:
                    p.text = "Realtime Streaming: Cloud Firestore snapshots() phát dữ liệu tức thì hai chiều giữa Mobile và Web."
                elif "Triển khai bằng Docker Compose" in txt or "Bảo mật & Phân quyền:" in txt:
                    p.text = "Bảo mật & Phân quyền: Google Sign-in cấp ID Token; Firestore Security Rules kiểm soát quyền tại server."
                elif "Mỗi service một database riêng" in txt or "Thông báo & File:" in txt:
                    p.text = "Thông báo & File: Server Python (Admin SDK) gửi FCM HTTP v1; Cloudinary lưu trữ file PDF báo cáo an toàn."
                elif "Sơ đồ Container" in txt:
                    p.text = "Sơ đồ Kiến trúc Hệ thống Mobile (PRM393 - MVVM & Firebase)"
                elif "draw.io" in txt:
                    p.text = "Architecture: Flutter Android App · Flutter Web · Firebase Platform · Cloudinary"

# ─────────────────────────────────────────────────────────────
# SLIDE 11: Technology Stack Table
# ─────────────────────────────────────────────────────────────
def update_slide_11(slide):
    for s in slide.shapes:
        if s.has_table:
            table = s.table
            rows_data = [
                ("Mobile App", "Flutter 3.x • Dart • Provider (MVVM) • Material 3",
                 "Ứng dụng di động Android cho sinh viên; quản lý trạng thái bằng Provider theo kiến trúc MVVM; chạy mượt mà trên thiết bị Android thật qua USB/APK."),
                ("Web Admin", "Flutter Web (main_admin.dart) • Responsive UI • Provider",
                 "Giao diện Web chuyên dụng cho Giảng viên & Moderator; quản lý môn học, chốt sổ, duyệt chuyển nhóm và import FAP từ file .csv, .xlsx, .xls XML."),
                ("Database", "Cloud Firestore (NoSQL) • Security Rules • runTransaction",
                 "Cơ sở dữ liệu Realtime NoSQL lưu trữ Room, Đơn Apply, Hồ sơ; bảo vệ bằng Security Rules; runTransaction chống race condition tranh slot cuối."),
                ("Auth & FCM", "Firebase Auth (Google Sign-In) • Firebase Cloud Messaging (FCM HTTP v1)",
                 "Đăng nhập Google bằng email trường (@fpt.edu.vn, @fe.edu.vn); bắn thông báo đẩy FCM nổ chuông trên điện thoại khi có đơn Apply hoặc có kết quả vote."),
                ("Cloud Services", "Firebase Crashlytics • Remote Config • Cloudinary CDN",
                 "Ghi nhận crash realtime trên mobile; đổi banner thông báo khẩn cấp từ xa; upload và lưu trữ file PDF báo cáo đề án an toàn qua Unsigned Preset."),
                ("Testing & Server", "Flutter Test Suite (102 Tests Pass 100%) • Python Admin SDK",
                 "Kiểm thử tự động 102 unit & widget tests cho toàn bộ ViewModel và Domain rules; server Python nghe sự kiện Firestore và gửi FCM chuẩn HTTP v1.")
            ]
            for i, data in enumerate(rows_data):
                if i + 1 < len(table.rows):
                    row = table.rows[i + 1]
                    for c_idx, val in enumerate(data):
                        if c_idx < len(row.cells):
                            cell = row.cells[c_idx]
                            cell.text = val
                            if cell.text_frame.paragraphs:
                                p = cell.text_frame.paragraphs[0]
                                p.font.name = FONT_NAME
                                p.font.size = Pt(10 if c_idx == 2 else 11)

# ─────────────────────────────────────────────────────────────
# SLIDE 13: Sequence Diagram (UI-04) — Join Request & Peer Voting
# ─────────────────────────────────────────────────────────────
def update_slide_13(slide):
    # Adjust subtitle
    for s in slide.shapes:
        if s.has_text_frame and "Một tương tác tiêu biểu" in s.text_frame.text:
            s.text_frame.paragraphs[0].text = "Một tương tác tiêu biểu giữa View, ViewModel, Firestore và hệ thống thông báo FCM."

    # Adjust the 3 right-hand side text boxes so they NEVER overlap
    for s in slide.shapes:
        if not s.has_text_frame:
            continue
        txt = s.text_frame.text
        if "1. THÔNG TIN TƯƠNG TÁC" in txt:
            s.top = Pt(140)
            s.height = Pt(125)
            tf = s.text_frame
            tf.word_wrap = True
            tf.clear()
            p0 = tf.paragraphs[0]
            set_para(p0, "1. THÔNG TIN TƯƠNG TÁC (UI-04)", 11, bold=True, color=COLOR_PURPLE)
            p1 = tf.add_paragraph()
            set_para(p1, "• Tác nhân (Actor): Sinh viên (Student) nộp đơn & Trưởng nhóm (Leader)", 10)
            p2 = tf.add_paragraph()
            set_para(p2, "• Điểm chạm UI: RoomDetailScreen & ApplicationDialog (Flutter)", 10)
            p3 = tf.add_paragraph()
            set_para(p3, "• Hàm chính: RoomDetailViewModel.applyToRoom(roomId, message)", 10)
            p4 = tf.add_paragraph()
            set_para(p4, "• Backend: Firestore ghi collection applications/{id} (status: pending)", 10)
        elif "2. RÀNG BUỘC NGHIỆP VỤ" in txt:
            s.top = Pt(280)
            s.height = Pt(210)
            tf = s.text_frame
            tf.word_wrap = True
            tf.clear()
            p0 = tf.paragraphs[0]
            set_para(p0, "2. RÀNG BUỘC NGHIỆP VỤ (BUSINESS RULES)", 11, bold=True, color=COLOR_PURPLE)
            p1 = tf.add_paragraph()
            set_para(p1, "• BR-17 (Giới hạn đơn): Sinh viên chỉ được gửi tối đa 3 đơn pending cùng lúc.", 10)
            p2 = tf.add_paragraph()
            set_para(p2, "• BR-25 (Quyền hạn): Trưởng nhóm mở đợt vote; các thành viên vote Chấp nhận/Từ chối.", 10)
            p3 = tf.add_paragraph()
            set_para(p3, "• BR-28 (Trần sĩ số): Kiểm tra members.length < maxSize (5); tự động khóa tuyển.", 10)
            p4 = tf.add_paragraph()
            set_para(p4, "• BR-30 (Trạng thái): Phòng phải ở trạng thái open hoặc group (chưa locked).", 10)
            p5 = tf.add_paragraph()
            set_para(p5, "• BR-27 (Đồng bộ đơn): Vào nhóm thành công, tự động hủy các đơn chờ ở phòng khác.", 10)
        elif "3. CƠ CHẾ RẼ NHÁNH" in txt:
            s.top = Pt(510)
            s.height = Pt(210)
            tf = s.text_frame
            tf.word_wrap = True
            tf.clear()
            p0 = tf.paragraphs[0]
            set_para(p0, "3. CƠ CHẾ RẼ NHÁNH & CONCURRENCY TRANSACTION", 11, bold=True, color=COLOR_PURPLE)
            p1 = tf.add_paragraph()
            set_para(p1, "• Nhánh Lỗi [Đầy phòng]: runTransaction rollback an toàn; SnackBar hiển thị thông báo lỗi.", 10)
            p2 = tf.add_paragraph()
            set_para(p2, "• Nhánh Hợp lệ [Duyệt]: runTransaction commit nguyên tử: thêm member vào rooms.members, tạo memberships/{spaceId_uid}, đổi trạng thái đơn sang accepted.", 10)
            p3 = tf.add_paragraph()
            set_para(p3, "• Bất đồng bộ (FCM): Server Python Admin SDK bắt trigger Firestore → bắn Push Notification nổ chuông ngay trên điện thoại ứng viên và trưởng nhóm.", 10)

# ─────────────────────────────────────────────────────────────
# SLIDE 14: Class Design (MVVM in Flutter) — FULL REDESIGN LEFT PANEL
# ─────────────────────────────────────────────────────────────
def update_slide_14(slide):
    # Remove all messy micro-textboxes on the left
    to_remove = []
    for s in slide.shapes:
        if s.name.startswith("TextBox") and s.has_text_frame:
            if s.left.pt < 550 and s.top.pt > 180:
                to_remove.append(s)
            elif "Class Diagram" in s.text_frame.text or "Controller xử lý HTTP" in s.text_frame.text:
                to_remove.append(s)
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    # Subtitle fix
    for s in slide.shapes:
        if s.has_text_frame and ("Minh họa phân tách trách nhiệm" in s.text_frame.text or "Mình họa phân tách trách nhiệm" in s.text_frame.text):
            s.text_frame.paragraphs[0].text = "Minh họa phân tách trách nhiệm theo kiến trúc MVVM trong Flutter qua luồng Join Request & Peer Voting."

    # Add ONE clean, beautifully formatted panel on the left
    tb = slide.shapes.add_textbox(Pt(54), Pt(185), Pt(505), Pt(570))
    tf = tb.text_frame
    tf.word_wrap = True
    tf.margin_left = Pt(4)
    tf.margin_top = Pt(4)
    tf.margin_right = Pt(4)
    tf.margin_bottom = Pt(4)

    content = [
        ("PHÂN TÁCH TRÁCH NHIỆM THEO KIẾN TRÚC MVVM", True, 13, COLOR_PURPLE),
        ("1. VIEW — Màn hình & Giao diện hiển thị (Screens & Widgets)", True, 10.5, COLOR_DARK),
        ("• RoomDetailScreen, ApplicationDetailScreen, MyGroupScreen, RoomCard, MemberTile.", False, 9.5, COLOR_MUTED),
        ("• Lắng nghe ViewModel qua context.watch<T>(), vẽ 4 trạng thái giao diện (Loading, Data, Empty, Error).", False, 9.5, COLOR_MUTED),

        ("2. VIEWMODEL — Quản lý trạng thái & Điều phối luồng (ChangeNotifier)", True, 10.5, COLOR_DARK),
        ("• RoomDetailViewModel, SpaceViewModel, AuthViewModel, AdminViewModel.", False, 9.5, COLOR_MUTED),
        ("• Nắm giữ UI State, gọi Service thực thi nghiệp vụ và phát notifyListeners() cập nhật giao diện tức thì.", False, 9.5, COLOR_MUTED),

        ("3. DOMAIN & RULES — Nghiệp vụ thuần Dart (Độc lập 100% với UI & Firebase)", True, 10.5, COLOR_DARK),
        ("• RoomRules: Kiểm tra 37 Business Rules (BR-01 → BR-37), trần sĩ số 3–5, quyền Leader, trạng thái phòng.", False, 9.5, COLOR_MUTED),
        ("• DistributionPlanner: Thuật toán tham lam đa mục tiêu cân bằng 5 kỹ năng cho sinh viên lẻ.", False, 9.5, COLOR_MUTED),
        ("• RosterParser: Trích xuất danh sách FAP từ Excel SpreadsheetML (.xls), .xlsx và CSV.", False, 9.5, COLOR_MUTED),

        ("4. SERVICE LAYER — Giao tiếp Firebase Cloud Platform & Dịch vụ ngoài", True, 10.5, COLOR_DARK),
        ("• GroupService: Thực thi Firestore runTransaction chống race condition tranh slot cuối.", False, 9.5, COLOR_MUTED),
        ("• NotificationService: Đồng bộ FCM Token thiết bị, tiếp nhận và điều hướng push notification.", False, 9.5, COLOR_MUTED),
        ("• FileStorageService: Tải biên bản báo cáo PDF lên Cloudinary CDN qua Unsigned Upload Preset.", False, 9.5, COLOR_MUTED),

        ("5. MODELS / ENTITIES — Mô hình dữ liệu bất biến (Immutable Data)", True, 10.5, COLOR_DARK),
        ("• Room, Application, AppUser, Space, LeaderElection, TransferRequest, CrashLog.", False, 9.5, COLOR_MUTED),
        ("• Ánh xạ hai chiều với document Firestore qua toMap() và fromFirestore() an toàn kiểu dữ liệu.", False, 9.5, COLOR_MUTED),
    ]

    tf.text = ""
    for idx, (text, is_bold, size, color) in enumerate(content):
        p = tf.paragraphs[0] if idx == 0 else tf.add_paragraph()
        set_para(p, text, size=size, bold=is_bold, color=color, space_after=1.5, space_before=4 if is_bold and idx > 0 else 0)

    # Caption note below the right diagram
    note_tb = slide.shapes.add_textbox(Pt(580), Pt(620), Pt(700), Pt(35))
    np = note_tb.text_frame.paragraphs[0]
    set_para(np, "Kiến trúc MVVM phân tách tuyệt đối: View chỉ vẽ giao diện; ViewModel nắm state; Domain chứa luật thuần; Service gọi Firebase & Cloudinary.", 9.5, italic=True, color=COLOR_MUTED)

# ─────────────────────────────────────────────────────────────
# SLIDE 15: Database Design 1/2 (Conceptual Firestore NoSQL) — FULL REDESIGN RIGHT PANEL
# ─────────────────────────────────────────────────────────────
def update_slide_15(slide):
    # Remove the 15 overlapping micro-textboxes on the right
    to_remove = []
    for s in slide.shapes:
        if s.name.startswith("TextBox") and s.has_text_frame:
            if s.left.pt > 930 and s.top.pt > 100:
                to_remove.append(s)
            elif "27 thực thể" in s.text_frame.text:
                # Update subtitle
                s.text_frame.paragraphs[0].text = "Mô hình Dữ liệu NoSQL Cloud Firestore: 7 Core Collections & Sub-collections phục vụ Realtime Mobile."
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    # Fix slide title
    for s in slide.shapes:
        if s.has_text_frame and "Database Design 1/2" in s.text_frame.text:
            s.text_frame.paragraphs[0].text = "Slide 14 Database Design 1/2 — Mô hình Khái niệm NoSQL (Cloud Firestore)"

    # Add ONE clean, beautifully structured panel on the right
    tb = slide.shapes.add_textbox(Pt(940), Pt(120), Pt(450), Pt(640))
    tf = tb.text_frame
    tf.word_wrap = True
    tf.margin_left = Pt(4)
    tf.margin_top = Pt(4)
    tf.margin_right = Pt(4)
    tf.margin_bottom = Pt(4)

    collections = [
        ("CÁC COLLECTION VÀ MỐI QUAN HỆ TRONG FIRESTORE", True, 13, COLOR_PURPLE),
        ("1. users/{uid} & fcm_tokens/{token}", True, 10.5, COLOR_DARK),
        ("• Lưu thông tin cá nhân, email trường, điểm 5 kỹ năng (tech, mgt, design, mkt, sale) và cam kết điều khoản. Sub-collection fcm_tokens lưu danh sách token thiết bị nổ chuông FCM.", False, 9.5, COLOR_MUTED),

        ("2. spaces/{spaceId} & enrollments/{spaceId_mssv}", True, 10.5, COLOR_DARK),
        ("• Cấu hình môn học theo kỳ (EXE101/201, sĩ số max 5, ngưỡng 3, hạn đăng ký). Sub-collection enrollments lưu danh sách FAP import từ file Excel để đối soát quyền đăng nhập (BR-01).", False, 9.5, COLOR_MUTED),

        ("3. rooms/{roomId} & elections/{electionId}", True, 10.5, COLOR_DARK),
        ("• Lưu thông tin phòng, mảng members chứa danh sách UID thành viên, leaderId, trạng thái (open, group, locked). Sub-collection elections quản lý các phiên bầu cử Leader kín.", False, 9.5, COLOR_MUTED),

        ("4. applications/{applicationId}", True, 10.5, COLOR_DARK),
        ("• Đơn xin gia nhập phòng, tin nhắn nộp đơn, trạng thái (pending/accepted/rejected), và map votes: {uid: bool} ghi nhận phiếu biểu quyết của từng thành viên trong nhóm.", False, 9.5, COLOR_MUTED),

        ("5. memberships/{spaceId_uid}", True, 10.5, COLOR_DARK),
        ("• Ánh xạ 1-1 giữa Sinh viên và Phòng trong một môn; Document ID dạng spaceId_uid đảm bảo bằng mã nguồn sinh viên không thể vào 2 phòng cùng môn tại một thời điểm (BR-06).", False, 9.5, COLOR_MUTED),

        ("6. transfer_requests/{id} & crash_logs/{id}", True, 10.5, COLOR_DARK),
        ("• transfer_requests: Đơn xin chuyển nhóm sau khi đã khóa sổ, chờ Giảng viên phê duyệt.\n• crash_logs: Báo cáo sự cố từ ứng dụng mobile gửi lên Firestore cho Giảng viên xem trên Web.", False, 9.5, COLOR_MUTED),

        ("ĐẶC TRƯNG THIẾT KẾ NOSQL TRONG DỰ ÁN", True, 10.5, COLOR_ORANGE),
        ("• Denormalization: Nhúng mảng members [uid] trong rooms để đọc 1 lần hiển thị ngay toàn bộ danh sách phòng trên Mobile, triệt tiêu N+1 query.\n• Concurrency Lock: Mọi thao tác thay đổi thành viên đều đi qua Firestore runTransaction để đảm bảo tính nguyên tử tuyệt đối.", False, 9.5, COLOR_MUTED),
    ]

    tf.text = ""
    for idx, (text, is_bold, size, color) in enumerate(collections):
        p = tf.paragraphs[0] if idx == 0 else tf.add_paragraph()
        set_para(p, text, size=size, bold=is_bold, color=color, space_after=2, space_before=4 if is_bold and idx > 0 else 0)

# ─────────────────────────────────────────────────────────────
# SLIDE 16: Database Design 2/2 (Physical Schema & Rules) — FULL REDESIGN RIGHT PANEL
# ─────────────────────────────────────────────────────────────
def update_slide_16(slide):
    # Remove ALL the 48 chaotic micro textboxes on Slide 16
    to_remove = []
    for s in slide.shapes:
        if s.name.startswith("TextBox") and s.has_text_frame:
            # Keep slide title and footer standard
            txt = s.text_frame.text.strip()
            if "Từ cấu trúc logic" in txt or "FPT University" in txt or "16" == txt:
                continue
            to_remove.append(s)
    print(f"Slide 16: Removing {len(to_remove)} micro shapes...")
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    # Update Slide Title
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                if "Database Design 1/2" in p.text or "ÁNH XẠ LOGICAL" in p.text:
                    p.text = "Slide 15 Database Design 2/2 — Firestore Schema, Rules & Concurrency"
                elif "Từ cấu trúc logic sang database" in p.text:
                    p.text = "Hiện thực hóa schema vật lý NoSQL, cơ chế bảo vệ Security Rules và giải pháp runTransaction."

    # Right side: Add a clean Table for the Physical Schema (x=880, y=105, width=515, height=250)
    rows = 7
    cols = 3
    table_shape = slide.shapes.add_table(rows, cols, Pt(880), Pt(105), Pt(515), Pt(240))
    table = table_shape.table
    table.columns[0].width = Pt(130)
    table.columns[1].width = Pt(175)
    table.columns[2].width = Pt(210)

    headers = [("Collection / Doc", True), ("Key Fields & Physical Types", True), ("Ràng buộc & Security Rules", True)]
    for ci, (h_text, _) in enumerate(headers):
        cell = table.cell(0, ci)
        cell.text = h_text
        p = cell.text_frame.paragraphs[0]
        set_para(p, h_text, 10, bold=True, color=COLOR_WHITE)
        cell.fill.solid()
        cell.fill.fore_color.rgb = COLOR_PURPLE

    schema_data = [
        ("users/{uid}", "email (String), skills (Map: 5 int), role (String)", "Chỉ chính chủ cập nhật profile; email bắt buộc @fpt.edu.vn hoặc @fe.edu.vn"),
        ("spaces/{id}", "name (String), maxSize (int: 5), isLocked (bool)", "Chỉ Giảng viên/Admin có quyền ghi; sinh viên chỉ có quyền đọc (Read-only)"),
        ("rooms/{id}", "members (Array<String>), leaderId, status (String)", "Sĩ số 3–5; ghi qua runTransaction; chỉ Leader mới được đổi tên và chốt nhóm"),
        ("applications/{id}", "roomId, applicantId, votes (Map<String, bool>)", "1 đơn pending/phòng; chỉ ứng viên được hủy đơn; chỉ thành viên phòng mới được vote"),
        ("memberships/{id}", "spaceId_uid (PK String), roomId, joinedAt", "Unique Key ${spaceId}_${uid} chống sinh viên gia nhập 2 phòng cùng lúc (BR-06)"),
        ("transfer_requests", "fromRoomId, toRoomId, studentId, status", "Chỉ gửi khi Space đã Locked; chỉ Giảng viên trên Web mới được Approve/Reject"),
    ]

    for ri, row_data in enumerate(schema_data):
        for ci, val in enumerate(row_data):
            cell = table.cell(ri + 1, ci)
            cell.text = val
            p = cell.text_frame.paragraphs[0]
            set_para(p, val, 9, bold=(ci == 0), color=COLOR_DARK)
            cell.fill.solid()
            cell.fill.fore_color.rgb = RGBColor(245, 245, 250) if ri % 2 == 0 else COLOR_WHITE

    # Underneath Table: Add TWO clean cards for Security Rules and Concurrency Transaction
    card_tb = slide.shapes.add_textbox(Pt(880), Pt(360), Pt(515), Pt(390))
    ctf = card_tb.text_frame
    ctf.word_wrap = True
    ctf.margin_left = Pt(4)
    ctf.margin_top = Pt(4)
    ctf.margin_right = Pt(4)
    ctf.margin_bottom = Pt(4)

    notes = [
        ("BẢO VỆ DỮ LIỆU BẰNG FIRESTORE SECURITY RULES", True, 11, COLOR_PURPLE),
        ("• Kiểm soát xác thực máy chủ: request.auth != null bảo vệ toàn bộ collection tại server Firebase.", False, 9.5, COLOR_MUTED),
        ("• Phân quyền theo Email Domain: Sinh viên (@fpt.edu.vn) chỉ thao tác phòng/đơn; Giảng viên (@fe.edu.vn) có quyền quản trị môn và duyệt chuyển nhóm.", False, 9.5, COLOR_MUTED),
        ("• Chống sửa trái phép: Client không thể tự ý ghi đè hồ sơ người khác hoặc tự đổi leaderId nếu không phải Leader hợp lệ.", False, 9.5, COLOR_MUTED),

        ("KIỂM SOÁT ĐỒNG THỜI (CONCURRENCY) QUA RUNTRANSACTION", True, 11, COLOR_ORANGE),
        ("• Bài toán Race Condition: Nhiều sinh viên cùng bấm 'Vào phòng' hoặc nhiều Leader cùng duyệt đơn tranh slot thứ 5 của phòng trong cùng 1 micro-giây.", False, 9.5, COLOR_MUTED),
        ("• Cơ chế Optimistic Locking: GroupService dùng FirebaseFirestore.instance.runTransaction đọc snapshot phòng, kiểm tra members.length < maxSize, rồi mới atomic commit ghi dữ liệu.", False, 9.5, COLOR_MUTED),
        ("• Xử lý xung đột: Nếu dữ liệu bị thay đổi giữa lúc đọc và ghi, Firestore tự động retry hoặc báo lỗi phòng đã đủ người mà không gây tràn sĩ số.", False, 9.5, COLOR_MUTED),

        ("MINH CHỨNG TRIỂN KHAI VÀ KIỂM THỬ THỰC TẾ", True, 11, COLOR_GREEN),
        ("• Cấu hình: File firestore.rules triển khai trực tiếp lên Firebase Cloud qua lệnh: firebase deploy --only firestore:rules.", False, 9.5, COLOR_MUTED),
        ("• Kiểm chứng: 102/102 bài unit & widget test pass 100% trong flutter test, kiểm thử toàn bộ các ca xung đột transaction.", False, 9.5, COLOR_MUTED),
    ]

    ctf.text = ""
    for idx, (text, is_bold, size, color) in enumerate(notes):
        p = ctf.paragraphs[0] if idx == 0 else ctf.add_paragraph()
        set_para(p, text, size=size, bold=is_bold, color=color, space_after=1.5, space_before=4 if is_bold and idx > 0 else 0)

# ─────────────────────────────────────────────────────────────
# SLIDE 17: Traceability Matrix (102 Tests & 37 BRs)
# ─────────────────────────────────────────────────────────────
def update_slide_17(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "TC-SP01" in txt and "12 tests" in txt:
                    p.text = "TC-ADM01–24\nadmin_test (24)"
                elif "TC-US01" in txt and "20 tests" in txt:
                    p.text = "TC-GRP01–25\ngroup_service (25)"
                elif "TC-EL01" in txt and "18 tests" in txt:
                    p.text = "TC-RST01–22\nroster_test (22)"
                elif "TC-MC01" in txt and "16 tests" in txt:
                    p.text = "TC-SPM01–10\nspace_vm (10)"
                elif "TC-RP01" in txt and "14 tests" in txt:
                    p.text = "TC-NTF01–15\nnotification (15)"
                elif "EF Core" in txt:
                    p.text = "Firestore runTransaction"
                elif "CourseSpacesPage" in txt:
                    p.text = "AdminPages (Web)"
                elif "CourseSpaceService" in txt:
                    p.text = "AdminService"
                elif "UI React → API Gateway" in txt:
                    p.text = "Flutter UI → ViewModel → FirebaseService → Firestore Collection. Ánh xạ nhất quán 100% theo thiết kế MVVM."

# ─────────────────────────────────────────────────────────────
# SLIDE 18 - 22: Demo Workflows
# ─────────────────────────────────────────────────────────────
def update_slides_18_22(prs):
    # Slide 18: Demo Overview
    s18 = prs.slides[17]
    for s in s18.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                if "Phân phối gRPC" in p.text:
                    p.text = p.text.replace("Phân phối gRPC & Chốt sổ", "Phân phối SV Lẻ & Chốt sổ")
                if "MailHog" in p.text:
                    p.text = p.text.replace("MailHog", "FCM Notification")

    # Slides 19 - 22: Demo WF-01 to WF-04
    for idx in range(18, 22):
        slide = prs.slides[idx]
        for s in slide.shapes:
            if s.has_text_frame:
                for p in s.text_frame.paragraphs:
                    txt = p.text
                    if "gRPC" in txt:
                        p.text = txt.replace("Matching gRPC", "Distribution Planner").replace("gRPC Service", "Admin Service").replace("gRPC", "Thuật toán Phân phối")
                    if "MailHog" in p.text:
                        p.text = p.text.replace("MailHog", "FCM Notification")
                    if "moderator@fpt.edu.vn" in p.text:
                        p.text = p.text.replace("moderator@fpt.edu.vn", "moderator@fe.edu.vn")
                    if "API /api/" in p.text:
                        p.text = p.text.replace("API /api/join-requests", "Firestore applications collection").replace("API /api/groups", "Firestore rooms collection")

# ─────────────────────────────────────────────────────────────
# SLIDE 23: Testing & Verification
# ─────────────────────────────────────────────────────────────
def update_slide_23(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "314" in txt:
                    p.text = "102"
                elif "22/37" in txt:
                    p.text = "37/37"
                elif "BR có unit test" in txt:
                    p.text = "BRs được kiểm chứng"
                elif "8/8 project test pass" in txt or "Chưa có E2E" in txt:
                    p.text = "102/102 test cases pass 100% trong 16 giây trên Flutter Test Suite."
                elif "Minh chứng:" in txt:
                    p.text = "Minh chứng: Lệnh flutter test pass 100%, logcat ADB trên điện thoại thật, chuông notification FCM nổ thực tế."

# ─────────────────────────────────────────────────────────────
# SLIDE 24: Conclusion / Requirements vs Delivered
# ─────────────────────────────────────────────────────────────
def update_slide_24(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "REST API + Firebase ID Token" in txt or "REST API + JWT" in txt:
                    p.text = "Kiến trúc MVVM + Provider"
                elif "4 Core, 10 RFC" in txt:
                    p.text = "Tách biệt rõ Model - View - ViewModel; 102 bài test kiểm thử logic tự động độc lập giao diện."
                elif "Brevo / FCM" in txt or "11 Redis consumers" in txt or "11 Firestore consumers" in txt:
                    p.text = "Server Python Admin SDK gửi FCM HTTP v1; điện thoại nổ chuông và mở đúng Room."
                elif "Outbox Pattern" in txt or "matching proto" in txt:
                    p.text = "Cloud Firestore NoSQL & runTransaction chống race condition tranh suất vào phòng."
                elif "AppointmentHub" in txt or "SignalR" in txt:
                    p.text = "Crashlytics báo lỗi realtime; Remote Config đổi banner thông báo từ xa tức thì."
                elif "Docker & Cloud" in txt or "Lưu trữ File Cloudinary" in txt:
                    p.text = "Lưu trữ File Cloudinary"
                elif "Khoảng 11 local containers" in txt:
                    p.text = "Unsigned Upload Preset lưu file PDF báo cáo đề án; an toàn không lộ API Secret trong APK."
                elif "React 18 + Vite" in txt or "Web Admin & Portals" in txt:
                    p.text = "Flutter Web Admin (main_admin.dart)"
                elif "cổng Student, Lecturer" in txt:
                    p.text = "Web quản trị cho Giảng viên: Import FAP Excel, phân phối sinh viên lẻ và chốt sổ."
                elif "Google Gemini API" in txt:
                    p.text = "Thuật toán phân phối sinh viên lẻ tối ưu hóa 5 trục kỹ năng (Tech, Mgt, Design, Mkt, Sale)."
                elif "xUnit, Moq" in txt:
                    p.text = "102/102 bài kiểm thử Flutter Unit & Widget tests kiểm chứng toàn bộ 37 Business Rules."
                elif "7 SERVICES" in txt:
                    p.text = "MOBILE FIRST"
                elif "7 dịch vụ" in txt or ".NET" in txt:
                    p.text = "Flutter Mobile (Android) & Flutter Web (Admin)"
                elif "Auth (5001)" in txt or "User (5002)" in txt:
                    p.text = "Flutter Mobile App (Sinh viên) + Flutter Web (Giảng viên) + Python FCM Server."
                elif "6 DATABASES" in txt:
                    p.text = "FIRESTORE NOSQL"
                elif "ExeAuthDb" in txt or "ExeUserDb" in txt or "6 cơ sở dữ liệu" in txt or "SQL Server" in txt:
                    p.text = "users, spaces, rooms, applications, memberships, transfer_requests, crash_logs."
                elif "100% yêu cầu kỹ thuật" in txt:
                    p.text = "100% yêu cầu kỹ thuật PRM393 & Rubric chấm Lab 3 của Thầy Phương đã hoàn thành."

# ─────────────────────────────────────────────────────────────
# SLIDE 25: Limitations & Future Work
# ─────────────────────────────────────────────────────────────
def update_slide_25(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "Gemini API Free Quota" in txt:
                    p.text = "Chế độ Offline toàn phần"
                elif "Giới hạn RPM/TPM của Gemini API" in txt:
                    p.text = "App có bộ đệm cache Firestore cơ bản nhưng cần hoàn thiện cơ chế giải quyết xung đột khi mất mạng dài ngày."
                elif "Container Footprint" in txt:
                    p.text = "Môi trường Nền tảng iOS"
                elif "Khoảng 11 containers" in txt:
                    p.text = "Hiện tại app tập trung tối ưu cho Android; bản iOS cần thiết bị macOS và tài khoản Apple Developer để cấu hình APNs."
                elif "Kubernetes & Cost" in txt:
                    p.text = "Đóng gói hoàn chỉnh bản iOS"
                elif "Trễn khai Helm" in txt:
                    p.text = "Cấu hình chứng chỉ APNs và build bản chạy trên iPhone khi có máy tính macOS."
                elif "Direct FAP" in txt or "Direct FAP / LMS" in txt:
                    p.text = "Chuyển Server lên Cloud Functions"
                elif "Tích hợp dữ liệu hai chiều" in txt:
                    p.text = "Chuyển script Python lắng nghe Firestore sang Firebase Cloud Functions để tự động hóa 100% trên đám mây."

# ─────────────────────────────────────────────────────────────
# SLIDE 26: 4 Lessons Learned
# ─────────────────────────────────────────────────────────────
def update_slide_26(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "Design Before Coding" in txt:
                    p.text = "Kỷ luật Kiến trúc MVVM trong Flutter"
                elif "Chuẩn hóa 34 Business Rules" in txt:
                    p.text = "Tách bạch rõ ràng ViewModel và Service giúp việc viết và chạy 102 bài unit test cực kỳ nhanh, độc lập hoàn toàn với giao diện UI."
                elif "Redis Backplane Tames Realtime" in txt or "Firestore Realtime Stream Tames" in txt:
                    p.text = "Xử lý Concurrency bằng Firestore Transactions"
                elif "Kết hợp SignalR" in txt or "Kết hợp Firestore" in txt:
                    p.text = "Sử dụng runTransaction giải quyết triệt để bài toán tranh chấp slot cuối cùng khi nhiều sinh viên cùng bấm vào nhóm tại một thời điểm."
                elif "Environment Parity Across Stack" in txt or "Làm chủ Vòng đời" in txt:
                    p.text = "Làm chủ Vòng đời Push Notification (FCM)"
                elif "Nắm vững 3 trạng thái" in txt:
                    p.text = "Nắm vững 3 trạng thái ứng dụng (Foreground, Background, Terminated) để xử lý hiển thị banner cục bộ và điều hướng mở đúng phòng."
                elif "Phase Delivery + Strict Reviews" in txt or "Bảo mật Đám mây" in txt:
                    p.text = "Bảo mật Đám mây (Cloud Security First)"
                elif "Tuyệt đối không nhúng" in txt or "Chia dự án thành 6 giai đoạn" in txt:
                    p.text = "Tuyệt đối không nhúng Service Account hoặc Private Key vào APK Android; luôn sử dụng Security Rules và Unsigned Presets."
                elif "Docker" in txt or "JWT" in txt or "Environment" in txt or "Protobuf" in txt:
                    p.text = "MVVM • Firestore Transactions • FCM Lifecycle • Cloud Security"

# ─────────────────────────────────────────────────────────────
# SLIDE 27: Thank You
# ─────────────────────────────────────────────────────────────
def update_slide_27(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "PRN232 - Fall 2026 - FPT University" in txt:
                    p.text = "PRM393 - Fall 2026 - FPT University"
                elif "EXE Team Matching - PRN232 - Fall 2026" in txt or "EXE Team Matching ·" in txt:
                    p.text = "EXE Team Matching · Flutter Mobile & Firebase · Nhóm 5"
                elif "Cảm ơn Thầy và các bạn đã lắng nghe!" in txt:
                    p.text = "Cảm ơn Thầy Phương và các bạn đã lắng nghe!"

# ─────────────────────────────────────────────────────────────
# GLOBAL RUN-SAFE CLEANUP
# ─────────────────────────────────────────────────────────────
GLOBAL_REPLACE = [
    ("PRN232 – Final Assignment", "PRM393 – Mobile Programming Assignment"),
    ("PRN232 – FINAL ASSIGNMENT", "PRM393 – FINAL ASSIGNMENT"),
    ("PRN232 - FALL 2026", "PRM393 - FALL 2026"),
    ("PRN232 - Fall 2026", "PRM393 - Fall 2026"),
    ("OVERVIEW - PRN232", "OVERVIEW - PRM393"),
    ("PRN232 - draw.io", "PRM393 - draw.io"),
    ("PRN232", "PRM393"),
    ("JWT Role Claims", "Firebase Authentication & Rules"),
    ("JWT Role Claim", "Firebase Auth UID / Email"),
    ("JWT", "Firebase ID Token"),
    ("YARP API Gateway và từng Microservice", "Firebase và Firestore Security Rules"),
    ("YARP API Gateway", "Firebase Platform"),
    ("YARP Gateway", "Firebase Backend"),
    ("YARP", "Firebase Backend"),
    ("dotnet test", "flutter test"),
    ("MailHog", "FCM Notification"),
    ("SignalR", "Firestore Realtime Stream"),
    ("Redis Backplane", "Firestore Realtime Stream"),
    ("Redis Streams", "Firestore Snapshots"),
    ("Redis 7 Streams", "Firestore Snapshots"),
    ("Redis", "Firestore"),
    ("gRPC & Chốt sổ", "Phân phối SV Lẻ & Chốt sổ"),
    ("gRPC Service", "Admin Service"),
    ("Matching gRPC", "Distribution Planner"),
    ("gRPC", "Thuật toán Phân phối"),
    ("moderator@fpt.edu.vn", "moderator@fe.edu.vn"),
    ("Docker Compose", "Firebase Platform"),
    ("Docker", "Firebase"),
    ("Kubernetes", "Cloud Functions"),
    ("EF Core Entity", "Firestore Collection"),
    ("EF Core", "Firestore SDK"),
    ("SQL Server", "Cloud Firestore"),
    ("Microsoft SQL Server 2022", "Cloud Firestore (NoSQL)"),
    ("Microsoft Cloud Firestore 2022", "Cloud Firestore (NoSQL)"),
]

def apply_global_clean(prs):
    for slide in prs.slides:
        for shape in slide.shapes:
            for old, new in GLOBAL_REPLACE:
                safe_replace_shape(shape, old, new)

# ─────────────────────────────────────────────────────────────
# MAIN EXECUTION
# ─────────────────────────────────────────────────────────────
def main():
    src_path = r"E:\PRM\Test 1\PRM393\Software_Project_Presentation_Group3.pptx"
    out_path1 = r"E:\PRM\Test 1\PRM393\Software_Project_Presentation_PRM393_Group5.pptx"
    out_path2 = r"E:\PRM\Test 1\Software_Project_Presentation_PRM393_Group5.pptx"
    out_path3 = r"E:\PRM\Test 1\PRM393\Software_Project_Presentation_PRM393_Group5_v2.pptx"
    out_path4 = r"E:\PRM\Test 1\Software_Project_Presentation_PRM393_Group5_v2.pptx"

    print(f"Loading original base template: {src_path}")
    prs = Presentation(src_path)
    print(f"Loaded {len(prs.slides)} slides.")

    print("Step 1: Applying global safe replacements...")
    apply_global_clean(prs)

    print("Step 2: Updating individual slides...")
    update_slide_1(prs.slides[0])
    update_slide_4(prs.slides[3])
    update_slide_5(prs.slides[4])
    update_slide_6(prs.slides[5])
    update_slide_7(prs.slides[6])
    update_slide_9(prs.slides[8])
    update_slide_10(prs.slides[9])
    update_slide_11(prs.slides[10])
    update_slide_13(prs.slides[12])
    
    print("Step 3: Redesigning Slide 14 (Class Design MVVM)...")
    update_slide_14(prs.slides[13])
    
    print("Step 4: Redesigning Slide 15 (Conceptual Firestore NoSQL)...")
    update_slide_15(prs.slides[14])
    
    print("Step 5: Redesigning Slide 16 (Physical Schema & Concurrency Table)...")
    update_slide_16(prs.slides[15])
    
    print("Step 6: Updating Slides 17 to 27...")
    update_slide_17(prs.slides[16])
    update_slides_18_22(prs)
    update_slide_23(prs.slides[22])
    update_slide_24(prs.slides[23])
    update_slide_25(prs.slides[24])
    update_slide_26(prs.slides[25])
    update_slide_27(prs.slides[26])

    print("Step 7: Applying second-pass global clean on newly added text...")
    apply_global_clean(prs)

    print("Step 8: Saving presentation...")
    for out in [out_path1, out_path2, out_path3, out_path4]:
        try:
            prs.save(out)
            print(f"  ✓ Saved to: {out}")
        except Exception as e:
            print(f"  ⚠ Could not save to {out} (file locked?): {e}")

    # Final verification scan
    print("\nStep 9: Final verification scan for residual terms...")
    prs_check = Presentation(out_path3)
    residuals = [".NET", "C#", "SQL Server", "Docker", "gRPC", "PRN232", "YARP", "Redis", "SignalR", "EF Core", "dotnet test"]
    for term in residuals:
        count = 0
        for si, slide in enumerate(prs_check.slides):
            for shape in slide.shapes:
                if shape.has_text_frame and term in shape.text_frame.text:
                    count += 1
                elif shape.has_table:
                    for row in shape.table.rows:
                        for cell in row.cells:
                            if term in cell.text_frame.text:
                                count += 1
        if count == 0:
            print(f"  ✓ '{term}' — 0 occurrences (CLEAN)")
        else:
            print(f"  ⚠ '{term}' — {count} occurrences found")

if __name__ == "__main__":
    main()
