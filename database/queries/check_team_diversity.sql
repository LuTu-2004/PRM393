-- ============================================================
-- check_team_diversity.sql
-- Kiem tra ty le chuyen nganh trong phong (BR-18, BR-19)
-- Phong khong duoc co qua 50% cung nganh
-- ============================================================

-- Query 1: Ty le nganh trong tung phong
SELECT
    r.id          AS room_id,
    r.name        AS room_name,
    u.major,
    COUNT(*)      AS member_count,
    r.member_count AS total_members,
    CAST(COUNT(*) AS FLOAT) / r.member_count AS ratio,
    CASE
        WHEN CAST(COUNT(*) AS FLOAT) / r.member_count > 0.5
        THEN 'CANH BAO: Vi pham BR-18 (>50% cung nganh)'
        ELSE 'OK'
    END AS status
FROM room_members rm
JOIN rooms r ON rm.room_id = r.id
JOIN users u ON rm.user_id = u.id
GROUP BY r.id, r.name, r.member_count, u.major
HAVING COUNT(*) > 1
ORDER BY ratio DESC;

-- Query 2: Danh sach phong dang vi pham BR-18
SELECT
    r.id, r.name,
    u.major,
    COUNT(*) AS same_major_count,
    r.member_count,
    CAST(COUNT(*) AS FLOAT) / r.member_count AS ratio
FROM room_members rm
JOIN rooms r ON rm.room_id = r.id
JOIN users u ON rm.user_id = u.id
GROUP BY r.id, r.name, r.member_count, u.major
HAVING CAST(COUNT(*) AS FLOAT) / r.member_count > 0.5;

-- Query 3: Kiem tra 1 phong cu the truoc khi them thanh vien moi
-- Su dung: thay :room_id va :new_major bang gia tri thuc
DECLARE @room_id NVARCHAR(128) = 'room_001';
DECLARE @new_major NVARCHAR(50) = 'SE';

SELECT
    COUNT(*) AS same_major_after,
    (SELECT member_count + 1 FROM rooms WHERE id = @room_id) AS total_after,
    CAST(COUNT(*) + 1 AS FLOAT) /
        (SELECT member_count + 1 FROM rooms WHERE id = @room_id) AS new_ratio,
    CASE
        WHEN CAST(COUNT(*) + 1 AS FLOAT) /
            (SELECT member_count + 1 FROM rooms WHERE id = @room_id) > 0.5
        THEN 'TU CHOI: Them thanh vien nay se vi pham BR-18'
        ELSE 'CHAP NHAN: Ty le van hop le'
    END AS verdict
FROM room_members rm
JOIN users u ON rm.user_id = u.id
WHERE rm.room_id = @room_id AND u.major = @new_major;
