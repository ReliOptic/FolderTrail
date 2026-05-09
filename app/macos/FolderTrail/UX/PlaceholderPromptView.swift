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
    @StateObject private var runModel: FolderTrailPromptRunModel
    @FocusState private var promptFocused: Bool
    @ObservedObject private var providerSettings: OpenRouterProviderSettings

    init(folderURL: URL) {
        self.init(folderURL: folderURL, providerSettings: OpenRouterProviderSettings.shared)
    }

    init(
        folderURL: URL,
        providerSettings: OpenRouterProviderSettings,
        runModel: FolderTrailPromptRunModel? = nil
    ) {
        self.folderURL = folderURL
        _selectedFolderURL = State(initialValue: folderURL)
        _providerSettings = ObservedObject(wrappedValue: providerSettings)
        _runModel = StateObject(wrappedValue: runModel ?? FolderTrailPromptRunModel())
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
                    runStatusSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            keyboardShortcutButtons

            footerActions
        }
        .padding(FolderTrailDesign.Spacing.xl)
        .frame(minWidth: 520, idealWidth: 640, minHeight: 420, idealHeight: 560)
        .sheet(isPresented: $showConsentModal) {
            ConsentModalView(sourceFolderURL: selectedFolderURL) {
                startRun()
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

            Button("시작") {
                showPreflight = true
            }
                .buttonStyle(FolderTrailPrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
                .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || runModel.status == .running)
        }
    }

    @ViewBuilder
    private var runStatusSection: some View {
        switch runModel.status {
        case .idle:
            EmptyView()
        case .running:
            HStack(spacing: FolderTrailDesign.Spacing.sm) {
                ProgressView()
                    .controlSize(.small)
                Text("정리 중")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            }
        case .done:
            if let result = runModel.result {
                FolderTrailPanel {
                    VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.sm) {
                        Text("완료")
                            .font(FolderTrailDesign.Typography.body.weight(.semibold))
                        Button("결과 폴더 열기") {
                            NSWorkspace.shared.open(result.workspaceURL)
                        }
                        .controlSize(.small)
                    }
                }
            }
        case .failed:
            FolderTrailPanel {
                VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.sm) {
                    Text(runModel.errorMessage ?? "정리를 완료하지 못했습니다. 다시 시도해 주세요.")
                        .font(FolderTrailDesign.Typography.meta)
                        .foregroundStyle(FolderTrailDesign.Palette.warning)
                    Button("다시 시도") {
                        startRun()
                    }
                    .controlSize(.small)
                }
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

    private func startRun() {
        showConsentModal = false
        showPreflight = false
        Task {
            await runModel.run(prompt: prompt, sourceFolderURL: selectedFolderURL)
        }
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
                readiness: ProviderReadiness.promptStatus(openRouterConnected: providerConnected)
            )

            Button("설정…") {
                settingsButton()
            }
            .controlSize(.small)
        }
    }

}

private struct PromptReadinessBar: View {
    let readiness: ProviderReadiness

    var body: some View {
        HStack(spacing: FolderTrailDesign.Spacing.sm) {
            Label(openRouterTitle, systemImage: readiness.openRouter.isReady ? "checkmark.circle" : "exclamationmark.circle")
                .foregroundStyle(readiness.openRouter.isReady ? FolderTrailDesign.Palette.success : FolderTrailDesign.Palette.warning)
            Text("·")
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            Label(localHelperTitle, systemImage: "terminal")
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
        }
        .font(FolderTrailDesign.Typography.meta)
        .lineLimit(1)
    }

    private var openRouterTitle: String {
        readiness.openRouter.isReady ? "OpenRouter 연결됨" : "OpenRouter는 설정에서 연결"
    }

    private var localHelperTitle: String {
        readiness.codexLocalHelper.isReady ? "Codex 준비됨" : "Codex 로그인 필요"
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
