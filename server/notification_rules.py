"""Quy tac: thay doi nao trong Firestore thi gui thong bao gi, cho ai. Khong goi Firebase."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Event:
    title: str
    body: str
    room_id: str | None = None
    # Gui thang cho cac uid nay.
    uids: tuple[str, ...] = ()
    # Gui cho Leader / moi thanh vien cua Room nay, phai doc Room moi biet la ai.
    leader_of: str | None = None
    members_of: str | None = None


def application_events(previous, current):
    """So sanh don Apply truoc va sau. previous la None khi don vua duoc tao."""
    room = current.get("roomId")
    applicant = current.get("applicantId")
    name = current.get("applicantName") or "Một sinh viên"
    status = current.get("status")
    events = []

    if previous is None:
        if status == "pending":
            events.append(
                Event("Có đơn Apply mới", f"{name} xin vào nhóm {room}.", room, leader_of=room)
            )
        return events

    if current.get("voteOpen") and not previous.get("voteOpen") and status == "pending":
        events.append(
            Event("Đã mở vote", f"Hãy vote cho {name} vào nhóm {room}.", room, members_of=room)
        )

    if status != previous.get("status"):
        if status == "accepted":
            events.append(
                Event("Bạn được nhận vào nhóm", f"Nhóm {room} đã vote nhận bạn.", room, (applicant,))
            )
        elif status == "rejected":
            events.append(
                Event("Đơn Apply bị từ chối", f"Đơn vào nhóm {room} đã bị từ chối.", room, (applicant,))
            )
    return events


def transfer_events(previous, current):
    """So sanh yeu cau chuyen nhom truoc va sau."""
    if previous is None or current.get("status") == previous.get("status"):
        return []
    student = current.get("studentId")
    target = current.get("toRoomId")
    if current.get("status") == "approved":
        return [Event("Yêu cầu chuyển nhóm được duyệt", f"Bạn đã sang nhóm {target}.", target, (student,))]
    if current.get("status") == "rejected":
        return [
            Event(
                "Yêu cầu chuyển nhóm bị từ chối",
                f"Giảng viên không duyệt chuyển sang nhóm {target}.",
                current.get("fromRoomId"),
                (student,),
            )
        ]
    return []
