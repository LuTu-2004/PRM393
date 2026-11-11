import os
import docx
from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, fill_hex):
    tcPr = cell._tc.get_or_add_tcPr()
    tcPr.append(parse_xml(f'<w:shd {nsdecls("w")} w:fill="{fill_hex}"/>'))

def set_cell_margins(cell, top=100, bottom=100, left=140, right=140):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(
        f'<w:tcMar {nsdecls("w")}>'
        f'<w:top w:w="{top}" w:type="dxa"/>'
        f'<w:bottom w:w="{bottom}" w:type="dxa"/>'
        f'<w:left w:w="{left}" w:type="dxa"/>'
        f'<w:right w:w="{right}" w:type="dxa"/>'
        f'</w:tcMar>'
    )
    tcPr.append(tcMar)

def add_callout(doc, text, title="LƯU Ý QUAN TRỌNG", bg_hex="FFF8E7", border_hex="D35400"):
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    tbl.columns[0].width = Inches(6.8)
    cell = tbl.cell(0, 0)
    set_cell_background(cell, bg_hex)
    set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
    
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="24" w:space="0" w:color="{border_hex}"/>'
        f'<w:top w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'<w:bottom w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(borders)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(2)
    r_title = p.add_run(f"📌 {title}: ")
    r_title.font.name = "Segoe UI"
    r_title.font.bold = True
    r_title.font.size = Pt(10.5)
    r_title.font.color.rgb = RGBColor(180, 60, 0)
    
    r_text = p.add_run(text)
    r_text.font.name = "Segoe UI"
    r_text.font.size = Pt(10)
    r_text.font.color.rgb = RGBColor(50, 50, 50)
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def add_qa_box(doc, question, answer, code_note=""):
    p_q = doc.add_paragraph()
    p_q.paragraph_format.space_before = Pt(8)
    p_q.paragraph_format.space_after = Pt(2)
    p_q.paragraph_format.keep_with_next = True
    
    r_badge = p_q.add_run("❓ CÂU HỎI XOÁY: ")
    r_badge.font.name = "Segoe UI"
    r_badge.font.bold = True
    r_badge.font.size = Pt(10.5)
    r_badge.font.color.rgb = RGBColor(192, 57, 43) # Red/Crimson
    
    r_q = p_q.add_run(question)
    r_q.font.name = "Segoe UI"
    r_q.font.bold = True
    r_q.font.size = Pt(10.5)
    r_q.font.color.rgb = RGBColor(30, 30, 30)
    
    # Answer box
    tbl = doc.add_table(rows=1, cols=1)
    tbl.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl.autofit = False
    tbl.columns[0].width = Inches(6.8)
    cell = tbl.cell(0, 0)
    set_cell_background(cell, "F4F6F7")
    set_cell_margins(cell, top=100, bottom=100, left=150, right=150)
    
    tcPr = cell._tc.get_or_add_tcPr()
    borders = parse_xml(
        f'<w:tcBorders {nsdecls("w")}>'
        f'<w:left w:val="single" w:sz="18" w:space="0" w:color="2980B9"/>'
        f'<w:top w:val="none"/>'
        f'<w:right w:val="none"/>'
        f'<w:bottom w:val="none"/>'
        f'</w:tcBorders>'
    )
    tcPr.append(borders)
    
    p_ans = cell.paragraphs[0]
    p_ans.paragraph_format.space_after = Pt(2)
    r_ans_label = p_ans.add_run("👉 Trả lời an toàn: ")
    r_ans_label.font.name = "Segoe UI"
    r_ans_label.font.bold = True
    r_ans_label.font.size = Pt(10)
    r_ans_label.font.color.rgb = RGBColor(41, 128, 185)
    
    r_ans = p_ans.add_run(answer)
    r_ans.font.name = "Segoe UI"
    r_ans.font.size = Pt(10)
    r_ans.font.color.rgb = RGBColor(40, 40, 40)
    
    if code_note:
        p_code = cell.add_paragraph()
        p_code.paragraph_format.space_before = Pt(3)
        p_code.paragraph_format.space_after = Pt(0)
        r_cn = p_code.add_run(f"🔍 Dẫn chứng code/vị trí: {code_note}")
        r_cn.font.name = "Consolas"
        r_cn.font.italic = True
        r_cn.font.size = Pt(9)
        r_cn.font.color.rgb = RGBColor(80, 80, 80)
        
    doc.add_paragraph().paragraph_format.space_after = Pt(4)

