import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"
PREFLIGHT = APP / "UX" / "PreflightView.swift"


class CodexLoginAutoRecheckTests(unittest.TestCase):
    def test_issue_63_successful_login_triggers_recheck_callback(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("loginRunner.start(onSuccess: onRecheck)", source)
        self.assertIn("func start(onSuccess: (() -> Void)? = nil)", source)
        self.assertIn("if succeeded", source)
        self.assertIn("onSuccess?()", source)
        self.assertIn("로그인 완료", source)
        self.assertIn("확인 중…", source)
        self.assertIn("로그인 후 자동 확인합니다", source)

    def test_issue_63_preflight_passes_rerun_as_success_callback(self):
        preflight = PREFLIGHT.read_text(encoding="utf-8")

        self.assertIn("CodexChatGPTOAuthView(onRecheck: rerunPreflight)", preflight)
        self.assertIn("private func rerunPreflight", preflight)
        self.assertIn("await runner.run(for: folderURL, workspaceMode: preflightWorkspaceMode)", preflight)


if __name__ == "__main__":
    unittest.main()
