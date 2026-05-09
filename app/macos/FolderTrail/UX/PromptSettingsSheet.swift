import SwiftUI

struct PromptSettingsSheet: View {
    @ObservedObject var providerSettings: OpenRouterProviderSettings

    private enum PromptSettingsLayout {
        static let width: CGFloat = 520
        static let minHeight: CGFloat = 420
        static let idealHeight: CGFloat = 560
        static let maxHeight: CGFloat = 640
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.md) {
            Text("v0.1 설정")
                .font(FolderTrailDesign.Typography.section)
            Text("OpenRouter 연결은 설정에서 관리합니다.")
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)

            Divider()

            ScrollView {
                settingsContent
            }
        }
        .padding(FolderTrailDesign.Spacing.xl)
        .frame(width: PromptSettingsLayout.width)
        .frame(minHeight: PromptSettingsLayout.minHeight, idealHeight: PromptSettingsLayout.idealHeight, maxHeight: PromptSettingsLayout.maxHeight)
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.lg) {
            ProviderConnectionSection(providerSettings: providerSettings)

            Divider()
            OpenRouterSettingsView(settings: providerSettings)

            Divider()
            CodexChatGPTOAuthView()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
