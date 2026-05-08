import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PREFLIGHT = ROOT / "app" / "macos" / "FolderTrail" / "Safety" / "PreflightCheck.swift"


class CodexGUIPathPreflightTests(unittest.TestCase):
    def test_issue_30_codex_lookup_handles_gui_path(self):
        source = PREFLIGHT.read_text(encoding="utf-8")

        self.assertIn('codexExecutableName = "codex"', source)
        self.assertIn("/opt/homebrew/bin/codex", source)
        self.assertIn("/usr/local/bin/codex", source)
        self.assertIn(".local/bin/codex", source)
        self.assertIn(".bun/bin/codex", source)
        self.assertIn("/bin/zsh", source)
        self.assertIn("command -v", source)
        self.assertIn("codex --version", source)
        self.assertIn("runCodexVersion", source)


if __name__ == "__main__":
    unittest.main()
