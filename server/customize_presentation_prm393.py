import os
import pptx
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor

def replace_text_in_paragraph(p, old_text, new_text):
    if old_text in p.text:
        # Try replacing in runs
        replaced_in_runs = False
        for r in p.runs:
            if old_text in r.text:
                r.text = r.text.replace(old_text, new_text)
                replaced_in_runs = True
        # If text was split across runs, replace at paragraph level
        if old_text in p.text:
            p.text = p.text.replace(old_text, new_text)

def replace_in_shape(shape, old_text, new_text):
    if shape.has_text_frame:
        for p in shape.text_frame.paragraphs:
            replace_text_in_paragraph(p, old_text, new_text)
    elif shape.has_table:
        for row in shape.table.rows:
            for cell in row.cells:
                for p in cell.text_frame.paragraphs:
                    replace_text_in_paragraph(p, old_text, new_text)

def apply_global_replacements(prs):
    REPLACEMENTS = [
        ("PRN232 – Final Assignment", "PRM393 – Mobile Programming Assignment"),
        ("PRN232 – FINAL ASSIGNMENT", "PRM393 – FINAL ASSIGNMENT"),
        ("PRN232 - FALL 2026", "PRM393 - FALL 2026"),
        ("PRN232 - Fall 2026", "PRM393 - Fall 2026"),
        ("OVERVIEW - PRN232", "OVERVIEW - PRM393"),
        ("PRN232", "PRM393"),
        ("Sản phẩm – Không gian Web App dành cho Sinh viên", "Sản phẩm – Ứng dụng Di động Android dành cho Sinh viên (Flutter)"),
        ("Không gian Web App dành cho Sinh viên (Student Portal)", "Ứng dụng Di động Android dành cho Sinh viên (Flutter Mobile App)"),
        ("Web App dành cho Sinh viên", "Mobile App Android cho Sinh viên (Flutter)"),
        ("JWT Role Claims", "Firebase Authentication (Google Sign-In) & Rules"),
        ("JWT Role Claim", "Firebase Auth UID / Email (@fpt.edu.vn, @fe.edu.vn)"),
        ("JWT", "Firebase ID Token"),
        ("YARP API Gateway và từng Microservice", "Firebase và Firestore Security Rules"),
        ("YARP API Gateway", "Firebase Platform"),
        ("YARP Gateway", "Firebase Backend"),
        ("dotnet test", "flutter test (102 tests pass)"),
        ("MailHog", "FCM Notification"),
        ("SignalR", "Firestore Realtime Stream"),
        ("Redis Backplane", "Firestore Realtime Stream"),
        ("Redis Streams", "Firestore Snapshots"),
        ("Redis", "Firestore"),
    ]
    
    for slide in prs.slides:
        for shape in slide.shapes:
            for old_text, new_text in REPLACEMENTS:
                replace_in_shape(shape, old_text, new_text)

def update_slide_1(slide):
    # Slide 1: Overview
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                if "Kiến trúc .NET 8" in p.text:
                    p.text = "Flutter & Firebase"
                elif "Microservices & gRPC" in p.text:
                    p.text = "Mobile App & Web Admin"
                elif "Matching Engine" in p.text:
                    p.text = "Cloud Firestore & FCM"
                elif "6 REST Services" in p.text or "6 SQL Server DBs" in p.text:
                    p.text = "Flutter Android App · Flutter Web · Cloud Firestore NoSQL"
                elif "YARP API Gateway" in p.text or "Redis Streams" in p.text:
                    p.text = "Firebase Auth · Push Notifications FCM · Cloudinary · Crashlytics"

def update_slide_10(slide):
    # Slide 10: System Architecture
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "Web App → Gateway" in txt:
                    p.text = "Mobile App (Android) + Web Admin (Flutter Web) kết nối trực tiếp Firebase Backend qua Firebase SDK."
                elif "Đồng bộ: REST" in txt:
                    p.text = "Dữ liệu Realtime: Cloud Firestore snapshots() cập nhật tức thì hai chiều giữa Mobile App và Web Admin."
                elif "Triển khai bằng Docker Compose" in txt:
                    p.text = "Bảo mật & Phân quyền: Google Sign-in cấp ID Token JWT; Firestore Security Rules kiểm soát quyền tại server."
                elif "Mỗi service một database riêng" in txt:
                    p.text = "Thông báo & File: Server Python (Admin SDK) gửi FCM HTTP v1; Cloudinary lưu trữ file PDF báo cáo / CV."
                elif "Sơ đồ Container (C4 – Level 2)" in txt:
                    p.text = "Sơ đồ Kiến trúc Hệ thống Mobile (PRM393 - Architecture)"
                elif "System Architecture : PRM393 - draw.io" in txt or "System Architecture" in txt:
                    p.text = "System Architecture: Flutter Mobile (Android) · Flutter Web · Firebase Platform"

