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
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.md) {
            Text("정리 전 확인")
                .font(FolderTrailDesign.Typography.section)

            FolderTrailPanel {
                ScrollView {
                    preflightRows
                }
                .frame(maxHeight: 220)
            }

            fallbackNote
            recoveryActions
            footerAction
        }
        .task {
            await runner.run(for: folderURL)
        }
    }

    private var preflightRows: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.sm) {
            ForEach(runner.checks) { check in
                HStack(alignment: .top, spacing: 8) {
                    Text(symbol(for: check.result))
                        .monospacedDigit()
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: FolderTrailDesign.Spacing.xs) {
                            Text(check.title)
                            Text(statusLabel(for: check.result))
                                .font(FolderTrailDesign.Typography.badge)
                                .foregroundStyle(statusColor(for: check.result))
                        }
                        if case .failed(let reason) = check.result {
                            Text(reason)
                                .font(FolderTrailDesign.Typography.meta)
                                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
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
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
        }
    }

    @ViewBuilder
    private var footerAction: some View {
        if runner.canProceedToConsent {
            Button("복사본 만들고 계속") {
                onProceed()
            }
            .buttonStyle(FolderTrailPrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)
        } else {
            Text("조치가 필요한 항목을 해결하기 전에는 계속할 수 없습니다.")
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
        }
    }

    private var recoveryActions: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.sm) {
            if hasFailed(.folderReadable) {
                Button("시스템 설정 열기") {
                    openPrivacySettings()
                }
            }

            if hasFailed(.providerConnected) {
                ProviderConnectView(settings: providerSettings)
            }

            if hasFailed(.codexAuthenticated) {
                codexLoginRecovery
            }
        }
    }

    private var codexLoginRecovery: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.xs) {
            Text("터미널에서 `codex login`을 실행하고 OAuth 로그인을 완료해 주세요. 토큰을 FolderTrail에 붙여넣지 마세요.")
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)

            HStack(spacing: FolderTrailDesign.Spacing.sm) {
                Button("codex login 명령 복사") {
                    copyCodexLoginCommand()
                }

                Button("다시 확인") {
                    rerunPreflight()
                }
            }
            .controlSize(.small)
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
            return FolderTrailDesign.Palette.success
        case .pending:
            return FolderTrailDesign.Palette.secondaryText
        case .failed:
            return FolderTrailDesign.Palette.warning
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

    private func copyCodexLoginCommand() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString("codex login", forType: .string)
    }

    private func rerunPreflight() {
        Task {
            await runner.run(for: folderURL)
        }
    }
}
