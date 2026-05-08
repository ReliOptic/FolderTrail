import AppKit
import SwiftUI

@MainActor
final class FolderTrailAppController {
    static let shared = FolderTrailAppController()

    private var promptPanel: NSPanel?
    private var hasOpenedDevelopmentPrompt = false

    private init() {}

    func openDevelopmentPromptIfNeeded() {
        guard !hasOpenedDevelopmentPrompt else { return }
        hasOpenedDevelopmentPrompt = true
        openPrompt(for: FileManager.default.homeDirectoryForCurrentUser)
    }

    func openPrompt(for folderURL: URL) {
        if promptPanel == nil {
            promptPanel = makePromptPanel()
        }

        promptPanel?.contentView = NSHostingView(rootView: PlaceholderPromptView(folderURL: folderURL))
        promptPanel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "FolderTrail"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }

    private func makePromptPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 360),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "FolderTrail"
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.transient, .ignoresCycle]
        panel.center()
        return panel
    }
}
