import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
PREFLIGHT_VIEW = APP / "UX" / "PreflightView.swift"
PREFLIGHT_CHECK = APP / "Safety" / "PreflightCheck.swift"
APP_SETTINGS = APP / "App" / "FolderTrailApp.swift"
PROVIDER_VIEW = APP / "UX" / "ProviderConnectView.swift"
OPENROUTER_SETTINGS = APP / "UX" / "OpenRouterSettingsView.swift"
PROMPT_SETTINGS = APP / "UX" / "PromptSettingsSheet.swift"


class OpenRouterSettingsOnlyTests(unittest.TestCase):
    def test_issue_86_prompt_keeps_openrouter_out_of_main_flow(self):
        prompt = PROMPT.read_text(encoding="utf-8")
        main_prompt = prompt.split("private struct PromptSettingsSheet", 1)[0]

        self.assertIn("settingsButton", main_prompt)
        self.assertIn("설정…", main_prompt)
        self.assertNotIn("CompactConnectionPanel", main_prompt)
        self.assertNotIn("RequiredProviderRow", main_prompt)
        self.assertNotIn("ProviderConnectView", main_prompt)
        self.assertNotIn('Text("OpenRouter', main_prompt)
        self.assertNotIn('Button("OpenRouter', main_prompt)
        self.assertNotIn('Label("OpenRouter', main_prompt)
        self.assertNotIn("providerConnected", main_prompt)

    def test_issue_86_preflight_does_not_check_or_recover_openrouter(self):
        view = PREFLIGHT_VIEW.read_text(encoding="utf-8")
        check = PREFLIGHT_CHECK.read_text(encoding="utf-8")

        self.assertIn("CodexChatGPTOAuthView", view)
        self.assertNotIn("ProviderConnectView", view)
        self.assertNotIn("providerSettings", view)
        self.assertNotIn("OpenRouter", view)
        self.assertNotIn("providerConnected", check)
        self.assertNotIn("OpenRouterCredentialStore.keychain.loadAPIKey", check)
        self.assertNotIn("OpenRouter 연결됨", check)

    def test_issue_86_openrouter_actions_remain_in_settings_only(self):
        app_settings = APP_SETTINGS.read_text(encoding="utf-8")
        provider = PROVIDER_VIEW.read_text(encoding="utf-8")
        openrouter_settings = OPENROUTER_SETTINGS.read_text(encoding="utf-8")
        settings_sheet = PROMPT_SETTINGS.read_text(encoding="utf-8")

        for settings_source in (app_settings, settings_sheet):
            self.assertIn("ProviderConnectView", settings_source)
            self.assertIn("OpenRouterSettingsView", settings_source)

        self.assertIn("OpenRouter 연결", provider)
        self.assertIn("다시 연결", provider)
        self.assertIn("API 키 저장", openrouter_settings)


if __name__ == "__main__":
    unittest.main()
