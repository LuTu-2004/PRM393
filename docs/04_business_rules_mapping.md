# 04 - Bang Doi Chieu Business Rules vs Man Hinh Code

| Ma BR | Mo ta ngan | Feature | File chinh | Ghi chu |
|-------|-----------|---------|-----------|---------|
| BR-01 | Chi sinh vien du dk | auth | firebase_auth_repository.dart | Kiem tra khi login |
| BR-02 | Email @fpt.edu.vn | auth | firebase_auth_repository.dart | Validate domain |
| BR-03 | 1 tai khoan = 1 MSSV | auth | firebase_user_repository.dart | Unique constraint |
| BR-04 | MSSV trich xuat nganh/khoa | profile | student_profile_service.dart | Parse MSSV |
| BR-05 | Hoan thien ho so truoc khi tham gia | profile | profile_bloc.dart | Guard trong matching |
| BR-06 | 1 nhom/hoc ky | matching | firebase_room_repository.dart | Query truoc khi approve |
| BR-07 | Min 4 thanh vien | room | room_repository.dart | Kiem tra truoc khi dong |
| BR-08 | Max 5 thanh vien | room | room_repository.dart | AppConfig.TEAM_MAX_MEMBERS |
| BR-09 | Bat buoc nhap thong tin phong | room | CreateRoomScreen | Form validation |
| BR-10 | Public/Private | room | CreateRoomScreen, RoomListScreen | Filter khi tim kiem |
| BR-11 | Moi truc tiep | room | invitation_repository.dart | |
| BR-12 | Tu dong dong phong | coordination | deadline_checker_service.dart | Chay background |
| BR-13 | Kick member | room | room_bloc.dart | Kiem tra >= min truoc khi kick |
| BR-14 | Tim kiem phong | matching | MatchingScreen | Filter: subject, semester, major |
| BR-15 | Goi y phong | matching | MatchingBloc | Sap xep theo do phu hop ky nang |
| BR-16 | Gui/duyet request | matching | invitation_repository.dart | |
| BR-17 | Max 3 pending requests | matching | firebase_invitation_repository.dart | Count pending truoc khi gui |
| BR-18 | Max 50% cung nganh | room | RoomRepository.approveRequest() | Check truoc khi them member |
| BR-19 | Canh bao ty le nganh | matching | MajorWarningBanner widget | Hien khi ratio > 0.5 |
| BR-20 | Request het han 48h | matching | InvitationRepository | Check expiredAt |
| BR-21 | Leader kich hoat bo phieu | voting | VotingBloc | |
| BR-22 | Bo phieu 24h | voting | VoteSessionRepository | endedAt = startedAt + 24h |
| BR-23 | 1 phieu, khong tu bau | voting | VotingScreen | Disable nut bau cho minh |
| BR-24 | An ket qua | voting | VotingResultScreen | Chi show khi status = 'ended' |
| BR-25 | De xuat loai it phieu nhat | voting | VotingResultScreen | Sort asc by vote count |
| BR-26 | Leader quyet dinh cuoi | voting | VotingResultScreen | Nut hanh dong chi hien voi Leader |
| BR-27 | Toan ven phieu | voting | VoteSessionRepository.close() | Assert total_votes = voter_count |
| BR-28 | Luu lich su phieu | voting | Firestore votes collection | |
| BR-29 | Import sinh vien | coordination | ImportStudentsScreen | CSV/Excel upload |
| BR-30 | Tong quan moderator | coordination | ModeratorDashboard | |
| BR-31 | Can thiep nhom | coordination | ModeratorDashboard | Role-based action |
| BR-32 | Deadline hoc ky | coordination | SemesterManagementScreen | |
| BR-33 | Thong bao nhom thieu nguoi | coordination | NotificationService | |
| BR-34 | Dong y dieu khoan | auth | LoginScreen | Luu acceptedPolicyAt |
| BR-35 | Phan quyen thong tin | auth | Firestore Security Rules | |
| BR-36 | Audit log | global | audit_log_service.dart | Goi sau moi hanh dong quan trong |
| BR-37 | Khong luu mat khau | auth | Firebase Auth (Google Sign-In) | |
