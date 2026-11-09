"""Server gui thong bao FCM cho EXE Team Matching.

Vai tro: day la "phia server" trong mo hinh FCM. App chi nhan thong bao, khong duoc gui,
vi gui can service account (khoa bi mat) va khoa nay khong bao gio duoc nam trong app.

Luong: app lay token -> luu users/{uid}/fcm_tokens/{token} -> script nay doc token bang
Admin SDK -> goi FCM HTTP v1 -> FCM dua thong bao toi thiet bi.

Cai dat:
    pip install -r server/requirements.txt
    Firebase Console > Project settings > Service accounts > Generate new private key
    Luu file NGOAI repo (khong commit), roi dat bien moi truong:
    set GOOGLE_APPLICATION_CREDENTIALS=C:\\duong\\dan\\service-account.json

Vi du:
    python server/send_fcm.py --uid <uid> --title "Nhac han" --body "Con 3 ngay" --room-id FA26EXE101-01
    python server/send_fcm.py --token <fcm-token> --title "Thu" --body "Xin chao"
"""

import argparse
import sys

import firebase_admin
from firebase_admin import exceptions, firestore, messaging


def tokens_of_user(db, uid):
    docs = db.collection("users").document(uid).collection("fcm_tokens").stream()
    return [doc.id for doc in docs]


def send(token, title, body, room_id):
    # Co phan notification: khi app o nen, he dieu hanh tu hien.
    # data.roomId: app dung de mo dung Room khi nguoi dung cham vao.
    message = messaging.Message(
        token=token,
        notification=messaging.Notification(title=title, body=body),
        data={"roomId": room_id} if room_id else None,
        android=messaging.AndroidConfig(priority="high"),
    )
    return messaging.send(message)


def main():
    parser = argparse.ArgumentParser(description="Gui thong bao FCM")
    target = parser.add_mutually_exclusive_group(required=True)
    target.add_argument("--uid", help="gui toi moi thiet bi cua nguoi dung nay")
    target.add_argument("--token", help="gui toi mot FCM token")
    parser.add_argument("--title", required=True)
    parser.add_argument("--body", required=True)
    parser.add_argument("--room-id", help="Room se mo khi cham thong bao")
    args = parser.parse_args()

    firebase_admin.initialize_app()
    db = firestore.client()
    tokens = [args.token] if args.token else tokens_of_user(db, args.uid)
    if not tokens:
        sys.exit("Nguoi dung nay chua co FCM token. Hay mo app va dang nhap truoc.")

    failed = 0
    for token in tokens:
        try:
            print("Da gui:", send(token, args.title, args.body, args.room_id))
        except messaging.UnregisteredError:
            # Token het hieu luc (go app...): xoa de lan sau khong gui nua.
            failed += 1
            print("Token het hieu luc:", token[:16] + "...")
            if args.uid:
                db.collection("users").document(args.uid).collection("fcm_tokens").document(
                    token
                ).delete()
        except exceptions.FirebaseError as error:
            failed += 1
            print("Loi gui:", error)

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