def create_document():
    doc = Document()
    
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
    style_normal = doc.styles['Normal']
    font = style_normal.font
    font.name = 'Segoe UI'
    font.size = Pt(10.5)
    font.color.rgb = RGBColor(40, 40, 40)
    
    # Header Title
    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_after = Pt(2)
    r_title = p_title.add_run("CẨM NANG THAO TÁC FIREBASE CONSOLE & VẤN ĐÁP CÔNG NGHỆ")
    r_title.font.name = 'Segoe UI'
    r_title.font.size = Pt(17)
    r_title.font.bold = True
    r_title.font.color.rgb = RGBColor(211, 84, 0) # Primary Orange
    
    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_after = Pt(10)
    r_sub = p_sub.add_run("PRM393 · Đồ án EXE Team Matching · Nhóm 5 · Chuẩn bị bảo vệ trực tiếp cùng Thầy Phương (Phuonglhk)")
    r_sub.font.italic = True
    r_sub.font.size = Pt(10)
    r_sub.font.color.rgb = RGBColor(110, 110, 110)
    
    p_hr = doc.add_paragraph()
    p_hr.paragraph_format.space_after = Pt(12)
    p_hr_border = parse_xml(f'<w:pBdr {nsdecls("w")}><w:bottom w:val="single" w:sz="8" w:space="1" w:color="D35400"/></w:pBdr>')
    p_hr._p.get_or_add_pPr().append(p_hr_border)
    
    add_callout(
        doc,
        "Tài liệu này được biên soạn đặc biệt để phục vụ buổi chấm Lab 3 và bảo vệ Assignment. "
        "Tập trung chính xác vào 2 chỉ đạo của Thầy Phương: (1) Cấu trúc 3 slide What-Why-How-Where cho 9 công nghệ, "
        "và (2) Kịch bản thao tác thực tế trên Firebase Console khi Thầy yêu cầu trình diễn trực tiếp.",
        title="MỤC ĐÍCH TÀI LIỆU"
    )
    
    # -------------------------------------------------------------
    # PHẦN 1
    # -------------------------------------------------------------
    h1 = doc.add_heading(level=1)
    r_h1 = h1.add_run("PHẦN 1: 6 THAO TÁC CỐT LÕI TRÊN FIREBASE CONSOLE KHI THẦY YÊU CẦU")
    r_h1.font.name = "Segoe UI"
    r_h1.font.bold = True
    r_h1.font.size = Pt(13)
    r_h1.font.color.rgb = RGBColor(211, 84, 0)
    h1.paragraph_format.space_before = Pt(12)
    h1.paragraph_format.space_after = Pt(6)
    
    p_note = doc.add_paragraph()
    p_note.add_run("👉 Đăng nhập sẵn trước trên Chrome: ").bold = True
    p_note.add_run("https://console.firebase.google.com ➔ Project: exe-team-matching-70774\n")
    p_note.add_run("👉 Mở song song 1 tab Web Giảng viên: ").bold = True
    p_note.add_run("http://localhost:5050")
    
    # Thao tác 1
    doc.add_heading("1. Xem FCM Token của thiết bị lưu ở đâu trên Firestore (Cực kỳ quan trọng)", level=2)
    p1 = doc.add_paragraph()
    p1.add_run("• Vấn đề thầy muốn kiểm tra: ").bold = True
    p1.add_run("FCM Token sinh ra từ đâu? Client có lưu lại không? Lưu ở chỗ nào trên Database?\n")
    p1.add_run("• Thao tác trên Firebase Console: \n").bold = True
    p1.add_run("   1. Menu bên trái: Chọn Build ➔ Firestore Database ➔ Tab Data.\n"
               "   2. Cột 1 (Collections): Chọn collection users.\n"
               "   3. Cột 2 (Documents): Chọn User UID của bạn (ví dụ: nVgzcc0j8yMu4C8JXkeW5XhsOdP2).\n"
               "   4. Cột 3 (Subcollections): Nhấp vào sub-collection fcm_tokens.\n"
               "   5. Bạn sẽ thấy Document ID chính là dãy FCM token dài ngoằng của điện thoại thật.\n")
    p1.add_run("• Lời giải thích khi chỉ màn hình: ").bold = True
    p1.add_run("\"Dạ thưa thầy, khi mở app và sinh viên đăng nhập Google, NotificationService gọi getToken() của Firebase Messaging. "
               "Sau đó app gọi saveFcmToken() lưu token vào đường dẫn users/{uid}/fcm_tokens/{token}. "
               "Việc dùng sub-collection giúp một sinh viên đăng nhập trên nhiều máy (điện thoại + tablet) đều lưu đủ token, "
               "và khi sinh viên bấm Đăng xuất, app sẽ tự xóa token của thiết bị đó.\"")
    
    # Thao tác 2
    doc.add_heading("2. Đổi giá trị Remote Config trực tiếp để app thay đổi tức thì (Live Demo)", level=2)
    p2 = doc.add_paragraph()
    p2.add_run("• Vấn đề thầy muốn kiểm tra: ").bold = True
    p2.add_run("Làm sao đổi giao diện/hành vi app mà không cần cài lại file APK?\n")
    p2.add_run("• Thao tác trên Firebase Console: \n").bold = True
    p2.add_run("   1. Menu bên trái: Chọn Run (hoặc Release & Monitor) ➔ Remote Config.\n"
               "   2. Trong danh sách Parameters, tìm tham số announcement_banner.\n"
               "   3. Nhấp vào cây bút (Edit), đổi giá trị Default value thành:\n"
               "      \"[THÔNG BÁO KHẨN]: Hạn chót nộp đơn vào Room là 23h59 hôm nay!\"\n"
               "   4. Bấm Save (Lưu) ➔ Bấm nút Publish changes màu xanh ở góc trên bên phải để xuất bản.\n")
    p2.add_run("• Quan sát trên điện thoại thật: ").bold = True
    p2.add_run("Không cần tắt app, nhờ cơ chế onConfigUpdated.listen() trong code, "
               "thanh thông báo màu cam sẽ tự động nảy ra trên đầu màn hình danh sách Room ngay tức thì!\n")
    p2.add_run("• Thao tác phụ (nếu thầy yêu cầu): ").bold = True
    p2.add_run("Sửa tham số room_list_limit từ 50 xuống 3 ➔ Danh sách trên app sẽ chỉ hiển thị đúng 3 Room.")
    
    # Thao tác 3
    doc.add_heading("3. Kiểm tra Crashlytics: Dev xem trên Firebase Console vs Admin xem trên Web", level=2)
    p3 = doc.add_paragraph()
    p3.add_run("• Vấn đề thầy muốn kiểm tra: ").bold = True
    p3.add_run("Cách kích hoạt crash, cơ chế gửi báo cáo lỗi, và giao diện xem lỗi cho Dev và Admin.\n")
    p3.add_run("• Thao tác Demo Crash trên điện thoại: \n").bold = True
    p3.add_run("   1. Mở app sinh viên ➔ Vào tab Hồ sơ ➔ Bấm nút \"Gây crash thử nghiệm\" ➔ Xác nhận.\n"
               "   2. App lập tức bị văng (Crash đột ngột).\n"
               "   3. Mở lại app lần 2 (Bắt buộc phải mở lại để SDK đọc log từ disk gửi lên server).\n")
    p3.add_run("• Xem kết quả phía Dev Team (Firebase Console): \n").bold = True
    p3.add_run("   ➔ Vào Release & Monitor ➔ Crashlytics ➔ Chọn app Android.\n"
               "   ➔ Xem danh sách lỗi Fatal: Click vào lỗi xem chi tiết Stack Trace, model máy thật, Android version, "
               "và Custom Keys (uid, user_role).\n")
    p3.add_run("• Xem kết quả phía Admin/Giảng viên (Web Quản Trị): \n").bold = True
    p3.add_run("   ➔ Mở tab localhost:5050 ➔ Chọn menu Sự cố ở thanh bên trái.\n"
               "   ➔ Web sẽ hiển thị bảng tóm tắt lỗi (được đọc từ Firestore collection crash_logs do app ghi tự động).")
    
    # Thao tác 4
    doc.add_heading("4. Bắn thông báo Push Notification (FCM) từ Server Python", level=2)
    p4 = doc.add_paragraph()
    p4.add_run("• Vấn đề thầy muốn kiểm tra: ").bold = True
    p4.add_run("Server gửi FCM thế nào? Có dùng Admin SDK không? Làm sao điện thoại nhận được?\n")
    p4.add_run("• Thao tác trên Terminal: \n").bold = True
    p4.add_run("   Mở cửa sổ dòng lệnh tại thư mục PRM393 và chạy:\n"
               "   python server/send_fcm.py --uid nVgzcc0j8yMu4C8JXkeW5XhsOdP2 --title \"Duyệt nhóm\" --body \"Bạn đã được chấp thuận vào nhóm EXE101!\"\n")
    p4.add_run("• Kết quả: ").bold = True
    p4.add_run("Điện thoại Android đang cắm cáp sẽ ting ting nổ chuông và hiện thanh notification trên đầu màn hình!\n")
    p4.add_run("• Chạy server tự động nghe sự kiện (Live Event Listening): \n").bold = True
    p4.add_run("   python server/notify_events.py\n"
               "   Khi bất kỳ sinh viên nào nộp đơn Apply hoặc Room mở biểu quyết, script này tự động phát hiện trên Firestore và bắn thông báo tức thì.")
    
    # Thao tác 5
    doc.add_heading("5. Mở và giải thích Security Rules trên Firestore", level=2)
    p5 = doc.add_paragraph()
    p5.add_run("• Vấn đề thầy muốn kiểm tra: ").bold = True
    p5.add_run("google-services.json có bảo mật không? Hacker sửa dữ liệu từ client thì chặn thế nào?\n")
    p5.add_run("• Thao tác trên Firebase Console: \n").bold = True
    p5.add_run("   Vào Firestore Database ➔ Tab Rules ➔ Cuộn xuống chỉ cho thầy các hàm:\n"
               "   • isStudent(): request.auth.token.email kết thúc bằng @fpt.edu.vn\n"
               "   • isLecturer(): request.auth.token.email kết thúc bằng @fe.edu.vn\n"
               "   • match /rooms/{roomId}: Chỉ thành viên trong nhóm mới được update trạng thái phòng.\n"
               "   • match /users/{uid}: Chỉ chủ sở hữu (request.auth.uid == uid) mới được sửa thông tin cá nhân.\n")
    p5.add_run("• Câu chốt hạ: ").bold = True
    p5.add_run("\"Dạ file config json ở client không phải là nơi bảo mật. Bức tường lửa bảo vệ 100% dữ liệu của hệ thống là Security Rules chạy trên server Firebase.\"")
    
    # Thao tác 6
    doc.add_heading("6. Kiểm tra tài khoản đã đăng nhập trong Authentication", level=2)
    p6 = doc.add_paragraph()
    p6.add_run("• Thao tác trên Firebase Console: \n").bold = True
    p6.add_run("   Vào Build ➔ Authentication ➔ Tab Users.\n"
               "   Chỉ cho thầy: Danh sách email sinh viên/admin, cột User UID (dùng làm khóa chính xuyên suốt các collection), "
               "cột Provider (Google icon), và thời gian Last Sign-in.")

    # -------------------------------------------------------------
    # PHẦN 2
    # -------------------------------------------------------------
    doc.add_page_break()
    h2 = doc.add_heading(level=1)
    r_h2 = h2.add_run("PHẦN 2: BỘ CÂU HỎI XOÁY KINH ĐIỂN CỦA THẦY & CÁCH TRẢ LỜI AN TOÀN")
    r_h2.font.name = "Segoe UI"
    r_h2.font.bold = True
    r_h2.font.size = Pt(13)
    r_h2.font.color.rgb = RGBColor(211, 84, 0)
    h2.paragraph_format.space_before = Pt(12)
    h2.paragraph_format.space_after = Pt(6)
    
    add_qa_box(
        doc,
        question="FCM token là gì? Ở đâu cấp? Client có lưu không? Tại sao app không tự gửi tin nhắn cho máy khác mà phải qua server Python?",
        answer="FCM Token là mã định danh duy nhất cho một lần cài đặt app trên một thiết bị cụ thể. "
               "Token do máy chủ FCM (Google) cấp khi app gọi FirebaseMessaging.instance.getToken(). "
               "Client CÓ LƯU token lên Firestore tại đường dẫn users/{uid}/fcm_tokens/{token}. "
               "App mobile KHÔNG ĐƯỢC PHÉP tự gửi tin nhắn vì việc gửi FCM chuẩn HTTP v1 bắt buộc phải có file khóa bí mật Service Account (Private Key). "
               "Nếu nhúng Service Account vào APK thì hacker dịch ngược app sẽ lấy trộm được toàn quyền kiểm soát Firebase. "
               "Do đó, Server Python phía sau giữ key an toàn để gửi tin nhắn thay cho client.",
        code_note="flutter_app/lib/services/notification_service.dart & server/send_fcm.py"
    )
    
    add_qa_box(
        doc,
        question="Code server gửi FCM nằm ở đâu? Gồm những file nào và hoạt động ra sao?",
        answer="Code server nằm ở thư mục server/ gồm 3 file: "
               "(1) server/send_fcm.py: Dùng Firebase Admin SDK đọc token từ Firestore và gọi FCM HTTP v1 để gửi notification. "
               "(2) server/notification_rules.py: Định nghĩa quy tắc nghiệp vụ: sự kiện nào thì thông báo cho ai (ví dụ: có đơn mới thì báo cho Leader). "
               "(3) server/notify_events.py: Chạy ngầm lắng nghe Stream Firestore trên collection applications và transfer_requests, khi có dữ liệu mới thì tự động kích hoạt gửi FCM.",
        code_note="Thư mục server/ trong dự án PRM393"
    )
    
    add_qa_box(
        doc,
        question="Client dùng FCM ra sao? Xử lý 3 trạng thái ứng dụng như thế nào?",
        answer="App xử lý đầy đủ các trạng thái của vòng đời ứng dụng: "
               "1. Khi App đang mở (Foreground): FirebaseMessaging.onMessage nhận data và dùng thư viện flutter_local_notifications để tự bắn banner cục bộ trên màn hình. "
               "2. Khi App chạy ngầm (Background): FirebaseMessaging.onBackgroundMessage nhận và hệ điều hành tự hiện thông báo. "
               "3. Khi Người dùng bấm vào thông báo: onMessageOpenedApp (từ nền) hoặc getInitialMessage (khi app đang tắt hẳn) sẽ đọc tham số payload data.roomId để tự động điều hướng mở thẳng vào chi tiết Room đó.",
        code_note="lib/services/notification_service.dart (hàm initialize)"
    )
    
    add_qa_box(
        doc,
        question="Tại sao khi bấm nút Crash trên điện thoại xong, mở Web Admin hoặc Firebase Console chưa thấy log ngay?",
        answer="Vì khi app crash, tiến trình (process) của app bị hệ điều hành Android ngắt đột ngột, SDK Crashlytics chỉ kịp ghi log khẩn cấp xuống bộ nhớ đệm (disk storage) của điện thoại. "
               "Bắt buộc người dùng phải MỞ LẠI APP LẦN 2, SDK mới khởi động và truyền gói tin crash đó lên máy chủ Firebase Console. "
               "Đồng thời, hàm didCrashOnPreviousExecution() trong app sẽ phát hiện lần mở trước bị crash để ghi một bản ghi tóm tắt vào collection crash_logs trên Firestore cho Web Admin xem.",
        code_note="lib/services/crashlytics_service.dart (hàm _reportPreviousCrash)"
    )
    
    add_qa_box(
        doc,
        question="Phần upload file PDF nhóm dùng gì thay thế Firebase Storage? Có bị lộ Secret Key trong APK không?",
        answer="Nhóm sử dụng dịch vụ Cloudinary để thay thế Firebase Storage (do Storage yêu cầu thẻ tín dụng gói Blaze). "
               "Nhóm dùng cơ chế UNSIGNED UPLOAD PRESET. App Android chỉ gửi Cloud Name và tên Preset cấu hình sẵn qua REST API HTTPS, "
               "hoàn toàn KHÔNG lưu API Secret trong mã nguồn hay APK. "
               "Trên trang quản trị Cloudinary, Preset đã được khoá chặt: chỉ cho phép upload định dạng PDF, dung lượng tối đa 10MB và tự động gom vào thư mục exe_reports/{uid}.",
        code_note="lib/services/file_storage_service.dart (hàm uploadPdf)"
    )
    
    add_qa_box(
        doc,
        question="File danh sách lớp tải từ FAP có đuôi là .xls cũ, làm sao hệ thống đọc được?",
        answer="Cổng đào tạo FAP của Đại học FPT khi xuất file Excel sẽ dùng đuôi .xls, nhưng thực chất cấu trúc bên trong là chuẩn XML Spreadsheet 2003 (SpreadsheetML). "
               "Nhóm em đã viết trực tiếp bộ parser XML thuần bằng Dart trong RosterParser._readSpreadsheetMl() "
               "để bóc tách từng thẻ <Row>, <Cell>, <Data> và tự động nhận diện các cột RollNumber, FullName, Email mà không cần thư viện ngoài. "
               "Nhóm đã test thành công trực tiếp với file thật SE1919_PRN232...xls của lớp.",
        code_note="lib/domain/roster_parser.dart (hàm _readSpreadsheetMl)"
    )
    
    add_qa_box(
        doc,
        question="Tại sao nhóm dùng MVVM + Provider? Làm sao chống lỗi 2 sinh viên cùng bấm giành 1 chỗ cuối trong Room (Race Condition)?",
        answer="MVVM tách biệt rõ 3 lớp: Model (dữ liệu), View (chỉ vẽ UI), ViewModel (xử lý logic nghiệp vụ). "
               "Provider giúp phân phối ViewModel xuống cây Widget và chỉ vẽ lại những widget cần thiết qua notifyListeners(). "
               "Để chống Race Condition khi 2 người cùng bấm vào chỗ trống cuối cùng, nhóm sử dụng FIRESTORE TRANSACTION (runTransaction). "
               "Transaction sẽ đọc số lượng thành viên hiện tại của Room, nếu còn chỗ mới ghi thêm; "
               "nếu có người ghi chen vào giữa, Firestore sẽ tự động rollback và thử lại, đảm bảo chỉ duy nhất một người thành công, người kia sẽ nhận thông báo phòng đã đủ sĩ số.",
        code_note="lib/services/group_service.dart (hàm joinRoom dùng runTransaction)"
    )

    # -------------------------------------------------------------
    # PHẦN 3
    # -------------------------------------------------------------
    doc.add_page_break()
    h3 = doc.add_heading(level=1)
    r_h3 = h3.add_run("PHẦN 3: BẢNG TỔNG HỢP 9 CÔNG NGHỆ LAB 3 (CHUẨN WHAT - WHY - HOW - WHERE)")
    r_h3.font.name = "Segoe UI"
    r_h3.font.bold = True
    r_h3.font.size = Pt(13)
    r_h3.font.color.rgb = RGBColor(211, 84, 0)
    h3.paragraph_format.space_before = Pt(12)
    h3.paragraph_format.space_after = Pt(6)
    
    # Table of 9 technologies
    tbl_tech = doc.add_table(rows=1, cols=5)
    tbl_tech.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_tech.autofit = False
    
    headers = ["STT & Tên", "What (Nó là gì?)", "Why (Tại sao dùng?)", "How (Cơ chế hoạt động)", "Where (Vị trí code & tích hợp)"]
    widths = [Inches(1.2), Inches(1.4), Inches(1.4), Inches(1.5), Inches(1.3)]
    
    for i, h in enumerate(headers):
        cell = tbl_tech.cell(0, i)
        cell.width = widths[i]
        set_cell_background(cell, "D35400")
        set_cell_margins(cell, top=100, bottom=100, left=100, right=100)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.font.name = "Segoe UI"
        r.font.bold = True
        r.font.size = Pt(9.5)
        r.font.color.rgb = RGBColor(255, 255, 255)
        
    tech_data = [
        ("01. MVVM + Provider", 
         "Kiến trúc phân tách Model - View - ViewModel kèm thư viện quản lý state Provider.",
         "UI không gọi Firebase trực tiếp; dễ unit test logic domain không cần mở app.",
         "View gọi read<VM>() ra lệnh; watch<VM>() nghe state; VM gọi Service và notifyListeners().",
         "lib/viewmodels/, lib/services/, lib/models/, lib/domain/"),
        ("02. Firebase Auth",
         "Dịch vụ định danh Google Sign-In cấp phiên làm việc bằng ID Token JWT.",
         "Sinh viên dùng email trường (@fpt.edu.vn, @fe.edu.vn), không cần tự viết lưu mật khẩu.",
         "App dùng signInWithProvider; Web dùng signInWithPopup; Security Rules đọc request.auth.",
         "lib/services/auth_service.dart, AuthGate, AdminGate"),
        ("03. Cloud Firestore",
         "CSDL NoSQL đám mây hỗ trợ Realtime Stream và Security Rules phân quyền server.",
         "Số chỗ trong Room đổi liên tục cần realtime; Transaction chống race condition.",
         "snapshots() lắng nghe thay đổi; runTransaction khóa đọc-ghi an toàn; Batch ghi gộp.",
         "lib/services/group_service.dart, admin_service.dart, firestore.rules"),
        ("04. Firebase Cloud Messaging",
         "Dịch vụ Push Notification gửi thông báo đến máy thật kể cả khi tắt app.",
         "Báo tin tức thời khi có đơn Apply mới, mở vote, có kết quả duyệt nhóm.",
         "Client lấy token lưu Firestore; Server Python Admin SDK đọc token và gửi FCM HTTP v1.",
         "lib/services/notification_service.dart, server/send_fcm.py, notify_events.py"),
        ("05. Google Analytics",
         "Thu thập và phân tích hành vi người dùng theo sự kiện (Events) và thuộc tính (User Properties).",
         "Theo dõi tỷ lệ chuyển đổi: đăng nhập, tạo đơn Apply, vote nhóm, xuất PDF.",
         "ViewModel gọi logEvent; SDK gom lô gửi định kỳ; bật DebugView qua lệnh adb shell setprop.",
         "lib/services/analytics_service.dart, observer trong lib/main.dart"),
        ("06. Firebase Crashlytics",
         "Báo cáo sự cố app thời gian thực: Fatal (crash) và Non-fatal (lỗi bắt được).",
         "Máy người dùng lỗi dev không thể xem log trực tiếp; giúp định vị chính xác dòng code gây crash.",
         "Bắt lỗi toàn cục qua PlatformDispatcher.onError; ghi kèm UID; mở lại app gửi log lên server.",
         "lib/services/crashlytics_service.dart, nút test trong profile_screen.dart"),
        ("07. Remote Config",
         "Kho tham số key-value trên đám mây giúp thay đổi hành vi app từ xa không cần build APK.",
         "Đăng banner thông báo khẩn cấp lên đầu app; giới hạn số Room tải về khi môn quá đông.",
         "setDefaults giá trị mặc định; fetch và activate; onConfigUpdated lắng nghe thay đổi realtime.",
         "lib/services/remote_config_service.dart, announcement_banner, room_list_limit"),
        ("08. Cloudinary",
         "Dịch vụ lưu trữ media & PDF trên đám mây thay thế Firebase Storage.",
         "Firestore giới hạn 1MB/doc; Storage cần thẻ tín dụng; Cloudinary có gói free đủ dùng.",
         "Unsigned Upload Preset gửi REST API multipart; nhận secure_url lưu vào Firestore metadata.",
         "lib/services/file_storage_service.dart, report_pdf_builder.dart"),
        ("09. Flutter Web",
         "Biên dịch mã nguồn Dart thành ứng dụng Web chạy trên trình duyệt cho Giảng viên.",
         "Thầy yêu cầu Admin dùng Web; quản lý nhiều lớp trên màn hình lớn; tái sử dụng toàn bộ Model.",
         "Điểm vào riêng main_admin.dart; kiểm tra quyền @fe.edu.vn hoặc Demo Admin qua Rules.",
         "lib/main_admin.dart, lib/screens/admin/admin_pages.dart, admin_viewmodel.dart"),
    ]
    
    for row_idx, item in enumerate(tech_data):
        row = tbl_tech.add_row()
        bg = "FFFFFF" if row_idx % 2 == 0 else "FDF6E2"
        for col_idx in range(5):
            cell = row.cells[col_idx]
            cell.width = widths[col_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            r = p.add_run(item[col_idx])
            r.font.name = "Segoe UI"
            r.font.size = Pt(8.5)
            if col_idx == 0:
                r.font.bold = True
                r.font.color.rgb = RGBColor(180, 60, 0)
            else:
                r.font.color.rgb = RGBColor(50, 50, 50)
                
    # -------------------------------------------------------------
    # PHẦN 4
    # -------------------------------------------------------------
    doc.add_page_break()
    h4 = doc.add_heading(level=1)
    r_h4 = h4.add_run("PHẦN 4: CHECKLIST CHUẨN BỊ TRƯỚC GIỜ BẢO VỆ & LỆNH TERMINAL NHANH")
    r_h4.font.name = "Segoe UI"
    r_h4.font.bold = True
    r_h4.font.size = Pt(13)
    r_h4.font.color.rgb = RGBColor(211, 84, 0)
    h4.paragraph_format.space_before = Pt(12)
    h4.paragraph_format.space_after = Pt(6)
    
    doc.add_heading("1. Checklist trước khi mở màn hình trình chiếu", level=2)
    p_ck = doc.add_paragraph()
    p_ck.add_run("☑ Mở sẵn 1 tab Chrome: ").bold = True
    p_ck.add_run("Trang Firebase Console (Firestore Data, Remote Config, Crashlytics).\n")
    p_ck.add_run("☑ Mở sẵn 1 tab Chrome: ").bold = True
    p_ck.add_run("Trang Web Giảng viên (http://localhost:5050).\n")
    p_ck.add_run("☑ Cắm sẵn cáp USB: ").bold = True
    p_ck.add_run("Điện thoại Android kết nối máy tính, bật USB Debugging, màn hình sáng sẵn.\n")
    p_ck.add_run("☑ Slide PowerPoint: ").bold = True
    p_ck.add_run("Đã DELETE hoặc HIDE Slide số 30 (Slide nội bộ) trước khi chiếu lên máy chiếu.\n")
    p_ck.add_run("☑ File mẫu Import FAP: ").bold = True
    p_ck.add_run("Để sẵn file SE1919_PRN232...xls ở màn hình Desktop để bấm Import là ra ngay.")
    
    doc.add_heading("2. Bảng tổng hợp các lệnh Terminal chạy nhanh", level=2)
    
    tbl_cmd = doc.add_table(rows=1, cols=3)
    tbl_cmd.alignment = WD_TABLE_ALIGNMENT.CENTER
    tbl_cmd.autofit = False
    
    cmd_headers = ["Mục đích", "Lệnh Terminal", "Ghi chú"]
    cmd_widths = [Inches(1.8), Inches(3.6), Inches(1.4)]
    
    for i, h in enumerate(cmd_headers):
        cell = tbl_cmd.cell(0, i)
        cell.width = cmd_widths[i]
        set_cell_background(cell, "2C3E50")
        set_cell_margins(cell, top=80, bottom=80, left=100, right=100)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(h)
        r.font.name = "Segoe UI"
        r.font.bold = True
        r.font.size = Pt(9.5)
        r.font.color.rgb = RGBColor(255, 255, 255)
        
    cmd_data = [
        ("Chạy Web Giảng viên", 
         "cd flutter_app\nflutter run -d chrome --web-port 5050 -t lib/main_admin.dart",
         "Tự cấp quyền Admin cho email của bạn"),
        ("Chạy App lên Android thật",
         "cd flutter_app\nflutter devices\nflutter run",
         "Cắm cáp USB chọn đúng mã máy Android"),
        ("Bắn FCM từ Server",
         "python server/send_fcm.py --uid <UID> --title \"Thong bao\" --body \"Noi dung\"",
         "Chạy từ thư mục gốc PRM393"),
        ("Chạy Server nghe sự kiện",
         "python server/notify_events.py",
         "Tự động gửi thông báo khi có đơn Apply mới"),
        ("Hot Restart code",
         "Bấm phím R (viết hoa) trong Terminal",
         "Nạp lại toàn bộ code mới không cần bật lại app"),
        ("Hot Reload nhanh",
         "Bấm phím r (viết thường) trong Terminal",
         "Cập nhật thay đổi giao diện UI nhanh"),
    ]
    
    for row_idx, item in enumerate(cmd_data):
        row = tbl_cmd.add_row()
        bg = "FFFFFF" if row_idx % 2 == 0 else "F8F9F9"
        for col_idx in range(3):
            cell = row.cells[col_idx]
            cell.width = cmd_widths[col_idx]
            set_cell_background(cell, bg)
            set_cell_margins(cell, top=80, bottom=80, left=80, right=80)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            r = p.add_run(item[col_idx])
            if col_idx == 1:
                r.font.name = "Consolas"
                r.font.size = Pt(8.5)
                r.font.bold = True
                r.font.color.rgb = RGBColor(30, 80, 160)
            else:
                r.font.name = "Segoe UI"
                r.font.size = Pt(9)
                r.font.color.rgb = RGBColor(40, 40, 40)
                
    # Save to both locations
    path1 = r"E:\PRM\Test 1\CAM_NANG_THAO_TAC_FIREBASE_VA_VAN_DAP.docx"
    path2 = r"E:\PRM\Test 1\PRM393\docs\CAM_NANG_THAO_TAC_FIREBASE_VA_VAN_DAP.docx"
    
    doc.save(path1)
    doc.save(path2)
    print(f"Xuat file Word thanh cong:\n1. {path1}\n2. {path2}")

if __name__ == "__main__":
    create_document()
