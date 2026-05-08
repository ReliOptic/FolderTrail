import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
SETTINGS_VIEW = APP / "UX" / "PlannerModelSettingsView.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class OpenRouterPlannerAdapterTests(unittest.TestCase):
    def test_issue_10_planner_adapter_contract_and_parsing(self):
        self.assertTrue(ADAPTER.exists(), "missing Intelligence/OpenRouterPlannerAdapter.swift")
        self.assertTrue(SETTINGS_VIEW.exists(), "missing UX/PlannerModelSettingsView.swift")

        source = ADAPTER.read_text(encoding="utf-8")
        settings = SETTINGS_VIEW.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("https://openrouter.ai/api/v1/chat/completions", source)
        self.assertIn("FolderTrail Planner", source)
        self.assertIn("OpenRouterKeychain.load", source)
        self.assertIn("URLSession.shared.data", source)
        self.assertIn("struct ActionPlan", source)
        self.assertIn("Codable", source)
        self.assertIn("authFailure", source)
        self.assertIn("networkFailure", source)
        self.assertIn("invalidJSON", source)
        self.assertIn("schemaMismatch", source)
        self.assertIn("anthropic/claude-sonnet-4.6", source)
        self.assertIn("MockPlannerAdapter", source)

        self.assertIn("curatedModels", settings)
        self.assertGreaterEqual(source.count("anthropic/"), 2)
        self.assertIn("TextField", settings)
        self.assertIn("Picker", settings)

        self.assertIn("OpenRouterPlannerAdapter.swift", project)
        self.assertIn("PlannerModelSettingsView.swift", project)

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

            let success = """
            {"plan_version":"0.1","provider":"openrouter","model":"anthropic/claude-sonnet-4.6","summary_ko":"정리합니다.","actions":[{"type":"create_folder","path":"Docs"}]}
            """
            let plan = try OpenRouterPlannerAdapter.decodeActionPlan(from: success.data(using: .utf8)!)
            expect(plan.actions.count == 1, "expected one action")

            do {
                _ = try OpenRouterPlannerAdapter.decodeActionPlan(from: Data("not-json".utf8))
                expect(false, "malformed JSON should fail")
            } catch PlannerAdapterError.invalidJSON {
            }

            do {
                _ = try OpenRouterPlannerAdapter.decodeActionPlan(from: Data("""
                {"plan_version":"0.1","provider":"openrouter","model":"x","summary_ko":"bad","actions":[]}
                """.utf8))
                expect(false, "empty actions should be schema mismatch")
            } catch PlannerAdapterError.schemaMismatch {
            }

            let mock = MockPlannerAdapter()
            let manifest = FolderManifest(
                manifest_version: "0.1",
                workspace_name: "Workspace",
                source_folder: "/source",
                total_files: 0,
                total_directories: 0,
                detail_level: .level_3_metadata,
                privacy_filter_applied: true,
                files: [],
                directory_summary: [],
                review_excluded: []
            )
            let mockPlan = try await mock.plan(prompt: "정리", manifest: manifest)
            expect(mockPlan.actions.count == 1, "mock should return a fixed action plan")
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "PlannerAdapterSmoke"
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
