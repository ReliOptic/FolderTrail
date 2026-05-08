import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
WRITER = APP / "Output" / "TrailWriter.swift"
DONE_VIEW = APP / "UX" / "DoneView.swift"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
STATUS = APP / "Execution" / "CompactStatusStateMachine.swift"
ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class TrailWriterDoneStateTests(unittest.TestCase):
    def test_issue_13_trail_writer_done_state(self):
        self.assertTrue(WRITER.exists(), "missing Output/TrailWriter.swift")
        self.assertTrue(DONE_VIEW.exists(), "missing UX/DoneView.swift")

        writer = WRITER.read_text(encoding="utf-8")
        view = DONE_VIEW.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        for name in [".foldertrail", "trail.json", "summary.md", "runtime_status.json", "folders_created", "files_moved", "files_renamed", "review_needed"]:
            self.assertIn(name, writer)
        self.assertIn("작업이 중단되었습니다", view)
        self.assertIn("결과 폴더 열기", view)
        self.assertIn("NSWorkspace.shared.open", view)
        self.assertIn("이 폴더로 다시 실행", view)
        self.assertIn("resetToIdle", view)
        self.assertIn("닫기", view)
        self.assertIn("NSApp.terminate", view)
        self.assertIn("TrailWriter.swift", project)
        self.assertIn("DoneView.swift", project)

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

            let root = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("FolderTrailTrailWriterSmoke-" + UUID().uuidString, isDirectory: true)
            let workspace = root.appendingPathComponent("Workspace", isDirectory: true)
            try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }

            let trail = ExecutionTrail(
                plan_version: "0.1",
                interrupted: false,
                action_logs: [
                    ActionExecutionLog(type: "create_folder", status: "success", path: "Docs", from: nil, to: nil, reason: nil),
                    ActionExecutionLog(type: "move", status: "success", path: nil, from: "a.txt", to: "Docs/a.txt", reason: nil),
                    ActionExecutionLog(type: "rename", status: "success", path: nil, from: "b.txt", to: "c.txt", reason: nil),
                    ActionExecutionLog(type: "mark_review_needed", status: "success", path: "unknown.zip", from: nil, to: nil, reason: nil)
                ],
                rejected_actions: [],
                validation_errors: []
            )
            let artifacts = try TrailWriter().write(
                trail: trail,
                workspaceURL: workspace,
                sourceFolderPath: "/source",
                userPrompt: "정리해줘",
                provider: "openrouter",
                model: "anthropic/claude-sonnet-4.6",
                manifestDetailLevel: "level_2_path_summary",
                summaryText: "정리가 완료되었습니다."
            )
            expect(FileManager.default.fileExists(atPath: artifacts.trailJSON.path), "trail.json missing")
            expect(FileManager.default.fileExists(atPath: artifacts.summaryMarkdown.path), "summary.md missing")
            expect(FileManager.default.fileExists(atPath: artifacts.runtimeStatusJSON.path), "runtime_status.json missing")

            let parsed = try TrailWriter.parseTrailCounters(from: artifacts.trailJSON)
            expect(parsed.folders_created == 1, "folder count")
            expect(parsed.files_moved == 1, "move count")
            expect(parsed.files_renamed == 1, "rename count")
            expect(parsed.review_needed == 1, "review count")

            let fallback = TrailWriter.parseTrailCountersOrFallback(from: workspace.appendingPathComponent("missing.json"))
            expect(fallback.folders_created == 0 && fallback.review_needed == 0, "missing trail fallback")

            let interrupted = ExecutionTrail(plan_version: "0.1", interrupted: true, action_logs: [], rejected_actions: [], validation_errors: [])
            let interruptedArtifacts = try TrailWriter().write(
                trail: interrupted,
                workspaceURL: workspace.appendingPathComponent("Interrupted", isDirectory: true),
                sourceFolderPath: "/source",
                userPrompt: "정리",
                provider: "mock",
                model: "offline",
                manifestDetailLevel: "level_3_metadata",
                summaryText: "작업이 중단되었습니다."
            )
            let interruptedData = try Data(contentsOf: interruptedArtifacts.trailJSON)
            expect(String(data: interruptedData, encoding: .utf8)!.contains("\"interrupted\":true"), "interrupted flag should be written")
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "TrailWriterSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(MANIFEST),
                    str(KEYCHAIN),
                    str(ADAPTER),
                    str(EXECUTOR),
                    str(STATUS),
                    str(WRITER),
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
