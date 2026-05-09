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
        self.assertIn("AI 준비됨", prompt)
        self.assertIn("AI 연결 필요", prompt)
        self.assertIn("로컬 도우미 선택 사항", prompt)
        self.assertNotIn("Codex fallback 선택", prompt)

    def test_issue_41_settings_surface_mentions_v0_1_provider_and_fallback(self):
        app = (APP / "App" / "FolderTrailApp.swift").read_text(encoding="utf-8")

        self.assertIn("CodexFallbackSettingsView", app)
        self.assertIn("v0.1 설정", app)
        self.assertIn("OpenRouter 연결", app)
        self.assertIn("Codex fallback", app)
        self.assertIn("codex login status", app)
        self.assertNotIn("Advanced", app)


if __name__ == "__main__":
    unittest.main()
