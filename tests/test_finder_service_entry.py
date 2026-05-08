import plistlib
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
INFO = APP / "Info.plist"
SERVICE_PROVIDER = APP / "Entry" / "FolderTrailServiceProvider.swift"
APP_CONTROLLER = APP / "App" / "FolderTrailAppController.swift"
PROMPT_VIEW = APP / "UX" / "PlaceholderPromptView.swift"
PROVIDER_CONNECT_VIEW = APP / "UX" / "ProviderConnectView.swift"
OPENROUTER_SETTINGS = APP / "Intelligence" / "OpenRouterProviderSettings.swift"
OPENROUTER_PKCE = APP / "Intelligence" / "OpenRouterPKCE.swift"
OPENROUTER_KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
PREFLIGHT_CHECK = APP / "Safety" / "PreflightCheck.swift"
PREFLIGHT_VIEW = APP / "UX" / "PreflightView.swift"
CONSENT_MODAL_VIEW = APP / "UX" / "ConsentModalView.swift"
WORKSPACE_COPY_SERVICE = APP / "Execution" / "WorkspaceCopyService.swift"


class FinderServiceEntryContractTests(unittest.TestCase):
    def test_issue_3_nsservices_contract_targets_finder_folder_urls(self):
        info = plistlib.loads(INFO.read_bytes())
        services = info.get("NSServices")

        self.assertIsInstance(services, list)
        self.assertEqual(1, len(services), "FolderTrail should expose one Finder service entry")

        service = services[0]
        self.assertEqual({"default": "New FolderTrail"}, service.get("NSMenuItem"))
        self.assertEqual("openFolderTrail", service.get("NSMessage"))
        self.assertEqual("FolderTrail", service.get("NSPortName"))
        self.assertIn("public.folder", service.get("NSSendFileTypes", []))
        self.assertIn("public.file-url", service.get("NSSendTypes", []))

    def test_issue_3_service_provider_reads_urls_and_reports_non_folder_error(self):
        source = SERVICE_PROVIDER.read_text()

        self.assertIn("@objc func openFolderTrail", source)
        self.assertIn("pasteboard.readObjects(forClasses: [NSURL.self]", source)
        self.assertIn("FolderTrailAppController.shared.openPrompt(for:", source)
        self.assertIn("폴더를 선택한 뒤 New FolderTrail을 실행해 주세요.", source)
        self.assertIn("error.pointee", source)
        self.assertIn("showError", source)

    def test_issue_3_folder_selection_uses_first_existing_folder_only(self):
        smoke = textwrap.dedent(
            """
            import Foundation

            func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
                if !condition() {
                    FileHandle.standardError.write(Data(message.utf8))
                    FileHandle.standardError.write(Data("\\n".utf8))
                    exit(1)
                }
            }

            let root = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("FolderTrailFinderServiceSmoke-" + UUID().uuidString)
            let firstFolder = root.appendingPathComponent("first", isDirectory: true)
            let secondFolder = root.appendingPathComponent("second", isDirectory: true)
            let fileURL = root.appendingPathComponent("not-a-folder.txt")

            try FileManager.default.createDirectory(at: firstFolder, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: secondFolder, withIntermediateDirectories: true)
            FileManager.default.createFile(atPath: fileURL.path, contents: Data("x".utf8))
            defer { try? FileManager.default.removeItem(at: root) }

            let selected = FolderTrailServiceSelection.firstExistingFolderURL(from: [firstFolder, secondFolder])
            expect(selected == firstFolder, "expected first folder selection to win")

            let skippedFile = FolderTrailServiceSelection.firstExistingFolderURL(from: [fileURL, secondFolder])
            expect(skippedFile == secondFolder, "expected non-folder entries to be ignored")

            let noFolder = FolderTrailServiceSelection.firstExistingFolderURL(from: [fileURL])
            expect(noFolder == nil, "expected nil for non-folder-only selection")
            """
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "FinderServiceEntrySmoke"
            main.write_text(smoke)

            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(SERVICE_PROVIDER),
                    str(APP_CONTROLLER),
                    str(PROMPT_VIEW),
                    str(PROVIDER_CONNECT_VIEW),
                    str(OPENROUTER_SETTINGS),
                    str(OPENROUTER_PKCE),
                    str(OPENROUTER_KEYCHAIN),
                    str(PREFLIGHT_CHECK),
                    str(PREFLIGHT_VIEW),
                    str(CONSENT_MODAL_VIEW),
                    str(WORKSPACE_COPY_SERVICE),
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