def update_slide_11(slide):
    # Slide 11: Technology Stack table
    for shape in slide.shapes:
        if shape.has_table:
            table = shape.table
            if len(table.rows) >= 7:
                # Update row 1
                table.rows[1].cells[0].text = "Mobile App"
                table.rows[1].cells[1].text = "Flutter 3.x • Dart • Provider (MVVM) • Material 3"
                table.rows[1].cells[2].text = "Xây dựng ứng dụng di động Android cho sinh viên; quản lý trạng thái bằng Provider theo kiến trúc MVVM; chạy mượt mà trên thiết bị Android thật."
                
                # Update row 2
                table.rows[2].cells[0].text = "Web Admin"
                table.rows[2].cells[1].text = "Flutter Web (main_admin.dart) • Responsive UI • Provider"
                table.rows[2].cells[2].text = "Giao diện Web chuyên dụng cho Giảng viên & Moderator; quản lý môn học, chốt sổ, duyệt chuyển nhóm và import FAP từ file .csv, .xlsx, .xls."
                
                # Update row 3
                table.rows[3].cells[0].text = "Database"
                table.rows[3].cells[1].text = "Cloud Firestore (NoSQL) • Security Rules • Transactions"
                table.rows[3].cells[2].text = "Lưu trữ dữ liệu Realtime (Room, đơn Apply, hồ sơ); bảo vệ bằng Security Rules; dùng runTransaction chống race condition khi tranh suất vào phòng."
                
                # Update row 4
                table.rows[4].cells[0].text = "Auth & FCM"
                table.rows[4].cells[1].text = "Firebase Auth (Google Sign-In) • Firebase Cloud Messaging"
                table.rows[4].cells[2].text = "Đăng nhập Google bằng email trường (@fpt.edu.vn, @fe.edu.vn); bắn thông báo đẩy FCM nổ chuông trên điện thoại khi có đơn Apply hoặc có kết quả vote."
                
                # Update row 5
                table.rows[5].cells[0].text = "Cloud Services"
                table.rows[5].cells[1].text = "Firebase Crashlytics • Remote Config • Cloudinary"
                table.rows[5].cells[2].text = "Báo cáo crash thời gian thực; đổi banner thông báo khẩn cấp từ xa; upload và lưu trữ file PDF báo cáo / CV an toàn qua Unsigned Preset."
                
                # Update row 6
                table.rows[6].cells[0].text = "Testing & Server"
                table.rows[6].cells[1].text = "Flutter Test (102 Tests Pass) • Python Admin SDK"
                table.rows[6].cells[2].text = "Kiểm thử tự động 102 unit & widget tests cho toàn bộ ViewModel và Domain rules; server Python nghe sự kiện Firestore và gửi FCM chuẩn HTTP v1."

def update_slide_14(slide):
    # Slide 14: Class Design / MVVM
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "JoinRequestsController" in txt:
                    p.text = "RoomDetailScreen & ApplicationDialog"
                elif "Tiếp nhận HTTP" in txt:
                    p.text = "Lớp View (UI): hiển thị thông tin Room, đơn Apply, nhận tương tác và lắng nghe ViewModel qua context.watch()."
                elif "JoinRequestService" in txt and "Thao tác" not in txt:
                    p.text = "GroupService & NotificationService"
                elif "EF Core" in txt:
                    p.text = "Firebase Firestore SDK"
                elif "JoinRequestRepository" in txt:
                    p.text = "Firebase Service Layer"
                elif "CreateJoinRequestValidator" in txt:
                    p.text = "RoomRules & Validation Logic"
                elif "GroupGuards" in txt:
                    p.text = "Business Rules (BR-01 → BR-37)"

