# AI_GUIDELINES.md — Huong dan Bat buoc cho AI Coding Assistant

> **DOC FILE NAY TRUOC KHI VIET BAT KY DONG CODE NAO**
>
> File nay duoc thiet ke de bat ky AI (ChatGPT, Claude, Gemini, Copilot,
> Cursor, Antigravity...) deu phai doc va tuan thu nghiem ngat.
> Vi pham quy tac o day se lam hong toan bo kien truc nhom.

---

## 1. Tong Quan Du An (Project Context)

| Thong tin       | Chi tiet                                                              |
|-----------------|-----------------------------------------------------------------------|
| Ten du an       | EXE Team Matching System                                              |
| Mon hoc         | PRM393 — Lab 3                                                        |
| Muc tieu        | Ung dung ghep nhom sinh vien cho mon EXE (EXE101, EXE201)             |
| Nen tang        | Flutter (Mobile App) — Android & iOS                                  |
| Backend         | Firebase (Firestore + Auth + Analytics + Crashlytics)                 |
| Kien truc       | Feature-First + Repository Pattern + BLoC/Cubit                       |
| Trang thai      | Dang phat trien — dung Mock Data (xem app_config.dart)                |

Hai nhom nguoi dung chinh:
- **Student (Sinh vien)** — Mobile App: Dang nhap, khai bao ho so, tim phong, xin vao nhom, bo phieu
- **Moderator (Giang vien)** — Mobile App (man hinh rieng): Import du lieu, phe duyet nhom, dong dang ky

---

## 2. 37 Business Rules (BR) — KHONG DUOC VI PHAM

Moi logic code PHAI tuan thu cac quy tac nghiep vu sau.
Khi AI sinh code, ghi ro BR nao dang duoc implement trong comment.

### Xac thuc & Ho so
| Ma BR | Mo ta |
|-------|-------|
| BR-01 | Chi sinh vien du dieu kien (da hoc EXE101 hoac EXE201) moi duoc dung |
| BR-02 | Dang nhap bang email truong (@fpt.edu.vn) qua Firebase Auth |
| BR-03 | Moi tai khoan lien ket dung 1 MSSV duy nhat |
| BR-04 | MSSV tu dong trich xuat: Nganh (major) va Khoa (cohort) |
| BR-05 | Phai hoan thien ho so truoc khi tham gia phong |
| BR-06 | Mot sinh vien chi o trong 1 nhom/phong tai cung 1 hoc ky |

### Quan ly Phong (Room)
| Ma BR | Mo ta |
|-------|-------|
| BR-07 | So thanh vien toi thieu: 4 nguoi |
| BR-08 | So thanh vien toi da: 5 nguoi |
| BR-09 | Leader tao phong khai bao: ten, mo ta du an, mon hoc, hoc ky |
| BR-10 | Phong co che do: Public (ai cung thay) hoac Private (chi moi truc tiep) |
| BR-11 | Leader co the moi truc tiep sinh vien qua MSSV hoac email |
| BR-12 | Phong tu dong dong neu khong du thanh vien truoc deadline hoc ky |
| BR-13 | Leader co the kick member (con du so luong toi thieu) |

### Ghep nhom & Tim kiem (Matching)
| Ma BR | Mo ta |
|-------|-------|
| BR-14 | Tim phong theo bo loc: mon hoc, hoc ky, nganh, ky nang |
| BR-15 | Goi y phong phu hop dua tren ho so ky nang sinh vien |
| BR-16 | Sinh vien gui request xin gia nhap — Leader duyet hoac tu choi |
| BR-17 | Toi da 3 request dang cho (pending) cung luc |
| BR-18 | KHONG qua 50% thanh vien cung chuyen nganh trong 1 nhom |
| BR-19 | CANH BAO khi ty le chuyen nganh vuot nguong 50% |
| BR-20 | Request tu dong het han sau 48 gio neu Leader khong phan hoi |

### Bo Phieu Thanh Vien (Voting)
| Ma BR | Mo ta |
|-------|-------|
| BR-21 | Sau khi nhom du thanh vien, Leader kich hoat vong bo phieu |
| BR-22 | Thoi han bo phieu: 24 gio ke tu khi Leader kich hoat |
| BR-23 | Moi thanh vien co dung 1 phieu bau cho nguoi khac (khong tu bau) |
| BR-24 | Ket qua bo phieu AN cho den khi thoi han 24h ket thuc |
| BR-25 | Thanh vien co so phieu thap nhat bi de xuat loai |
| BR-26 | Quyet dinh loai thanh vien cuoi cung thuoc ve Leader |
| BR-27 | Tong so phieu hop le = so thanh vien tham gia bo phieu |
| BR-28 | Luu lich su ket qua bo phieu de Moderator kiem tra |

