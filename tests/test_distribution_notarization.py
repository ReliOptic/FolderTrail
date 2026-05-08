import os
import stat
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "build.sh"
EXPORT_OPTIONS = ROOT / "app" / "macos" / "ExportOptions.plist"
ENTITLEMENTS = ROOT / "app" / "macos" / "FolderTrail" / "FolderTrail.entitlements"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"
README = ROOT / "README.md"


class DistributionNotarizationContractTests(unittest.TestCase):
    def test_issue_14_distribution_contract(self):
        self.assertTrue(SCRIPT.exists(), "missing scripts/build.sh")
        self.assertTrue(EXPORT_OPTIONS.exists(), "missing ExportOptions.plist")

        script = SCRIPT.read_text(encoding="utf-8")
        export_options = EXPORT_OPTIONS.read_text(encoding="utf-8")
        entitlements = ENTITLEMENTS.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")
        readme = README.read_text(encoding="utf-8")

        self.assertTrue(os.access(SCRIPT, os.X_OK), "scripts/build.sh must be executable")
        for token in ["xcodebuild archive", "-exportArchive", "notarytool submit", "stapler staple", "spctl --assess"]:
            self.assertIn(token, script)
        self.assertIn("Developer ID Application", export_options)
        self.assertIn("com.apple.security.app-sandbox", entitlements)
        self.assertIn("<false/>", entitlements)
        self.assertIn("ENABLE_HARDENED_RUNTIME = YES", project)
        self.assertIn("설치", readme)
        self.assertIn("Gatekeeper", readme)
        self.assertIn("Finder Services", readme)
        self.assertIn("Developer ID", readme)


if __name__ == "__main__":
    unittest.main()
