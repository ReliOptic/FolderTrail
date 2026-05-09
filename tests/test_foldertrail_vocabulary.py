import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
WORKSPACE_MODE = APP / "Execution" / "WorkspaceModePolicy.swift"


class FolderTrailVocabularyTests(unittest.TestCase):
    def test_issue_40_prompt_uses_foldertrail_vocabulary(self):
        prompt = (APP / "UX" / "PlaceholderPromptView.swift").read_text(encoding="utf-8")
        mode_policy = WORKSPACE_MODE.read_text(encoding="utf-8")

        self.assertNotIn("개발용", prompt)
        self.assertIn("정리할 폴더", prompt)
        self.assertIn("폴더 바꾸기…", prompt)
        self.assertIn("workspaceMode.primaryActionTitle", prompt)
        self.assertIn("복사본으로 시작", mode_policy)

    def test_issue_40_preflight_and_provider_copy_are_user_facing(self):
        preflight_view = (APP / "UX" / "PreflightView.swift").read_text(encoding="utf-8")
        preflight_check = (APP / "Safety" / "PreflightCheck.swift").read_text(encoding="utf-8")
        provider = (APP / "UX" / "ProviderConnectView.swift").read_text(encoding="utf-8")
        mode_policy = WORKSPACE_MODE.read_text(encoding="utf-8")

        self.assertIn("정리 전 확인", preflight_view)
        self.assertIn("복사본 만들고 계속", preflight_view)
        self.assertIn("폴더를 읽을 수 있음", preflight_check)
        self.assertIn("workspaceMode.preflightWorkspaceTitle", preflight_check)
        self.assertIn("작업 복사본을 만들 수 있음", mode_policy)
        self.assertNotIn("OpenRouter", preflight_view + preflight_check)
        self.assertIn("OpenRouter 연결", provider)

        for awkward_copy in [
            'Text("Preflight")',
            'Text("Provider")',
            'Label("connected"',
            'Label("notConnected"',
            'Label("failed"',
            'Button("Connect OpenRouter")',
            'Button("Retry")',
        ]:
            self.assertNotIn(awkward_copy, preflight_view + provider)


if __name__ == "__main__":
    unittest.main()
