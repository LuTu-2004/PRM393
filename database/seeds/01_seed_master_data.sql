-- ============================================================
-- 01_seed_master_data.sql
-- Du lieu chuan: hoc ky, cac loai du lieu dau vao co dinh
-- ============================================================

-- Hoc ky hien tai
INSERT INTO semesters (id, name, reg_deadline, is_active) VALUES
('FALL2026',   'Fall 2026',   '2026-12-15 23:59:00', 1),
('SPRING2027', 'Spring 2027', '2027-05-15 23:59:00', 0);

-- Ghi chu ve cac ky nang (Skills) - trong Firestore luu la array strings
-- Danh sach goi y cho sinh vien chon:
-- 'Frontend Development', 'Backend Development', 'Mobile Development (Flutter)',
-- 'UI/UX Design', 'Business Analysis', 'Project Management',
-- 'Marketing', 'Finance', 'Data Analysis', 'DevOps'

-- Ghi chu ve dinh huong khoi nghiep (Orientation) - trong Firestore luu la string:
-- 'Technology Startup', 'Social Enterprise', 'Service Business',
-- 'E-commerce', 'EdTech', 'HealthTech', 'FinTech'

-- Mon hoc EXE hop le: 'EXE101', 'EXE201'
-- Vai tro nguoi dung: 'student', 'moderator'
-- Trang thai phong: 'open', 'full', 'closed', 'confirmed'
-- Kieu invitation: 'request', 'invite'
-- Trang thai invitation: 'pending', 'accepted', 'rejected', 'expired'

SELECT 'Master data reference loaded' AS status;
