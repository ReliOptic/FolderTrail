import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
MODE_POLICY = APP / "Execution" / "WorkspaceModePolicy.swift"
PIPELINE = APP / "Execution" / "FolderTrailRunPipeline.swift"
RUN_MODEL = APP / "Execution" / "FolderTrailPromptRunModel.swift"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
CONSENT = APP / "UX" / "ConsentModalView.swift"
PREFLIGHT_CHECK = APP / "Safety" / "PreflightCheck.swift"
PREFLIGHT_VIEW = APP / "UX" / "PreflightView.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"
CONTEXT = ROOT / "CONTEXT.md"


class WorkspaceModePolicyArchitectureTests(unittest.TestCase):
    def test_issue_105_workspace_mode_policy_is_the_single_public_mode_interface(self):
        self.assertTrue(MODE_POLICY.exists(), "workspace mode policy module should exist")
        policy = MODE_POLICY.read_text(encoding="utf-8")
        pipeline = PIPELINE.read_text(encoding="utf-8")
        preflight_check = PREFLIGHT_CHECK.read_text(encoding="utf-8")
        preflight_view = PREFLIGHT_VIEW.read_text(encoding="utf-8")
        prompt = PROMPT.read_text(encoding="utf-8")
        consent = CONSENT.read_text(encoding="utf-8")
        run_model = RUN_MODEL.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")
        context = CONTEXT.read_text(encoding="utf-8")

        self.assertIn("enum WorkspacePreparationMode: String, CaseIterable, Equatable", policy)
        for interface_name in [
            "modePickerTitle",
            "modeDescription",
            "preflightWorkspaceTitle",
            "consentHeadline",
            "consentDescription",
            "workspaceReadyStepText",
            "requiresPreflightBeforeConsent",
        ]:
            self.assertIn(interface_name, policy)

        self.assertNotIn("enum WorkspacePreparationMode", pipeline)
        self.assertNotIn("enum PreflightWorkspaceMode", preflight_check)
        self.assertNotIn("preflightWorkspaceMode", preflight_view)

        self.assertIn("mode.modePickerTitle", prompt)
        self.assertIn("workspaceMode.modeDescription", prompt)
        self.assertIn("workspaceMode.primaryActionTitle", prompt)
        self.assertIn("workspaceMode.requiresPreflightBeforeConsent", prompt)
        self.assertIn("workspaceMode.consentHeadline", consent)
        self.assertIn("workspaceMode.consentDescription", consent)
        self.assertIn("workspaceMode.workspaceReadyStepText", run_model)
        self.assertIn("workspaceMode.preflightWorkspaceTitle", preflight_check)
        self.assertIn("WorkspaceModePolicy.swift", project)
        self.assertIn("Workspace preparation mode", context)

    def test_issue_105_workspace_mode_policy_behavior_is_stable(self):
        smoke = textwrap.dedent(
            r'''
            import Foundation

            func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
                if !condition() {
                    FileHandle.standardError.write(Data(message.utf8))
                    FileHandle.standardError.write(Data("\n".utf8))
                    exit(1)
                }
            }

            @main
            struct Smoke {
                static func main() {
                    expect(WorkspacePreparationMode.allCases == [.copiedWorkspace, .directSource], "mode order should keep safe copy first")
                    expect(WorkspacePreparationMode.copiedWorkspace.primaryActionTitle == "복사본으로 시작", "copied primary action copy drifted")
                    expect(WorkspacePreparationMode.directSource.primaryActionTitle == "원본에서 바로 시작", "direct primary action copy drifted")
                    expect(WorkspacePreparationMode.copiedWorkspace.preflightWorkspaceTitle == "작업 복사본을 만들 수 있음", "copied preflight copy drifted")
                    expect(WorkspacePreparationMode.directSource.preflightWorkspaceTitle == "원본 폴더에 쓸 수 있음", "direct preflight copy drifted")
                    expect(WorkspacePreparationMode.copiedWorkspace.requiresPreflightBeforeConsent, "safe copy should still preflight before consent")
                    expect(!WorkspacePreparationMode.directSource.requiresPreflightBeforeConsent, "direct source should stay explicit one-click mode")
                }
            }
            '''
        )
        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "WorkspaceModePolicySmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-parse-as-library",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(MODE_POLICY),
                    str(main),
                    "-o",
                    str(exe),
                ],
                check=True,
                cwd=ROOT,
            )
            subprocess.run([str(exe)], check=True, cwd=ROOT)


if __name__ == "__main__":
    unittest.main()
