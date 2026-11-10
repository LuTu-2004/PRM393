"""Tu gui thong bao FCM khi du lieu Firestore doi: don Apply moi, mo vote, ket qua vote,
ket qua chuyen nhom.

Luong: app ghi Firestore -> script nhan thay doi qua listener -> tim uid nguoi nhan -> doc token
-> goi FCM HTTP v1. Script chi doc Firestore, khong ghi gi vao du lieu cua app.

Chay mot ban duy nhat trong luc demo (chay hai ban se gui trung):
    set GOOGLE_APPLICATION_CREDENTIALS=C:\\duong\\dan\\service-account.json
    python server/notify_events.py

Trang thai cu chi nam trong bo nho: luc khoi dong coi moi du lieu la da biet, nen khong gui lai
thong bao cu, va thay doi xay ra khi script dang tat se khong duoc gui.
"""

import time

import firebase_admin
from firebase_admin import firestore

from notification_rules import application_events, transfer_events
from send_fcm import send_to_user


def recipients(db, event):
    uids = set(event.uids)
    room_id = event.leader_of or event.members_of
    if room_id:
        snapshot = db.collection("rooms").document(room_id).get()
        room = snapshot.to_dict() or {}
        if event.leader_of and room.get("leaderId"):
            uids.add(room["leaderId"])
        if event.members_of:
            uids.update(room.get("memberIds") or [])
    return uids


def deliver(db, event):
    for uid in recipients(db, event):
        send_to_user(db, uid, event.title, event.body, event.room_id)


def watch(db, collection, rules):
    """Lang nghe mot collection. Lan goi dau chi ghi nho trang thai hien co, khong gui gi."""
    known = {}
    first = [True]

    def on_change(_docs, changes, _read_time):
        for change in changes:
            doc_id = change.document.id
            if change.type.name == "REMOVED":
                known.pop(doc_id, None)
                continue
            current = change.document.to_dict() or {}
            previous = known.get(doc_id)
            known[doc_id] = current
            if first[0]:
                continue
            # Loi cua mot thong bao khong duoc lam dung listener.
            try:
                for event in rules(previous, current):
                    print(f"[{collection}/{doc_id}] {event.title}")
                    deliver(db, event)
            except Exception as error:
                print(f"Loi xu ly {collection}/{doc_id}: {error}")
        if first[0]:
            first[0] = False
            print(f"Dang theo doi {collection} ({len(known)} ban ghi)")

    return db.collection(collection).on_snapshot(on_change)


def main():
    firebase_admin.initialize_app()
    db = firestore.client()
    watchers = [
        watch(db, "applications", application_events),
        watch(db, "transfer_requests", transfer_events),
    ]
    print("Dang chay, bam Ctrl+C de dung.")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        for watcher in watchers:
            watcher.unsubscribe()


if __name__ == "__main__":
    main()
