import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"


class CodexOAuthRecheckTerminalStateTests(unittest.TestCase):
    def test_issue_67_successful_browser_login_uses_bounded_terminal_status_copy(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("recheckLoginStatusAfterSuccess", source)
        self.assertIn("Codex / ChatGPT 로그인 완료", source)
        self.assertIn("브라우저 로그인은 끝났지만 앱에서 아직 확인하지 못했습니다", source)
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
