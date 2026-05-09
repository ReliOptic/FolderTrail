import SwiftUI

@main
struct FolderTrailApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var plannerModelSettings = PlannerModelSettings()

    var body: some Scene {
        Settings {
            FolderTrailSettingsView(
                providerSettings: OpenRouterProviderSettings.shared,
                plannerModelSettings: plannerModelSettings
            )
            .padding(20)
            .frame(width: 420)
        }
    }
}

struct FolderTrailSettingsView: View {
    @ObservedObject var providerSettings: OpenRouterProviderSettings
    @ObservedObject var plannerModelSettings: PlannerModelSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("v0.1 설정")
                .font(.title3.weight(.semibold))
            Text("연결을 관리하세요.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            ProviderConnectView(settings: providerSettings)
            Divider()
            OpenRouterSettingsView(settings: providerSettings)
            Divider()
            CodexChatGPTOAuthView()
            Divider()
            PlannerModelSettingsView(settings: plannerModelSettings)
        }
    }
}
