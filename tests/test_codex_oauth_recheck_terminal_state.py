import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"


class CodexOAuthRecheckTerminalStateTests(unittest.TestCase):
    def test_issue_67_successful_browser_login_uses_bounded_terminal_status_copy(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("recheckLoginStatusAfterSuccess", source)
        self.assertIn("로그인 완료", source)
        self.assertIn("다시 확인해 주세요", source)
        self.assertIn("onSuccess?()", source)
        self.assertNotIn("로그인 완료. 확인 중…", source)

    def test_issue_67_recheck_reuses_bounded_preflight_status_check(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")
        preflight = (APP / "Safety" / "PreflightCheck.swift").read_text(encoding="utf-8")

        self.assertIn("PreflightCheck.isCodexAuthenticated()", source)
        self.assertIn("static func isCodexAuthenticated() -> Bool", preflight)
        self.assertIn("codexCommandTimeout: TimeInterval = 4", preflight)


if __name__ == "__main__":
    unittest.main()
