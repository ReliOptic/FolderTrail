import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PREFLIGHT_CHECK = APP / "Safety" / "PreflightCheck.swift"
PREFLIGHT_VIEW = APP / "UX" / "PreflightView.swift"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"


class PreflightProgressTimeoutTests(unittest.TestCase):
    def test_issue_52_runner_renders_pending_rows_before_background_checks(self):
        source = PREFLIGHT_CHECK.read_text(encoding="utf-8")

        self.assertIn("static func pendingChecks", source)
        self.assertIn("checks = PreflightCheck.pendingChecks(workspaceMode: workspaceMode)", source)
        self.assertIn("Task.detached(priority: .userInitiated)", source)
        self.assertRegex(source, r"let resolvedChecks = await Task\.detached")
        self.assertIn("checks = resolvedChecks", source)

    def test_issue_52_codex_checks_have_bounded_timeout_and_rerun_is_visible(self):
        source = PREFLIGHT_CHECK.read_text(encoding="utf-8")
        view = PREFLIGHT_VIEW.read_text(encoding="utf-8") + CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("codexCommandTimeout", source)
        self.assertIn("timeout: TimeInterval = codexCommandTimeout", source)
        self.assertIn("Date().addingTimeInterval(timeout)", source)
        self.assertIn("process.terminate()", source)
        self.assertIn("다시 확인", view)
        self.assertIn("rerunPreflight", view)

        self.assertNotIn("process.waitUntilExit()", source)


if __name__ == "__main__":
    unittest.main()
