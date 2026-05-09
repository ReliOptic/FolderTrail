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
            Text("OpenRouter 연결, Codex fallback, 실행 진단만 다룹니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            ProviderConnectView(settings: providerSettings)
            Divider()
            OpenRouterSettingsView(settings: providerSettings)
            Divider()
            CodexFallbackSettingsView()
            Divider()
            PlannerModelSettingsView(settings: plannerModelSettings)
        }
    }
}

struct CodexFallbackSettingsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Codex fallback")
                .font(.headline)
            Text("Codex fallback은 선택 사항입니다. 터미널에서 `codex --version`과 `codex login status`로 설치와 로그인을 확인합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
