import os
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "scripts" / "build-dev-dmg.sh"


class DevDMGPackagingTests(unittest.TestCase):
    def test_issue_57_dev_dmg_script_expands_bundle_metadata(self):
        self.assertTrue(SCRIPT.exists(), "missing dev DMG build script")
        self.assertTrue(os.access(SCRIPT, os.X_OK), "dev DMG build script must be executable")

        script = SCRIPT.read_text(encoding="utf-8")

        for token in [
            "CFBundleExecutable",
            "FolderTrail",
            "CFBundleIdentifier",
            "com.relioptic.FolderTrail",
            "MARKETING_VERSION",
            "CURRENT_PROJECT_VERSION",
            "MACOSX_DEPLOYMENT_TARGET",
            "DEVELOPMENT_LANGUAGE",
        ]:
            self.assertIn(token, script)

        self.assertIn("plistlib", script)
        self.assertIn("unexpanded Info.plist placeholder", script)
        self.assertIn("codesign --force --deep --sign -", script)
        self.assertIn("hdiutil create", script)
        self.assertIn("hdiutil verify", script)
        self.assertIn("shasum -a 256", script)

    def test_issue_57_dev_dmg_script_rejects_placeholder_executable(self):
        script = SCRIPT.read_text(encoding="utf-8")

        self.assertIn("$(EXECUTABLE_NAME)", script)
        self.assertIn("raise SystemExit", script)
        self.assertIn("executable != \"FolderTrail\"", script)
        self.assertIn("if \"$(\" in rendered", script)


if __name__ == "__main__":
    unittest.main()
