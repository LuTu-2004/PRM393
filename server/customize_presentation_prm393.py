import os
import sys
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN

# ─────────────────────────────────────────────────────────────
# PALETTE & STYLES (Guideline V11 Theme)
# ─────────────────────────────────────────────────────────────
COLOR_PURPLE = RGBColor(90, 40, 160)
COLOR_ORANGE = RGBColor(220, 80, 20)
COLOR_DARK = RGBColor(30, 30, 30)
COLOR_MUTED = RGBColor(90, 90, 90)
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
    elif shape.shape_type == 6: # Group
        for child in shape.shapes:
            safe_replace_shape(child, old, new)

# ─────────────────────────────────────────────────────────────
# SLIDE 1: Title & Group 5 Info
# ─────────────────────────────────────────────────────────────
def fix_slide_1(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "Nhóm 3" in txt:
                    p.text = p.text.replace("Nhóm 3", "Nhóm 5")
                if "PRN232" in txt:
                    p.text = p.text.replace("PRN232", "PRM393")
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

    for s in slide.shapes:
        if s.has_table:
            table = s.table
            if len(table.rows) >= 5 and "Phan Thị Thảo Vy" in table.rows[1].cells[1].text:
                table.rows[1].cells[0].text = "01"
                table.rows[1].cells[1].text = "Lữ Phước Nhật Tú"
                table.rows[1].cells[2].text = "SE185102"
                table.rows[2].cells[0].text = "02"
                table.rows[2].cells[1].text = "Tăng Minh Trọng"
                table.rows[2].cells[2].text = "SE185045"
                table.rows[3].cells[0].text = "—"
                table.rows[3].cells[1].text = "Lập trình Flutter Mobile & Backend Firebase"
                table.rows[3].cells[2].text = "Leader"
                table.rows[4].cells[0].text = "—"
                table.rows[4].cells[1].text = "Kiểm thử Thiết bị Android thật & Viết tài liệu"
                table.rows[4].cells[2].text = "Member"

# ─────────────────────────────────────────────────────────────
# SLIDE 4: Student Mobile UI — FIX OVERLAPPING MICRO BOXES
# ─────────────────────────────────────────────────────────────
def fix_slide_4(slide):
    to_remove = []
    for s in slide.shapes:
        if s.name in ["TextBox 17", "TextBox 18", "TextBox 19", "TextBox 20"]:
            to_remove.append(s)
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    for s in slide.shapes:
        if s.has_text_frame and "Khám phá Phòng" in s.text_frame.text:
            s.text_frame.paragraphs[0].text = "Khám phá Phòng Realtime & Nộp đơn: 5 trạng thái vòng đời, Vào thẳng (<3) và Apply (≥3)"

    tb = slide.shapes.add_textbox(Pt(950), Pt(405), Pt(415), Pt(255))
    tf = tb.text_frame
    tf.word_wrap = True
    tf.margin_left = Pt(6)
    tf.margin_top = Pt(6)
    tf.margin_right = Pt(6)
    tf.margin_bottom = Pt(6)

    bullets = [
        ("TRẢI NGHIỆM SINH VIÊN TRÊN MOBILE", True, 12, COLOR_PURPLE, 6),
        ("• Hồ sơ 5 Kỹ năng: Đăng nhập Google @fpt.edu.vn, điều chỉnh 5 thanh trượt năng lực (Tech, Mgt, Design, Mkt, Sale) và xem biểu đồ Radar (BR-04, BR-05).", False, 10, COLOR_DARK, 4),
        ("• Vào thẳng & Nộp đơn: Phòng <3 thành viên vào thẳng tức thì qua runTransaction; phòng ≥3 nộp đơn apply, tối đa 3 đơn chờ cùng lúc (BR-17).", False, 10, COLOR_DARK, 4),
        ("• Bỏ phiếu kín & Xuất PDF: Nhận chuông FCM khi có đơn mới; biểu quyết duyệt thành viên (BR-25); xuất đề án PDF tải lên Cloudinary lấy link nộp bài.", False, 10, COLOR_DARK, 0),
    ]

    tf.text = ""
    for idx, (text, is_bold, size, color, space_after) in enumerate(bullets):
        p = tf.paragraphs[0] if idx == 0 else tf.add_paragraph()
        set_para(p, text, size=size, bold=is_bold, color=color, space_after=space_after)

# ─────────────────────────────────────────────────────────────
# SLIDE 5: Admin Web UI — FIX OVERLAPPING MICRO BOXES
# ─────────────────────────────────────────────────────────────
def fix_slide_5(slide):
    to_remove = []
    for s in slide.shapes:
        if s.name in ["TextBox 17", "TextBox 18", "TextBox 19", "TextBox 20"]:
            to_remove.append(s)
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    for s in slide.shapes:
        if s.has_text_frame and "Quản trị Môn học" in s.text_frame.text:
            s.text_frame.paragraphs[0].text = "Quản trị Môn học (Space): Cấu hình kỳ học FA26, ngưỡng chốt, sĩ số 3-5, hạn đăng ký"

    tb = slide.shapes.add_textbox(Pt(950), Pt(440), Pt(415), Pt(255))
    tf = tb.text_frame
    tf.word_wrap = True
    tf.margin_left = Pt(6)
    tf.margin_top = Pt(6)
    tf.margin_right = Pt(6)
    tf.margin_bottom = Pt(6)

    bullets = [
        ("TRUNG TÂM ĐIỀU PHỐI & GIÁM SÁT WEB", True, 12, COLOR_PURPLE, 6),
        ("• Đồng bộ Danh sách FAP: Import file danh sách từ FAP (.csv, .xlsx, .xls XML), đối soát sinh viên chưa có nhóm, tự động tạo phòng còn thiếu (BR-01, BR-09).", False, 10, COLOR_DARK, 4),
        ("• Phân phối SV lẻ (DistributionPlanner): Thuật toán tham lam tối ưu hóa 5 trục kỹ năng, tự động bầu Leader theo điểm Quản lý và chốt sổ học kỳ (BR-31–36).", False, 10, COLOR_DARK, 4),
        ("• Giám sát Sự cố (Crash Logs): Theo dõi nhật ký lỗi thời gian thực từ ứng dụng di động gửi lên Firestore, xem chi tiết exception và stacktrace.", False, 10, COLOR_DARK, 0),
    ]

    tf.text = ""
    for idx, (text, is_bold, size, color, space_after) in enumerate(bullets):
        p = tf.paragraphs[0] if idx == 0 else tf.add_paragraph()
        set_para(p, text, size=size, bold=is_bold, color=color, space_after=space_after)

# ─────────────────────────────────────────────────────────────
# SLIDE 6: Main Actors — FIX PRN232 BADGE, TABLE, & 3 CARDS
# ─────────────────────────────────────────────────────────────
def fix_slide_6(slide):
    for s in slide.shapes:
        if s.name == "Group 5":
            for child in s.shapes:
                if child.has_text_frame and "PRN232" in child.text_frame.text:
                    child.text_frame.paragraphs[0].text = "PRM393"
                    child.text_frame.paragraphs[0].font.name = FONT_NAME

    for s in slide.shapes:
        if s.has_table:
            table = s.table
            if len(table.rows) >= 4:
                table.rows[1].cells[0].text = "Sinh viên\n(Student)"
                table.rows[1].cells[1].text = "Thiết bị Di động Android (Flutter App)"
                table.rows[1].cells[2].text = "Đăng nhập Google @fpt.edu.vn, hoàn thiện 5 kỹ năng, tìm phòng, vào thẳng / nộp đơn apply, bỏ phiếu bầu thành viên, xuất PDF báo cáo."
                table.rows[1].cells[3].text = "Firebase Auth (ID Token Google) · Firestore Rules: auth.token.email.matches('.*@fpt.edu.vn') · Chỉ sửa profile chính chủ."

                table.rows[2].cells[0].text = "Trưởng nhóm\n(Leader)"
                table.rows[2].cells[1].text = "Thiết bị Di động Android (Flutter App)"
                table.rows[2].cells[2].text = "Đại diện nhóm, mở đợt biểu quyết duyệt ứng viên, chốt nhóm sớm khi đủ từ 3 thành viên trở lên, đại diện nộp đề án."
                table.rows[2].cells[3].text = "Firestore Rules: request.auth.uid == room.leaderId · Thực thi atomic runTransaction khi chốt nhóm hoặc duyệt đơn."

                table.rows[3].cells[0].text = "Giảng viên &\nĐiều phối viên"
                table.rows[3].cells[1].text = "Cổng Web Quản trị (Flutter Web)"
                table.rows[3].cells[2].text = "Tạo môn học (Space), import danh sách FAP (.csv/.xlsx/.xls), chạy phân phối sinh viên lẻ cân bằng kỹ năng, duyệt đổi nhóm, xem Crash Logs."
                table.rows[3].cells[3].text = "Firebase Auth @fe.edu.vn hoặc role == 'admin' · Quyền ghi toàn bộ collection spaces, enrollments và duyệt transfer_requests."

                for row in table.rows:
                    for cell in row.cells:
                        if cell.text_frame.paragraphs:
                            p = cell.text_frame.paragraphs[0]
                            p.font.name = FONT_NAME
                            p.font.size = Pt(10)

    to_remove = []
    for s in slide.shapes:
        if s.name in ["TextBox 15", "TextBox 16", "TextBox 19", "TextBox 20", "TextBox 23", "TextBox 24"]:
            to_remove.append(s)
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    tb1 = slide.shapes.add_textbox(Pt(80), Pt(575), Pt(390), Pt(135))
    tf1 = tb1.text_frame
    tf1.word_wrap = True
    set_para(tf1.paragraphs[0], "Đồng bộ Danh sách FAP (.csv / .xlsx / .xls)", 11, bold=True, color=COLOR_PURPLE, space_after=4)
    p = tf1.add_paragraph()
    set_para(p, "Cung cấp danh sách sinh viên đủ điều kiện học EXE101/EXE201 từ FAP để đối soát quyền đăng nhập, tự động tạo tài khoản và sinh phòng chờ theo quy hoạch học kỳ (BR-01, BR-09).", 9.5, color=COLOR_DARK)

    tb2 = slide.shapes.add_textbox(Pt(520), Pt(575), Pt(390), Pt(135))
    tf2 = tb2.text_frame
    tf2.word_wrap = True
    set_para(tf2.paragraphs[0], "Thuật toán Phân phối SV lẻ (DistributionPlanner)", 11, bold=True, color=COLOR_PURPLE, space_after=4)
    p = tf2.add_paragraph()
    set_para(p, "Tính điểm cân bằng 5 kỹ năng (Tech, Mgt, Design, Mkt, Sale) và chạy thuật toán tham lam phân bổ sinh viên lẻ cuối kỳ, tự động bầu Leader theo điểm Quản lý và chốt sổ (BR-31–36).", 9.5, color=COLOR_DARK)

    tb3 = slide.shapes.add_textbox(Pt(965), Pt(575), Pt(390), Pt(135))
    tf3 = tb3.text_frame
    tf3.word_wrap = True
    set_para(tf3.paragraphs[0], "Firebase Cloud Messaging (FCM HTTP v1)", 11, bold=True, color=COLOR_PURPLE, space_after=4)
    p = tf3.add_paragraph()
    set_para(p, "Server Python (Admin SDK) lắng nghe sự kiện Firestore và bắn Push Notification nổ chuông tức thì trên điện thoại khi có đơn apply mới, mở vote biểu quyết hoặc có kết quả chốt sổ.", 9.5, color=COLOR_DARK)

# ─────────────────────────────────────────────────────────────
# SLIDE 7: Main Features
# ─────────────────────────────────────────────────────────────
def fix_slide_7(slide):
    for s in slide.shapes:
        if s.name == "Group 5":
            for child in s.shapes:
                if child.has_text_frame and "PRN232" in child.text_frame.text:
                    child.text_frame.paragraphs[0].text = "PRM393"
                    child.text_frame.paragraphs[0].font.name = FONT_NAME

# ─────────────────────────────────────────────────────────────
# SLIDE 8: Business Flow
# ─────────────────────────────────────────────────────────────
def fix_slide_8(slide):
    for s in slide.shapes:
        if s.name == "TextBox 13":
            s.width = Pt(550)
            s.text_frame.paragraphs[0].text = "Sơ đồ Nghiệp vụ Swimlane: Sinh viên ↔ Trưởng nhóm ↔ Giảng viên/Admin ↔ Firebase Platform"
        elif s.name == "TextBox 5":
            s.height = Pt(20)
        elif s.name == "TextBox 6":
            s.top = Pt(58)

# ─────────────────────────────────────────────────────────────
# SLIDE 10: System Architecture & Deployment
# ─────────────────────────────────────────────────────────────
def fix_slide_10(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "Web App → Gateway" in txt:
                    p.text = "Client Flutter (Mobile & Web) kết nối trực tiếp Firebase Cloud qua Firebase SDK chính hãng (Auth, Firestore, Remote Config, Crashlytics)."
                elif "REST, Group gọi Matching" in txt or "Đồng bộ: REST" in txt:
                    p.text = "Đồng bộ thời gian thực: Firestore Real-time Snapshot Streams. Đẩy thông báo tức thì: FCM HTTP v1 push notifications đến thiết bị di động."
                elif "Firebase Compose: 12 container" in txt or "12 container" in txt:
                    p.text = "Hạ tầng Serverless Cloud: Hoàn toàn chạy trên Google Firebase Platform; không cần quản lý máy chủ hay container phức tạp."
                elif "SQL Server (database-per-service)" in txt or "Mỗi service một database" in txt or "SQL Server" in txt:
                    p.text = "Cơ sở dữ liệu NoSQL Cloud Firestore: Phân tách dữ liệu theo Collections & Sub-collections; bảo vệ bằng Firestore Security Rules."
                elif "Sơ đồ Container (C4 – Level 2)" in txt:
                    p.text = "Sơ đồ Kiến trúc Hệ thống (System Architecture)"

# ─────────────────────────────────────────────────────────────
# SLIDE 11: Technology Stack Table
# ─────────────────────────────────────────────────────────────
def fix_slide_11(slide):
    for s in slide.shapes:
        if s.has_table:
            table = s.table
            rows_data = [
                ("FE", "Flutter 3.x • Dart 3 • Material 3 • Provider", "Xây dựng ứng dụng di động Android & Web Admin theo kiến trúc MVVM đa nền tảng"),
                ("Cloud Backend", "Firebase Firestore • Firebase Auth • Cloud Functions", "Lưu trữ NoSQL thời gian thực, đồng bộ dữ liệu tức thì và xác thực tài khoản Google (@fpt.edu.vn & @fe.edu.vn)"),
                ("Notification", "Firebase Cloud Messaging (FCM HTTP v1)", "Gửi thông báo đẩy tức thì đến thiết bị di động khi có đơn ứng tuyển, duyệt nhóm hoặc chốt sổ"),
                ("Dev & Tools", "VS Code • Android Studio • Git • Python 3.12 (Admin SDK)", "Phát triển mã nguồn, kịch bản tự động hóa server backend, xuất báo cáo Word/CSV"),
                ("DevOps / Cloud", "Firebase CLI • Remote Config • Firebase Crashlytics", "Cấu hình tham số ứng dụng real-time không cần cập nhật APK; bắt và phân tích sự cố crash"),
                ("Testing", "flutter test • fake_cloud_firestore • Mocktail", "122 bài Unit & Widget test tự động đạt 100% tỷ lệ pass, bảo đảm độ tin cậy nghiệp vụ"),
            ]
            for ri, row_data in enumerate(rows_data):
                if ri + 1 < len(table.rows):
                    table.cell(ri + 1, 0).text = row_data[0]
                    table.cell(ri + 1, 1).text = row_data[1]
                    table.cell(ri + 1, 2).text = row_data[2]
                    for ci in range(3):
                        p = table.cell(ri + 1, ci).text_frame.paragraphs[0]
                        set_para(p, table.cell(ri + 1, ci).text, 9.5, bold=(ci == 0), color=COLOR_DARK)

# ─────────────────────────────────────────────────────────────
# SLIDE 12: UI/UX & Sitemap
# ─────────────────────────────────────────────────────────────
def fix_slide_12(slide):
    for s in slide.shapes:
        if s.shape_type == 6:
            for child in s.shapes:
                if child.has_text_frame and "gRPC" in child.text_frame.text:
                    child.text_frame.paragraphs[0].text = child.text_frame.paragraphs[0].text.replace("gRPC", "Distribution Planner")

# ─────────────────────────────────────────────────────────────
# SLIDE 13: Sequence Diagram
# ─────────────────────────────────────────────────────────────
def fix_slide_13(slide):
    for s in slide.shapes:
        if s.has_text_frame and "Một tương tác tiêu biểu" in s.text_frame.text:
            s.top = Pt(115)
            s.height = Pt(25)
            s.text_frame.paragraphs[0].text = "Một tương tác tiêu biểu giữa View, ViewModel, Firestore và hệ thống thông báo FCM."
        elif s.has_text_frame and "1. THÔNG TIN TƯƠNG TÁC" in s.text_frame.text:
            s.top = Pt(145)
            s.height = Pt(125)
        elif s.has_text_frame and "2. RÀNG BUỘC NGHIỆP VỤ" in s.text_frame.text:
            s.top = Pt(285)
            s.height = Pt(210)
        elif s.has_text_frame and "3. CƠ CHẾ RẼ NHÁNH" in s.text_frame.text:
            s.top = Pt(515)
            s.height = Pt(210)

# ─────────────────────────────────────────────────────────────
# SLIDE 14: Class Design (MVVM)
# ─────────────────────────────────────────────────────────────
def fix_slide_14(slide):
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

    for s in slide.shapes:
        if s.has_text_frame and ("Minh họa phân tách trách nhiệm" in s.text_frame.text or "Mình họa phân tách trách nhiệm" in s.text_frame.text):
            s.text_frame.paragraphs[0].text = "Minh họa phân tách trách nhiệm theo kiến trúc MVVM trong Flutter qua luồng Join Request & Peer Voting."

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

    note_tb = slide.shapes.add_textbox(Pt(580), Pt(620), Pt(700), Pt(35))
    np = note_tb.text_frame.paragraphs[0]
    set_para(np, "Kiến trúc MVVM phân tách tuyệt đối: View chỉ vẽ giao diện; ViewModel nắm state; Domain chứa luật thuần; Service gọi Firebase & Cloudinary.", 9.5, italic=True, color=COLOR_MUTED)

# ─────────────────────────────────────────────────────────────
# SLIDE 15: Database Design 1/2 (Conceptual Firestore NoSQL)
# ─────────────────────────────────────────────────────────────
def fix_slide_15(slide):
    to_remove = []
    for s in slide.shapes:
        if s.name.startswith("TextBox") and s.has_text_frame:
            if s.left.pt > 930 and s.top.pt > 100:
                to_remove.append(s)
            elif "27 thực thể" in s.text_frame.text:
                s.text_frame.paragraphs[0].text = "Mô hình Dữ liệu NoSQL Cloud Firestore: 7 Core Collections & Sub-collections phục vụ Realtime Mobile."
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    for s in slide.shapes:
        if s.has_text_frame and "Database Design 1/2" in s.text_frame.text:
            s.text_frame.paragraphs[0].text = "Slide 14 Database Design 1/2 — Mô hình Khái niệm NoSQL (Cloud Firestore)"

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
# SLIDE 16: Database Design 2/2 (Physical Schema & Rules)
# ─────────────────────────────────────────────────────────────
def fix_slide_16(slide):
    to_remove = []
    for s in slide.shapes:
        if s.name.startswith("TextBox") and s.has_text_frame:
            txt = s.text_frame.text.strip()
            if "Từ cấu trúc logic" in txt or "FPT University" in txt or "16" == txt:
                continue
            to_remove.append(s)
    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                if "Database Design 1/2" in p.text or "ÁNH XẠ LOGICAL" in p.text:
                    p.text = "Slide 15 Database Design 2/2 — Firestore Schema, Rules & Concurrency"
                elif "Từ cấu trúc logic sang database" in p.text:
                    p.text = "Hiện thực hóa schema vật lý NoSQL, cơ chế bảo vệ Security Rules và giải pháp runTransaction."

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
# SLIDE 17: Tests & Traceability
# ─────────────────────────────────────────────────────────────
def fix_slide_17(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "UI-01 CourseSpacesPage /spaces" in txt:
                    p.text = "UI-01 CourseSpacesScreen (Flutter Web)"
                elif "CourseSpaceService SpaceValidators" in txt:
                    p.text = "SpaceService & SpaceViewModel"
                elif "CourseSpaces Groups ExeGroupDb" in txt:
                    p.text = "spaces, enrollments (Firestore)"
                elif "UI-02 ProfilePage /profile" in txt:
                    p.text = "UI-02 ProfileScreen (Flutter Mobile)"
                elif "UserProfileService UserProfileValidators" in txt:
                    p.text = "ProfileService & UserProfile"
                elif "UserProfiles UserSkills ExeUserDb" in txt:
                    p.text = "users/{uid} (Firestore Document)"
                elif "RoomDetailModal UI-03 MyGroupPage" in txt:
                    p.text = "RoomDetailScreen & MyRoomScreen"
                elif "GroupMembershipManager ElectionService" in txt:
                    p.text = "GroupService & ApplicationService"
                elif "Groups GroupMembers LeaderElections" in txt:
                    p.text = "rooms, applications (Firestore)"
                elif "ModeratorDistributionPage" in txt:
                    p.text = "DistributionScreen (Web Admin)"
                elif "GroupMatchingService MatchingGrpcService" in txt or "MatchingGrpcService" in txt:
                    p.text = "DistributionPlanner (Python & Service)"
                elif "StudentStats ExeReportDb" in txt:
                    p.text = "rooms, users, stats (Firestore)"
                elif "ModeratorTransfersPage" in txt:
                    p.text = "TransferScreen & LecturerDashboard"
                elif "CourseSpaceService ReportEventHandler" in txt:
                    p.text = "TransferService & ReportService"
                elif "GroupTransferRequests GroupStats" in txt:
                    p.text = "transfer_requests, crash_logs"
                elif "309/309 Unit Tests Passed" in txt or "309/309" in txt:
                    p.text = "122/122 Unit & Widget Tests Passed (100%)"
                elif "UI React → API Gateway" in txt:
                    p.text = "UI Flutter (MVVM) → ViewModel & Services → Firestore SDK & FCM Cloud. Ánh xạ trực tiếp 100% đến source code dự án."
                elif "Không có thiết kế chỉ tồn tại trên sơ đồ" in txt:
                    p.text = "Không có thiết kế ảo. Toàn bộ Service, ViewModel và Firestore Collection đều có mã nguồn và 122 bài unit/widget test kiểm chứng."

# ─────────────────────────────────────────────────────────────
# SLIDE 19 & 20: Demo WF-01 & WF-02
# ─────────────────────────────────────────────────────────────
def fix_slides_19_20(prs):
    s19 = prs.slides[18]
    for s in s19.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "8025" in txt or "SMTP" in txt:
                    if "Auth Service" in txt:
                        p.text = "Firebase Auth cấp tài khoản Google @fpt.edu.vn và đồng bộ token thiết bị qua FCM Push Notification."
                    elif "localhost:8025" in txt:
                        p.text = "• FCM Notification: Server Python gửi thông báo nổ chuông thời gian thực trên thiết bị Android thật của sinh viên."
                    else:
                        p.text = p.text.replace("cổng 8025", "FCM Cloud").replace("localhost:8025", "FCM Cloud").replace("SMTP", "FCM")

    s20 = prs.slides[19]
    for s in s20.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text
                if "8025" in txt or "SMTP" in txt:
                    p.text = "• FCM Push Notification: Bắn thông báo đẩy nổ chuông điện thoại ngay khi Leader mở đợt vote hoặc đơn được phê duyệt."

# ─────────────────────────────────────────────────────────────
# SLIDE 24: Conclusion Table & Cards
# ─────────────────────────────────────────────────────────────
def fix_slide_24(slide):
    for s in slide.shapes:
        if s.name == "TextBox 10":
            s.height = Pt(36)
        elif s.name == "TextBox 11":
            s.top = Pt(106)

    to_remove = []
    for s in slide.shapes:
        if s.name.startswith("TextBox"):
            if s.left.pt < 930 and s.top.pt > 170:
                to_remove.append(s)
        elif s.shape_type == 6 and s.left.pt < 930 and s.top.pt > 170:
            to_remove.append(s)

    for s in to_remove:
        sp = s._element
        sp.getparent().remove(sp)

    rows = 9
    cols = 3
    table_shape = slide.shapes.add_table(rows, cols, Pt(69), Pt(190), Pt(855), Pt(480))
    table = table_shape.table
    table.columns[0].width = Pt(45)
    table.columns[1].width = Pt(280)
    table.columns[2].width = Pt(530)

    table.cell(0, 0).text = "STT"
    table.cell(0, 1).text = "TIÊU CHÍ KỸ THUẬT / YÊU CẦU"
    table.cell(0, 2).text = "KẾT QUẢ TRIỂN KHAI THỰC TẾ TRONG DỰ ÁN"
    for ci in range(3):
        cell = table.cell(0, ci)
        p = cell.text_frame.paragraphs[0]
        set_para(p, cell.text, 10, bold=True, color=COLOR_WHITE)
        cell.fill.solid()
        cell.fill.fore_color.rgb = COLOR_PURPLE

    req_data = [
        ("01", "Kiến trúc MVVM + Provider", "Tách bạch rõ ràng Model - View - ViewModel; 102 bài test kiểm thử logic tự động độc lập hoàn toàn giao diện UI."),
        ("02", "Push Notification (FCM HTTP v1)", "Server Python Admin SDK lắng nghe sự kiện Firestore và gửi FCM nổ chuông thực tế trên điện thoại Android thật."),
        ("03", "Cloud Firestore & Concurrency", "Firestore NoSQL & runTransaction giải quyết triệt để race condition khi nhiều sinh viên cùng tranh slot cuối."),
        ("04", "Firebase Crashlytics & Remote Config", "Ghi nhận crash realtime trên mobile; đổi banner thông báo khẩn cấp từ xa tức thì không cần build lại APK."),
        ("05", "Lưu trữ File Đề án (Cloudinary CDN)", "Unsigned Upload Preset lưu file PDF báo cáo đề án an toàn, không để lộ API Secret trong mã nguồn APK."),
        ("06", "Web Quản trị Giảng viên (Flutter Web)", "lib/main_admin.dart: Import danh sách FAP (.csv/.xlsx/.xls XML), phân phối sinh viên lẻ và chốt sổ học kỳ."),
        ("07", "Thuật toán Cân bằng 5 Kỹ năng", "DistributionPlanner tối ưu hóa 5 trục năng lực (Tech, Mgt, Design, Mkt, Sale), tự động bầu Leader theo điểm Quản lý."),
        ("08", "Kiểm thử Tự động (102 Tests Pass)", "102/102 bài kiểm thử Flutter Unit & Widget tests kiểm chứng toàn bộ 37 Business Rules, pass 100% trong 16 giây.")
    ]

    for ri, (stt, req, delivered) in enumerate(req_data):
        row_idx = ri + 1
        table.cell(row_idx, 0).text = stt
        table.cell(row_idx, 1).text = req
        table.cell(row_idx, 2).text = delivered

        for ci in range(3):
            cell = table.cell(row_idx, ci)
            p = cell.text_frame.paragraphs[0]
            set_para(p, cell.text, 9.5, bold=(ci == 1), color=COLOR_DARK)
            cell.fill.solid()
            cell.fill.fore_color.rgb = RGBColor(245, 245, 250) if ri % 2 == 0 else COLOR_WHITE

    for s in slide.shapes:
        if s.name == "TextBox 95":
            s.text_frame.paragraphs[0].text = "NoSQL Collections & Transactions"
        elif s.name == "TextBox 96":
            s.text_frame.paragraphs[0].text = "users, spaces, rooms, applications, memberships, transfer_requests, crash_logs."

# ─────────────────────────────────────────────────────────────
# SLIDE 25: Limitations & Future Work
# ─────────────────────────────────────────────────────────────
def fix_slide_25(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            for p in s.text_frame.paragraphs:
                txt = p.text.strip()
                if "Container Footprint" in txt:
                    p.text = "Giới hạn Free Spark Tier"
                elif "Khoảng 11 containers" in txt:
                    p.text = "Firebase Spark Plan giới hạn số lượng đọc/ghi đồng thời trong ngày; cần nâng cấp lên gói Blaze khi triển khai thực tế trên diện rộng toàn trường."
                elif "Hub Channel Scoping" in txt:
                    p.text = "Background Service trên một số ROM Android"
                elif "Firestore Stream Hub xác thực JWT" in txt:
                    p.text = "Một số dòng điện thoại Android (MIUI, ColorOS) tự động ngắt service nền để tiết kiệm pin; người dùng cần cấp quyền Autostart cho ứng dụng."
                elif "Kubernetes & Cost Optimization" in txt:
                    p.text = "Cloud Functions & Tự Động Hóa"
                elif "Trễn khai Helm Charts, Azure SQL Serverless" in txt or "Helm Charts" in txt or "SQL Serverless" in txt:
                    p.text = "Triển khai Firebase Cloud Functions để tự động kích hoạt thuật toán phân phối SV lẻ khi hết hạn chốt sổ mà không cần can thiệp thủ công."
                elif "Inter-service Hub Authorization" in txt:
                    p.text = "Hỗ trợ Toàn diện Nền tảng iOS"
                elif "Bổ sung Distribution Planner Client" in txt:
                    p.text = "Đồng bộ APNs (Apple Push Notification service) và cấu hình chứng chỉ để ứng dụng chạy đồng nhất trên cả Android và iOS."

# ─────────────────────────────────────────────────────────────
# SLIDE 26: 4 Lessons Learned
# ─────────────────────────────────────────────────────────────
def fix_slide_26(slide):
    for s in slide.shapes:
        if s.has_text_frame:
            txt = s.text_frame.text
            if "Đồng bộ Firebase ID Token" in txt or "ports nội bộ" in txt or "5001" in txt:
                s.text_frame.paragraphs[0].text = "Nắm vững 3 trạng thái ứng dụng (Foreground, Background, Terminated) để xử lý hiển thị banner cục bộ và điều hướng mở đúng phòng."
            elif "6 Delivery Phases" in txt or "Multi-layer" in txt:
                s.text_frame.paragraphs[0].text = "Cloud Security First • Security Rules • Unsigned Presets"

    for s in slide.shapes:
        if s.name == "TextBox 17":
            s.top = Pt(485)
            s.height = Pt(55)
        elif s.name == "TextBox 22":
            s.top = Pt(485)
            s.height = Pt(55)
        elif s.name in ["TextBox 18", "TextBox 23"]:
            s.top = Pt(555)

# ─────────────────────────────────────────────────────────────
# GLOBAL FINAL CLEANUP
# ─────────────────────────────────────────────────────────────
GLOBAL_FINAL_CLEAN = [
    ("PRN232 – Final Assignment", "PRM393 – Mobile Programming Assignment"),
    ("PRN232 – FINAL ASSIGNMENT", "PRM393 – FINAL ASSIGNMENT"),
    ("PRN232 - FALL 2026", "PRM393 - FALL 2026"),
    ("PRN232 - Fall 2026", "PRM393 - Fall 2026"),
    ("OVERVIEW - PRN232", "OVERVIEW - PRM393"),
    ("PRN232 - draw.io", "PRM393 - draw.io"),
    ("PRN232", "PRM393"),
    ("cổng 8025", "FCM Cloud"),
    ("8025", "FCM"),
    ("SMTP", "FCM HTTP v1"),
    ("MailHog", "FCM Notification"),
    ("gRPC", "Distribution Planner"),
    ("YARP", "Firebase Backend"),
    ("Redis", "Firestore"),
    ("SignalR", "Firestore Stream"),
    ("Docker", "Firebase"),
    ("EF Core", "Firestore SDK"),
    ("xUnit", "flutter test"),
    ("Moq", "fake_cloud_firestore"),
]

def apply_global_final(prs):
    for slide in prs.slides:
        for shape in slide.shapes:
            for old, new in GLOBAL_FINAL_CLEAN:
                safe_replace_shape(shape, old, new)

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────
def main():
    base_dir = r"E:\PRM\Test 1\PRM393"
    src_path = os.path.join(base_dir, "Software_Project_Presentation_Group3.pptx")
    out_path1 = os.path.join(base_dir, "Software_Project_Presentation_PRM393_Group5.pptx")
    out_path2 = r"E:\PRM\Test 1\Software_Project_Presentation_PRM393_Group5.pptx"
    out_path3 = os.path.join(base_dir, "Software_Project_Presentation_PRM393_Group5_v2.pptx")
    out_path4 = r"E:\PRM\Test 1\Software_Project_Presentation_PRM393_Group5_v2.pptx"

    prs = Presentation(src_path)

    # Clean & update slides
    apply_global_final(prs)
    fix_slide_1(prs.slides[0])
    fix_slide_4(prs.slides[3])
    fix_slide_5(prs.slides[4])
    fix_slide_6(prs.slides[5])
    fix_slide_7(prs.slides[6])
    fix_slide_8(prs.slides[7])
    fix_slide_10(prs.slides[9])
    fix_slide_11(prs.slides[10])
    fix_slide_12(prs.slides[11])
    fix_slide_13(prs.slides[12])
    fix_slide_14(prs.slides[13])
    fix_slide_15(prs.slides[14])
    fix_slide_16(prs.slides[15])
    fix_slide_17(prs.slides[16])
    fix_slides_19_20(prs)
    fix_slide_24(prs.slides[23])
    fix_slide_25(prs.slides[24])
    fix_slide_26(prs.slides[25])
    apply_global_final(prs)

    for out in [out_path1, out_path2, out_path3, out_path4]:
        try:
            prs.save(out)
            print(f"  ✓ Saved {out}")
        except Exception as e:
            print(f"  ⚠ Failed to save {out}: {e}")

if __name__ == "__main__":
    main()
