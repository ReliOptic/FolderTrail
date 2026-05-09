import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"


class CodexOAuthCompletedStateTests(unittest.TestCase):
    def test_issue_79_existing_auth_is_checked_before_launching_browser_login(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("refreshExistingLoginStatus", source)
        self.assertIn("guard !(await Self.isAlreadyAuthenticated())", source)
        self.assertLess(source.index("guard !(await Self.isAlreadyAuthenticated())"), source.index("runLoginProcess"))
        self.assertIn("PreflightCheck.isCodexAuthenticated()", source)
        self.assertIn(".task { await loginRunner.refreshExistingLoginStatus() }", source)

    def test_issue_79_completed_auth_state_disables_repeat_login_and_explains_next_action(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("@Published private(set) var isAuthenticated = false", source)
        self.assertIn("로그인 완료", source)
        self.assertIn("로그인 완료", source)
        self.assertIn(".disabled(loginRunner.isRunning || loginRunner.isAuthenticated)", source)


if __name__ == "__main__":
    unittest.main()
