import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFLIGHT_VIEW = ROOT / "app" / "macos" / "FolderTrail" / "UX" / "PreflightView.swift"
CODEX_AUTH = ROOT / "app" / "macos" / "FolderTrail" / "UX" / "CodexChatGPTAuthView.swift"


class CodexLoginOnboardingTests(unittest.TestCase):
    def test_issue_39_codex_auth_failure_has_safe_login_guidance(self):
        source = PREFLIGHT_VIEW.read_text(encoding="utf-8") + CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("codexLoginRecovery", source)
        self.assertIn("hasFailed(.codexAuthenticated)", source)
        self.assertIn("Codex 로그인", source)
        self.assertIn("브라우저에서 로그인하세요", source)
        self.assertIn("브라우저에서 로그인하세요", source)
        self.assertIn("Codex 로그인", source)
        self.assertIn("CodexLoginRunner", source)
        self.assertIn("codex login", source)
        self.assertIn("브라우저에서 로그인하세요", source)
        self.assertNotIn("NSWorkspace.shared.open(url)", CODEX_AUTH.read_text(encoding="utf-8"))

    def test_issue_39_user_can_rerun_preflight_after_external_login(self):
        source = PREFLIGHT_VIEW.read_text(encoding="utf-8") + CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("다시 확인", source)
        self.assertIn("rerunPreflight", source)
        self.assertIn("await runner.run(for: folderURL, workspaceMode: workspaceMode)", source)


if __name__ == "__main__":
    unittest.main()
