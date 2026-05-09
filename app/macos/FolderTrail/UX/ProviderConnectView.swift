import AppKit
import SwiftUI

struct ProviderConnectView: View {
    @ObservedObject var settings: OpenRouterProviderSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenRouter 연결")
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
                Text("저장된 키를 확인하거나 새로 연결하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("저장된 연결 확인") {
                        settings.refreshStatus()
                    }
                    Button("연결") {
                        connectWithBrowser()
                    }
                }
            case .keychainPermissionNeeded(let message):
                Label("Keychain 허용 필요", systemImage: "lock.trianglebadge.exclamationmark")
                    .foregroundStyle(.orange)
                Text("macOS 허용 후 다시 확인하세요.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("다시 확인") {
                        settings.refreshStatus(force: true)
                    }
                    Button("다시 연결") {
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
