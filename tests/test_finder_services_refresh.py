import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_DELEGATE = ROOT / "app" / "macos" / "FolderTrail" / "App" / "AppDelegate.swift"
README = ROOT / "README.md"


class FinderServicesRefreshTests(unittest.TestCase):
    def test_issue_31_app_requests_services_refresh_at_launch(self):
        source = APP_DELEGATE.read_text(encoding="utf-8")

        self.assertIn("NSApp.setServicesProvider(serviceProvider)", source)
        self.assertIn("NSUpdateDynamicServices()", source)
        self.assertLess(
            source.index("NSApp.setServicesProvider(serviceProvider)"),
            source.index("NSUpdateDynamicServices()"),
            "FolderTrail should install its provider before asking Services to refresh",
        )

    def test_issue_31_install_notes_explain_finder_services_refresh(self):
        readme = README.read_text(encoding="utf-8")

        self.assertIn("Finder Services", readme)
        self.assertIn("/Applications", readme)
        self.assertIn("Finder", readme)
        self.assertRegex(readme, r"로그아웃/로그인|relaunch|재실행")


if __name__ == "__main__":
    unittest.main()
