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
                Text("저장된 연결 확인은 Keychain 접근이 필요할 수 있으며 macOS가 허용을 요청할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("저장된 연결 확인") {
                        settings.refreshStatus()
                    }
                    Button("OpenRouter 연결") {
                        connectWithBrowser()
                    }
                }
            case .keychainPermissionNeeded(let message):
                Label("Keychain 허용 필요", systemImage: "lock.trianglebadge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("저장된 OpenRouter 키를 확인하려면 Keychain 접근 허용이 필요합니다. macOS가 허용을 요청할 수 있습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("다시 확인") {
                        settings.refreshStatus(force: true)
                    }
                    Button("OpenRouter 다시 연결") {
                        connectWithBrowser()
                    }
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
