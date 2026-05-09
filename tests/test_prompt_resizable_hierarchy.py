import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CONTROLLER = APP / "App" / "FolderTrailAppController.swift"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"


class PromptResizableHierarchyTests(unittest.TestCase):
    def test_issue_61_panel_is_resizable_with_minimum_size(self):
        controller = CONTROLLER.read_text(encoding="utf-8")

        self.assertIn(".resizable", controller)
        self.assertIn("panel.minSize", controller)
        self.assertIn("NSSize(width: 520, height: 420)", controller)
        self.assertIn("setContentSize", controller)
        self.assertIn("NSSize(width: 640, height: 560)", controller)

    def test_issue_61_prompt_prioritizes_task_before_compact_auth(self):
        prompt = PROMPT.read_text(encoding="utf-8")

        self.assertIn("promptComposer", prompt)
        self.assertIn("CompactConnectionPanel", prompt)
        self.assertIn("RequiredProviderRow", prompt)
        self.assertIn("OptionalLocalHelperRow", prompt)
        self.assertIn("OpenRouter 필요", prompt)
        self.assertIn("선택: Codex / ChatGPT", prompt)
        self.assertIn("ScrollView", prompt)
        self.assertIn(".frame(minWidth: 520, idealWidth: 640, minHeight: 420, idealHeight: 560)", prompt)

        self.assertLess(prompt.index("promptComposer"), prompt.index("CompactConnectionPanel"))
        self.assertNotIn("PromptConnectionPanel", prompt)
        self.assertNotIn("서로 다른 로그인입니다.", prompt)
        self.assertNotIn("Codex / ChatGPT OAuth는 로컬 도우미를 터미널/브라우저에서 연결합니다", prompt)


if __name__ == "__main__":
    unittest.main()
