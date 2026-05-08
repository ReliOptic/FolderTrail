import AppKit
import SwiftUI

@MainActor
struct PlaceholderPromptView: View {
    let folderURL: URL

    private let recommendedPrompts = [
        "중복 파일을 찾아서 정리해줘",
        "프로젝트별로 폴더를 나눠줘",
        "오래된 다운로드 파일을 분류해줘",
    ]

    @State private var prompt = ""
    @State private var selectedFolderURL: URL
    @State private var showPreflight = false
    @State private var showConsentModal = false
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

            VStack(alignment: .leading, spacing: 4) {
                Text("정리할 폴더")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(.secondary)
                Text(selectedFolderURL.lastPathComponent.isEmpty ? selectedFolderURL.path : selectedFolderURL.lastPathComponent)
                    .font(FolderTrailDesign.Typography.section)
                    .lineLimit(1)
            }

            if !providerSettings.isConnected {
                ProviderConnectView(settings: providerSettings)
            }

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
                .frame(minHeight: 120)
                .focused($promptFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: FolderTrailDesign.Radius.sm)
                        .stroke(Color.secondary.opacity(0.25))
                )

            keyboardShortcutButtons

            if showPreflight {
                PreflightView(
                    folderURL: selectedFolderURL,
                    runner: PreflightRunner(),
                    providerSettings: providerSettings
                ) {
                    showConsentModal = true
                }
            }

            HStack {
                Button("정리할 폴더 바꾸기…") {
                    chooseFolder()
                }

                Spacer()

                if providerSettings.isConnected {
                    Button("안전 작업공간에서 시작") {
                        showPreflight = true
                    }
                        .buttonStyle(FolderTrailPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(FolderTrailDesign.Spacing.xl)
        .frame(minWidth: 520, minHeight: 360)
        .sheet(isPresented: $showConsentModal) {
            ConsentModalView(sourceFolderURL: selectedFolderURL) { _ in
                showConsentModal = false
            } onCancel: {
                showConsentModal = false
            }
            .interactiveDismissDisabled(true)
        }
    }

    private var statusStrip: some View {
        PromptStatusStrip(
            folderName: selectedFolderURL.lastPathComponent.isEmpty
                ? selectedFolderURL.path
                : selectedFolderURL.lastPathComponent,
            providerConnected: providerSettings.isConnected,
            settingsButton: {
                openSettingsWindow()
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

    private func openSettingsWindow() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
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

            FolderTrailStatusPill(title: providerStatusTitle, systemImage: providerStatusImage)
            FolderTrailStatusPill(title: runReadinessTitle, systemImage: runReadinessImage)
            FolderTrailStatusPill(title: "Codex fallback 선택", systemImage: "terminal")

            Button("설정…") {
                settingsButton()
            }
            .controlSize(.small)
        }
    }

    private var providerStatusTitle: String {
        providerConnected ? "OpenRouter 연결됨" : "OpenRouter 연결 필요"
    }

    private var providerStatusImage: String {
        providerConnected ? "checkmark.circle" : "circle"
    }

    private var runReadinessTitle: String {
        providerConnected ? "실행 준비" : "연결 필요"
    }

    private var runReadinessImage: String {
        providerConnected ? "play.circle" : "exclamationmark.circle"
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
