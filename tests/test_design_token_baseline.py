import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
PROJECT = ROOT / "app" / "macos" / "FolderTrail.xcodeproj" / "project.pbxproj"
DESIGN = APP / "UX" / "FolderTrailDesign.swift"


class DesignTokenBaselineTests(unittest.TestCase):
    def test_issue_42_design_tokens_and_components_exist(self):
        self.assertTrue(DESIGN.exists(), "missing shared v0.1 design baseline")
        source = DESIGN.read_text(encoding="utf-8")

        for token in ["enum FolderTrailDesign", "enum Spacing", "enum Radius", "enum Typography", "enum Palette"]:
            self.assertIn(token, source)
        for component in ["FolderTrailPanel", "FolderTrailPrimaryButtonStyle", "FolderTrailChipButtonStyle", "FolderTrailStatusPill"]:
            self.assertIn(component, source)
        self.assertNotIn("import AppKit", source)

    def test_issue_42_prompt_and_preflight_use_shared_design_language(self):
        prompt = (APP / "UX" / "PlaceholderPromptView.swift").read_text(encoding="utf-8")
        preflight = (APP / "UX" / "PreflightView.swift").read_text(encoding="utf-8")
        project = PROJECT.read_text(encoding="utf-8")

        self.assertIn("FolderTrailDesign.swift", project)
        self.assertIn("PromptStatusStrip", prompt)
        self.assertIn("FolderTrailDesign.Palette.warning", prompt)
        self.assertIn("FolderTrailChipButtonStyle", prompt)
        self.assertIn("FolderTrailPrimaryButtonStyle", prompt)
        self.assertIn("FolderTrailPanel", preflight)
        self.assertIn("FolderTrailPrimaryButtonStyle", preflight)


if __name__ == "__main__":
    unittest.main()
