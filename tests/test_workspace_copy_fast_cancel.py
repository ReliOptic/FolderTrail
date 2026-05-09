import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / "app" / "macos" / "FolderTrail" / "Execution" / "WorkspaceCopyService.swift"


class WorkspaceCopyFastCancelTests(unittest.TestCase):
    def test_issue_99_workspace_copy_has_cancellation_and_fast_clone_contract(self):
        source = SERVICE.read_text(encoding="utf-8")

        self.assertIn("shouldCancel", source)
        self.assertIn("Task.isCancelled", source)
        self.assertIn("CancellationError", source)
        self.assertIn("clonefile", source)
        self.assertIn("copyFile", source)

    def test_issue_99_cancellation_removes_partial_workspace(self):
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

            func write(_ url: URL, _ text: String) throws {
                try text.data(using: .utf8)!.write(to: url)
            }

            let root = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("FolderTrailWorkspaceCancelSmoke-" + UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }

            let source = root.appendingPathComponent("Downloads", isDirectory: true)
            try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
            try write(source.appendingPathComponent("a.txt"), "a")
            try write(source.appendingPathComponent("b.txt"), "b")
            try FileManager.default.createDirectory(at: source.appendingPathComponent("Nested", isDirectory: true), withIntermediateDirectories: true)
            try write(source.appendingPathComponent("Nested/c.txt"), "c")

            var checks = 0
            let service = WorkspaceCopyService(shouldCancel: {
                checks += 1
                return checks > 2
            })

            do {
                _ = try service.copyWorkspace(sourceFolderURL: source)
                expect(false, "copy should have been cancelled")
            } catch is CancellationError {
                let expectedWorkspace = source.deletingLastPathComponent()
                    .appendingPathComponent("Downloads_FolderTrail_Workspace", isDirectory: true)
                expect(!FileManager.default.fileExists(atPath: expectedWorkspace.path), "cancelled copy should remove partial workspace")
            } catch {
                expect(false, "expected CancellationError, got \(error)")
            }
        
            var completedChecks = 0
            let completed = WorkspaceCopyService(shouldCancel: {
                completedChecks += 1
                return false
            })
            let result = try completed.copyWorkspace(sourceFolderURL: source)
            expect(FileManager.default.fileExists(atPath: result.workspaceURL.appendingPathComponent("a.txt").path), "completed copy should include file")
            expect(FileManager.default.fileExists(atPath: result.workspaceURL.appendingPathComponent("Nested/c.txt").path), "completed copy should include nested file")
            expect(completedChecks > 0, "copy should consult cancellation hook")
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "WorkspaceCopyFastCancelSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(SERVICE),
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
