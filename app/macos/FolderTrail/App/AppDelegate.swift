import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = FolderTrailServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setServicesProvider(serviceProvider)
        NSUpdateDynamicServices()
        FolderTrailAppController.shared.openDevelopmentPromptIfNeeded()
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if flag {
            FolderTrailAppController.shared.bringPromptToFront()
        } else {
            FolderTrailAppController.shared.openPrompt(for: FileManager.default.homeDirectoryForCurrentUser)
        }
        return true
    }
}

private extension NSApplication {
    func setServicesProvider(_ provider: Any?) {
        servicesProvider = provider
    }
}
