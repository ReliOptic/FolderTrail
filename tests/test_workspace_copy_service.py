import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SERVICE = ROOT / "app" / "macos" / "FolderTrail" / "Execution" / "WorkspaceCopyService.swift"


class WorkspaceCopyServiceBehaviorTests(unittest.TestCase):
    def test_issue_8_safe_workspace_copy_behavior(self):
        source = SERVICE.read_text(encoding="utf-8")
        self.assertIn("AsyncStream", source)
        self.assertIn("WorkspaceCopyProgress", source)
        self.assertIn("copyItem", source)
        self.assertNotIn("Process()", source, "workspace copy must not shell out")
        self.assertIn("private(set) var readOnlySourceFolderURL", source)
        self.assertIn("failed(reason:", source)

        smoke = textwrap.dedent(
            r"""
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
                .appendingPathComponent("FolderTrailWorkspaceCopySmoke-" + UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }

            let source = root.appendingPathComponent("Project", isDirectory: true)
            try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)

            let service = WorkspaceCopyService()
            let emptyResult = try service.copyWorkspace(sourceFolderURL: source)
            expect(emptyResult.workspaceURL.lastPathComponent == "Project_FolderTrail_Workspace", "unexpected empty workspace name")
            expect(FileManager.default.fileExists(atPath: emptyResult.workspaceURL.path), "empty workspace was not created")
            expect(service.readOnlySourceFolderURL == source, "source folder should be recorded read-only")

            let nested = source.appendingPathComponent("Nested", isDirectory: true)
            try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
            try write(nested.appendingPathComponent("keep.txt"), "keep")
            try FileManager.default.createDirectory(at: source.appendingPathComponent(".git", isDirectory: true), withIntermediateDirectories: true)
            try write(source.appendingPathComponent(".git/config"), "secret")
            try FileManager.default.createDirectory(at: source.appendingPathComponent("node_modules", isDirectory: true), withIntermediateDirectories: true)
            try write(source.appendingPathComponent("node_modules/pkg.js"), "skip")
            try write(source.appendingPathComponent(".DS_Store"), "skip")
            try FileManager.default.createDirectory(at: source.appendingPathComponent(".Trash", isDirectory: true), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: source.appendingPathComponent(".foldertrail", isDirectory: true), withIntermediateDirectories: true)

            let duplicateResult = try service.copyWorkspace(sourceFolderURL: source)
            expect(duplicateResult.workspaceURL.lastPathComponent == "Project_FolderTrail_Workspace_2", "duplicate workspace should receive _2 suffix")
            expect(FileManager.default.fileExists(atPath: duplicateResult.workspaceURL.appendingPathComponent("Nested/keep.txt").path), "nested file was not copied")
            expect(!FileManager.default.fileExists(atPath: duplicateResult.workspaceURL.appendingPathComponent(".git").path), ".git should be excluded")
            expect(!FileManager.default.fileExists(atPath: duplicateResult.workspaceURL.appendingPathComponent("node_modules").path), "node_modules should be excluded")
            expect(!FileManager.default.fileExists(atPath: duplicateResult.workspaceURL.appendingPathComponent(".DS_Store").path), ".DS_Store should be excluded")
            expect(!FileManager.default.fileExists(atPath: duplicateResult.workspaceURL.appendingPathComponent(".Trash").path), ".Trash should be excluded")
            expect(!FileManager.default.fileExists(atPath: duplicateResult.workspaceURL.appendingPathComponent(".foldertrail").path), ".foldertrail should be excluded")
            """
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "WorkspaceCopySmoke"
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
