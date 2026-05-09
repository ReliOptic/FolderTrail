import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
SETTINGS = APP / "UX" / "PromptSettingsSheet.swift"


class BoundedScrollLayoutTests(unittest.TestCase):
    def test_issue_96_prompt_body_and_composer_are_bounded(self):
        prompt = PROMPT.read_text(encoding="utf-8")

        self.assertIn("enum PromptLayout", prompt)
        self.assertIn("static let promptMaxHeight", prompt)
        self.assertIn("static let bodyMaxHeight", prompt)
        self.assertIn("ScrollView", prompt)
        self.assertIn(".frame(maxHeight: PromptLayout.bodyMaxHeight)", prompt)
        self.assertIn(".frame(minHeight: PromptLayout.promptMinHeight, idealHeight: PromptLayout.promptIdealHeight, maxHeight: PromptLayout.promptMaxHeight)", prompt)
        self.assertLess(prompt.index("promptComposer"), prompt.index("preflightSection"))
        self.assertLess(prompt.index("preflightSection"), prompt.index("runStatusSection"))

    def test_issue_96_settings_sheet_scrolls_inside_a_max_height(self):
        settings = SETTINGS.read_text(encoding="utf-8")

        self.assertIn("enum PromptSettingsLayout", settings)
        self.assertIn("static let maxHeight", settings)
        self.assertIn("ScrollView", settings)
        self.assertIn("settingsContent", settings)
        self.assertIn(".frame(width: PromptSettingsLayout.width)", settings)
        self.assertIn(".frame(minHeight: PromptSettingsLayout.minHeight, idealHeight: PromptSettingsLayout.idealHeight, maxHeight: PromptSettingsLayout.maxHeight)", settings)
        self.assertLess(settings.index("Text(\"v0.1 설정\")"), settings.index("ScrollView"))
        self.assertIn("ProviderConnectionSection", settings)
        self.assertIn("OpenRouterSettingsView", settings)
        self.assertIn("CodexChatGPTOAuthView", settings)

    def test_issue_96_footer_keeps_one_primary_action_for_current_state(self):
        prompt = PROMPT.read_text(encoding="utf-8")
        footer = prompt.split("private var footerActions", 1)[1].split("@ViewBuilder", 1)[0]

        self.assertIn("if runModel.status == .running", footer)
        self.assertIn('Button("정지")', footer)
        self.assertIn('Button("시작")', footer)
        self.assertEqual(footer.count(".buttonStyle(FolderTrailPrimaryButtonStyle())"), 2)
        self.assertNotIn('Button("시작") {\n                    showPreflight = true\n                }\n                .buttonStyle(FolderTrailPrimaryButtonStyle())\n                .keyboardShortcut(.defaultAction)\n                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || runModel.status == .running)', footer)


if __name__ == "__main__":
    unittest.main()
