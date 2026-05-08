import SwiftUI

struct PlaceholderPromptView: View {
    let folderURL: URL

    @State private var prompt = ""
    @State private var selectedFolderURL: URL

    init(folderURL: URL) {
        self.folderURL = folderURL
        _selectedFolderURL = State(initialValue: folderURL)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FolderTrail")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 4) {
                Text("선택된 폴더")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(selectedFolderURL.lastPathComponent.isEmpty ? selectedFolderURL.path : selectedFolderURL.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
            }

            TextEditor(text: $prompt)
                .font(.body)
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.25))
                )

            HStack {
                Button("개발용 폴더 선택…") {
                    chooseFolder()
                }

                Spacer()

                Button("안전 복사본에서 실행") {}
                    .keyboardShortcut(.defaultAction)
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 360)
    }

    private func chooseFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = selectedFolderURL

        if openPanel.runModal() == .OK, let url = openPanel.url {
            selectedFolderURL = url
        }
    }
}

