import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFLIGHT = ROOT / "app" / "macos" / "FolderTrail" / "Safety" / "PreflightCheck.swift"


class CodexOAuthStatusPreflightTests(unittest.TestCase):
    def test_issue_34_codex_auth_is_separate_from_cli_discovery(self):
        source = PREFLIGHT.read_text(encoding="utf-8")

        self.assertIn("case codexAvailable", source)
        self.assertIn("case codexAuthenticated", source)
        self.assertIn("Codex 로그인됨", source)
        self.assertIn("checkCodexAuthenticated", source)
        self.assertIn('"login"', source)
        self.assertIn('"status"', source)
        self.assertIn("codex login status", source)
        self.assertIn("runCodexLoginStatus", source)
        self.assertIn("codex login status", source)

    def test_issue_34_preflight_keeps_install_and_login_failures_distinct(self):
        source = PREFLIGHT.read_text(encoding="utf-8")

        install_failure = "앱 환경에서 `codex --version`이 성공하지 않았습니다."
        auth_failure = "Codex 로그인 후 다시 확인해 주세요."

        self.assertIn(install_failure, source)
        self.assertIn(auth_failure, source)
        self.assertLess(source.index(install_failure), source.index(auth_failure))


if __name__ == "__main__":
    unittest.main()
