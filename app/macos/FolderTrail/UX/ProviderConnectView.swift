import AppKit
import SwiftUI

struct ProviderConnectView: View {
    @ObservedObject var settings: OpenRouterProviderSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 연결")
                .font(.headline)

            switch settings.status {
            case .connected:
                Label("OpenRouter 연결됨", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(settings.maskedAPIKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .notConnected:
                Label("OpenRouter 연결 필요", systemImage: "circle")
                    .foregroundStyle(.secondary)
                Button("OpenRouter 연결") {
                    connectWithBrowser()
                }
            case .failed(let message):
                Label("OpenRouter 연결 실패", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("다시 연결") {
                    connectWithBrowser()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func connectWithBrowser() {
        Task {
            await settings.connectWithBrowser { url in
                NSWorkspace.shared.open(url)
            }
            NSApp.activate(ignoringOtherApps: true)
            FolderTrailAppController.shared.bringPromptToFront()
        }
    }
}
