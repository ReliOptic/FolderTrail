import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROMPT_VIEW = APP / "UX" / "PlaceholderPromptView.swift"
APP_CONTROLLER = APP / "App" / "FolderTrailAppController.swift"


class FloatingPromptWindowContractTests(unittest.TestCase):
    def test_issue_5_prompt_window_contract(self):
        prompt_view = PROMPT_VIEW.read_text(encoding="utf-8")
        app_controller = APP_CONTROLLER.read_text(encoding="utf-8")

        self.assertIn("selectedFolderURL.lastPathComponent", prompt_view)
        self.assertIn("TextEditor(text: $prompt)", prompt_view)
        self.assertIn("recommendedPrompts", prompt_view)
        self.assertGreaterEqual(prompt_view.count("PromptChipButton"), 1)
        self.assertIn("ProviderConnectView", prompt_view)
        self.assertIn("providerSettings.isConnected", prompt_view)
        self.assertIn("OpenRouter 연결", (APP / "UX" / "ProviderConnectView.swift").read_text(encoding="utf-8"))
        self.assertIn('Button("시작")', prompt_view)
        self.assertIn(".disabled(prompt.trimmingCharacters", prompt_view)
        self.assertIn("@FocusState", prompt_view)
        self.assertIn('.keyboardShortcut("k", modifiers: .command)', prompt_view)
        self.assertIn('.keyboardShortcut("w", modifiers: .command)', prompt_view)
        self.assertIn("NSApp.keyWindow?.close()", prompt_view)
        self.assertIn("level = .floating", app_controller)


if __name__ == "__main__":
    unittest.main()
