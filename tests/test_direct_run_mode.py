import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PIPELINE = APP / "Execution" / "FolderTrailRunPipeline.swift"
RUN_MODEL = APP / "Execution" / "FolderTrailPromptRunModel.swift"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
CONSENT = APP / "UX" / "ConsentModalView.swift"
PREFLIGHT = APP / "Safety" / "PreflightCheck.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
OPENROUTER_ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
WORKSPACE = APP / "Execution" / "WorkspaceCopyService.swift"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
WRITER = APP / "Output" / "TrailWriter.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
CREDENTIAL_STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"


class DirectRunModeTests(unittest.TestCase):
    def test_issue_101_ui_exposes_explicit_direct_mode(self):
        prompt = PROMPT.read_text(encoding="utf-8")
        consent = CONSENT.read_text(encoding="utf-8")
        preflight = PREFLIGHT.read_text(encoding="utf-8")
        run_model = RUN_MODEL.read_text(encoding="utf-8")

        self.assertIn("WorkspacePreparationMode", prompt)
        self.assertIn("workspaceMode", prompt)
        self.assertIn("빠른 모드", prompt)
        self.assertIn("원본에서 바로 시작", prompt)
        self.assertIn("원본 폴더가 직접 변경될 수 있습니다", prompt)
        self.assertIn("workspaceMode: workspaceMode", prompt)
        self.assertIn("runModel.start(prompt: prompt, sourceFolderURL: selectedFolderURL, workspaceMode: workspaceMode)", prompt)

        self.assertIn("workspaceMode", consent)
        self.assertIn("원본 폴더에서 바로 진행합니다", consent)
        self.assertIn("원본 폴더는 변경하지 않습니다", consent)

        self.assertIn("workspaceMode", preflight)
        self.assertIn("원본 폴더에 쓸 수 있음", preflight)
        self.assertIn("checkSelectedFolderWritable", preflight)

        self.assertIn("workspaceMode: WorkspacePreparationMode = .copiedWorkspace", run_model)

    def test_issue_101_pipeline_skips_copy_in_direct_mode(self):
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
                    let root = URL(fileURLWithPath: NSTemporaryDirectory())
                        .appendingPathComponent("FolderTrailDirectModeSmoke-" + UUID().uuidString, isDirectory: true)
                    let source = root.appendingPathComponent("Downloads", isDirectory: true)
                    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
                    try "hello".write(to: source.appendingPathComponent("note.txt"), atomically: true, encoding: .utf8)
                    defer { try? FileManager.default.removeItem(at: root) }

                    let manifest = FolderManifest(
                        manifest_version: "0.1",
                        workspace_name: "Downloads",
                        source_folder: source.path,
                        total_files: 1,
                        total_directories: 0,
                        detail_level: .level_3_metadata,
                        privacy_filter_applied: true,
                        files: [],
                        directory_summary: [],
                        review_excluded: []
                    )
                    let plan = ActionPlan(
                        plan_version: "0.1",
                        provider: "double",
                        model: "none",
                        summary_ko: "완료",
                        actions: [PlanAction(type: "write_summary", path: "FolderTrailSummary.md", content: "완료")]
                    )
                    let trail = ExecutionTrail(
                        plan_version: "0.1",
                        interrupted: false,
                        action_logs: [],
                        rejected_actions: [],
                        validation_errors: []
                    )
                    let artifacts = TrailArtifacts(
                        trailJSON: source.appendingPathComponent(".foldertrail/trail.json"),
                        summaryMarkdown: source.appendingPathComponent(".foldertrail/summary.md"),
                        runtimeStatusJSON: source.appendingPathComponent(".foldertrail/runtime_status.json")
                    )

                    var copyCalls = 0
                    var manifestWorkspace: URL?
                    var executeWorkspace: URL?
                    let pipeline = FolderTrailRunPipeline(
                        copyWorkspace: { url in
                            copyCalls += 1
                            return WorkspaceCopyResult(
                                sourceFolderURL: url,
                                workspaceURL: root.appendingPathComponent("Copy", isDirectory: true)
                            )
                        },
                        buildManifest: { workspaceURL, sourcePath in
                            manifestWorkspace = workspaceURL
                            expect(sourcePath == source.path, "manifest should receive original source path")
                            return manifest
                        },
                        planActions: { _, _ in plan },
                        executePlan: { _, workspaceURL in
                            executeWorkspace = workspaceURL
                            return trail
                        },
                        writeTrail: { _, workspaceURL, sourcePath, _, _, _ in
                            if copyCalls == 0 {
                                expect(workspaceURL == source, "trail should write relative to direct source workspace")
                            } else {
                                expect(workspaceURL.lastPathComponent == "Copy", "trail should write relative to copied workspace")
                            }
                            expect(sourcePath == source.path, "trail should retain source path")
                            return artifacts
                        }
                    )

                    let directResult = try await pipeline.run(
                        prompt: "정리",
                        sourceFolderURL: source,
                        workspaceMode: .directSource
                    )

                    expect(copyCalls == 0, "direct mode must skip copyWorkspace")
                    expect(manifestWorkspace == source, "direct mode manifest should scan selected folder")
                    expect(executeWorkspace == source, "direct mode executor should target selected folder")
                    expect(directResult.workspaceURL == source, "direct result workspace should be selected folder")
                    expect(directResult.sourceFolderURL == source, "direct result source should be selected folder")

                    let copiedResult = try await pipeline.run(
                        prompt: "정리",
                        sourceFolderURL: source,
                        workspaceMode: .copiedWorkspace
                    )
                    expect(copyCalls == 1, "copied mode should call copyWorkspace")
                    expect(copiedResult.workspaceURL.lastPathComponent == "Copy", "copied mode should use copy result")
                }
            }
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "DirectRunModeSmoke"
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
                    str(WORKSPACE),
                    str(EXECUTOR),
                    str(WRITER),
                    str(PIPELINE),
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
