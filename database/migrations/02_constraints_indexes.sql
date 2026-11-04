-- ============================================================
-- 02_constraints_indexes.sql
-- Them Index tang toc truy van va Constraint nghiep vu
-- Tham khao: BR-17, BR-18, BR-20, BR-27
-- ============================================================

-- Index tim kiem phong theo hoc ky va mon hoc (BR-14)
CREATE INDEX idx_rooms_semester_subject
    ON rooms (semester_id, subject_code, status);

-- Index dem pending invitations cua mot sinh vien (BR-17: toi da 3)
CREATE INDEX idx_invitations_pending_user
    ON invitations (to_user, status)
    WHERE status = 'pending';

-- Index lich su bo phieu theo session (BR-28)
CREATE INDEX idx_votes_session
    ON votes (session_id);

-- Index audit log theo actor (BR-36)
CREATE INDEX idx_audit_actor_time
    ON audit_logs (actor_id, created_at DESC);

-- Constraint: khong duoc co qua 50% cung nganh trong phong (BR-18)
-- Thuc thi o tang application (Flutter + Repository), khong enforce o DB
-- Ly do: Firebase Firestore khong ho tro complex constraint
-- -> Kiem tra trong RoomRepository.approveRequest() truoc khi them member

-- Constraint: Request expired sau 48h (BR-20)
-- Thuc thi o tang application: check expired_at < GETDATE() khi lay pending invitations

-- Constraint: Tong phieu hop le = so thanh vien bo phieu (BR-27)
-- Kiem tra trong VotingRepository.closeVoteSession() truoc khi dong session