### Dieu Phoi Vien (Moderator)
| Ma BR | Mo ta |
|-------|-------|
| BR-29 | Import danh sach sinh vien du dieu kien vao he thong |
| BR-30 | Xem tong quan: danh sach phong, tien do ghep nhom theo hoc ky |
| BR-31 | Quyen can thiep: giai tan nhom, chuyen thanh vien giua cac nhom |
| BR-32 | Dat thoi han dang ky nhom cho tung hoc ky |
| BR-33 | Nhan thong bao khi co nhom chua du thanh vien gan deadline |

### Dieu Khoan & Bao Mat
| Ma BR | Mo ta |
|-------|-------|
| BR-34 | Dong y dieu khoan lan dau dang nhap — luu timestamp |
| BR-35 | Thong tin ho so sinh vien chi Moderator moi xem toan bo |
| BR-36 | Log moi hoat dong quan trong (tao phong, kick, bo phieu) de audit |
| BR-37 | Khong luu mat khau — toan bo xac thuc qua Firebase Auth (Google Sign-In) |

---

## 3. Kien Truc Du An (Architecture)

```
flutter_app/lib/
  core/
    config/app_config.dart   <- DIEM KIEM SOAT MOCK/REAL (doc phan 4)
    theme/                   <- Mau sac, typography, spacing
    constants/               <- Hang so BR (deadline, max_members...)
  repositories/
    interfaces/              <- Abstract class dinh nghia "hop dong"
    mock/                    <- Implement offline (test UI, demo khong mang)
    firebase/                <- Implement that (ket noi Firestore)
  features/
    auth/                    <- Dang nhap Google (BR-02, BR-37)
    profile/                 <- Khai bao ho so sinh vien (BR-04, BR-05)
    room/                    <- Quan ly phong (BR-07 -> BR-13)
    matching/                <- Tim phong, gui request (BR-14 -> BR-20)
    voting/                  <- Bo phieu thanh vien (BR-21 -> BR-28)
    coordination/            <- Man hinh Moderator (BR-29 -> BR-33)
```

Luong du lieu (bat buoc):
  UI (Screen/Widget)
    <--> BLoC / Cubit (State Management)
    <--> Repository Interface (abstract)
    <--> [MockRepository] HOAC [FirebaseRepository]  (tuy app_config.dart)

---

## 4. Cong Tac Mock/Real Data — QUAN TRONG NHAT

File: lib/core/config/app_config.dart

class AppConfig {
  // ==========================================================
  // DOI GIA TRI NAY DE CHUYEN GIUA MOCK VA FIREBASE THAT
  // true  = MockRepository (offline, test UI, demo khong can mang)
  // false = FirebaseRepository (ket noi Firestore that)
  // ==========================================================
  static const bool USE_MOCK_DATA = true;

  // Gioi han nghiep vu (BR)
  static const int TEAM_MIN_MEMBERS = 4;          // BR-07
  static const int TEAM_MAX_MEMBERS = 5;          // BR-08
  static const int REQUEST_EXPIRY_HOURS = 48;     // BR-20
  static const int VOTING_DURATION_HOURS = 24;    // BR-22
  static const int MAX_PENDING_REQUESTS = 3;      // BR-17
  static const double MAX_SAME_MAJOR_RATIO = 0.5; // BR-18 (50%)
}

Khi demo cho thay: Neu mang lop hoc khong on dinh, bat USE_MOCK_DATA = true
de demo offline hoan toan, khong bao gio bi "sap" tren lop.

---

## 5. Quy Uoc Dat Ten (Naming Conventions)

| Pham vi | Quy uoc | Vi du |
|---------|---------|-------|
| Firestore Collections | snake_case so nhieu | users, student_profiles, rooms |
| Firestore Fields | camelCase | fullName, studentCode, createdAt |
| Dart Classes | PascalCase | RoomRepository, VotingBloc |
| Dart Variables/Functions | camelCase | getRooms(), isLeader |
| Dart Constants | SCREAMING_SNAKE_CASE | MAX_MEMBERS, USE_MOCK_DATA |
| Dart Files | snake_case | room_repository.dart, voting_bloc.dart |
| BLoC Events | PascalCase + Event | LoadRoomsEvent, JoinRoomEvent |
| BLoC States | PascalCase + State | RoomsLoadedState, RoomsErrorState |

