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
                runner: PreflightRunner()
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

            Button("설정…") {
                settingsButton()
            }
            .controlSize(.small)
        }
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
