import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRIBUTING = ROOT / "CONTRIBUTING.md"
AGENTS = ROOT / "AGENTS.md"


class DoneContractDocsTests(unittest.TestCase):
    def test_issue_88_contributing_defines_done_as_user_visible_acceptance(self):
        source = CONTRIBUTING.read_text(encoding="utf-8")

        self.assertIn("Done means verified acceptance", source)
        self.assertIn("Do not call a PR or issue done just because tests passed or the branch merged.", source)
        self.assertIn("acceptance evidence", source)
        self.assertIn("user-visible behavior", source)
        self.assertIn("manual or scripted smoke check", source)
        self.assertIn("known gaps", source)

    def test_issue_88_agent_notes_forbid_done_without_acceptance_evidence(self):
        source = AGENTS.read_text(encoding="utf-8")

        self.assertIn("Do not say done", source)
        self.assertIn("acceptance evidence", source)
        self.assertIn("If the user-visible flow was not verified, say what remains unverified.", source)

    def test_issue_88_pr_checklist_tracks_red_green_acceptance_and_gaps(self):
        source = CONTRIBUTING.read_text(encoding="utf-8")

        self.assertIn("RED evidence", source)
        self.assertIn("GREEN evidence", source)
        self.assertIn("Acceptance evidence", source)
        self.assertIn("Known gaps", source)


if __name__ == "__main__":
    unittest.main()
