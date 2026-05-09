import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
PREFLIGHT = APP / "Safety" / "PreflightCheck.swift"
PLANNER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
SETTINGS = APP / "Intelligence" / "OpenRouterProviderSettings.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class OpenRouterCredentialStoreTests(unittest.TestCase):
    def test_issue_72_direct_keychain_reads_are_concentrated_behind_store(self):
        self.assertTrue(STORE.exists(), "missing Safety/OpenRouterCredentialStore.swift")
        store = STORE.read_text(encoding="utf-8")
        preflight = PREFLIGHT.read_text(encoding="utf-8")
        planner = PLANNER.read_text(encoding="utf-8")
        settings = SETTINGS.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("struct OpenRouterCredentialStore", store)
        self.assertIn("static let keychain", store)
        self.assertIn("func loadAPIKey", store)
        self.assertIn("func saveAPIKey", store)
        self.assertIn("func deleteAPIKey", store)
        self.assertIn("OpenRouterKeychain.load", store)
        self.assertNotIn("OpenRouterKeychain.load", preflight)
        self.assertNotIn("OpenRouterKeychain.load", planner)
        self.assertNotIn("OpenRouterKeychain.load", settings)
        self.assertIn("OpenRouterCredentialStore.swift", project)

    def test_issue_72_store_normalizes_blank_credentials_for_callers(self):
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

            var saved: [String] = []
            var deleted = false
            let blankStore = OpenRouterCredentialStore(
                load: { "   " },
                save: { saved.append($0) },
                delete: { deleted = true }
            )
            let blankKey = try blankStore.loadAPIKey()
            expect(blankKey == nil, "blank stored credentials should normalize to nil")

            let keyStore = OpenRouterCredentialStore(
                load: { "  sk-test-1234  " },
                save: { saved.append($0) },
                delete: { deleted = true }
            )
            let loadedKey = try keyStore.loadAPIKey()
            expect(loadedKey == "sk-test-1234", "stored credentials should be trimmed")
            try keyStore.saveAPIKey("  sk-save-5678  ")
            expect(saved == ["sk-save-5678"], "saved credentials should be trimmed once at the seam")
            try keyStore.deleteAPIKey()
            expect(deleted, "delete should go through the same seam")
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "OpenRouterCredentialStoreSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(STORE),
                    str(KEYCHAIN),
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
