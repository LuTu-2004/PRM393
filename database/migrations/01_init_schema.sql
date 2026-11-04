-- ============================================================
-- 01_init_schema.sql
-- Tao cau truc bang chinh cho EXE Team Matching
-- Tham khao: BR-02, BR-03, BR-04, BR-06, BR-07, BR-08, BR-09
-- ============================================================
-- Ghi chu: File nay danh cho SQL Server (SSMS) hoac PostgreSQL
-- Neu dung Firebase Firestore thi coi file nay la tai lieu tham khao thiet ke

CREATE TABLE semesters (
    id             NVARCHAR(50)  PRIMARY KEY,
    name           NVARCHAR(100) NOT NULL,
    reg_deadline   DATETIME      NOT NULL,      -- BR-12, BR-32
    is_active      BIT           DEFAULT 1
);

CREATE TABLE users (
    id                  NVARCHAR(128) PRIMARY KEY,  -- Firebase UID
    email               NVARCHAR(100) NOT NULL UNIQUE,  -- BR-02
    full_name           NVARCHAR(100) NOT NULL,
    role                NVARCHAR(20)  NOT NULL CHECK (role IN ('student', 'moderator')),
    student_code        NVARCHAR(20)  UNIQUE,        -- BR-03 (NULL cho moderator)
    major               NVARCHAR(50),                -- BR-04
    cohort              NVARCHAR(20),                -- BR-04
    accepted_policy_at  DATETIME,                   -- BR-34
    created_at          DATETIME      DEFAULT GETDATE()
);

CREATE TABLE student_profiles (
    user_id     NVARCHAR(128) PRIMARY KEY REFERENCES users(id),
    skills      NVARCHAR(MAX),   -- JSON array
    orientation NVARCHAR(200),
    bio         NVARCHAR(MAX),
    is_complete BIT DEFAULT 0,   -- BR-05
    updated_at  DATETIME DEFAULT GETDATE()
);

CREATE TABLE rooms (
    id           NVARCHAR(128) PRIMARY KEY,
    name         NVARCHAR(100) NOT NULL,
    description  NVARCHAR(MAX),
    subject_code NVARCHAR(20)  NOT NULL CHECK (subject_code IN ('EXE101', 'EXE201')),
    semester_id  NVARCHAR(50)  REFERENCES semesters(id),
    leader_id    NVARCHAR(128) REFERENCES users(id),
    is_public    BIT DEFAULT 1,   -- BR-10
    status       NVARCHAR(20)  DEFAULT 'open' CHECK (status IN ('open', 'full', 'closed', 'confirmed')),
    member_count INT DEFAULT 1,
    max_members  INT DEFAULT 5 CHECK (max_members <= 5),  -- BR-08
    min_members  INT DEFAULT 4 CHECK (min_members >= 4),  -- BR-07
    created_at   DATETIME DEFAULT GETDATE()
);

CREATE TABLE room_members (
    id        NVARCHAR(128) PRIMARY KEY,
    room_id   NVARCHAR(128) NOT NULL REFERENCES rooms(id),
    user_id   NVARCHAR(128) NOT NULL REFERENCES users(id),
    joined_at DATETIME DEFAULT GETDATE(),
    UNIQUE (room_id, user_id)   -- BR-06: 1 sinh vien chi o 1 nhom/hoc ky
);

CREATE TABLE invitations (
    id          NVARCHAR(128) PRIMARY KEY,
    room_id     NVARCHAR(128) NOT NULL REFERENCES rooms(id),
    from_user   NVARCHAR(128) NOT NULL REFERENCES users(id),
    to_user     NVARCHAR(128) NOT NULL REFERENCES users(id),
    type        NVARCHAR(20)  NOT NULL CHECK (type IN ('request', 'invite')),
    status      NVARCHAR(20)  DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'expired')),
    expired_at  DATETIME NOT NULL,  -- BR-20: DATEADD(HOUR, 48, created_at)
    created_at  DATETIME DEFAULT GETDATE()
);

CREATE TABLE vote_sessions (
    id           NVARCHAR(128) PRIMARY KEY,
    room_id      NVARCHAR(128) NOT NULL REFERENCES rooms(id),
    initiated_by NVARCHAR(128) NOT NULL REFERENCES users(id),  -- BR-21
    started_at   DATETIME DEFAULT GETDATE(),
    ended_at     DATETIME NOT NULL,  -- BR-22: DATEADD(HOUR, 24, started_at)
    status       NVARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'ended'))
);

CREATE TABLE votes (
    id         NVARCHAR(128) PRIMARY KEY,
    session_id NVARCHAR(128) NOT NULL REFERENCES vote_sessions(id),
    voter_id   NVARCHAR(128) NOT NULL REFERENCES users(id),
    target_id  NVARCHAR(128) NOT NULL REFERENCES users(id),
    created_at DATETIME DEFAULT GETDATE(),
    UNIQUE (session_id, voter_id),           -- BR-23: moi nguoi chi bo 1 phieu/session
    CHECK (voter_id <> target_id)            -- BR-23: khong tu bau cho minh
);

CREATE TABLE audit_logs (
    id          NVARCHAR(128) PRIMARY KEY,
    actor_id    NVARCHAR(128) REFERENCES users(id),
    action      NVARCHAR(50)  NOT NULL,  -- BR-36
    target_type NVARCHAR(30),
    target_id   NVARCHAR(128),
    meta        NVARCHAR(MAX),
    created_at  DATETIME DEFAULT GETDATE()
);
