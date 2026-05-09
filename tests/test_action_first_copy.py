import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
UX_FILES = [
    APP / "UX" / "CodexChatGPTAuthView.swift",
    APP / "UX" / "ProviderConnectView.swift",
    APP / "UX" / "PromptSettingsSheet.swift",
    APP / "App" / "FolderTrailApp.swift",
]
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
PREFLIGHT = APP / "UX" / "PreflightView.swift"
PREFLIGHT_CHECK = APP / "Safety" / "PreflightCheck.swift"
RUN_MODEL = APP / "Execution" / "FolderTrailPromptRunModel.swift"


class ActionFirstCopyTests(unittest.TestCase):
    def test_issue_87_auth_and_settings_copy_avoid_explainer_phrases(self):
        source = "\n".join(path.read_text(encoding="utf-8") for path in UX_FILES)

        banned = [
            "별도 로그인",
            "별개",
            "없어도",
            "무엇과 다름",
            "OAuth는",
            "토큰을 FolderTrail",
            "정리는 OpenRouter",
            "macOS가 허용을 요청할 수 있습니다",
            "필요할 수 있으며",
        ]
        for phrase in banned:
            self.assertNotIn(phrase, source)

    def test_issue_87_core_ctas_are_short_actions(self):
        auth = (APP / "UX" / "CodexChatGPTAuthView.swift").read_text(encoding="utf-8")
        provider = (APP / "UX" / "ProviderConnectView.swift").read_text(encoding="utf-8")
        prompt = PROMPT.read_text(encoding="utf-8")

        self.assertIn("복사본으로 시작", prompt)
        self.assertIn('Button("로그인")', auth)
        self.assertIn('Button("다시 확인")', auth)
        self.assertIn('Button("연결")', provider)
        self.assertIn('Button("다시 연결")', provider)
        self.assertNotIn('Button("Codex / ChatGPT 로그인")', auth)
        self.assertNotIn('Button("OpenRouter 다시 연결")', provider)

    def test_issue_87_failure_and_completion_copy_points_to_one_next_action(self):
        preflight = PREFLIGHT.read_text(encoding="utf-8")
        preflight_check = PREFLIGHT_CHECK.read_text(encoding="utf-8")
        run_model = RUN_MODEL.read_text(encoding="utf-8")

        self.assertIn("필수 항목을 먼저 처리해 주세요.", preflight)
        self.assertIn("Codex 로그인 후 다시 확인해 주세요.", preflight_check)
        self.assertIn("다시 시도해 주세요.", run_model)
        self.assertNotIn("터미널에서 `codex login`", preflight_check)
        self.assertNotIn("정리를 완료하지 못했습니다. 다시 시도해 주세요.", run_model)
        self.assertNotIn("정리 계획을 이해하지 못했습니다. 다시 시도해 주세요.", run_model)


if __name__ == "__main__":
    unittest.main()
