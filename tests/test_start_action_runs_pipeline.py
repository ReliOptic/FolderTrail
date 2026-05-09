import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
RUN_MODEL = APP / "Execution" / "FolderTrailPromptRunModel.swift"
PIPELINE = APP / "Execution" / "FolderTrailRunPipeline.swift"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
CONSENT = APP / "UX" / "ConsentModalView.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
OPENROUTER_ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
CODEX_ADAPTER = APP / "Intelligence" / "CodexPlannerAdapter.swift"
WORKSPACE = APP / "Execution" / "WorkspaceCopyService.swift"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
WRITER = APP / "Output" / "TrailWriter.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
CREDENTIAL_STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class StartActionRunsPipelineTests(unittest.TestCase):
    def test_issue_85_prompt_wires_consent_to_run_model(self):
        prompt = PROMPT.read_text(encoding="utf-8")
        consent = CONSENT.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertTrue(RUN_MODEL.exists(), "missing Execution/FolderTrailPromptRunModel.swift")
        self.assertIn("FolderTrailPromptRunModel.swift", project)
        self.assertIn("@StateObject private var runModel", prompt)
        self.assertIn("startRun()", prompt)
        self.assertIn("runModel.start(prompt: prompt, sourceFolderURL: selectedFolderURL, workspaceMode: workspaceMode)", prompt)
        self.assertIn("runStatusSection", prompt)
        self.assertIn("결과 폴더 열기", prompt)
        self.assertIn("정리 중", prompt)
        self.assertIn("다시 시도", prompt)
        self.assertIn("onAllow()", consent)
        self.assertNotIn("startCopy(sourceFolderURL", consent)

    def test_issue_85_run_model_calls_pipeline_once_and_records_result(self):
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
                        .appendingPathComponent("FolderTrailPromptRunModelSource", isDirectory: true)
                    let workspace = source.deletingLastPathComponent()
                        .appendingPathComponent("FolderTrailPromptRunModelWorkspace", isDirectory: true)
                    let manifest = FolderManifest(
                        manifest_version: "0.1",
                        workspace_name: "Workspace",
                        source_folder: source.path,
                        total_files: 0,
                        total_directories: 0,
                        detail_level: .level_3_metadata,
                        privacy_filter_applied: true,
                        files: [],
                        directory_summary: [],
                        review_excluded: []
                    )
                    let plan = ActionPlan(
                        plan_version: "0.1",
                        provider: "codex",
                        model: "codex-cli",
                        summary_ko: "완료",
                        actions: [PlanAction(type: "write_summary", path: "summary.md", content: "완료")]
                    )
                    let trail = ExecutionTrail(
                        plan_version: "0.1",
                        interrupted: false,
                        action_logs: [],
                        rejected_actions: [],
                        validation_errors: []
                    )
                    let artifacts = TrailArtifacts(
                        trailJSON: workspace.appendingPathComponent(".foldertrail/trail.json"),
                        summaryMarkdown: workspace.appendingPathComponent(".foldertrail/summary.md"),
                        runtimeStatusJSON: workspace.appendingPathComponent(".foldertrail/runtime_status.json")
                    )
                    let expected = FolderTrailRunResult(
                        prompt: "정리",
                        sourceFolderURL: source,
                        workspaceURL: workspace,
                        manifest: manifest,
                        plan: plan,
                        trail: trail,
                        artifacts: artifacts,
                        states: [.promptReceived, .workspaceReady, .manifestBuilt, .planReady, .executing, .trailWritten, .done]
                    )

                    var calls: [(String, URL)] = []
                    let model = FolderTrailPromptRunModel(runPipeline: { prompt, sourceURL, _, _ in
                        calls.append((prompt, sourceURL))
                        return expected
                    })

                    await model.run(prompt: "정리", sourceFolderURL: source)
                    let result = model.result
                    let status = model.status

                    expect(calls.count == 1, "run model should call pipeline once")
                    expect(calls.first?.0 == "정리", "run model should pass prompt")
                    expect(calls.first?.1 == source, "run model should pass selected folder")
                    expect(status == .done, "run model should finish done")
                    expect(result?.workspaceURL == workspace, "run model should retain result")

                    let failing = FolderTrailPromptRunModel(runPipeline: { _, _, _, _ in
                        throw PlannerAdapterError.networkFailure
                    })
                    await failing.run(prompt: "정리", sourceFolderURL: source)
                    let failedStatus = failing.status
                    let errorMessage = failing.errorMessage
                    expect(failedStatus == .failed, "runner failure should become failed status")
                    expect(errorMessage != nil, "runner failure should set an error message")
                }
            }
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "PromptRunModelSmoke"
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