def update_slide_15_16(slide15, slide16):
    # Slide 15: NoSQL Collections
    for shape in slide15.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "CourseSpace → Group" in txt:
                    p.text = "users (Collection) & fcm_tokens (Sub-collection)"
                elif "Một CourseSpace có thể có" in txt:
                    p.text = "Lưu hồ sơ sinh viên, 5 điểm kỹ năng (skills: tech, management, design, marketing, sale), vai trò role, và danh sách FCM token thiết bị."
                elif "Group → GroupMember" in txt:
                    p.text = "spaces (Collection) & enrollments (Sub-collection)"
                elif "Mỗi Group có tối đa 5" in txt:
                    p.text = "Cấu hình môn học (EXE101/201, sĩ số max 5, ngưỡng 3, hạn đăng ký). Sub-collection lưu danh sách sinh viên FAP import từ Excel/CSV."
                elif "Student → GroupMember" in txt:
                    p.text = "rooms (Collection)"
                elif "Trong một CourseSpace, mỗi sinh viên" in txt:
                    p.text = "Lưu thông tin phòng, mảng members chứa danh sách UID, leaderId, số chỗ trống, trạng thái (open, group, locked)."
                elif "Group → JoinRequest" in txt:
                    p.text = "applications (Collection)"
                elif "Một Group có thể nhận nhiều đơn" in txt:
                    p.text = "Đơn xin gia nhập phòng, tin nhắn nộp đơn, trạng thái pending/accepted/rejected, mảng votes chứa UID các thành viên đã biểu quyết."

    # Slide 16: Security Rules & Integrity
    for shape in slide16.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "nvarchar" in txt or "Status" in txt:
                    p.text = "Bảo Vệ Dữ Liệu Bằng Firestore Security Rules"
                elif "Định danh duy nhất và bảo vệ quan hệ nội bộ database" in txt:
                    p.text = "Security Rules chạy trên server Firebase, bảo vệ toàn bộ collection, phân quyền theo email @fpt.edu.vn và @fe.edu.vn."
                elif "Ngân trúng RoomCode" in txt or "SQL Server" in txt:
                    p.text = "runTransaction: Đảm bảo giao dịch nguyên tử, chống tranh chấp chỗ cuối cùng khi nhiều sinh viên cùng bấm vào phòng."

def update_slide_17(slide):
    # Slide 17: Testing Breakdown
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "TC-SP01" in txt or "TC-US01" in txt:
                    pass
                elif "12 tests" in txt:
                    p.text = "admin_test (24)"
                elif "20 tests" in txt:
                    p.text = "group_service (25)"
                elif "18 tests" in txt:
                    p.text = "roster_test (22)"
                elif "16 tests" in txt:
                    p.text = "space_vm (10)"
                elif "14 tests" in txt:
                    p.text = "notification (15)"
                elif "EF Core" in txt:
                    p.text = "Firestore Transaction"
                elif "CourseSpacesPage" in txt:
                    p.text = "AdminPages (Web)"
                elif "CourseSpaceService" in txt:
                    p.text = "AdminService"

def update_slide_23(slide):
    # Slide 23: Testing & Verification
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "314" in txt:
                    p.text = "102"
                elif "22/37" in txt:
                    p.text = "37/37"
                elif "BR có unit test" in txt:
                    p.text = "BRs được kiểm chứng"
                elif "8/8 project test pass" in txt or "Chưa có E2E tự động" in txt:
                    p.text = "102/102 test cases pass 100% trong 16 giây trên Flutter Test Suite."
                elif "Minh chứng: kết quả dotnet test" in txt:
                    p.text = "Minh chứng: Lệnh flutter test pass 100%, log adb trên điện thoại thật, chuông notification FCM nổ thực tế."

def update_slide_6(slide):
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "gRPC" in txt or "Cổng 5005" in txt:
                    p.text = "Distribution Planner (Thuật toán phân phối SV lẻ)"
                elif "MailHog" in txt:
                    p.text = "FCM Push Notification Service"

def update_slide_18_22(prs):
    # Slides 18 to 22 (Demo Workflows)
    for idx in range(17, 22):
        slide = prs.slides[idx]
        for shape in slide.shapes:
            if shape.has_text_frame:
                for p in shape.text_frame.paragraphs:
                    txt = p.text.strip()
                    if "Phân phối gRPC & Chốt sổ" in txt:
                        p.text = p.text.replace("Phân phối gRPC & Chốt sổ", "Phân phối SV Lẻ & Chốt sổ")
                    if "gRPC" in p.text:
                        p.text = p.text.replace("gRPC Service", "Admin Service").replace("Matching gRPC", "Distribution Planner").replace("gRPC", "Thuật toán Phân phối")
                    if "moderator@fpt.edu.vn" in p.text:
                        p.text = p.text.replace("moderator@fpt.edu.vn", "moderator@fe.edu.vn")
                    if "MailHog" in p.text:
                        p.text = p.text.replace("MailHog", "FCM Notification")

