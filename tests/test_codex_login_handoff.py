import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PREFLIGHT_VIEW = APP / "UX" / "PreflightView.swift"


class CodexLoginHandoffTests(unittest.TestCase):
    def test_issue_51_preflight_opens_visible_codex_login_handoff(self):
        view = PREFLIGHT_VIEW.read_text(encoding="utf-8")

        self.assertIn("Codex 로그인 열기", view)
        self.assertIn("openCodexLoginInTerminal", view)
        self.assertIn("foldertrail-codex-login-", view)
        self.assertIn("NSWorkspace.shared.open(commandURL)", view)
        self.assertIn("codex login", view)
        self.assertIn("브라우저가 열릴 수 있습니다", view)
        self.assertIn("다시 확인", view)
        self.assertIn("토큰을 FolderTrail에 붙여넣지 마세요", view)

        self.assertNotIn("codex login 명령 복사", view)


if __name__ == "__main__":
    unittest.main()
