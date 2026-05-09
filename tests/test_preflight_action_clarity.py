import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"


class PreflightActionClarityTests(unittest.TestCase):
    def test_issue_38_preflight_body_is_scrollable_and_statuses_are_legible(self):
        view = (APP / "UX" / "PreflightView.swift").read_text(encoding="utf-8")

        self.assertIn("ScrollView", view)
        self.assertIn("preflightRows", view)
        self.assertIn("statusLabel", view)
        self.assertIn("통과", view)
        self.assertIn("확인 중", view)
        self.assertIn("조치 필요", view)
        self.assertIn("계속할 수 없습니다", view)
        self.assertIn("복사본 만들고 계속", view)

    def test_issue_38_codex_chatgpt_oauth_does_not_hide_primary_next_action(self):
        source = (APP / "Safety" / "PreflightCheck.swift").read_text(encoding="utf-8")
        view = (APP / "UX" / "PreflightView.swift").read_text(encoding="utf-8")

        self.assertIn("var blocksProceed", source)
        self.assertRegex(source, r"case \.folderReadable, \.workspaceWritable, \.codexAvailable, \.codexAuthenticated:\n\s+return true")
        self.assertNotIn("providerConnected", source)
        self.assertIn("checks.filter { $0.id.blocksProceed }", source)
        self.assertNotIn("OpenRouter", view)


if __name__ == "__main__":
    unittest.main()
