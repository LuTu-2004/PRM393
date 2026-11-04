# 02 - Ke Hoach Analytics & Crashlytics (Lab 3 Requirement)

## Firebase Analytics — Danh sach Su kien Can Track

| Ten Su kien (Event Name) | Trigger | Parameters |
|--------------------------|---------|------------|
| `user_signed_in` | Sau khi dang nhap thanh cong (BR-02) | role, major, cohort |
| `profile_completed` | Sau khi hoan thien ho so (BR-05) | skills_count, orientation |
| `room_created` | Leader tao phong moi (BR-09) | subject_code, is_public |
| `room_searched` | Tim kiem phong (BR-14) | filters_used, results_count |
| `join_request_sent` | Gui request xin vao phong (BR-16) | room_id, pending_count |
| `join_request_approved` | Leader duyet request (BR-16) | new_member_major, room_major_ratio |
| `major_warning_shown` | Hien thi canh bao ty le nganh (BR-19) | room_id, ratio |
| `vote_session_started` | Leader kich hoat bo phieu (BR-21) | room_id, member_count |
| `vote_cast` | Thanh vien bo phieu (BR-23) | session_id |
| `vote_session_closed` | Ket thuc phien bo phieu (BR-22) | session_id, total_votes |
| `moderator_action` | Moderator thao tac (BR-31) | action_type, target_room_id |

## Firebase Crashlytics — Cac Diem Can Bat Loi

| Diem Bat Loi | Vi tri trong code | Loi thuong gap |
|--------------|-------------------|----------------|
| Dang nhap Firebase Auth | auth/firebase_auth_repository.dart | Token het han, mang mat |
| Goi Firestore API | Moi repository Firebase | Permission denied, Quota exceeded |
| Xu ly cong thuc ty le nganh (BR-18) | RoomRepository.approveRequest() | Division by zero |
| Tinh toan deadline (BR-20, BR-22) | Firestore Timestamp xu ly | Timezone mismatch |
| Import sinh vien hang loat (BR-29) | coordination/firebase_repository | File format loi, data null |

## Cach Implement

### Analytics
```dart
// Trong BLoC, sau khi hanh dong thanh cong:
FirebaseAnalytics.instance.logEvent(
  name: 'room_created',
  parameters: {
    'subject_code': event.subjectCode,
    'is_public': event.isPublic ? 'yes' : 'no',
  },
);
```

### Crashlytics
```dart
// Trong cac ham co rui ro cao:
try {
  await roomRepo.approveRequest(requestId);
} catch (e, stackTrace) {
  FirebaseCrashlytics.instance.recordError(e, stackTrace,
    reason: 'approveRequest failed: BR-18 check');
  rethrow;
}
```

## Ghi chu
- KHONG track thong tin ca nhan (MSSV, email) trong Analytics — chi dung role, major, cohort
- Bat Crashlytics ngay tu buoi dau, khong doi den khi nop bai moi bat
