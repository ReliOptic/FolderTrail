import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
WORKSPACE_MODE = APP / "Execution" / "WorkspaceModePolicy.swift"
READINESS = APP / "Safety" / "ProviderReadiness.swift"
PREFLIGHT = APP / "Safety" / "PreflightCheck.swift"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"


class CodexFirstReadinessTests(unittest.TestCase):
    def test_issue_83_codex_auth_is_required_and_openrouter_is_optional(self):
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

            let codexReadyWithoutOpenRouter = ProviderReadiness.evaluate(
                openRouterAPIKey: { nil },
                codexAuthenticated: { true }
            )
            expect(codexReadyWithoutOpenRouter.codexLocalHelper.result.isPassed, "Codex login should satisfy the primary readiness gate")
            expect(codexReadyWithoutOpenRouter.codexLocalHelper.requirement == .required, "Codex should be required")
            expect(codexReadyWithoutOpenRouter.openRouter.requirement == .optional, "OpenRouter should be optional")
            expect(codexReadyWithoutOpenRouter.canProceed, "Missing OpenRouter must not block the main start flow")

            let openRouterReadyWithoutCodex = ProviderReadiness.evaluate(
                openRouterAPIKey: { "sk-or-ready" },
                codexAuthenticated: { false }
            )
            expect(openRouterReadyWithoutCodex.openRouter.result.isPassed, "OpenRouter can be connected independently")
            expect(!openRouterReadyWithoutCodex.canProceed, "Missing Codex login must block the main start flow")
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "CodexFirstReadinessSmoke"
            main.write_text(smoke, encoding="utf-8")
            subprocess.run(
                [
                    "swiftc",
                    "-warnings-as-errors",
                    "-target",
                    "arm64-apple-macosx14.0",
                    str(READINESS),
                    str(APP / "Safety" / "OpenRouterKeychain.swift"),
                    str(APP / "Safety" / "OpenRouterCredentialStore.swift"),
                    str(WORKSPACE_MODE),
                    str(PREFLIGHT),
                    str(main),
                    "-o",
                    str(exe),
                ],
                check=True,
                cwd=ROOT,
            )
            subprocess.run([str(exe)], check=True, cwd=ROOT)

    def test_issue_83_preflight_blocks_on_codex_not_openrouter(self):
        source = PREFLIGHT.read_text(encoding="utf-8")

        self.assertRegex(source, r"case \.folderReadable, \.workspaceWritable, \.codexAvailable, \.codexAuthenticated:\n\s+return true")
        self.assertNotIn("providerConnected", source)
        self.assertNotIn("OpenRouterCredentialStore.keychain.loadAPIKey", source)

    def test_issue_83_prompt_start_button_is_not_hidden_by_openrouter_connection(self):
        source = PROMPT.read_text(encoding="utf-8")
        mode_policy = WORKSPACE_MODE.read_text(encoding="utf-8")

        self.assertIn("workspaceMode.primaryActionTitle", source)
        self.assertIn("복사본으로 시작", mode_policy)
        self.assertNotIn("if providerSettings.isConnected", source)


if __name__ == "__main__":
    unittest.main()
