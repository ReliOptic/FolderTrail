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
        VStack(alignment: .leading, spacing: 12) {
            Text("시작 전 확인")
                .font(.headline)

            ScrollView {
                preflightRows
            }
            .frame(maxHeight: 220)

            fallbackNote
            recoveryActions
            footerAction
        }
        .task {
            await runner.run(for: folderURL)
        }
    }

    private var preflightRows: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(runner.checks) { check in
                HStack(alignment: .top, spacing: 8) {
                    Text(symbol(for: check.result))
                        .monospacedDigit()
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(check.title)
                            Text(statusLabel(for: check.result))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(statusColor(for: check.result))
                        }
                        if case .failed(let reason) = check.result {
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var fallbackNote: some View {
        if hasFailed(.codexAvailable) || hasFailed(.codexAuthenticated) {
            Text("Codex fallback은 선택 사항입니다. OpenRouter 연결로 먼저 진행할 수 있습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var footerAction: some View {
        if runner.canProceedToConsent {
            Button("안전 작업공간 만들기") {
                onProceed()
            }
            .keyboardShortcut(.defaultAction)
        } else {
            Text("조치가 필요한 항목을 해결하기 전에는 계속할 수 없습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
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

    private func statusLabel(for result: PreflightCheckResult) -> String {
        switch result {
        case .passed:
            return "통과"
        case .pending:
            return "확인 중"
        case .failed:
            return "조치 필요"
        }
    }

    private func statusColor(for result: PreflightCheckResult) -> Color {
        switch result {
        case .passed:
            return .green
        case .pending:
            return .secondary
        case .failed:
            return .orange
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
