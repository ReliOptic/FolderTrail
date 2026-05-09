import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"


class StatusSettingsEntryTests(unittest.TestCase):
    def test_issue_41_prompt_has_minimal_status_strip_and_settings_entry(self):
        prompt = (APP / "UX" / "PlaceholderPromptView.swift").read_text(encoding="utf-8")

        self.assertIn("PromptStatusStrip", prompt)
        self.assertIn("statusStrip", prompt)
        self.assertIn("settingsButton", prompt)
        self.assertIn("설정…", prompt)
        self.assertIn("openSettingsSheet", prompt)
        self.assertIn("showSettingsSheet", prompt)
        self.assertNotIn("showSettingsWindow:", prompt)
        self.assertNotIn('Text("OpenRouter', prompt)
        self.assertNotIn("PromptReadinessBar", prompt)
        self.assertNotIn("Codex fallback 선택", prompt)

    def test_issue_41_settings_surface_mentions_v0_1_provider_and_local_helper(self):
        app = (APP / "App" / "FolderTrailApp.swift").read_text(encoding="utf-8")
        prompt_settings = (APP / "UX" / "PromptSettingsSheet.swift").read_text(encoding="utf-8")

        self.assertIn("CodexChatGPTOAuthView", app)
        self.assertIn("v0.1 설정", app)
        self.assertIn("OpenRouter", app)
        self.assertIn("ProviderConnectView", prompt_settings)
        self.assertIn("OpenRouterSettingsView", prompt_settings)
        self.assertNotIn("Advanced", app + prompt_settings)


if __name__ == "__main__":
    unittest.main()
