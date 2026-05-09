import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PIPELINE = APP / "Execution" / "FolderTrailRunPipeline.swift"
WORKSPACE = APP / "Execution" / "WorkspaceCopyService.swift"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
WRITER = APP / "Output" / "TrailWriter.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
CREDENTIAL_STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class RunPipelineTests(unittest.TestCase):
    def test_issue_69_run_pipeline_orchestrates_workspace_manifest_plan_execute_trail(self):
        self.assertTrue(PIPELINE.exists(), "missing Execution/FolderTrailRunPipeline.swift")
        project = PROJECT.read_text(encoding="utf-8")
        self.assertIn("FolderTrailRunPipeline.swift", project)

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
                        .appendingPathComponent("FolderTrailRunPipelineSmoke-" + UUID().uuidString, isDirectory: true)
                    let source = root.appendingPathComponent("Original", isDirectory: true)
                    try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
                    try "hello".write(to: source.appendingPathComponent("note.txt"), atomically: true, encoding: .utf8)
                    defer { try? FileManager.default.removeItem(at: root) }

                    var observed: [FolderTrailRunState] = []
                    let pipeline = FolderTrailRunPipeline(planner: MockPlannerAdapter()) { state in
                        observed.append(state)
                    }

                    let result = try await pipeline.run(prompt: "정리해줘", sourceFolderURL: source)

                    expect(result.prompt == "정리해줘", "result should preserve prompt")
                    expect(result.sourceFolderURL == source, "result should preserve source url")
                    expect(result.workspaceURL != source, "pipeline must operate on a copied workspace")
                    expect(FileManager.default.fileExists(atPath: source.appendingPathComponent("note.txt").path), "source file must remain untouched")
                    expect(FileManager.default.fileExists(atPath: result.workspaceURL.appendingPathComponent("note.txt").path), "workspace should contain copied file")
                    expect(result.manifest.files.contains { $0.path == "note.txt" }, "manifest should be built from workspace copy")
                    expect(result.plan.provider == "mock", "mock planner should be used without network")
                    expect(result.trail.action_logs.contains { $0.type == "write_summary" && $0.status == "success" }, "plan should execute")
                    expect(FileManager.default.fileExists(atPath: result.artifacts.trailJSON.path), "canonical trail artifact should be written")
                    expect(FileManager.default.fileExists(atPath: result.artifacts.summaryMarkdown.path), "summary artifact should be written")
                    expect(FileManager.default.fileExists(atPath: result.artifacts.runtimeStatusJSON.path), "runtime status artifact should be written")

                    let expected: [FolderTrailRunState] = [
                        .promptReceived,
                        .workspaceReady,
                        .manifestBuilt,
                        .planReady,
                        .executing,
                        .trailWritten,
                        .done,
                    ]
                    expect(observed == expected, "states should represent prompt->workspace->manifest->plan->execute->trail/done")
                    expect(result.states == expected, "result should retain emitted state sequence")

                    let fakeWorkspace = root.appendingPathComponent("FakeWorkspace", isDirectory: true)
                    try FileManager.default.createDirectory(at: fakeWorkspace, withIntermediateDirectories: true)
                    let fakeManifest = FolderManifest(
                        manifest_version: "0.1",
                        workspace_name: "FakeWorkspace",
                        source_folder: source.path,
                        total_files: 0,
                        total_directories: 0,
                        detail_level: .level_3_metadata,
                        privacy_filter_applied: true,
                        files: [],
                        directory_summary: [],
                        review_excluded: []
                    )
                    let fakePlan = ActionPlan(
                        plan_version: "0.1",
                        provider: "double",
                        model: "none",
                        summary_ko: "테스트",
                        actions: []
                    )
                    let fakeTrail = ExecutionTrail(
                        plan_version: "0.1",
                        interrupted: false,
                        action_logs: [],
                        rejected_actions: [],
                        validation_errors: []
                    )
                    let fakeArtifacts = TrailArtifacts(
                        trailJSON: fakeWorkspace.appendingPathComponent("trail.json"),
                        summaryMarkdown: fakeWorkspace.appendingPathComponent("summary.md"),
                        runtimeStatusJSON: fakeWorkspace.appendingPathComponent("runtime_status.json")
                    )
                    var calls: [String] = []
                    let doubled = FolderTrailRunPipeline(
                        copyWorkspace: { url in
                            calls.append("copy")
                            return WorkspaceCopyResult(sourceFolderURL: url, workspaceURL: fakeWorkspace)
                        },
                        buildManifest: { workspaceURL, sourcePath in
                            calls.append("manifest")
                            expect(workspaceURL == fakeWorkspace, "test double manifest should receive workspace")
                            expect(sourcePath == source.path, "test double manifest should receive source path")
                            return fakeManifest
                        },
                        planActions: { prompt, manifest in
                            calls.append("plan")
                            expect(prompt == "double", "test double planner should receive prompt")
                            expect(manifest == fakeManifest, "test double planner should receive manifest")
                            return fakePlan
                        },
                        executePlan: { plan, workspaceURL in
                            calls.append("execute")
                            expect(plan == fakePlan, "test double executor should receive plan")
                            expect(workspaceURL == fakeWorkspace, "test double executor should receive workspace")
                            return fakeTrail
                        },
                        writeTrail: { trail, workspaceURL, sourcePath, prompt, plan, manifest in
                            calls.append("trail")
                            expect(trail == fakeTrail, "test double writer should receive trail")
                            expect(workspaceURL == fakeWorkspace, "test double writer should receive workspace")
                            expect(sourcePath == source.path, "test double writer should receive source path")
                            expect(prompt == "double", "test double writer should receive prompt")
                            expect(plan == fakePlan, "test double writer should receive plan")
                            expect(manifest == fakeManifest, "test double writer should receive manifest")
                            return fakeArtifacts
                        }
                    )
                    let doubleResult = try await doubled.run(prompt: "double", sourceFolderURL: source)
                    expect(calls == ["copy", "manifest", "plan", "execute", "trail"], "test doubles should run in pipeline order")
                    expect(doubleResult.states == expected, "test double run should emit the same states")
                }
            }
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "RunPipelineSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-parse-as-library",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(MANIFEST),
                    str(KEYCHAIN),
                    str(CREDENTIAL_STORE),
                    str(ADAPTER),
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
