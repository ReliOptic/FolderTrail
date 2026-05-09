import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PREFLIGHT_VIEW = APP / "UX" / "PreflightView.swift"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"


class CodexLoginHandoffTests(unittest.TestCase):
    def test_issue_51_preflight_opens_visible_codex_login_handoff(self):
        view = PREFLIGHT_VIEW.read_text(encoding="utf-8")
        handoff = CODEX_AUTH.read_text(encoding="utf-8")
        source = view + handoff

        self.assertIn("CodexChatGPTOAuthView", view)
        self.assertIn("Codex / ChatGPT 로그인", source)
        self.assertIn("CodexLoginRunner", source)
        self.assertIn("codex login", source)
        self.assertIn("브라우저 로그인은 Codex가 열어 줍니다", source)
        self.assertIn("토큰을 FolderTrail에 붙여넣지 마세요", source)
        self.assertIn("다시 확인", source)

        self.assertNotIn("codex login 명령 복사", source)
        self.assertNotIn("NSWorkspace.shared.open(url)", handoff)


if __name__ == "__main__":
    unittest.main()
