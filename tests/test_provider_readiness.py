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
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class ProviderReadinessContractTests(unittest.TestCase):
    def test_issue_70_readiness_module_separates_codex_and_openrouter(self):
        self.assertTrue(READINESS.exists(), "missing Safety/ProviderReadiness.swift")

        project = PROJECT.read_text(encoding="utf-8")
        self.assertIn("ProviderReadiness.swift", project)

    def test_issue_83_readiness_logic_requires_codex_and_allows_optional_openrouter_to_fail(self):
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

            let readyWithoutOpenRouter = ProviderReadiness.evaluate(
                openRouterAPIKey: { nil },
                codexAuthenticated: { true }
            )
            expect(readyWithoutOpenRouter.codexLocalHelper.result.isPassed, "Codex login should satisfy required readiness")
            expect(readyWithoutOpenRouter.canProceed, "Missing OpenRouter must not block proceeding")
            if case .failed(let openRouterReason) = readyWithoutOpenRouter.openRouter.result {
                expect(openRouterReason.contains("설정"), "OpenRouter failure should point to settings")
            } else {
                expect(false, "Missing OpenRouter should be reported independently")
            }

            let readyOpenRouterWithoutCodex = ProviderReadiness.evaluate(
                openRouterAPIKey: { "sk-or-ready" },
                codexAuthenticated: { false }
            )
            expect(readyOpenRouterWithoutCodex.openRouter.result.isPassed, "OpenRouter can be connected independently")
            if case .failed(let codexReason) = readyOpenRouterWithoutCodex.codexLocalHelper.result {
                expect(codexReason.contains("Codex"), "Codex failure should name the primary readiness gate")
            } else {
                expect(false, "Missing Codex should fail")
            }
            expect(!readyOpenRouterWithoutCodex.canProceed, "Missing Codex must block proceeding")

            let promptStatus = ProviderReadiness.promptStatus(openRouterConnected: true)
            expect(promptStatus.openRouter.requirement == .optional, "OpenRouter prompt item is optional")
            expect(promptStatus.codexLocalHelper.requirement == .required, "Codex prompt item is required")
            '''
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            main = Path(temp_dir) / "main.swift"
            exe = Path(temp_dir) / "ProviderReadinessSmoke"
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


if __name__ == "__main__":
    unittest.main()