def update_slide_24(slide):
    # Slide 24: Conclusion / Requirements vs Delivered
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "REST API + Firebase ID Token" in txt or "REST API + JWT" in txt:
                    p.text = "Kiến trúc MVVM + Provider"
                elif "4 Core, 10 RFC" in txt:
                    p.text = "Tách biệt rõ Model - View - ViewModel; 102 bài test kiểm thử logic tự động."
                elif "Push Notification (FCM)" in txt:
                    pass
                elif "Brevo / FCM" in txt or "11 Redis consumers" in txt or "11 Firestore consumers" in txt:
                    p.text = "Server Python Admin SDK gửi FCM HTTP v1; điện thoại nổ chuông và mở đúng Room."
                elif "Cloud Firestore & Security Rules" in txt:
                    pass
                elif "Outbox Pattern" in txt or "matching proto" in txt:
                    p.text = "Cloud Firestore NoSQL & runTransaction chống race condition tranh suất vào phòng."
                elif "Firebase Crashlytics & Remote Config" in txt:
                    pass
                elif "AppointmentHub" in txt or "SignalR" in txt:
                    p.text = "Crashlytics báo lỗi realtime; Remote Config đổi banner thông báo từ xa tức thì."
                elif "Docker & Cloud" in txt or "Lưu trữ File Cloudinary" in txt:
                    p.text = "Lưu trữ File Cloudinary"
                elif "Khoảng 11 local containers" in txt:
                    p.text = "Unsigned Upload Preset lưu file PDF báo cáo / CV; an toàn không lộ API Secret trong APK."
                elif "Web Quản trị Giảng viên" in txt:
                    pass
                elif "lib/main_admin.dart" in txt:
                    p.text = "lib/main_admin.dart: Import danh sách FAP từ file .xls XML, phân phối sinh viên lẻ và chốt sổ."
                elif "AI & Smart Matching" in txt:
                    p.text = "Thuật toán Cân bằng 5 Kỹ năng"
                elif "Google Gemini API" in txt:
                    p.text = "Thuật toán phân phối sinh viên lẻ tối ưu hóa 5 trục kỹ năng (Tech, Mgt, Design, Mkt, Sale)."
                elif "E2E Testing & Quality" in txt:
                    p.text = "102 Tests Pass 100%"
                elif "xUnit, Moq" in txt:
                    p.text = "102/102 bài kiểm thử Flutter Unit & Widget tests kiểm chứng toàn bộ 37 Business Rules."
                elif "7 SERVICES" in txt:
                    p.text = "MOBILE FIRST"
                elif "App Android chạy trên máy thật" in txt:
                    pass
                elif "7 dịch vụ" in txt or ".NET" in txt:
                    p.text = "Flutter Mobile (Android) & Flutter Web (Admin)"
                elif "Auth (5001)" in txt or "User (5002)" in txt:
                    p.text = "Flutter Mobile App (Sinh viên) + Flutter Web (Giảng viên) + Python FCM Server."
                elif "FIREBASE BACKEND" in txt:
                    pass
                elif "ExeAuthDb" in txt or "ExeUserDb" in txt or "6 cơ sở dữ liệu" in txt or "SQL Server" in txt:
                    p.text = "users, spaces, rooms, applications, memberships, transfer_requests, crash_logs."
                elif "100% yêu cầu kỹ thuật" in txt:
                    p.text = "100% yêu cầu kỹ thuật PRM393 & Rubric chấm Lab 3 của Thầy Phương đã hoàn thành."

def update_slide_25(slide):
    # Slide 25: Limitations & Future Work
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "Gemini API Free Quota" in txt:
                    p.text = "Chế độ Offline toàn phần"
                elif "Giới hạn RPM/TPM của Gemini API" in txt:
                    p.text = "App có bộ đệm cache Firestore cơ bản nhưng cần hoàn thiện cơ chế đồng bộ ngoại tuyến khi mất mạng dài ngày."
                elif "Container Footprint" in txt:
                    p.text = "Môi trường Nền tảng iOS"
                elif "Khoảng 11 containers yêu cầu" in txt:
                    p.text = "Hiện tại app tập trung tối ưu cho Android; bản iOS cần thiết bị macOS và tài khoản Apple Developer để cấu hình APNs."
                elif "Kubernetes & Cost Optimization" in txt:
                    p.text = "Đóng gói hoàn chỉnh bản iOS"
                elif "Trễn khai Helm Charts" in txt:
                    p.text = "Cấu hình chứng chỉ APNs và build bản chạy trên iPhone khi có máy tính macOS."
                elif "Direct FAP / LMS Webhooks" in txt:
                    p.text = "Chuyển Server lên Cloud Functions"
                elif "Tích hợp dữ liệu hai chiều" in txt:
                    p.text = "Chuyển script Python lắng nghe Firestore sang Firebase Cloud Functions để tự động hóa 100% trên đám mây."

