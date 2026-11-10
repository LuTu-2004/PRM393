"""Chay: python -m unittest discover -s server"""

import unittest

from notification_rules import application_events, transfer_events

APP = {
    "roomId": "FA26EXE101-01",
    "applicantId": "d",
    "applicantName": "SV D",
    "status": "pending",
    "voteOpen": False,
}


class ApplicationEvents(unittest.TestCase):
    def test_new_application_goes_to_leader(self):
        event = application_events(None, APP)[0]
        self.assertEqual(event.leader_of, "FA26EXE101-01")
        self.assertIn("SV D", event.body)

    def test_new_non_pending_application_is_silent(self):
        self.assertEqual(application_events(None, {**APP, "status": "withdrawn"}), [])

    def test_opening_vote_goes_to_members(self):
        event = application_events(APP, {**APP, "voteOpen": True})[0]
        self.assertEqual(event.members_of, "FA26EXE101-01")

    def test_a_ballot_alone_is_silent(self):
        opened = {**APP, "voteOpen": True}
        self.assertEqual(application_events(opened, {**opened, "votes": {"a": True}}), [])

    def test_accepted_goes_to_applicant_and_opens_room(self):
        opened = {**APP, "voteOpen": True}
        event = application_events(opened, {**opened, "status": "accepted"})[0]
        self.assertEqual(event.uids, ("d",))
        self.assertEqual(event.room_id, "FA26EXE101-01")
        self.assertIn("nhận", event.title)

    def test_rejected_goes_to_applicant(self):
        event = application_events(APP, {**APP, "status": "rejected"})[0]
        self.assertEqual(event.uids, ("d",))
        self.assertIn("từ chối", event.title)

    def test_cancelled_and_withdrawn_are_silent(self):
        for status in ("cancelled", "withdrawn"):
            self.assertEqual(application_events(APP, {**APP, "status": status}), [])

    def test_same_status_does_not_notify_again(self):
        accepted = {**APP, "status": "accepted"}
        self.assertEqual(application_events(accepted, {**accepted, "decidedAt": 1}), [])

    def test_vote_opened_with_decision_in_same_write_only_reports_decision(self):
        events = application_events(APP, {**APP, "voteOpen": True, "status": "accepted"})
        self.assertEqual([e.uids for e in events], [("d",)])


class TransferEvents(unittest.TestCase):
    REQUEST = {
        "studentId": "s",
        "fromRoomId": "FA26EXE101-01",
        "toRoomId": "FA26EXE101-02",
        "status": "pending",
    }

    def test_new_request_is_silent(self):
        self.assertEqual(transfer_events(None, self.REQUEST), [])

    def test_approved_opens_target_room(self):
        event = transfer_events(self.REQUEST, {**self.REQUEST, "status": "approved"})[0]
        self.assertEqual(event.uids, ("s",))
        self.assertEqual(event.room_id, "FA26EXE101-02")

    def test_rejected_opens_current_room(self):
        event = transfer_events(self.REQUEST, {**self.REQUEST, "status": "rejected"})[0]
        self.assertEqual(event.room_id, "FA26EXE101-01")

    def test_no_status_change_is_silent(self):
        self.assertEqual(transfer_events(self.REQUEST, dict(self.REQUEST)), [])


if __name__ == "__main__":
    unittest.main()
