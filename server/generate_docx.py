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

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = parse_xml(f'<w:tcMar {nsdecls("w")}><w:top w:w="{top}" w:type="dxa"/><w:bottom w:w="{bottom}" w:type="dxa"/><w:left w:w="{left}" w:type="dxa"/><w:right w:w="{right}" w:type="dxa"/></w:tcMar>')
    tcPr.append(tcMar)

def create_document():
    doc = Document()
    
    # Page setup
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
    # Styles setup
    style_normal = doc.styles['Normal']
    font = style_normal.font
    font.name = 'Segoe UI'
    font.size = Pt(10.5)
    font.color.rgb = RGBColor(40, 40, 40)
    
    # Title
    p_title = doc.add_paragraph()
    p_title.paragraph_format.space_after = Pt(4)
    run_title = p_title.add_run("TÀI LIỆU HƯỚNG DẪN KIỂM THỬ TRÊN THIẾT BỊ ANDROID THẬT")
    run_title.font.name = 'Segoe UI'
    run_title.font.size = Pt(17)
    run_title.font.bold = True
    run_title.font.color.rgb = RGBColor(211, 84, 0) # Primary Orange FPT/Firebase
    
    # Subtitle
    p_sub = doc.add_paragraph()
    p_sub.paragraph_format.space_after = Pt(14)
    r_sub = p_sub.add_run("Hệ thống: EXE Team Matching (PRM393 - Lab 3) · Nhánh: feature/docx-business-mvvm")
    r_sub.font.italic = True
    r_sub.font.size = Pt(10)
    r_sub.font.color.rgb = RGBColor(120, 120, 120)
    
    # Horizontal rule
    p_hr = doc.add_paragraph()
    p_hr.paragraph_format.space_after = Pt(12)
    p_hr_border = parse_xml(f'<w:pBdr {nsdecls("w")}><w:bottom w:val="single" w:sz="6" w:space="1" w:color="D35400"/></w:pBdr>')
    p_hr._p.get_or_add_pPr().append(p_hr_border)
    
    # Section 1: Muc tieu
    h1 = doc.add_heading(level=1)
    h1.paragraph_format.space_before = Pt(12)
    h1.paragraph_format.space_after = Pt(6)
    r1 = h1.add_run("1. MỤC TIÊU KIỂM THỬ")
    r1.font.name = 'Segoe UI'
    r1.font.bold = True
    r1.font.size = Pt(13)
    r1.font.color.rgb = RGBColor(31, 78, 121)
    
    doc.add_paragraph("Tài liệu này được lập nhằm hướng dẫn chi tiết cho thành viên trong nhóm kiểm tra toàn diện 6 tính năng nghiệp vụ cốt lõi trên điện thoại Android thật để chuẩn bị cho buổi nghiệm thu với Giảng viên:")
    
    goals = [
        "Chạy ứng dụng trực tiếp trên điện thoại Android thật qua cáp kết nối USB.",
        "Kiểm tra tự động ghi nhận FCM Token và nhận thông báo đẩy thời gian thực từ Server Python.",
        "Kích hoạt và theo dõi lỗi trên Firebase Crashlytics (Fatal Crash và Non-fatal Handled Error).",
        "Kiểm tra luồng Bỏ phiếu kín duyệt thành viên vào nhóm (Quy tắc BR-25: cần hơn 50% thành viên đồng ý).",
        "Xuất và tải lên biên bản báo cáo đề án dạng PDF lưu trữ Cloudinary.",
        "Đồng bộ trạng thái với trang Web Quản trị của Giảng viên (Web Moderator & Import danh sách FAP)."
    ]
    for g in goals:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_after = Pt(3)
        p.add_run(g)
        
    # Section 2: Chuan bi
    h2 = doc.add_heading(level=1)
    h2.paragraph_format.space_before = Pt(14)
    h2.paragraph_format.space_after = Pt(6)
    r2 = h2.add_run("2. CHUẨN BỊ MÔI TRƯỜNG & LẤY CODE")
    r2.font.name = 'Segoe UI'
    r2.font.bold = True
    r2.font.size = Pt(13)
    r2.font.color.rgb = RGBColor(31, 78, 121)
    
    doc.add_paragraph("Bước 1: Lấy mã nguồn mới nhất từ GitHub:")
    
    # Code box
    tbl_code1 = doc.add_table(rows=1, cols=1)
    tbl_code1.alignment = WD_TABLE_ALIGNMENT.CENTER
    c1 = tbl_code1.cell(0, 0)
    set_cell_background(c1, "F2F4F7")
    set_cell_margins(c1, 120, 120, 180, 180)
    p_code1 = c1.paragraphs[0]
    p_code1.paragraph_format.space_after = Pt(0)
    r_code1 = p_code1.add_run("git fetch origin\ngit checkout feature/docx-business-mvvm\ngit pull origin feature/docx-business-mvvm")
    r_code1.font.name = 'Consolas'
    r_code1.font.size = Pt(9.5)
    r_code1.font.color.rgb = RGBColor(40, 40, 40)
    
    doc.add_paragraph().paragraph_format.space_after = Pt(4)
    doc.add_paragraph("Bước 2: Cấu hình điện thoại Android:")
    p = doc.add_paragraph(style='List Bullet')
    p.add_run("Vào Cài đặt > Thông tin điện thoại > Nhấn 7 lần vào 'Số hiệu bản dựng' (Build number) để bật quyền Nhà phát triển.")
    p = doc.add_paragraph(style='List Bullet')
    p.add_run("Vào Cài đặt > Tùy chọn nhà phát triển > Gạt BẬT 'Gỡ lỗi qua USB' (USB Debugging).")
    p = doc.add_paragraph(style='List Bullet')
    p.add_run("Cắm cáp USB nối điện thoại vào máy tính, trên màn hình điện thoại chọn 'Luôn cho phép'.")
    p = doc.add_paragraph(style='List Bullet')
    p.add_run("Kiểm tra máy nhận diện bằng lệnh: flutter devices")
    
    doc.add_paragraph("Bước 3: Khởi chạy ứng dụng lên máy thật:")
    tbl_code2 = doc.add_table(rows=1, cols=1)
    tbl_code2.alignment = WD_TABLE_ALIGNMENT.CENTER
    c2 = tbl_code2.cell(0, 0)
    set_cell_background(c2, "F2F4F7")
    set_cell_margins(c2, 120, 120, 180, 180)
    p_code2 = c2.paragraphs[0]
    p_code2.paragraph_format.space_after = Pt(0)
    r_code2 = p_code2.add_run("cd flutter_app\nflutter pub get\nflutter run")
    r_code2.font.name = 'Consolas'
    r_code2.font.size = Pt(9.5)
    r_code2.font.color.rgb = RGBColor(40, 40, 40)
    
    # Section 3: Chi tiet 6 bai test
    h3 = doc.add_heading(level=1)
    h3.paragraph_format.space_before = Pt(16)
    h3.paragraph_format.space_after = Pt(6)
    r3 = h3.add_run("3. CHECKLIST 6 HẠNG MỤC KIỂM THỬ TRÊN MÁY THẬT")
    r3.font.name = 'Segoe UI'
    r3.font.bold = True
    r3.font.size = Pt(13)
    r3.font.color.rgb = RGBColor(31, 78, 121)
    
    # Test 1
    h_t1 = doc.add_heading(level=2)
    h_t1.paragraph_format.space_before = Pt(8)
    h_t1.paragraph_format.space_after = Pt(4)
    rt1 = h_t1.add_run("TEST 1: Đăng nhập Google & Kiểm tra lưu FCM Token")
    rt1.font.bold = True
    rt1.font.size = Pt(11)
    rt1.font.color.rgb = RGBColor(192, 57, 43)
    
    p = doc.add_paragraph()
    p.add_run("• Mục tiêu: ").bold = True
    p.add_run("Sinh viên đăng nhập bằng email trường FPT và ứng dụng tự động đẩy token thiết bị lên Firestore.")
    p = doc.add_paragraph()
    p.add_run("• Thao tác: ").bold = True
    p.add_run("Mở app trên Android > Bấm 'Đăng nhập bằng Google' chọn tài khoản @fpt.edu.vn > Hoàn tất khai báo hồ sơ kỹ năng và cam kết.")
    p = doc.add_paragraph()
    p.add_run("• Tiêu chuẩn PASS: ").bold = True
    p.add_run("Vào được trang chủ. Lên Firebase Console > Firestore Database > users > [UID] > sub-collection fcm_tokens: xuất hiện 1 document token thiết bị với platform: 'android'.")
    
    # Test 2
    h_t2 = doc.add_heading(level=2)
    h_t2.paragraph_format.space_before = Pt(10)
    h_t2.paragraph_format.space_after = Pt(4)
    rt2 = h_t2.add_run("TEST 2: Nhận thông báo đẩy FCM từ Server Python")
    rt2.font.bold = True
    rt2.font.size = Pt(11)
    rt2.font.color.rgb = RGBColor(192, 57, 43)
    
    p = doc.add_paragraph()
    p.add_run("• Mục tiêu: ").bold = True
    p.add_run("Thiết bị Android nhận thông báo đẩy thời gian thực gửi từ server qua FCM HTTP v1.")
    p = doc.add_paragraph()
    p.add_run("• Thao tác trên máy tính: ").bold = True
    p.add_run("Mở PowerShell, đặt biến môi trường và chạy script bắn thông báo:")
    
    tbl_t2 = doc.add_table(rows=1, cols=1)
    tbl_t2.alignment = WD_TABLE_ALIGNMENT.CENTER
    ct2 = tbl_t2.cell(0, 0)
    set_cell_background(ct2, "F2F4F7")
    set_cell_margins(ct2, 100, 100, 150, 150)
    pt2 = ct2.paragraphs[0]
    pt2.paragraph_format.space_after = Pt(0)
    rt2_code = pt2.add_run('$env:GOOGLE_APPLICATION_CREDENTIALS="E:\\PRM\\Test 1\\exe-team-matching-70774-firebase-adminsdk-fbsvc-cbb25f4495.json"\npython server/send_fcm.py --uid <UID_SINH_VIEN> --title "Nhắc hạn ghép nhóm" --body "Còn 3 ngày nữa là chốt nhóm!"')
    rt2_code.font.name = 'Consolas'
    rt2_code.font.size = Pt(9)
    
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.add_run("• Tiêu chuẩn PASS: ").bold = True
    p.add_run("Thử nghiệm trên 3 trạng thái đều nhận thông báo:\n  + Foreground: Đang mở app (hiện pop-up nội bộ/chuông).\n  + Background: App ẩn dưới nền (thanh trạng thái Android hiện banner thông báo).\n  + Terminated: Đã tắt hẳn app (thanh thông báo vẫn hiện, bấm vào sẽ tự mở app).")
    
    # Test 3
    h_t3 = doc.add_heading(level=2)
    h_t3.paragraph_format.space_before = Pt(10)
    h_t3.paragraph_format.space_after = Pt(4)
    rt3 = h_t3.add_run("TEST 3: Kiểm thử Firebase Crashlytics (Demo sự cố cho Giảng viên)")
    rt3.font.bold = True
    rt3.font.size = Pt(11)
    rt3.font.color.rgb = RGBColor(192, 57, 43)
    
    p = doc.add_paragraph()
    p.add_run("• Mục tiêu: ").bold = True
    p.add_run("Chứng minh Crashlytics bắt lỗi tự động khi có sự cố xảy ra.")
    p = doc.add_paragraph()
    p.add_run("• Thao tác: ").bold = True
    p.add_run("Vào tab Hồ sơ (Profile) > cuộn xuống mục 'Kiểm tra Crashlytics (demo)':\n  1. Bấm 'Ghi lỗi thử nghiệm' (Handled Error) -> App gửi log lỗi nhẹ lên hệ thống.\n  2. Bấm 'Gây crash thử nghiệm' (Fatal Crash) > Xác nhận 'Crash ngay' -> App lập tức bị đóng lại (văng app).")
    p = doc.add_paragraph()
    p.add_run("• Tiêu chuẩn PASS: ").bold = True
    p.add_run("Mở lại app trên điện thoại (để gửi crash log lên Cloud). Vào Firebase Console > Crashlytics hoặc Web Moderator > mục Sự cố hệ thống: thấy bản ghi sự cố xuất hiện.")
    
    # Test 4
    h_t4 = doc.add_heading(level=2)
    h_t4.paragraph_format.space_before = Pt(10)
    h_t4.paragraph_format.space_after = Pt(4)
    rt4 = h_t4.add_run("TEST 4: Luồng Bỏ phiếu kín duyệt thành viên vào nhóm (Quy tắc BR-25)")
    rt4.font.bold = True
    rt4.font.size = Pt(11)
    rt4.font.color.rgb = RGBColor(192, 57, 43)
    
    p = doc.add_paragraph()
    p.add_run("• Quy tắc nghiệp vụ BR-25: ").bold = True
    p.add_run("Khi nhóm đã đủ 3 người (trạng thái Group), ứng viên mới nộp đơn phải qua bỏ phiếu kín. Đơn chỉ được chấp thuận khi có hơn 50% thành viên trong nhóm đồng ý (yes * 2 > memberCount).")
    p = doc.add_paragraph()
    p.add_run("• Kịch bản thử nghiệm: ").bold = True
    p.add_run("\n  1. Nhóm A đang có 3 thành viên (Ngưỡng đậu: cần 2 phiếu đồng ý).\n  2. Tài khoản thứ 4 bấm 'Xin gia nhập (Apply)' vào nhóm A.\n  3. Leader của nhóm A mở chi tiết phòng > Đơn xin gia nhập > Bấm 'Mở vote' cho ứng viên.\n  4. Thành viên 1 vào vote: Đồng ý (1/3 phiếu -> Đơn vẫn chờ).\n  5. Thành viên 2 vào vote: Đồng ý (2/3 phiếu -> Vượt 50%!).")
    p = doc.add_paragraph()
    p.add_run("• Tiêu chuẩn PASS: ").bold = True
    p.add_run("Ngay khi đạt phiếu thứ 2, đơn tự động đổi sang trạng thái 'accepted' và ứng viên thứ 4 lập tức xuất hiện trong danh sách thành viên của phòng mà không cần ai duyệt thêm.")
    
    # Test 5
    h_t5 = doc.add_heading(level=2)
    h_t5.paragraph_format.space_before = Pt(10)
    h_t5.paragraph_format.space_after = Pt(4)
    rt5 = h_t5.add_run("TEST 5: Xuất & Tải lên báo cáo đề án PDF (Cloudinary)")
    rt5.font.bold = True
    rt5.font.size = Pt(11)
    rt5.font.color.rgb = RGBColor(192, 57, 43)
    
    p = doc.add_paragraph()
    p.add_run("• Mục tiêu: ").bold = True
    p.add_run("Tạo biên bản chốt nhóm PDF và lưu trữ lên Cloudinary thông qua unsigned upload preset.")
    p = doc.add_paragraph()
    p.add_run("• Thao tác: ").bold = True
    p.add_run("Tạo file flutter_app/cloudinary.json (cloud name và upload preset unsigned). Chạy app với cờ --dart-define-from-file=cloudinary.json. Vào mục Báo cáo đề án > Bấm 'Xuất & Tải lên biên bản PDF'.")
    p = doc.add_paragraph()
    p.add_run("• Tiêu chuẩn PASS: ").bold = True
    p.add_run("App render PDF, hiện thanh tiến độ tải lên và trả về đường dẫn HTTPS trực tiếp xem file PDF trên Cloudinary.")
    
    # Test 6
    h_t6 = doc.add_heading(level=2)
    h_t6.paragraph_format.space_before = Pt(10)
    h_t6.paragraph_format.space_after = Pt(4)
    rt6 = h_t6.add_run("TEST 6: Web Quản trị của Giảng viên & Import danh sách FAP")
    rt6.font.bold = True
    rt6.font.size = Pt(11)
    rt6.font.color.rgb = RGBColor(192, 57, 43)
    
    p = doc.add_paragraph()
    p.add_run("• Mục tiêu: ").bold = True
    p.add_run("Kiểm tra giao diện Web Moderator dành cho Giảng viên và tính năng import danh sách sinh viên FAP từ file CSV/Excel.")
    p = doc.add_paragraph()
    p.add_run("• Thao tác: ").bold = True
    p.add_run("Chạy lệnh Web:")
    
    tbl_t6 = doc.add_table(rows=1, cols=1)
    tbl_t6.alignment = WD_TABLE_ALIGNMENT.CENTER
    ct6 = tbl_t6.cell(0, 0)
    set_cell_background(ct6, "F2F4F7")
    set_cell_margins(ct6, 100, 100, 150, 150)
    pt6 = ct6.paragraphs[0]
    pt6.paragraph_format.space_after = Pt(0)
    rt6_code = pt6.add_run('flutter run -d chrome --web-port 5050 -t lib/main_admin.dart --dart-define=DEMO_ADMIN_EMAIL=tulpnse185102@fpt.edu.vn')
    rt6_code.font.name = 'Consolas'
    rt6_code.font.size = Pt(9)
    
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(4)
    p.add_run("Đăng nhập bằng Google > Chọn môn FA26 - EXE101 > Bấm Import danh sách FAP > Chọn file docs/fap-roster-sample.csv.")
    p = doc.add_paragraph()
    p.add_run("• Tiêu chuẩn PASS: ").bold = True
    p.add_run("Danh sách sinh viên được nạp lên Firestore. Hệ thống tự động so khớp và thống kê danh sách sinh viên lẻ chưa có nhóm.")
    
    # Section 4: Luu y
    h4 = doc.add_heading(level=1)
    h4.paragraph_format.space_before = Pt(16)
    h4.paragraph_format.space_after = Pt(6)
    r4 = h4.add_run("4. NHỮNG LƯU Ý SỐNG CÒN KHI TRÌNH BÀY VỚI THẦY")
    r4.font.name = 'Segoe UI'
    r4.font.bold = True
    r4.font.size = Pt(13)
    r4.font.color.rgb = RGBColor(192, 57, 43)
    
    notes = [
        "Firestore Rules: Đảm bảo rules mới trong firestore.rules đã được Publish trên Firebase Console. Nếu chưa publish, thao tác vote và web sẽ bị chặn lỗi PERMISSION_DENIED.",
        "Bảo mật tài khoản: Tuyệt đối không commit file service-account.json (chứa private key) hoặc cloudinary.json lên GitHub.",
        "Kết nối mạng: Giữ điện thoại Android và máy tính cùng kết nối mạng Wifi/4G ổn định để Firebase đồng bộ dữ liệu tức thì."
    ]
    for n in notes:
        p = doc.add_paragraph(style='List Bullet')
        p.paragraph_format.space_after = Pt(3)
        p.add_run(n)
        
    doc.save("e:/PRM/Test 1/PRM393/docs/HUONG_DAN_KIEM_THU_DEVICE_THAT.docx")
    doc.save("e:/PRM/Test 1/HUONG_DAN_KIEM_THU_DEVICE_THAT.docx")
    print("Xuat file Word .docx thanh cong!")

if __name__ == "__main__":
    create_document()
