import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = FolderTrailServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setServicesProvider(serviceProvider)
        FolderTrailAppController.shared.openDevelopmentPromptIfNeeded()
    }
}

private extension NSApplication {
    func setServicesProvider(_ provider: Any?) {
        servicesProvider = provider
    }
}
