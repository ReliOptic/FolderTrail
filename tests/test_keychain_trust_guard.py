import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "app" / "macos" / "FolderTrail"
SETTINGS = APP / "Intelligence" / "OpenRouterProviderSettings.swift"
PROVIDER_VIEW = APP / "UX" / "ProviderConnectView.swift"
README = ROOT / "README.md"


class KeychainTrustGuardTests(unittest.TestCase):
    def test_issue_37_provider_settings_do_not_read_keychain_on_init(self):
        source = SETTINGS.read_text(encoding="utf-8")

        self.assertIn("private var hasCheckedStoredCredentials = false", source)
        self.assertIn("case keychainPermissionNeeded", source)
        self.assertNotRegex(source, r"init\(\) \{\s*refreshStatus\(\)\s*\}")
        self.assertIn("func refreshStatus(force: Bool = false)", source)
        self.assertIn("guard force || !hasCheckedStoredCredentials else", source)
        self.assertLess(source.index("func refreshStatus"), source.index("credentialStore.loadAPIKey"))
        self.assertNotIn("OpenRouterKeychain.load", source)

    def test_issue_37_provider_view_explains_keychain_before_user_action(self):
        source = PROVIDER_VIEW.read_text(encoding="utf-8")

        self.assertIn("저장된 연결 확인", source)
        self.assertIn("저장된 키를 확인하거나 새로 연결하세요", source)
        self.assertIn("macOS 허용 후 다시 확인하세요", source)
        self.assertIn("Keychain 허용 필요", source)
        self.assertIn("settings.refreshStatus()", source)
        self.assertIn("settings.refreshStatus(force: true)", source)

    def test_issue_37_dev_keychain_limit_is_documented(self):
        readme = README.read_text(encoding="utf-8")

        self.assertIn("개발용 ad-hoc 빌드", readme)
        self.assertIn("Keychain", readme)
        self.assertIn("Developer ID 서명", readme)


if __name__ == "__main__":
    unittest.main()
