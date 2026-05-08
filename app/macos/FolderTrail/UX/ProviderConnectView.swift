import AppKit
import SwiftUI

struct ProviderConnectView: View {
    @ObservedObject var settings: OpenRouterProviderSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Provider")
                .font(.headline)

            switch settings.status {
            case .connected:
                Label("connected", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(settings.maskedAPIKey)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .notConnected:
                Label("notConnected", systemImage: "circle")
                    .foregroundStyle(.secondary)
                Button("Connect OpenRouter") {
                    connectWithBrowser()
                }
            case .failed(let message):
                Label("failed", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Retry") {
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
