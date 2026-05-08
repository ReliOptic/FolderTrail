import SwiftUI

struct ManifestConfirmationView: View {
    let totalFiles: Int
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("큰 폴더 확인")
                .font(.headline)
            Text("5,000개가 넘는 파일은 매니페스트 생성 전에 사용자 확인이 필요합니다.")
            Text("총 파일 수: \(totalFiles)")
                .foregroundStyle(.secondary)

            HStack {
                Button("취소", action: onCancel)
                Spacer()
                Button("계속", action: onConfirm)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
