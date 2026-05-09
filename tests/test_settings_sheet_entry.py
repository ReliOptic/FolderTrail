import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
APP_FILE = APP / "App" / "FolderTrailApp.swift"


class SettingsSheetEntryTests(unittest.TestCase):
    def test_issue_49_prompt_settings_opens_in_app_sheet(self):
        prompt = PROMPT.read_text(encoding="utf-8")

        self.assertIn("showSettingsSheet", prompt)
        self.assertIn(".sheet(isPresented: $showSettingsSheet)", prompt)
        self.assertIn("PromptSettingsSheet", prompt)
        self.assertIn("Codex / ChatGPT OAuth", prompt)
        self.assertIn("private func openSettingsSheet", prompt)
        self.assertIn("showSettingsSheet = true", prompt)
        self.assertNotIn("showSettingsWindow:", prompt)

    def test_issue_49_settings_scene_reuses_same_v0_1_content(self):
        app = APP_FILE.read_text(encoding="utf-8")

        self.assertIn("struct FolderTrailSettingsView", app)
        self.assertIn("ProviderConnectView", app)
        self.assertIn("OpenRouterSettingsView", app)
        self.assertIn("CodexChatGPTOAuthView", app)
        self.assertIn("PlannerModelSettingsView", app)


if __name__ == "__main__":
    unittest.main()
