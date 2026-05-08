import SwiftUI

@main
struct FolderTrailApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            VStack(alignment: .leading, spacing: 20) {
                ProviderConnectView(settings: OpenRouterProviderSettings.shared)
                Divider()
                OpenRouterSettingsView(settings: OpenRouterProviderSettings.shared)
            }
                .padding(20)
                .frame(width: 420)
        }
    }
}
