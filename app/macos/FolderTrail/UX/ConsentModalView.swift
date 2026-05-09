import SwiftUI

@MainActor
struct ConsentModalView: View {
    let sourceFolderURL: URL
    let workspaceMode: WorkspacePreparationMode
    let workspaceFolderName: String
    let onAllow: () -> Void
    let onCancel: () -> Void

    init(
        sourceFolderURL: URL,
        workspaceMode: WorkspacePreparationMode = .copiedWorkspace,
        onAllow: @escaping () -> Void = {},
        onCancel: @escaping () -> Void
    ) {
        self.sourceFolderURL = sourceFolderURL
        self.workspaceMode = workspaceMode
        self.workspaceFolderName = WorkspaceCopyService.workspaceFolderName(for: sourceFolderURL)
        self.onAllow = onAllow
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("시작 전 확인")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                labeledValue("원본 폴더", value: sourceFolderURL.lastPathComponent)
                switch workspaceMode {
                case .copiedWorkspace:
                    labeledValue("생성할 작업 폴더", value: workspaceFolderName)
                case .directSource:
                    labeledValue("작업 대상", value: sourceFolderURL.lastPathComponent)
                }
            }

            Text(workspaceMode.consentHeadline)
                .font(.headline)
                .foregroundStyle(workspaceMode.consentAccentIsWarning ? .orange : .green)

            Text(workspaceMode.consentDescription)
                .foregroundStyle(.secondary)

            HStack {
                Button("취소") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("허용하고 시작") {
                    onAllow()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 460)
    }

    private func labeledValue(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value.isEmpty ? sourceFolderURL.path : value)
                .font(.body.weight(.medium))
                .lineLimit(2)
        }
    }
}
