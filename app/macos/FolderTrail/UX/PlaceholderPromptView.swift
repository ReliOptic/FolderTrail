import AppKit
import SwiftUI

@MainActor
struct PlaceholderPromptView: View {
    let folderURL: URL

    private let recommendedPrompts = [
        "중복 정리",
        "프로젝트별 정돈",
        "오래된 다운로드 분류",
    ]

    @State private var prompt = ""
    @State private var selectedFolderURL: URL
    @State private var showPreflight = false
    @State private var showConsentModal = false
    @State private var showSettingsSheet = false
    @FocusState private var promptFocused: Bool
    @ObservedObject private var providerSettings: OpenRouterProviderSettings

    init(folderURL: URL) {
        self.init(folderURL: folderURL, providerSettings: OpenRouterProviderSettings.shared)
    }

    init(folderURL: URL, providerSettings: OpenRouterProviderSettings) {
        self.folderURL = folderURL
        _selectedFolderURL = State(initialValue: folderURL)
        _providerSettings = ObservedObject(wrappedValue: providerSettings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.lg) {
            statusStrip

            ScrollView {
                VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.lg) {
                    folderSummary
                    promptComposer
                    CompactConnectionPanel(providerSettings: providerSettings)
                    preflightSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            keyboardShortcutButtons

            footerActions
        }
        .padding(FolderTrailDesign.Spacing.xl)
        .frame(minWidth: 520, idealWidth: 640, minHeight: 420, idealHeight: 560)
        .sheet(isPresented: $showConsentModal) {
            ConsentModalView(sourceFolderURL: selectedFolderURL) { _ in
                showConsentModal = false
            } onCancel: {
                showConsentModal = false
            }
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showSettingsSheet) {
            PromptSettingsSheet(providerSettings: providerSettings)
            .padding(FolderTrailDesign.Spacing.xl)
            .frame(width: 420)
        }
    }

    private var folderSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("정리할 폴더")
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(.secondary)
            Text(selectedFolderURL.lastPathComponent.isEmpty ? selectedFolderURL.path : selectedFolderURL.lastPathComponent)
                .font(FolderTrailDesign.Typography.section)
                .lineLimit(1)
        }
    }

    private var promptComposer: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.md) {
            HStack(spacing: 8) {
                ForEach(recommendedPrompts, id: \.self) { recommendedPrompt in
                    PromptChipButton(title: recommendedPrompt) {
                        prompt = recommendedPrompt
                        promptFocused = true
                    }
                }
            }

            TextEditor(text: $prompt)
                .font(FolderTrailDesign.Typography.body)
                .frame(minHeight: 96)
                .focused($promptFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: FolderTrailDesign.Radius.sm)
                        .stroke(Color.secondary.opacity(0.25))
                )
        }
    }

    @ViewBuilder
    private var preflightSection: some View {
        if showPreflight {
            PreflightView(
                folderURL: selectedFolderURL,
                runner: PreflightRunner(),
                providerSettings: providerSettings
            ) {
                showConsentModal = true
            }
        }
    }

    private var footerActions: some View {
        HStack {
            Button("폴더 바꾸기…") {
                chooseFolder()
            }

            Spacer()

            if providerSettings.isConnected {
                Button("복사본으로 정리 시작") {
                    showPreflight = true
                }
                    .buttonStyle(FolderTrailPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var statusStrip: some View {
        PromptStatusStrip(
            folderName: selectedFolderURL.lastPathComponent.isEmpty
                ? selectedFolderURL.path
                : selectedFolderURL.lastPathComponent,
            providerConnected: providerSettings.isConnected,
            settingsButton: {
                openSettingsSheet()
            }
        )
    }

    private var keyboardShortcutButtons: some View {
        HStack {
            Button("요청 입력") {
                promptFocused = true
            }
            .keyboardShortcut("k", modifiers: .command)

            Button("창 닫기") {
                NSApp.keyWindow?.close()
            }
            .keyboardShortcut("w", modifiers: .command)
        }
        .frame(width: 0, height: 0)
        .opacity(0)
        .accessibilityHidden(true)
    }

    private func chooseFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = selectedFolderURL

        if openPanel.runModal() == .OK, let url = openPanel.url {
            selectedFolderURL = url
            showPreflight = false
        }
    }

    private func openSettingsSheet() {
        showSettingsSheet = true
    }
}

private struct PromptStatusStrip: View {
    let folderName: String
    let providerConnected: Bool
    let settingsButton: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("FolderTrail")
                    .font(FolderTrailDesign.Typography.title)
                Text(folderName)
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            PromptReadinessBar(
                providerConnected: providerConnected,
                helperTitle: "로컬 도우미 선택 사항"
            )

            Button("설정…") {
                settingsButton()
            }
            .controlSize(.small)
        }
    }

}

