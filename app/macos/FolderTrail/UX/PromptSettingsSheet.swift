import SwiftUI

struct PromptSettingsSheet: View {
    @ObservedObject var providerSettings: OpenRouterProviderSettings

    var body: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.lg) {
            Text("v0.1 설정")
                .font(FolderTrailDesign.Typography.section)
            Text("OpenRouter 연결은 설정에서 관리합니다.")
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)

            Divider()
            ProviderConnectionSection(providerSettings: providerSettings)

            Divider()
            OpenRouterSettingsView(settings: providerSettings)

            Divider()
            CodexChatGPTOAuthView()
        }
    }
}

private struct ProviderConnectionSection: View {
    @ObservedObject var providerSettings: OpenRouterProviderSettings

    var body: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.xs) {
            Text("AI 제공자")
                .font(FolderTrailDesign.Typography.body.weight(.semibold))
            Text("OpenRouter")
                .font(FolderTrailDesign.Typography.meta.weight(.semibold))
            ProviderConnectView(settings: providerSettings)
        }
    }
}
