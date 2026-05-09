import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
PREFLIGHT_VIEW = APP / "UX" / "PreflightView.swift"
PREFLIGHT_CHECK = APP / "Safety" / "PreflightCheck.swift"


class ModernPromptChromeTests(unittest.TestCase):
    def test_issue_50_prompt_chrome_is_compact_and_uses_current_product_language(self):
        prompt = PROMPT.read_text(encoding="utf-8")

        self.assertIn("PromptStatusStrip", prompt)
        self.assertIn("settingsButton", prompt)
        self.assertNotIn('Text("OpenRouter', prompt)
        self.assertIn('Button("시작")', prompt)
        self.assertIn("폴더 바꾸기…", prompt)
        self.assertIn("중복 정리", prompt)
        self.assertIn("프로젝트별 정돈", prompt)
        self.assertIn(".frame(minWidth: 520, idealWidth: 640, minHeight: 420, idealHeight: 560)", prompt)

        awkward_copy = [
            "FolderTrailStatusPill(title:",
            "Codex fallback 선택",
            "실행 준비",
            "안전 작업공간에서 시작",
            "정리할 폴더 바꾸기…",
        ]
        for copy in awkward_copy:
            self.assertNotIn(copy, prompt)

    def test_issue_50_preflight_copy_says_copy_not_workspace(self):
        preflight_view = PREFLIGHT_VIEW.read_text(encoding="utf-8")
        preflight_check = PREFLIGHT_CHECK.read_text(encoding="utf-8")

        self.assertIn("정리 전 확인", preflight_view)
        self.assertIn("복사본 만들고 계속", preflight_view)
        self.assertIn("작업 복사본을 만들 수 있음", preflight_check)
        self.assertNotIn("안전 작업공간", preflight_view + preflight_check)


if __name__ == "__main__":
    unittest.main()
