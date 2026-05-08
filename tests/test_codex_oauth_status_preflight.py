import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFLIGHT = ROOT / "app" / "macos" / "FolderTrail" / "Safety" / "PreflightCheck.swift"


class CodexOAuthStatusPreflightTests(unittest.TestCase):
    def test_issue_34_codex_auth_is_separate_from_cli_discovery(self):
        source = PREFLIGHT.read_text(encoding="utf-8")

        self.assertIn("case codexAvailable", source)
        self.assertIn("case codexAuthenticated", source)
        self.assertIn("Codex CLI fallback is authenticated", source)
        self.assertIn("checkCodexAuthenticated", source)
        self.assertIn('"login"', source)
        self.assertIn('"status"', source)
        self.assertIn("codex login status", source)
        self.assertIn("runCodexLoginStatus", source)
        self.assertIn("Run `codex login`", source)

    def test_issue_34_preflight_keeps_install_and_login_failures_distinct(self):
        source = PREFLIGHT.read_text(encoding="utf-8")

        install_failure = "`codex --version` did not succeed from the app environment."
        auth_failure = "Codex CLI is installed but not authenticated. Run `codex login` in Terminal and finish OAuth, then retry."

        self.assertIn(install_failure, source)
        self.assertIn(auth_failure, source)
        self.assertLess(source.index(install_failure), source.index(auth_failure))


if __name__ == "__main__":
    unittest.main()
