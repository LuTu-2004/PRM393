# Database — EXE Team Matching

Thu muc nay chua toan bo tai nguyen lien quan den co so du lieu.

## Cau truc

| Thu muc | Noi dung |
|---------|----------|
| `erd/` | File DBML (dbdiagram.io) va anh ERD xuat ra |
| `migrations/` | Script SQL DDL tao cau truc bang (chay theo thu tu 01, 02...) |
| `seeds/` | Du lieu mau de test cac Business Rules |
| `queries/` | Cac cau truy van kiem tra nghiep vu |

## Cach su dung

### Firebase Firestore (san xuat)
- Khong can chay SQL — Firestore la NoSQL
- Cau truc bang trong `erd/exe_matching.dbml` la tai lieu tham khao thiet ke
- Collections tren Firestore: `users`, `student_profiles`, `rooms`,
  `room_members`, `invitations`, `votes`, `vote_sessions`, `semesters`

### Neu dung SQL Server / PostgreSQL (SSMS - de test logic)
1. Chay theo thu tu: `migrations/01_init_schema.sql` -> `02_constraints_indexes.sql`
2. Nap du lieu mau: `seeds/01_seed_master_data.sql` -> `02_seed_test_cases.sql`
3. Kiem tra nghiep vu bang cac file trong `queries/`

## Firestore Collection Schema

### users
- id (string, auto - Firebase UID)
- email (string) — BR-02
- fullName (string)
- role (string) — "student" | "moderator"
- studentCode (string, nullable) — BR-03, BR-04
- major (string, nullable) — BR-04
- cohort (string, nullable) — BR-04
- acceptedPolicyAt (timestamp, nullable) — BR-34
- createdAt (timestamp)

### student_profiles
- userId (string, ref: users)
- skills (array<string>)
- orientation (string) — dinh huong khoi nghiep
- bio (string)
- isProfileComplete (boolean) — BR-05
- updatedAt (timestamp)

### rooms
- id (string, auto)
- name (string)
- description (string)
- subjectCode (string) — "EXE101" | "EXE201"
- semesterId (string, ref: semesters)
- leaderId (string, ref: users)
- isPublic (boolean) — BR-10
- status (string) — "open" | "full" | "closed" | "confirmed"
- memberCount (number)
- maxMembers (number = 5) — BR-08
- minMembers (number = 4) — BR-07
- createdAt (timestamp)

### invitations
- id (string, auto)
- roomId (string, ref: rooms)
- fromUserId (string, ref: users)
- toUserId (string, ref: users)
- type (string) — "request" (xin vao) | "invite" (moi truc tiep)
- status (string) — "pending" | "accepted" | "rejected" | "expired"
- expiredAt (timestamp) — BR-20 (48h)
- createdAt (timestamp)

### vote_sessions
- id (string, auto)
- roomId (string, ref: rooms)
- startedAt (timestamp)
- endedAt (timestamp) — BR-22 (24h sau startedAt)
- status (string) — "active" | "ended"
- initiatedBy (string, ref: users) — Leader kich hoat (BR-21)

### votes
- id (string, auto)
- sessionId (string, ref: vote_sessions)
- voterId (string, ref: users) — nguoi bau
- targetId (string, ref: users) — nguoi duoc bau (khac voterId) — BR-23
- createdAt (timestamp)

### semesters
- id (string, auto)
- name (string) — "Fall2026", "Spring2027"
- registrationDeadline (timestamp) — BR-12, BR-32
- isActive (boolean)
