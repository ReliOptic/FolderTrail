import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
EXECUTOR = APP / "Execution" / "SafeExecutor.swift"
ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
CREDENTIAL_STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class SafeExecutorBehaviorTests(unittest.TestCase):
    def test_issue_11_safe_executor_behavior(self):
        self.assertTrue(EXECUTOR.exists(), "missing Execution/SafeExecutor.swift")
        source = EXECUTOR.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("final class SafeExecutor", source)
        self.assertIn("allowedActionTypes", source)
        self.assertIn("create_folder", source)
        self.assertIn("mark_review_needed", source)
        self.assertNotIn("func writeTrail", source)
        self.assertNotIn('appendingPathComponent("trail.json")', source)
        self.assertIn("rejected_actions", source)
        self.assertIn("validation_errors", source)
        self.assertIn("interrupted", source)
        self.assertIn("standardizedFileURL", source)
        self.assertIn("SafeExecutor.swift", project)

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

            func plan(_ actions: [PlanAction]) -> ActionPlan {
                ActionPlan(plan_version: "0.1", provider: "mock", model: "offline", summary_ko: "테스트", actions: actions)
            }

            let root = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("FolderTrailSafeExecutorSmoke-" + UUID().uuidString, isDirectory: true)
            let workspace = root.appendingPathComponent("Workspace", isDirectory: true)
            let source = root.appendingPathComponent("Original", isDirectory: true)
            try FileManager.default.createDirectory(at: workspace, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }

            let executor = SafeExecutor(workspaceURL: workspace)
            let emptyTrail = try executor.execute(plan([]))
            expect(emptyTrail.action_logs.isEmpty, "empty plan should produce empty action logs")
            expect(!FileManager.default.fileExists(atPath: workspace.appendingPathComponent("trail.json").path), "SafeExecutor must not write root trail.json")
            expect(!FileManager.default.fileExists(atPath: workspace.appendingPathComponent(".foldertrail").path), "SafeExecutor must not write final .foldertrail artifacts")

            try "move me".write(to: workspace.appendingPathComponent("input.txt"), atomically: true, encoding: .utf8)
            try "review me".write(to: workspace.appendingPathComponent("unknown.zip"), atomically: true, encoding: .utf8)
            let validTrail = try executor.execute(plan([
                PlanAction(type: "create_folder", path: "Docs"),
                PlanAction(type: "write_summary", path: "Docs/summary.md", content: "hello"),
                PlanAction(type: "copy", from: "input.txt", to: "Docs/input-copy.txt"),
                PlanAction(type: "move", from: "input.txt", to: "Docs/input.txt"),
                PlanAction(type: "mark_review_needed", path: "unknown.zip", reason: "archive")
            ]))
            expect(validTrail.action_logs.filter { $0.status == "success" }.count == 5, "valid actions should succeed")
            expect(FileManager.default.fileExists(atPath: workspace.appendingPathComponent("Docs/summary.md").path), "summary should be written")
            expect(FileManager.default.fileExists(atPath: workspace.appendingPathComponent("_review_before_delete/unknown.zip").path), "review file should be moved")
            expect(!FileManager.default.fileExists(atPath: source.appendingPathComponent("Docs").path), "source folder must never be written")

            let rejectedTrail = try executor.execute(plan([
                PlanAction(type: "delete", path: "Docs/summary.md"),
                PlanAction(type: "create_folder", path: "../Escape")
            ]))
            expect(rejectedTrail.rejected_actions.contains { $0.type == "delete" }, "delete should be rejected")
            expect(rejectedTrail.validation_errors.contains { $0.path == "../Escape" }, "out of bounds path should be validation error")

            var checks = 0
            let cancellingExecutor = SafeExecutor(workspaceURL: workspace, shouldStop: {
                checks += 1
                return checks > 1
            })
            let cancelledTrail = try cancellingExecutor.execute(plan([
                PlanAction(type: "create_folder", path: "A"),
                PlanAction(type: "create_folder", path: "B")
            ]))
            expect(cancelledTrail.interrupted, "trail should record interruption")
            expect(FileManager.default.fileExists(atPath: workspace.appendingPathComponent("A").path), "current action should complete")
            expect(!FileManager.default.fileExists(atPath: workspace.appendingPathComponent("B").path), "next action should not run after stop")
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "SafeExecutorSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(MANIFEST),
                    str(KEYCHAIN),
                    str(CREDENTIAL_STORE),
                    str(ADAPTER),
                    str(EXECUTOR),
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