def update_slide_26(slide):
    # Slide 26: 4 Lessons Learned
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "Design Before Coding" in txt:
                    p.text = "Kỷ luật Kiến trúc MVVM trong Flutter"
                elif "Chuẩn hóa 34 Business Rules" in txt:
                    p.text = "Tách bạch rõ ràng ViewModel và Service giúp việc viết và chạy 102 bài unit test cực kỳ nhanh, độc lập hoàn toàn với giao diện UI."
                elif "Redis Backplane Tames Realtime" in txt:
                    p.text = "Xử lý Concurrency bằng Firestore Transaction"
                elif "Kết hợp SignalR, Redis Backplane" in txt:
                    p.text = "Sử dụng runTransaction giải quyết triệt để bài toán tranh chấp slot cuối cùng khi nhiều sinh viên cùng bấm vào nhóm tại một thời điểm."
                elif "Environment Parity Across Stack" in txt or "Làm chủ Vòng đời" in txt:
                    p.text = "Làm chủ Vòng đời Push Notification (FCM)"
                elif "Đồng bộ JWT" in txt or "Đồng bộ Firebase" in txt:
                    p.text = "Nắm vững 3 trạng thái ứng dụng (Foreground, Background, Terminated) để xử lý hiển thị banner cục bộ và điều hướng mở đúng phòng."
                elif "Phase Delivery + Strict Reviews" in txt or "Bảo mật Đám mây" in txt:
                    p.text = "Bảo mật Đám mây (Cloud Security First)"
                elif "Chia dự án thành 6 giai đoạn" in txt:
                    p.text = "Tuyệt đối không nhúng Service Account hoặc Private Key vào APK Android; luôn sử dụng Security Rules và Unsigned Presets."
                elif "Docker" in txt or "JWT" in txt or "Environment" in txt:
                    p.text = "FCM Lifecycle • Security Rules • Unsigned Presets"

def update_slide_27(slide):
    # Slide 27: Thank you
    for shape in slide.shapes:
        if shape.has_text_frame:
            for p in shape.text_frame.paragraphs:
                txt = p.text.strip()
                if "PRN232 - Fall 2026 - FPT University" in txt:
                    p.text = "PRM393 - Fall 2026 - FPT University"
                elif "EXE Team Matching - PRN232 - Fall 2026" in txt:
                    p.text = "EXE Team Matching · Flutter Mobile & Firebase · Nhóm 5"
                elif "Cảm ơn Thầy và các bạn đã lắng nghe!" in txt:
                    p.text = "Cảm ơn Thầy Phương và các bạn đã lắng nghe!"

def main():
    src_path = r"Software_Project_Presentation_Group3.pptx"
    out_path1 = r"Software_Project_Presentation_PRM393_Group5.pptx"
    out_path2 = r"..\Software_Project_Presentation_PRM393_Group5.pptx"
    
    prs = Presentation(src_path)
    print("Loaded presentation. Applying global replacements...")
    apply_global_replacements(prs)
    
    print("Updating specific slides...")
    update_slide_1(prs.slides[0])
    update_slide_6(prs.slides[5])
    update_slide_10(prs.slides[9])
    update_slide_11(prs.slides[10])
    update_slide_14(prs.slides[13])
    update_slide_15_16(prs.slides[14], prs.slides[15])
    update_slide_17(prs.slides[16])
    update_slide_18_22(prs)
    update_slide_23(prs.slides[22])
    update_slide_24(prs.slides[23])
    update_slide_25(prs.slides[24])
    update_slide_26(prs.slides[25])
    update_slide_27(prs.slides[26])
    
    prs.save(out_path1)
    prs.save(out_path2)
    print("Saved modified presentation to:")
    print("1.", os.path.abspath(out_path1))
    print("2.", os.path.abspath(out_path2))

if __name__ == "__main__":
    main()
