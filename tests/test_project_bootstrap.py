import plistlib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MACOS = ROOT / "app" / "macos"
APP = MACOS / "FolderTrail"
PROJECT = MACOS / "FolderTrail.xcodeproj" / "project.pbxproj"


class ProjectBootstrapContractTests(unittest.TestCase):
    def test_issue_2_project_shell_contract(self):
        expected_files = [
            PROJECT,
            MACOS / "FolderTrail.xcodeproj" / "xcshareddata" / "xcschemes" / "FolderTrail.xcscheme",
            APP / "App" / "FolderTrailApp.swift",
            APP / "App" / "AppDelegate.swift",
            APP / "App" / "FolderTrailAppController.swift",
            APP / "Entry" / "FolderTrailServiceProvider.swift",
            APP / "UX" / "PlaceholderPromptView.swift",
            APP / "Info.plist",
            APP / "FolderTrail.entitlements",
        ]
        for path in expected_files:
            self.assertTrue(path.exists(), f"missing {path.relative_to(ROOT)}")

        for directory in ["App", "Entry", "UX", "Safety", "Intelligence", "Execution", "Output"]:
            self.assertTrue((APP / directory).is_dir(), f"missing architecture directory FolderTrail/{directory}")

        info = plistlib.loads((APP / "Info.plist").read_bytes())
        self.assertTrue(info.get("LSUIElement"), "app must run as LSUIElement agent with no Dock icon")
        self.assertIn("NSServices", info, "Finder service declaration must exist for service-provider bootstrap")

        entitlements = plistlib.loads((APP / "FolderTrail.entitlements").read_bytes())
        self.assertFalse(entitlements.get("com.apple.security.app-sandbox"), "App Sandbox must be disabled")

        project = PROJECT.read_text()
        self.assertRegex(project, r"ENABLE_HARDENED_RUNTIME = YES;", "Hardened Runtime must be enabled")
        self.assertRegex(project, r"CODE_SIGN_ENTITLEMENTS = FolderTrail/FolderTrail\.entitlements;", "entitlements must be wired")

        service_provider = (APP / "Entry" / "FolderTrailServiceProvider.swift").read_text()
        self.assertIn("openFolderTrail", service_provider)
        self.assertIn("NSPasteboard", service_provider)
        self.assertIn("FolderTrailAppController.shared.openPrompt", service_provider)


if __name__ == "__main__":
    unittest.main()
