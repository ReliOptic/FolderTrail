import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
BUILDER = APP / "Intelligence" / "ManifestBuilder.swift"
CONFIRM_VIEW = APP / "UX" / "ManifestConfirmationView.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class ManifestBuilderBehaviorTests(unittest.TestCase):
    def test_issue_9_manifest_builder_behavior(self):
        self.assertTrue(BUILDER.exists(), "missing Intelligence/ManifestBuilder.swift")
        self.assertTrue(CONFIRM_VIEW.exists(), "missing UX/ManifestConfirmationView.swift")

        source = BUILDER.read_text(encoding="utf-8")
        confirm_view = CONFIRM_VIEW.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("struct FolderManifest", source)
        self.assertIn("privacy_filter_applied", source)
        self.assertIn("level_3_metadata", source)
        self.assertIn("level_2_path_summary", source)
        self.assertIn("level_1_directory_summary", source)
        self.assertIn("level_0_confirm", source)
        self.assertIn("200", source)
        self.assertIn("1000", source)
        self.assertIn("5000", source)
        self.assertIn("previewBudget", source)
        self.assertIn("20_000", source)
        self.assertIn("1_000", source)
        self.assertIn("sensitive_filename_pattern", source)
        self.assertIn("relativePath", source)
        self.assertIn("ManifestConfirmationView", confirm_view)
        self.assertIn("5,000", confirm_view)
        self.assertIn("ManifestBuilder.swift", project)
        self.assertIn("ManifestConfirmationView.swift", project)

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
                .appendingPathComponent("FolderTrailManifestSmoke-" + UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: root) }

            let empty = root.appendingPathComponent("Empty_FolderTrail_Workspace", isDirectory: true)
            try FileManager.default.createDirectory(at: empty, withIntermediateDirectories: true)
            let builder = ManifestBuilder()
            let emptyManifest = try builder.build(workspaceURL: empty, sourceFolderPath: "/source/Empty")
            expect(emptyManifest.detail_level == .level_3_metadata, "empty folder should use level 3")
            expect(emptyManifest.privacy_filter_applied, "privacy filter must always be true")
            expect(emptyManifest.files.isEmpty, "empty manifest should have no files")

            let project = root.appendingPathComponent("Project_FolderTrail_Workspace", isDirectory: true)
            try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
            try write(project.appendingPathComponent("README.md"), String(repeating: "a", count: 1200))
            let nested = project.appendingPathComponent("nested", isDirectory: true)
            try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
            try write(nested.appendingPathComponent("data.json"), "{\"ok\": true}")
            try write(project.appendingPathComponent(".env"), "SECRET=1")

            let manifest = try builder.build(workspaceURL: project, sourceFolderPath: "/source/Project")
            expect(manifest.detail_level == .level_3_metadata, "small folder should use level 3")
            expect(manifest.files.contains { $0.path == "README.md" }, "single file path should be relative")
            expect(manifest.files.contains { $0.path == "nested/data.json" }, "nested path should be relative")
            expect(manifest.files.allSatisfy { !$0.path.hasPrefix(project.path) }, "paths must not be absolute")
            expect(manifest.files.first { $0.path == "README.md" }?.text_preview?.count == 1000, "preview should be capped per file")
            expect(manifest.review_excluded.contains { $0.path == ".env" && $0.reason == "sensitive_filename_pattern" }, "sensitive file should be excluded")

            let archive = root.appendingPathComponent("Archive_FolderTrail_Workspace", isDirectory: true)
            try FileManager.default.createDirectory(at: archive, withIntermediateDirectories: true)
            for index in 0..<201 {
                try write(archive.appendingPathComponent("file-\(index).txt"), "x")
            }
            let archiveManifest = try builder.build(workspaceURL: archive, sourceFolderPath: "/source/Archive")
            expect(archiveManifest.detail_level == .level_2_path_summary, "201 files should use level 2")
            expect(archiveManifest.files.allSatisfy { $0.size_bytes == nil && $0.size_bucket != nil }, "level 2 should use size buckets only")
            """
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "ManifestBuilderSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(BUILDER),
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
