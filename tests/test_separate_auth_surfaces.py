import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
CODEX_AUTH = APP / "UX" / "CodexChatGPTAuthView.swift"
SETTINGS = APP / "App" / "FolderTrailApp.swift"
PREFLIGHT = APP / "UX" / "PreflightView.swift"
PROMPT_SETTINGS = APP / "UX" / "PromptSettingsSheet.swift"


class SeparateAuthSurfacesTests(unittest.TestCase):
    def test_issue_59_settings_shows_openrouter_and_codex_chatgpt_as_distinct_logins(self):
        prompt = PROMPT.read_text(encoding="utf-8")
        settings = PROMPT_SETTINGS.read_text(encoding="utf-8")

        self.assertNotIn("CompactConnectionPanel", prompt)
        self.assertNotIn('Text("OpenRouter', prompt)
        self.assertIn("ProviderConnectionSection", settings)
        self.assertIn("CodexChatGPTOAuthView", settings)
        self.assertIn("AI 제공자", settings)
        self.assertIn("OpenRouter", settings)

    def test_issue_59_codex_chatgpt_oauth_view_launches_visible_browser_handoff(self):
        source = CODEX_AUTH.read_text(encoding="utf-8")

        self.assertIn("struct CodexChatGPTOAuthView", source)
        self.assertIn("Codex / ChatGPT OAuth", source)
        self.assertIn("OpenRouter와 별개", source)
        self.assertIn("Codex / ChatGPT 로그인", source)
        self.assertIn("CodexLoginRunner", source)
        self.assertIn("codex login", source)
        self.assertIn("브라우저 로그인은 Codex가 열어 줍니다", source)
        self.assertNotIn("NSWorkspace.shared.open(url)", source)

    def test_issue_59_settings_and_preflight_reuse_same_codex_auth_surface(self):
        settings = SETTINGS.read_text(encoding="utf-8")
        preflight = PREFLIGHT.read_text(encoding="utf-8")

        self.assertIn("CodexChatGPTOAuthView", settings)
        self.assertIn("CodexChatGPTOAuthView", preflight)
        self.assertIn("onRecheck: rerunPreflight", preflight)
        self.assertNotIn("private func openCodexLoginInTerminal", preflight)


if __name__ == "__main__":
    unittest.main()
