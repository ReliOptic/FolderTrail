import AppKit
import SwiftUI

@MainActor
struct PreflightView: View {
    let folderURL: URL

    @ObservedObject private var runner: PreflightRunner
    @ObservedObject private var providerSettings: OpenRouterProviderSettings
    private let onProceed: () -> Void

    init(folderURL: URL) {
        self.init(
            folderURL: folderURL,
            runner: PreflightRunner(),
            providerSettings: OpenRouterProviderSettings.shared,
            onProceed: {}
        )
    }

    init(
        folderURL: URL,
        runner: PreflightRunner,
        providerSettings: OpenRouterProviderSettings,
        onProceed: @escaping () -> Void
    ) {
        self.folderURL = folderURL
        self.onProceed = onProceed
        _runner = ObservedObject(wrappedValue: runner)
        _providerSettings = ObservedObject(wrappedValue: providerSettings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preflight")
                .font(.headline)

            ForEach(runner.checks) { check in
                HStack(alignment: .top, spacing: 8) {
                    Text(symbol(for: check.result))
                        .monospacedDigit()
                    VStack(alignment: .leading, spacing: 4) {
                        Text(check.title)
                        if case .failed(let reason) = check.result {
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            recoveryActions

            if runner.canProceedToConsent {
                Button("동의 단계로 계속") {
                    onProceed()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .task {
            await runner.run(for: folderURL)
        }
    }

    private var recoveryActions: some View {
        VStack(alignment: .leading, spacing: 8) {
            if hasFailed(.folderReadable) {
                Button("시스템 설정 열기") {
                    openPrivacySettings()
                }
            }

            if hasFailed(.providerConnected) {
                ProviderConnectView(settings: providerSettings)
            }
        }
    }

    private func symbol(for result: PreflightCheckResult) -> String {
        switch result {
        case .passed:
            return "✓"
        case .pending:
            return "◐"
        case .failed:
            return "✗"
        }
    }

    private func hasFailed(_ checkID: PreflightCheckID) -> Bool {
        runner.checks.contains { check in
            check.id == checkID && {
                if case .failed = check.result {
                    return true
                }
                return false
            }()
        }
    }

    private func openPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }
}
