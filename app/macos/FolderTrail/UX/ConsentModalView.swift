import SwiftUI

@MainActor
struct ConsentModalView: View {
    let sourceFolderURL: URL
    let workspaceFolderName: String
    let onAllow: () -> Void
    let onCancel: () -> Void

    init(
        sourceFolderURL: URL,
        onAllow: @escaping () -> Void = {},
        onCancel: @escaping () -> Void
    ) {
        self.sourceFolderURL = sourceFolderURL
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
                labeledValue("생성할 작업 폴더", value: workspaceFolderName)
            }

            Text("원본 폴더는 변경하지 않습니다")
                .font(.headline)
                .foregroundStyle(.green)

            Text("FolderTrail은 별도 작업 폴더를 만든 뒤 그 안에서 정리 계획을 실행합니다.")
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
