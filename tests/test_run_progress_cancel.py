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
CODEX_ADAPTER = APP / "Intelligence" / "CodexPlannerAdapter.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
OPENROUTER_ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
WORKSPACE = APP / "Execution" / "WorkspaceCopyService.swift"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
WRITER = APP / "Output" / "TrailWriter.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
CREDENTIAL_STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"


class RunProgressCancelTests(unittest.TestCase):
    def test_issue_95_prompt_shows_progress_elapsed_and_cancel_instead_of_repeat_start(self):
        prompt = PROMPT.read_text(encoding="utf-8")
        model = RUN_MODEL.read_text(encoding="utf-8")

        self.assertIn("case cancelled", model)
        self.assertIn("@Published private(set) var stepText", model)
        self.assertIn("@Published private(set) var elapsedSeconds", model)
        self.assertIn("func start(", model)
        self.assertIn("workspaceMode: WorkspacePreparationMode = .copiedWorkspace", model)
        self.assertIn("func cancel()", model)
        self.assertIn("runPipeline(prompt, sourceFolderURL, workspaceMode) { state in", model)

        self.assertIn("runModel.start(prompt: prompt, sourceFolderURL: selectedFolderURL, workspaceMode: workspaceMode)", prompt)
        self.assertIn("runModel.cancel()", prompt)
        self.assertIn('Button("정지")', prompt)
        self.assertIn("elapsedTimeText", prompt)
        self.assertIn("runModel.stepText", prompt)
        self.assertIn("if runModel.status == .running", prompt)

    def test_issue_95_run_model_records_state_elapsed_and_cancel(self):
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

            func sampleResult(source: URL) -> FolderTrailRunResult {
                let workspace = source.deletingLastPathComponent().appendingPathComponent("Workspace", isDirectory: true)
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
                return FolderTrailRunResult(
                    prompt: "정리",
                    sourceFolderURL: source,
                    workspaceURL: workspace,
                    manifest: manifest,
                    plan: plan,
                    trail: trail,
                    artifacts: artifacts,
                    states: [.promptReceived, .workspaceReady, .manifestBuilt, .planReady, .executing, .trailWritten, .done]
                )
            }

            @main
            struct Smoke {
                static func main() async throws {
                    let source = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("FolderTrailCancelSmoke", isDirectory: true)

                    let done = FolderTrailPromptRunModel(runPipeline: { prompt, sourceURL, _, onState in
                        expect(prompt == "정리", "prompt should pass through")
                        onState(.workspaceReady)
                        onState(.manifestBuilt)
                        return sampleResult(source: sourceURL)
                    })
                    done.start(prompt: "정리", sourceFolderURL: source)
                    try await Task.sleep(nanoseconds: 80_000_000)
                    expect(done.status == .done, "successful run should finish")
                    expect(done.stepText == "완료", "successful run should end with done text")
                    expect(done.elapsedSeconds >= 0, "elapsed seconds should be available")

                    let cancellable = FolderTrailPromptRunModel(runPipeline: { _, _, _, onState in
                        onState(.manifestBuilt)
                        while !Task.isCancelled {
                            try await Task.sleep(nanoseconds: 20_000_000)
                        }
                        throw CancellationError()
                    })
                    cancellable.start(prompt: "정리", sourceFolderURL: source)
                    try await Task.sleep(nanoseconds: 80_000_000)
                    expect(cancellable.status == .running, "run should enter running state")
                    expect(cancellable.stepText == "목록 확인 중", "state should map to readable step text")
                    cancellable.cancel()
                    try await Task.sleep(nanoseconds: 80_000_000)
                    expect(cancellable.status == .cancelled, "cancel should update status")
                    expect(cancellable.errorMessage == "취소했습니다.", "cancel should provide short status")
                }
            }
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "RunProgressCancelSmoke"
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

    def test_issue_95_codex_cli_terminates_on_task_cancellation(self):
        source = CODEX_ADAPTER.read_text(encoding="utf-8")

        self.assertIn("Task.isCancelled", source)
        self.assertIn("process.terminate()", source)
        self.assertIn("CancellationError", source)


if __name__ == "__main__":
    unittest.main()
