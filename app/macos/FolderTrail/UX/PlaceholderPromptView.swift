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
        VStack(alignment: .leading, spacing: 16) {
            Text("FolderTrail")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("정리할 폴더")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(selectedFolderURL.lastPathComponent.isEmpty ? selectedFolderURL.path : selectedFolderURL.lastPathComponent)
                    .font(.headline)
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
                .font(.body)
                .frame(minHeight: 120)
                .focused($promptFocused)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
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
                        .keyboardShortcut(.defaultAction)
                        .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding(24)
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
}

private struct PromptChipButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.bordered)
            .controlSize(.small)
    }
}
