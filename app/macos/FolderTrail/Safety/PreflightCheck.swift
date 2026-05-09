import Foundation

enum PreflightCheckResult: Equatable {
    case pending
    case passed
    case failed(reason: String)

    var isPassed: Bool {
        if case .passed = self {
            return true
        }
        return false
    }
}

enum PreflightCheckID: String, CaseIterable {
    case folderReadable
    case workspaceWritable
    case codexAvailable
    case codexAuthenticated

    var title: String {
        switch self {
        case .folderReadable:
            return "폴더를 읽을 수 있음"
        case .workspaceWritable:
            return "작업 복사본을 만들 수 있음"
        case .codexAvailable:
            return "Codex CLI 설치됨"
        case .codexAuthenticated:
            return "Codex / ChatGPT 로그인됨"
        }
    }

    var blocksProceed: Bool {
        switch self {
        case .folderReadable, .workspaceWritable, .codexAvailable, .codexAuthenticated:
            return true
        }
    }
}

struct PreflightCheckState: Identifiable, Equatable {
    let id: PreflightCheckID
    var result: PreflightCheckResult

    var title: String {
        id.title
    }
}

enum PreflightCheck {
    private static let codexExecutableName = "codex"
    private static let codexCommandTimeout: TimeInterval = 4

    static func runAll(
        for folderURL: URL,
        fileManager: FileManager = .default
    ) -> [PreflightCheckState] {
        return PreflightCheckID.allCases.map { checkID in
            PreflightCheckState(
                id: checkID,
                result: run(
                    checkID,
                    folderURL: folderURL,
                    fileManager: fileManager
                )
            )
        }
    }

    static func pendingChecks() -> [PreflightCheckState] {
        PreflightCheckID.allCases.map {
            PreflightCheckState(id: $0, result: .pending)
        }
    }

    static func allPassed(_ checks: [PreflightCheckState]) -> Bool {
        checks.allSatisfy { $0.result.isPassed }
    }

    static func canProceedToConsent(_ checks: [PreflightCheckState]) -> Bool {
        checks.filter { $0.id.blocksProceed }.allSatisfy { $0.result.isPassed }
    }

    private static func run(
        _ checkID: PreflightCheckID,
        folderURL: URL,
        fileManager: FileManager
    ) -> PreflightCheckResult {
        switch checkID {
        case .folderReadable:
            return checkFolderReadable(folderURL, fileManager: fileManager)
        case .workspaceWritable:
            return checkSiblingWorkspaceWritable(folderURL, fileManager: fileManager)
        case .codexAvailable:
            return checkCodexAvailable()
        case .codexAuthenticated:
            return checkCodexAuthenticated()
        }
    }

    private static func checkFolderReadable(
        _ folderURL: URL,
        fileManager: FileManager
    ) -> PreflightCheckResult {
        fileManager.isReadableFile(atPath: folderURL.path)
            ? .passed
            : .failed(reason: "이 폴더를 아직 읽을 수 없습니다.")
    }

    private static func checkSiblingWorkspaceWritable(
        _ folderURL: URL,
        fileManager: FileManager
    ) -> PreflightCheckResult {
        let parentURL = folderURL.deletingLastPathComponent()
        let probeURL = parentURL.appendingPathComponent(
            ".foldertrail-preflight-\(UUID().uuidString)",
            isDirectory: true
        )

        do {
            try fileManager.createDirectory(
                at: probeURL,
                withIntermediateDirectories: false
            )
            try fileManager.removeItem(at: probeURL)
            return .passed
        } catch {
            try? fileManager.removeItem(at: probeURL)
            return .failed(reason: "이 폴더 옆에 작업 복사본을 만들 수 없습니다.")
        }
    }

    private static func checkCodexAvailable() -> PreflightCheckResult {
        if firstWorkingCodexExecutableURL() != nil {
            return .passed
        }

        let loginShellCommand = """
        command -v \(codexExecutableName) >/dev/null && \(codexExecutableName) --version >/dev/null
        """

        if runCodexVersion(
            executableURL: URL(fileURLWithPath: "/bin/zsh"),
            arguments: ["-lc", loginShellCommand]
        ) {
            return .passed
        }

        return .failed(
            reason: "앱 환경에서 `codex --version`이 성공하지 않았습니다."
        )
    }

    static func isCodexAuthenticated() -> Bool {
        // Keep OAuth/auth failure separate from install failure by running codex login status.
        if let candidateURL = firstWorkingCodexExecutableURL(), runCodexLoginStatus(
            executableURL: candidateURL,
            arguments: ["login", "status"]
        ) {
            return true
        }

        let loginShellCommand = """
        command -v \(codexExecutableName) >/dev/null && \(codexExecutableName) login status >/dev/null
        """

        return runCodexLoginStatus(
            executableURL: URL(fileURLWithPath: "/bin/zsh"),
            arguments: ["-lc", loginShellCommand]
        )
    }

    private static func checkCodexAuthenticated() -> PreflightCheckResult {
        if isCodexAuthenticated() {
            return .passed
        }

        return .failed(
            reason: "Codex CLI는 설치되어 있지만 로그인되어 있지 않습니다. 터미널에서 `codex login`으로 OAuth 로그인을 완료한 뒤 다시 시도해 주세요."
        )
    }

    private static func firstWorkingCodexExecutableURL() -> URL? {
        codexCandidateURLs().first {
            runCodexVersion(executableURL: $0, arguments: ["--version"])
        }
    }

    private static func codexCandidateURLs() -> [URL] {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser

        return [
            URL(fileURLWithPath: "/opt/homebrew/bin/codex"),
            URL(fileURLWithPath: "/usr/local/bin/codex"),
            homeDirectory.appendingPathComponent(".local/bin/codex"),
            homeDirectory.appendingPathComponent(".bun/bin/codex")
        ]
    }

    private static func runCodexVersion(executableURL: URL, arguments: [String]) -> Bool {
        runCodexCommand(executableURL: executableURL, arguments: arguments)
    }

    private static func runCodexLoginStatus(executableURL: URL, arguments: [String]) -> Bool {
        runCodexCommand(executableURL: executableURL, arguments: arguments)
    }

    private static func runCodexCommand(
        executableURL: URL,
        arguments: [String],
        timeout: TimeInterval = codexCommandTimeout
    ) -> Bool {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            let deadline = Date().addingTimeInterval(timeout)
            while process.isRunning, Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }

            if process.isRunning {
                process.terminate()
                return false
            }

            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

@MainActor
final class PreflightRunner: ObservableObject {
    @Published private(set) var checks: [PreflightCheckState] = PreflightCheck.pendingChecks()

    var allPassed: Bool {
        PreflightCheck.allPassed(checks)
    }

    var canProceedToConsent: Bool {
        PreflightCheck.canProceedToConsent(checks)
    }

    func run(for folderURL: URL) async {
        checks = PreflightCheck.pendingChecks()
        let resolvedChecks = await Task.detached(priority: .userInitiated) {
            PreflightCheck.runAll(for: folderURL)
        }.value
        checks = resolvedChecks
    }
}
