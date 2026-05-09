import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
RUN_MODEL = APP / "Execution" / "FolderTrailPromptRunModel.swift"
PIPELINE = APP / "Execution" / "FolderTrailRunPipeline.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
OPENROUTER_ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
CODEX_ADAPTER = APP / "Intelligence" / "CodexPlannerAdapter.swift"
WORKSPACE = APP / "Execution" / "WorkspaceCopyService.swift"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
WRITER = APP / "Output" / "TrailWriter.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
CREDENTIAL_STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"


class DirectModeUXRecoveryTests(unittest.TestCase):
    def test_issue_103_prompt_has_mode_selector_and_single_direct_action(self):
        prompt = PROMPT.read_text(encoding="utf-8")

        self.assertIn("modeSelector", prompt)
        self.assertIn("Picker(\"실행 방식\", selection: $workspaceMode)", prompt)
        self.assertIn("안전 모드", prompt)
        self.assertIn("빠른 모드", prompt)
        self.assertIn("원본에서 바로 시작", prompt)
        self.assertIn("복사본으로 시작", prompt)
        self.assertIn("primaryActionTitle", prompt)
        self.assertIn("private func primaryAction()", prompt)
        self.assertIn("case .directSource", prompt)
        self.assertIn("startRun()", prompt)
        self.assertIn("case .copiedWorkspace", prompt)
        self.assertIn("showPreflight = true", prompt)
        self.assertIn("runModel.status == .idle", prompt)
        self.assertNotIn("빠른 모드: 복사 없이 원본에서 진행", prompt)

        footer = prompt.split("private var footerActions", 1)[1].split("@ViewBuilder", 1)[0]
        self.assertIn("if runModel.status == .running", footer)
        self.assertIn("else if runModel.status == .idle", footer)
        self.assertNotIn('Button("시작")', footer)

    def test_issue_103_run_model_surfaces_actionable_planner_failures(self):
        source = RUN_MODEL.read_text(encoding="utf-8")

        self.assertIn("Codex 로그인이 필요합니다", source)
        self.assertIn("Codex 실행에 실패했습니다", source)
        self.assertIn("AI 응답을 실행 계획으로 읽지 못했습니다", source)
        self.assertIn("실행 계획 형식이 맞지 않습니다", source)

    def test_issue_103_error_messages_are_observable(self):
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
                static func main() async throws {
                    let source = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("FolderTrailDirectUXSmoke", isDirectory: true)

                    let invalid = FolderTrailPromptRunModel(runPipeline: { _, _, _, _ in
                        throw PlannerAdapterError.invalidJSON
                    })
                    await invalid.run(prompt: "정리", sourceFolderURL: source, workspaceMode: .directSource)
                    expect(invalid.status == .failed, "invalid json should fail")
                    expect(invalid.errorMessage == "AI 응답을 실행 계획으로 읽지 못했습니다.", "invalid json should be actionable")

                    let schema = FolderTrailPromptRunModel(runPipeline: { _, _, _, _ in
                        throw PlannerAdapterError.schemaMismatch
                    })
                    await schema.run(prompt: "정리", sourceFolderURL: source, workspaceMode: .directSource)
                    expect(schema.errorMessage == "실행 계획 형식이 맞지 않습니다.", "schema mismatch should be actionable")

                    let network = FolderTrailPromptRunModel(runPipeline: { _, _, _, _ in
                        throw PlannerAdapterError.networkFailure
                    })
                    await network.run(prompt: "정리", sourceFolderURL: source, workspaceMode: .directSource)
                    expect(network.errorMessage == "Codex 실행에 실패했습니다.", "network should mention Codex execution")
                }
            }
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "DirectModeUXRecoverySmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-parse-as-library",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(MANIFEST),
                    str(KEYCHAIN),
                    str(CREDENTIAL_STORE),
                    str(OPENROUTER_ADAPTER),
                    str(CODEX_ADAPTER),
                    str(WORKSPACE),
                    str(EXECUTOR),
                    str(WRITER),
                    str(PIPELINE),
                    str(RUN_MODEL),
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
