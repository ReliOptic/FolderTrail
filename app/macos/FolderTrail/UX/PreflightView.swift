import AppKit
import SwiftUI

@MainActor
struct PreflightView: View {
    let folderURL: URL
    let workspaceMode: WorkspacePreparationMode

    @ObservedObject private var runner: PreflightRunner
    private let onProceed: () -> Void

    init(folderURL: URL) {
        self.init(
            folderURL: folderURL,
            workspaceMode: .copiedWorkspace,
            runner: PreflightRunner(),
            onProceed: {}
        )
    }

    init(
        folderURL: URL,
        workspaceMode: WorkspacePreparationMode = .copiedWorkspace,
        runner: PreflightRunner,
        onProceed: @escaping () -> Void
    ) {
        self.folderURL = folderURL
        self.workspaceMode = workspaceMode
        self.onProceed = onProceed
        _runner = ObservedObject(wrappedValue: runner)
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

            recoveryActions
            footerAction
        }
        .task {
            await runner.run(for: folderURL, workspaceMode: preflightWorkspaceMode)
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
    private var footerAction: some View {
        if runner.canProceedToConsent {
            Button("복사본 만들고 계속") {
                onProceed()
            }
            .buttonStyle(FolderTrailPrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)
        } else {
            Text("필수 항목을 먼저 처리해 주세요.")
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

            if hasFailed(.codexAuthenticated) {
                codexLoginRecovery
            }
        }
    }

    private var codexLoginRecovery: some View {
        CodexChatGPTOAuthView(onRecheck: rerunPreflight)
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

    private func rerunPreflight() {
        Task {
            await runner.run(for: folderURL, workspaceMode: preflightWorkspaceMode)
        }
    }

    private var preflightWorkspaceMode: PreflightWorkspaceMode {
        workspaceMode == .copiedWorkspace ? .copiedWorkspace : .directSource
    }
}
