import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class ConsentModalContractTests(unittest.TestCase):
    def test_issue_7_consent_modal_contract(self):
        consent_path = APP / "UX" / "ConsentModalView.swift"
        copy_service_path = APP / "Execution" / "WorkspaceCopyService.swift"
        prompt_path = APP / "UX" / "PlaceholderPromptView.swift"

        self.assertTrue(consent_path.exists(), "missing UX/ConsentModalView.swift")
        self.assertTrue(copy_service_path.exists(), "missing Execution/WorkspaceCopyService.swift")

        consent = consent_path.read_text(encoding="utf-8")
        copy_service = copy_service_path.read_text(encoding="utf-8")
        prompt = prompt_path.read_text(encoding="utf-8")
        preflight_view = (APP / "UX" / "PreflightView.swift").read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("struct ConsentModalView", consent)
        self.assertIn("sourceFolderURL", consent)
        self.assertIn("workspaceFolderName", consent)
        self.assertIn("원본 폴더는 변경하지 않습니다", consent)
        self.assertIn("허용하고 시작", consent)
        self.assertIn("취소", consent)
        self.assertIn("WorkspaceCopyService", consent)
        self.assertIn("startCopy", consent)
        self.assertIn("onCancel", consent)

        self.assertIn("final class WorkspaceCopyService", copy_service)
        self.assertIn("workspaceFolderName", copy_service)
        self.assertIn("startCopy", copy_service)
        self.assertIn("workspaceURL", copy_service)

        self.assertIn(".sheet(isPresented: $showConsentModal)", prompt)
        self.assertIn("ConsentModalView", prompt)
        self.assertIn(".interactiveDismissDisabled(true)", prompt)
        self.assertIn("canProceedToConsent", preflight_view)

        self.assertIn("ConsentModalView.swift", project)
        self.assertIn("WorkspaceCopyService.swift", project)


if __name__ == "__main__":
    unittest.main()
