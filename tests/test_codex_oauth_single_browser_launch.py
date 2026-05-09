import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"


class CodexOAuthSingleBrowserLaunchTests(unittest.TestCase):
    def test_issue_81_codex_login_delegates_browser_opening_to_cli_only(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn('process.arguments = ["-lc", "codex login"]', source)
        self.assertNotIn("NSWorkspace.shared.open(url)", source)
        self.assertNotIn("extractAuthURL", source)
        self.assertIn("readabilityHandler", source)
        self.assertIn("브라우저에서 로그인하세요", source)


if __name__ == "__main__":
    unittest.main()
