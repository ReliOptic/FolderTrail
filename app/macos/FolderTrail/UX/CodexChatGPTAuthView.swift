import AppKit
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
                Text("로컬 도우미")
                    .font(FolderTrailDesign.Typography.body.weight(.semibold))
                Label("Codex / ChatGPT OAuth", systemImage: "terminal")
                    .font(FolderTrailDesign.Typography.meta.weight(.semibold))
                Text("OpenRouter와 별개 로그인입니다. OpenRouter는 AI 제공자 연결이고, Codex / ChatGPT OAuth는 로컬 도우미를 브라우저에서 연결합니다. 토큰을 FolderTrail에 붙여넣지 마세요.")
                    .font(FolderTrailDesign.Typography.meta)
                    .foregroundStyle(FolderTrailDesign.Palette.secondaryText)
            }

            HStack(spacing: FolderTrailDesign.Spacing.sm) {
                Button(style == .compact ? "로그인" : "Codex / ChatGPT 로그인") {
                    loginRunner.start()
                }
                .disabled(loginRunner.isRunning)

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

@MainActor
final class CodexLoginRunner: ObservableObject {
    @Published private(set) var isRunning = false
    @Published private(set) var statusText = "브라우저에서 로그인을 마치면 FolderTrail이 확인합니다."

    func start() {
        guard !isRunning else { return }

        isRunning = true
        statusText = "브라우저를 열고 있어요…"

        Task {
            let succeeded = await Self.runLoginProcess { url in
                Task { @MainActor in
                    NSWorkspace.shared.open(url)
                    self.statusText = "브라우저에서 로그인을 마치면 FolderTrail이 확인합니다."
                }
            }

            isRunning = false
            statusText = succeeded
                ? "로그인 완료"
                : "로그인을 확인하지 못했습니다. 다시 시도해 주세요."
        }
    }

    nonisolated private static func runLoginProcess(openURL: @escaping @Sendable (URL) -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            let state = CodexLoginProcessState(continuation: continuation)
            let process = Process()
            let outputPipe = Pipe()

            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-lc", "codex login"]
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            outputPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty,
                      let text = String(data: data, encoding: .utf8),
                      let url = extractAuthURL(from: text)
                else { return }

                state.openOnce(url, openURL: openURL)
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

    nonisolated static func extractAuthURL(from text: String) -> URL? {
        text
            .split(whereSeparator: { $0.isWhitespace })
            .compactMap { URL(string: String($0)) }
            .first { url in
                url.scheme?.hasPrefix("http") == true
                    && url.host?.contains("auth.openai.com") == true
            }
    }
}

private final class CodexLoginProcessState: @unchecked Sendable {
    private let lock = NSLock()
    private var didFinish = false
    private var didOpenURL = false
    private let continuation: CheckedContinuation<Bool, Never>

    init(continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
    }

    func openOnce(_ url: URL, openURL: @Sendable (URL) -> Void) {
        lock.lock()
        let shouldOpen = !didOpenURL
        didOpenURL = true
        lock.unlock()

        if shouldOpen {
            openURL(url)
        }
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
