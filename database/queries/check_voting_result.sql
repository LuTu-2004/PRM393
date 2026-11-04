-- ============================================================
-- check_voting_result.sql
-- Kiem tra ket qua bo phieu (BR-27, BR-28)
-- ============================================================

-- Query 1: Ket qua tong hop cua 1 phien bo phieu
-- Thay :session_id bang ID that
DECLARE @session_id NVARCHAR(128) = 'session_001';

SELECT
    u.id          AS target_id,
    u.full_name   AS ten_thanh_vien,
    u.major,
    COUNT(v.id)   AS so_phieu_nhan,
    vs.status     AS trang_thai_phien,
    vs.ended_at   AS ket_thuc_luc
FROM vote_sessions vs
JOIN votes v ON vs.id = v.session_id
JOIN users u ON v.target_id = u.id
WHERE vs.id = @session_id
GROUP BY u.id, u.full_name, u.major, vs.status, vs.ended_at
ORDER BY so_phieu_nhan ASC;  -- Nguoi it phieu nhat o dau (BR-25: de xuat loai)

-- Query 2: Kiem tra tinh toan ven BR-27
-- Tong phieu hop le phai bang so thanh vien tham gia bo phieu
DECLARE @session_id2 NVARCHAR(128) = 'session_001';

SELECT
    (SELECT COUNT(DISTINCT voter_id) FROM votes WHERE session_id = @session_id2) AS so_nguoi_da_bau,
    (SELECT COUNT(*) FROM votes WHERE session_id = @session_id2) AS tong_phieu,
    CASE
        WHEN (SELECT COUNT(DISTINCT voter_id) FROM votes WHERE session_id = @session_id2)
            = (SELECT COUNT(*) FROM votes WHERE session_id = @session_id2)
        THEN 'HOP LE: Moi nguoi bau dung 1 phieu (BR-27)'
        ELSE 'LOI: So phieu khong khop'
    END AS kiem_tra_br27;

-- Query 3: Danh sach ai chua bo phieu trong phien
SELECT
    u.full_name AS chua_bo_phieu,
    u.email
FROM room_members rm
JOIN users u ON rm.user_id = u.id
JOIN vote_sessions vs ON rm.room_id = vs.room_id
WHERE vs.id = @session_id2
  AND u.id NOT IN (
    SELECT voter_id FROM votes WHERE session_id = @session_id2
  );