---

## 6. KHONG DUOC LAM (DO NOT — danh cho AI)

- KHONG tu y them package moi vao pubspec.yaml ngoai danh sach Section 7
- KHONG goi Firestore truc tiep trong Widget hoac BLoC — phai qua Repository
- KHONG hardcode email, API key, MSSV mau trong code that — dung AppConfig
- KHONG bo qua check USE_MOCK_DATA truoc khi goi bat ky Firebase API nao
- KHONG tao them thu muc feature moi ngoai 6 feature da co
- KHONG tron lan logic cua 2 BR khac nhau vao 1 ham
- KHONG bo qua kiem tra BR-18 (ty le nganh) khi xu ly joinRoom / approveRequest
- KHONG dung setState trong man hinh phuc tap — phai dung BLoC/Cubit

---

## 7. Package Da Duoc Approve (pubspec.yaml)

dependencies:
  flutter_bloc: ^8.x          # State management (BLoC/Cubit)
  firebase_core: ^3.x         # Firebase core
  firebase_auth: ^5.x         # Authentication (BR-02, BR-37)
  cloud_firestore: ^5.x       # Database chinh (Firestore)
  firebase_analytics: ^11.x   # Lab 3 yeu cau
  firebase_crashlytics: ^4.x  # Lab 3 yeu cau
  google_sign_in: ^6.x        # Dang nhap Google (BR-37)
  equatable: ^2.x             # So sanh BLoC States
  get_it: ^8.x                # Dependency Injection (inject dung Repository)
  go_router: ^14.x            # Routing / Navigation
  intl: ^0.19.x               # Dinh dang ngay gio (deadline BR-20, BR-22)

---

## 8. Prompt Mau — Copy-Paste Khi Dung AI

Khi nho AI viet code, LUON bat dau bang doan prompt nay:

---
Toi dang lam du an EXE Team Matching (Flutter + Firebase + BLoC/Cubit).
Hay doc file AI_GUIDELINES.md trong thu muc goc cua du an truoc.

Task hien tai: [MO TA TASK, vi du: "Tao man hinh danh sach phong"]
Feature: [TEN FEATURE, vi du: "room"]
Business Rules lien quan: [DANH SACH BR, vi du: "BR-07, BR-08, BR-14, BR-18, BR-19"]

Yeu cau bat buoc:
- Tuan thu Feature-First: code vao lib/features/[feature]/
- Dung BLoC/Cubit cho state management
- Dung Repository interface trong lib/repositories/interfaces/
- Phai tuong thich voi USE_MOCK_DATA trong app_config.dart
- Ghi comment ro BR nao dang duoc implement trong tung ham
---

---

## 9. Cau Truc Thu Muc Day Du

Lab 3/
  AI_GUIDELINES.md              <- AI doc file nay dau tien
  README.md                     <- Huong dan setup va chay project
  database/
    erd/
      exe_matching.dbml         <- Schema thiet ke (dung tren dbdiagram.io)
      erd_diagram.png           <- Anh ERD xuat ra (chen vao bao cao/slide)
    migrations/
      01_init_schema.sql        <- Tao cac bang chinh
      02_constraints_indexes.sql <- Khoa ngoai, Unique, Indexes
    seeds/
      01_seed_master_data.sql   <- Du lieu chuan: mon hoc, vai tro, ky nang
      02_seed_test_cases.sql    <- Mock sinh vien, nhom de test BR
    queries/
      check_team_diversity.sql  <- Query kiem tra ty le nganh (BR-18, BR-19)
      check_voting_result.sql   <- Query dem phieu bau (BR-27, BR-28)
    README.md                   <- Huong dan setup DB
  flutter_app/
    lib/
      core/config/app_config.dart  <- DIEM KIEM SOAT MOCK/REAL
      repositories/             <- Repository Pattern
      features/                 <- Cac tinh nang
    test/                       <- Unit test & Widget test
    pubspec.yaml
  docs/
    01_architecture.md
    02_analytics_plan.md
    03_test_cases.md
    04_business_rules_mapping.md
  submission/
    report/
    slides/
    video/

---

Cap nhat lan cuoi: 01/11/2026 — Nhom 4, PRM393 Lab 3
