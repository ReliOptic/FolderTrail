import Foundation
import SwiftUI

struct CodexChatGPTOAuthView: View {
    enum Style {
        case full
        case compact
    }

    var style: Style = .full
    var onRecheck: (() -> Void)? = nil

    @StateObject private var loginRunner = CodexLoginRunner()

    var body: some View {
        VStack(alignment: .leading, spacing: FolderTrailDesign.Spacing.xs) {
            if style == .full {
                Text("Codex")
                    .font(FolderTrailDesign.Typography.body.weight(.semibold))
                Label("Codex 로그인", systemImage: "terminal")
                    .font(FolderTrailDesign.Typography.meta.weight(.semibold))
                Text("브라우저에서 로그인하세요.")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            }

            HStack(spacing: FolderTrailDesign.Spacing.sm) {
                Button("로그인") {
                    loginRunner.start(onSuccess: onRecheck)
                }
                .disabled(loginRunner.isRunning || loginRunner.isAuthenticated)

                if loginRunner.isRunning {
                    ProgressView()
                        .controlSize(.small)
                }

                if let onRecheck {
                    Button("다시 확인") {
                        onRecheck()
                    }
                }
            }
            .controlSize(.small)

            Text(loginRunner.statusText)
                .font(FolderTrailDesign.Typography.meta)
                .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
        }
        .task { await loginRunner.refreshExistingLoginStatus() }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

@MainActor
final class CodexLoginRunner: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var isAuthenticated = false
    @Published private(set) var statusText = "로그인 후 자동 확인합니다."

    func refreshExistingLoginStatus() async {
        guard !isRunning else { return }
        if await Self.isAlreadyAuthenticated() {
            markAuthenticated()
        }
    }

    func start(onSuccess: (() -> Void)? = nil) {
        guard !isRunning else { return }

        isRunning = true
        statusText = "확인 중…"

        Task {
            guard !(await Self.isAlreadyAuthenticated()) else {
                isRunning = false
                markAuthenticated()
                onSuccess?()
                return
            }

            statusText = "브라우저에서 로그인하세요."
            let succeeded = await Self.runLoginProcess()

            if succeeded {
                statusText = "확인 중…"
                let authenticated = await Self.recheckLoginStatusAfterSuccess()
                isRunning = false

                if authenticated {
                    markAuthenticated()
                } else {
                    isAuthenticated = false
                    statusText = "다시 확인해 주세요."
                }
                onSuccess?()
            } else {
                isRunning = false
                isAuthenticated = false
                statusText = "다시 시도해 주세요."
            }
        }
    }

    private func markAuthenticated() {
        isAuthenticated = true
        statusText = "로그인 완료"
    }

    nonisolated private static func isAlreadyAuthenticated() async -> Bool {
        await Task.detached(priority: .userInitiated) {
            PreflightCheck.isCodexAuthenticated()
        }.value
    }

    nonisolated private static func recheckLoginStatusAfterSuccess() async -> Bool {
        await Task.detached(priority: .userInitiated) {
            PreflightCheck.isCodexAuthenticated()
        }.value
    }

    nonisolated private static func runLoginProcess() async -> Bool {
        await withCheckedContinuation { continuation in
            let state = CodexLoginProcessState(continuation: continuation)
            let process = Process()
            let outputPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", "codex login"]
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                _ = handle.availableData
            }

            process.terminationHandler = { finishedProcess in
                outputPipe.fileHandleForReading.readabilityHandler = nil
                state.finish(finishedProcess.terminationStatus == 0)
            }

            do {
                try process.run()
            } catch {
                outputPipe.fileHandleForReading.readabilityHandler = nil
                state.finish(false)
                return
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 180) {
                if process.isRunning {
                    process.terminate()
                    state.finish(false)
                }
            }
        }
    }
}

private final class CodexLoginProcessState: @unchecked Sendable {
    private let lock = NSLock()
    private var didFinish = false
    private let continuation: CheckedContinuation<Bool, Never>

    init(continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    func finish(_ result: Bool) {
        lock.lock()
        let shouldFinish = !didFinish
        didFinish = true
        lock.unlock()

        if shouldFinish {
            continuation.resume(returning: result)
        }
    }
}
