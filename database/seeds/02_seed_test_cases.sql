-- ============================================================
-- 02_seed_test_cases.sql
-- Mock data: Sinh vien va phong de test cac Business Rules
-- ============================================================

-- === SINH VIEN MAU (test BR-04, BR-05, BR-06) ===

-- SE (Software Engineering) students
INSERT INTO users (id, email, full_name, role, student_code, major, cohort, accepted_policy_at) VALUES
('uid_se_001', 'se001@fpt.edu.vn', 'Nguyen Van An', 'student', 'SE001', 'SE', 'K18', GETDATE()),
('uid_se_002', 'se002@fpt.edu.vn', 'Tran Thi Bich', 'student', 'SE002', 'SE', 'K18', GETDATE()),
('uid_se_003', 'se003@fpt.edu.vn', 'Le Van Cuong', 'student', 'SE003', 'SE', 'K18', GETDATE()),

-- BA (Business Administration) students  
('uid_ba_001', 'ba001@fpt.edu.vn', 'Pham Thi Dung', 'student', 'BA001', 'BA', 'K18', GETDATE()),
('uid_ba_002', 'ba002@fpt.edu.vn', 'Hoang Van Em', 'student', 'BA002', 'BA', 'K18', GETDATE()),

-- MKT (Marketing) student
('uid_mkt_001', 'mkt001@fpt.edu.vn', 'Vo Thi Phuong', 'student', 'MKT001', 'MKT', 'K18', GETDATE()),

-- Moderator
('uid_mod_001', 'mod001@fpt.edu.vn', 'Co Nguyen Ha', 'moderator', NULL, NULL, NULL, GETDATE());

-- Ho so sinh vien
INSERT INTO student_profiles (user_id, skills, orientation, bio, is_complete) VALUES
('uid_se_001', '["Backend Development", "Mobile Development (Flutter)"]', 'Technology Startup', 'SE sinh vien yeu thich lam mobile app', 1),
('uid_se_002', '["Frontend Development", "UI/UX Design"]', 'EdTech', 'SE sinh vien thiet ke gioi', 1),
('uid_se_003', '["Backend Development", "DevOps"]', 'FinTech', 'SE chuyen server-side', 1),
('uid_ba_001', '["Business Analysis", "Project Management"]', 'Social Enterprise', 'BA am hieu nghiep vu', 1),
('uid_ba_002', '["Finance", "Marketing"]', 'E-commerce', 'BA thich kinh doanh', 1),
('uid_mkt_001', '["Marketing", "Business Analysis"]', 'Technology Startup', 'MKT yeu thich marketing', 1);

-- === PHONG MAU ===

-- Phong 1: Da du 4 nguoi (3 SE + 1 BA) -> CANH BAO BR-18 (75% SE > 50%)
INSERT INTO rooms (id, name, description, subject_code, semester_id, leader_id, is_public, status, member_count) VALUES
('room_001', 'Alpha Team', 'Du an ung dung giao duc truc tuyen', 'EXE101', 'FALL2026', 'uid_se_001', 1, 'full', 4);

INSERT INTO room_members (id, room_id, user_id) VALUES
('rm_001', 'room_001', 'uid_se_001'),
('rm_002', 'room_001', 'uid_se_002'),
('rm_003', 'room_001', 'uid_se_003'),
('rm_004', 'room_001', 'uid_ba_001');
-- Ghi chu: 3/4 = 75% la SE -> vi pham BR-18 -> he thong phai canh bao!

-- Phong 2: Phong mo, dang can them nguoi (BR-14 co the tim thay)
INSERT INTO rooms (id, name, description, subject_code, semester_id, leader_id, is_public, status, member_count) VALUES
('room_002', 'Beta Startup', 'Startup fintech cho sinh vien', 'EXE101', 'FALL2026', 'uid_ba_002', 1, 'open', 2);

INSERT INTO room_members (id, room_id, user_id) VALUES
('rm_005', 'room_002', 'uid_ba_002'),
('rm_006', 'room_002', 'uid_mkt_001');

SELECT 'Test data loaded successfully' AS status;
-- Test cases:
-- 1. Kiem tra BR-18: SELECT * FROM room_members WHERE room_id = 'room_001' -- 75% SE
-- 2. Kiem tra BR-07: room_002 co 2 nguoi < 4 -> chua du dieu kien
-- 3. Kiem tra BR-06: Thu them uid_se_001 vao room_002 -> phai bi chan
