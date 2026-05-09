import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
CODEX_ADAPTER = APP / "Intelligence" / "CodexPlannerAdapter.swift"
OPENROUTER_ADAPTER = APP / "Intelligence" / "OpenRouterPlannerAdapter.swift"
MANIFEST = APP / "Intelligence" / "ManifestBuilder.swift"
KEYCHAIN = APP / "Safety" / "OpenRouterKeychain.swift"
CREDENTIAL_STORE = APP / "Safety" / "OpenRouterCredentialStore.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class CodexPlannerAdapterTests(unittest.TestCase):
    def test_issue_84_codex_adapter_is_project_source_and_uses_codex_exec(self):
        self.assertTrue(CODEX_ADAPTER.exists(), "missing Intelligence/CodexPlannerAdapter.swift")

        source = CODEX_ADAPTER.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("struct CodexPlannerAdapter", source)
        self.assertIn("PlannerAdapter", source)
        self.assertIn("codex exec", source)
        self.assertIn("--output-last-message", source)
        self.assertIn("--sandbox read-only", source)
        self.assertIn("--ask-for-approval never", source)
        self.assertIn("--skip-git-repo-check", source)
        self.assertIn("CommandRunner", source)
        self.assertIn("CodexPlannerAdapter.swift", project)

    def test_issue_84_codex_adapter_builds_action_plan_without_live_cli(self):
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
                    let adapter = CodexPlannerAdapter(commandRunner: { request in
                        expect(request.arguments.contains { $0.contains("codex exec") }, "Codex adapter should run codex exec")
                        expect(request.arguments.contains { $0.contains("--output-last-message") }, "Codex adapter should capture the last message")
                        expect(request.prompt.contains("Return only ActionPlan JSON"), "prompt should demand JSON only")
                        expect(request.prompt.contains("FolderManifest JSON"), "prompt should include manifest JSON")
                        return """
                        Here is the plan:
                        {"plan_version":"0.1","provider":"codex","model":"codex-cli","summary_ko":"정리합니다.","actions":[{"type":"create_folder","path":"Docs","reason":"문서 정리"}]}
                        """
                    })

                    let manifest = FolderManifest(
                        manifest_version: "0.1",
                        workspace_name: "Workspace",
                        source_folder: "/source",
                        total_files: 1,
                        total_directories: 0,
                        detail_level: .level_3_metadata,
                        privacy_filter_applied: true,
                        files: [
                            ManifestFile(
                                path: "note.txt",
                                name: "note.txt",
                                extension: "txt",
                                size_bytes: 5,
                                size_bucket: nil,
                                modified_date_bucket: nil,
                                text_preview: nil
                            )
                        ],
                        directory_summary: [],
                        review_excluded: []
                    )

                    let plan = try await adapter.plan(prompt: "문서를 정리", manifest: manifest)
                    expect(plan.provider == "codex", "provider should be codex")
                    expect(plan.model == "codex-cli", "model should identify CLI")
                    expect(plan.actions.first?.path == "Docs", "plan should decode returned JSON")

                    let invalid = CodexPlannerAdapter(commandRunner: { _ in "not json" })
                    do {
                        _ = try await invalid.plan(prompt: "x", manifest: manifest)
                        expect(false, "invalid JSON should fail")
                    } catch PlannerAdapterError.invalidJSON {
                    }

                    let failed = CodexPlannerAdapter(commandRunner: { _ in
                        throw PlannerAdapterError.networkFailure
                    })
                    do {
                        _ = try await failed.plan(prompt: "x", manifest: manifest)
                        expect(false, "runner failure should map to network failure")
                    } catch PlannerAdapterError.networkFailure {
                    }
                }
            }
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "CodexPlannerAdapterSmoke"
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
                    str(CODEX_ADAPTER),
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
