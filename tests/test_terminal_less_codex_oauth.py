import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"


class TerminalLessCodexOAuthTests(unittest.TestCase):
    def test_issue_62_codex_oauth_runs_in_app_without_terminal_command(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("final class CodexLoginRunner", source)
        self.assertIn("@StateObject private var loginRunner", source)
        self.assertIn("loginRunner.start", source)
        self.assertIn("Process()", source)
        self.assertIn("readabilityHandler", source)
        self.assertIn("extractAuthURL", source)
        self.assertIn("NSWorkspace.shared.open(url)", source)
        self.assertIn("브라우저를 열고 있어요", source)
        self.assertIn("브라우저에서 로그인을 마치면 FolderTrail이 확인합니다", source)
        self.assertIn("로그인 완료", source)

        forbidden = [
            "openInTerminal",
            ".command",
            "NSWorkspace.shared.open(commandURL)",
            "Press return to close",
            "터미널",
        ]
        for token in forbidden:
            self.assertNotIn(token, source)

    def test_issue_62_ui_disables_duplicate_login_while_running(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("loginRunner.isRunning", source)
        self.assertIn(".disabled(loginRunner.isRunning)", source)
        self.assertIn("ProgressView", source)
        self.assertIn("Codex / ChatGPT 로그인", source)


if __name__ == "__main__":
    unittest.main()
