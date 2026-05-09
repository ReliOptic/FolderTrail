import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class ArchitectureBehaviorTestContract(unittest.TestCase):
    def test_issue_73_hardened_architecture_tests_use_behavior_smoke_paths(self):
        provider = (ROOT / "tests" / "test_provider_readiness.py").read_text(encoding="utf-8")
        pipeline = (ROOT / "tests" / "test_run_pipeline.py").read_text(encoding="utf-8")

        self.assertIn("swiftc", provider)
        self.assertIn("swiftc", pipeline)
        self.assertNotIn("struct ProviderReadiness", provider)
        self.assertNotIn("final class FolderTrailRunPipeline", pipeline)


if __name__ == "__main__":
    unittest.main()
