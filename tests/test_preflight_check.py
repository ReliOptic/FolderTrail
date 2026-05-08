import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class PreflightCheckContractTests(unittest.TestCase):
    def test_issue_6_preflight_contract(self):
        preflight_path = APP / "Safety" / "PreflightCheck.swift"
        view_path = APP / "UX" / "PreflightView.swift"

        self.assertTrue(preflight_path.exists(), "missing Safety/PreflightCheck.swift")
        self.assertTrue(view_path.exists(), "missing UX/PreflightView.swift")

        preflight = preflight_path.read_text(encoding="utf-8")
        view = view_path.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("enum PreflightCheckResult", preflight)
        self.assertRegex(preflight, r"case\s+passed")
        self.assertRegex(preflight, r"case\s+failed\(reason:")
        self.assertIn("isReadableFile", preflight)
        self.assertIn("deletingLastPathComponent", preflight)
        self.assertIn("createDirectory", preflight)
        self.assertIn("removeItem", preflight)
        self.assertIn("OpenRouterKeychain.load", preflight)
        self.assertIn("Process()", preflight)
        self.assertIn('"codex"', preflight)
        self.assertIn('"--version"', preflight)
        self.assertIn("allPassed", preflight)
        self.assertIn("canProceedToConsent", preflight)

        self.assertIn("struct PreflightView", view)
        self.assertIn("✓", view)
        self.assertIn("◐", view)
        self.assertIn("✗", view)
        self.assertIn("시스템 설정 열기", view)
        self.assertIn("x-apple.systempreferences:com.apple.preference.security?Privacy", view)
        self.assertIn("ProviderConnectView", view)
        self.assertIn("Connect OpenRouter", (APP / "UX" / "ProviderConnectView.swift").read_text(encoding="utf-8"))

        self.assertIn("PreflightCheck.swift", project)
        self.assertIn("PreflightView.swift", project)


if __name__ == "__main__":
    unittest.main()