private struct PromptReadinessBar: View {
    let providerConnected: Bool
    let helperTitle: String

    var body: some View {
        HStack(spacing: FolderTrailDesign.Spacing.sm) {
            Label(providerConnected ? "AI 준비됨" : "AI 연결 필요", systemImage: providerConnected ? "checkmark.circle" : "exclamationmark.circle")
                .foregroundStyle(providerConnected ? FolderTrailDesign.Palette.success : FolderTrailDesign.Palette.warning)
            Text("·")
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            Label(helperTitle, systemImage: "terminal")
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
        }
        .font(FolderTrailDesign.Typography.meta)
        .lineLimit(1)
    }
}

private struct PromptChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(FolderTrailChipButtonStyle())
            .controlSize(.small)
    }
}

private struct CompactConnectionPanel: View {
    @ObservedObject var providerSettings: OpenRouterProviderSettings

    var body: some View {
        FolderTrailPanel {
            VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.sm) {
                RequiredProviderRow(providerSettings: providerSettings)
                Divider()
                OptionalLocalHelperRow()
            }
        }
    }
}

private struct RequiredProviderRow: View {
    @ObservedObject var providerSettings: OpenRouterProviderSettings

    var body: some View {
        HStack(alignment: .top, spacing: FolderTrailDesign.Spacing.md) {
            VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.xs) {
                Text("OpenRouter 필요")
                    .font(FolderTrailDesign.Typography.body.weight(.semibold))
                Text("정리를 실행하는 AI 제공자 연결")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            }

            Spacer()

            switch providerSettings.status {
            case .connected:
                Label("연결됨", systemImage: "checkmark.circle.fill")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(FolderTrailDesign.Palette.success)
            default:
                Button("연결") {
                    connectOpenRouter()
                }
                .controlSize(.small)
            }
        }
    }

    private func connectOpenRouter() {
        Task {
            await providerSettings.connectWithBrowser { url in
                NSWorkspace.shared.open(url)
            }
            NSApp.activate(ignoringOtherApps: true)
            FolderTrailAppController.shared.bringPromptToFront()
        }
    }
}

private struct OptionalLocalHelperRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: FolderTrailDesign.Spacing.md) {
            VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.xs) {
                Text("선택: Codex / ChatGPT")
                    .font(FolderTrailDesign.Typography.body.weight(.semibold))
                Text("로컬 도우미 OAuth. 없어도 OpenRouter로 먼저 진행할 수 있습니다.")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
                    .lineLimit(2)
            }

            Spacer()

            CodexChatGPTOAuthView(style: .compact)
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
            Text("AI 모델 호출에 쓰는 제공자 연결입니다. Codex / ChatGPT OAuth와 별개입니다.")
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            ProviderConnectView(settings: providerSettings)
        }
    }
}

private struct PromptSettingsSheet: View {
    @ObservedObject var providerSettings: OpenRouterProviderSettings

    var body: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.lg) {
            Text("v0.1 설정")
                .font(FolderTrailDesign.Typography.section)
            Text("OpenRouter 제공자 연결과 Codex / ChatGPT OAuth는 별도 로그인입니다.")
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)

            Divider()
            ProviderConnectionSection(providerSettings: providerSettings)

            Divider()
            CodexChatGPTOAuthView()
        }
    }
}
