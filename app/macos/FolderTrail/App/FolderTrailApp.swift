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
            Text("OpenRouter 제공자 연결과 Codex / ChatGPT OAuth를 별도로 다룹니다.")
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
