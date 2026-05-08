import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MACOS = ROOT / "app" / "macos"
APP = MACOS / "FolderTrail"
PROJECT = MACOS / "FolderTrail.xcodeproj" / "project.pbxproj"


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


class ProviderConnectContractTests(unittest.TestCase):
    def test_openrouter_provider_connect_contract(self):
        expected_files = [
            APP / "Intelligence" / "OpenRouterPKCE.swift",
            APP / "Intelligence" / "OpenRouterProviderSettings.swift",
            APP / "Safety" / "OpenRouterKeychain.swift",
            APP / "UX" / "ProviderConnectView.swift",
            APP / "UX" / "OpenRouterSettingsView.swift",
        ]
        for path in expected_files:
            self.assertTrue(path.exists(), f"missing {path.relative_to(ROOT)}")

        pkce = read(APP / "Intelligence" / "OpenRouterPKCE.swift")
        self.assertIn("https://openrouter.ai/auth", pkce)
        self.assertIn("http://localhost:3000/openrouter/callback", pkce)
        self.assertIn("code_challenge", pkce)
        self.assertIn("code_challenge_method", pkce)
        self.assertIn("S256", pkce)
        self.assertIn("https://openrouter.ai/api/v1/auth/keys", pkce)
        self.assertRegex(pkce, r"SHA256\.hash|CC_SHA256", "PKCE challenge must use SHA-256")
        self.assertIn("OpenRouterCallbackServer", pkce)
        self.assertIn("NWListener", pkce)
        self.assertIn("localhost", pkce)
        self.assertIn("URLComponents", pkce)
        self.assertIn('.name == "code"', pkce)

        keychain = read(APP / "Safety" / "OpenRouterKeychain.swift")
        self.assertIn('service = "FolderTrail"', keychain)
        self.assertIn('account = "openrouter.default"', keychain)
        self.assertIn("kSecClassGenericPassword", keychain)
        self.assertIn("SecItemAdd", keychain)
        self.assertIn("SecItemCopyMatching", keychain)
        self.assertIn("SecItemDelete", keychain)

        settings = read(APP / "Intelligence" / "OpenRouterProviderSettings.swift")
        self.assertIn("enum ProviderConnectionStatus", settings)
        self.assertRegex(settings, r"case\s+connected")
        self.assertRegex(settings, r"case\s+notConnected")
        self.assertRegex(settings, r"case\s+failed")
        self.assertIn("isConnected", settings)
        self.assertIn("saveManualAPIKey", settings)
        self.assertIn("maskedAPIKey", settings)
        self.assertIn("connectWithBrowser", settings)
        self.assertIn("code_verifier", settings)
        self.assertIn("code_challenge_method", settings)
        self.assertIn("URLSession.shared.data", settings)
        self.assertNotIn("apiKey =", settings, "settings model must not persist the raw API key outside Keychain")

        provider_view = read(APP / "UX" / "ProviderConnectView.swift")
        self.assertIn("Connect OpenRouter", provider_view)
        self.assertIn("connected", provider_view)
        self.assertIn("notConnected", provider_view)
        self.assertIn("Retry", provider_view)
        self.assertIn("connectWithBrowser", provider_view)
        self.assertNotRegex(provider_view, r"Text\([^\n]*apiKey", "Provider UI must not render a raw API key")

        settings_view = read(APP / "UX" / "OpenRouterSettingsView.swift")
        self.assertIn("SecureField", settings_view)
        self.assertIn("saveManualAPIKey", settings_view)
        self.assertIn("maskedAPIKey", settings_view)

        project = read(PROJECT)
        for name in [
            "OpenRouterPKCE.swift",
            "OpenRouterProviderSettings.swift",
            "OpenRouterKeychain.swift",
            "ProviderConnectView.swift",
            "OpenRouterSettingsView.swift",
        ]:
            self.assertIn(name, project, f"{name} must be wired into the Xcode target")


if __name__ == "__main__":
    unittest.main()
