# EXE Team Matching — PRM393 Lab 3

Ung dung ghep nhom sinh vien cho cac mon EXE (EXE101, EXE201) tren Flutter.

## Cau truc thu muc

- `AI_GUIDELINES.md` — Doc truoc khi lam bat cu thu gi (danh cho ca nguoi va AI)
- `database/` — Thiet ke DB, script SQL, du lieu mau
- `flutter_app/` — Ma nguon ung dung Flutter chinh
- `docs/` — Tai lieu kien truc, test plan, analytics plan
- `submission/` — Bao cao, slide, video nop bai

## Huong dan Setup Nhanh

### 1. Cai dat Flutter
Yeu cau: Flutter SDK >= 3.19, Dart >= 3.3

### 2. Clone / mo thu muc

### 3. Cai dat dependencies
```
cd flutter_app
flutter pub get
```

### 4. Cau hinh Firebase
- Tao project tren Firebase Console
- Them file `google-services.json` (Android) vao `flutter_app/android/app/`
- Them file `GoogleService-Info.plist` (iOS) vao `flutter_app/ios/Runner/`

### 5. Chay o che do Mock (khong can Firebase)
Mo file `flutter_app/lib/core/config/app_config.dart`
Dat `USE_MOCK_DATA = true` -> co the chay app offline hoan toan.

### 6. Chay app
```
cd flutter_app
flutter run
```

## Business Rules
Tham khao day du trong `AI_GUIDELINES.md` phan 2 (37 BR).

## Nhom thuc hien
- Nhom 4 — PRM393 — Lab 3
