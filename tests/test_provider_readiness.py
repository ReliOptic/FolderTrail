import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
READINESS = APP / "Safety" / "ProviderReadiness.swift"
PREFLIGHT = APP / "Safety" / "PreflightCheck.swift"
PROMPT = APP / "UX" / "PlaceholderPromptView.swift"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"


class ProviderReadinessContractTests(unittest.TestCase):
    def test_issue_70_readiness_module_separates_required_openrouter_and_optional_codex(self):
        self.assertTrue(READINESS.exists(), "missing Safety/ProviderReadiness.swift")

        source = READINESS.read_text(encoding="utf-8")
        preflight = PREFLIGHT.read_text(encoding="utf-8")
        prompt = PROMPT.read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("struct ProviderReadiness", source)
        self.assertIn("enum ProviderReadinessRequirement", source)
        self.assertIn("case required", source)
        self.assertIn("case optional", source)
        self.assertIn("openRouter", source)
        self.assertIn("codexLocalHelper", source)
        self.assertIn("canProceed", source)
        self.assertIn("OpenRouter를 연결해야 AI 정리를 시작할 수 있습니다.", source)
        self.assertIn("Codex / ChatGPT OAuth는 선택 사항입니다", source)

        self.assertIn("ProviderReadiness.evaluate", preflight)
        self.assertIn("providerReadiness", preflight)
        self.assertIn("ProviderReadiness.promptStatus", prompt)
        self.assertIn("readiness.openRouter", prompt)
        self.assertIn("readiness.codexLocalHelper", prompt)
        self.assertIn("ProviderReadiness.swift", project)

    def test_issue_70_readiness_logic_allows_optional_codex_to_fail(self):
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

            let readyWithoutCodex = ProviderReadiness.evaluate(
                openRouterAPIKey: { "sk-or-ready" },
                codexAuthenticated: { false }
            )
            expect(readyWithoutCodex.openRouter.result.isPassed, "OpenRouter key should satisfy required provider")
            expect(!readyWithoutCodex.codexLocalHelper.result.isPassed, "Codex local helper can remain unavailable")
            expect(readyWithoutCodex.canProceed, "Optional Codex failure must not block proceeding")

            let missingOpenRouter = ProviderReadiness.evaluate(
                openRouterAPIKey: { "  " },
                codexAuthenticated: { true }
            )
            expect(!missingOpenRouter.openRouter.result.isPassed, "Blank OpenRouter key should fail")
            expect(missingOpenRouter.codexLocalHelper.result.isPassed, "Codex can be ready independently")
            expect(!missingOpenRouter.canProceed, "Required OpenRouter failure must block proceeding")

            let promptStatus = ProviderReadiness.promptStatus(openRouterConnected: true)
            expect(promptStatus.openRouter.requirement == .required, "OpenRouter prompt item remains required")
            expect(promptStatus.codexLocalHelper.requirement == .optional, "Codex prompt item remains optional")
            expect(promptStatus.canProceed, "Prompt status proceeds from OpenRouter readiness only")
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
