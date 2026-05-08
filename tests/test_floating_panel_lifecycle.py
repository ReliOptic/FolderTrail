import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"


class FloatingPanelLifecycleTests(unittest.TestCase):
    def test_issue_29_panel_reopens_and_survives_oauth_roundtrip(self):
        app_delegate = (APP / "App" / "AppDelegate.swift").read_text(encoding="utf-8")
        controller = (APP / "App" / "FolderTrailAppController.swift").read_text(encoding="utf-8")
        provider_view = (APP / "UX" / "ProviderConnectView.swift").read_text(encoding="utf-8")

        self.assertIn("applicationShouldHandleReopen", app_delegate)
        self.assertIn("openPrompt", app_delegate)
        self.assertIn("bringPromptToFront", app_delegate)

        self.assertIn("NSWindowDelegate", controller)
        self.assertIn("hidesOnDeactivate = false", controller)
        self.assertIn("isReleasedWhenClosed = false", controller)
        self.assertIn("bringPromptToFront", controller)
        self.assertIn("windowWillClose", controller)
        self.assertIn("NSApp.terminate", controller)

        self.assertIn("bringPromptToFront", provider_view)
        self.assertIn("NSApp.activate", provider_view)


if __name__ == "__main__":
    unittest.main()
