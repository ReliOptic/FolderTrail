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
    case providerConnected
    case codexAvailable
    case codexAuthenticated

    var title: String {
        switch self {
        case .folderReadable:
            return "Folder is readable"
        case .workspaceWritable:
            return "Sibling workspace can be created"
        case .providerConnected:
            return "OpenRouter provider is connected"
        case .codexAvailable:
            return "Codex CLI fallback is available"
        case .codexAuthenticated:
            return "Codex CLI fallback is authenticated"
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

    static func runAll(
        for folderURL: URL,
        fileManager: FileManager = .default
    ) -> [PreflightCheckState] {
        PreflightCheckID.allCases.map { checkID in
            PreflightCheckState(
                id: checkID,
                result: run(checkID, folderURL: folderURL, fileManager: fileManager)
            )
        }
    }

    static func allPassed(_ checks: [PreflightCheckState]) -> Bool {
        checks.allSatisfy { $0.result.isPassed }
    }

    static func canProceedToConsent(_ checks: [PreflightCheckState]) -> Bool {
        allPassed(checks)
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
        case .providerConnected:
            return checkProviderConnected()
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
            : .failed(reason: "FolderTrail cannot read this folder yet.")
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
            return .failed(reason: "FolderTrail cannot create a sibling workspace next to this folder.")
        }
    }

    private static func checkProviderConnected() -> PreflightCheckResult {
        do {
            let savedKey = try OpenRouterKeychain.load()?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return savedKey?.isEmpty == false
                ? .passed
                : .failed(reason: "Connect OpenRouter before running FolderTrail.")
        } catch {
            return .failed(reason: error.localizedDescription)
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
            reason: "`codex --version` did not succeed from the app environment."
        )
    }

    private static func checkCodexAuthenticated() -> PreflightCheckResult {
        // Keep OAuth/auth failure separate from install failure by running codex login status.
        if let candidateURL = firstWorkingCodexExecutableURL(), runCodexLoginStatus(
            executableURL: candidateURL,
            arguments: ["login", "status"]
        ) {
            return .passed
        }

        let loginShellCommand = """
        command -v \(codexExecutableName) >/dev/null && \(codexExecutableName) login status >/dev/null
        """

        if runCodexLoginStatus(
            executableURL: URL(fileURLWithPath: "/bin/zsh"),
            arguments: ["-lc", loginShellCommand]
        ) {
            return .passed
        }

        return .failed(
            reason: "Codex CLI is installed but not authenticated. Run `codex login` in Terminal and finish OAuth, then retry."
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

    private static func runCodexCommand(executableURL: URL, arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}

@MainActor
final class PreflightRunner: ObservableObject {
    @Published private(set) var checks: [PreflightCheckState] = PreflightCheckID.allCases.map {
        PreflightCheckState(id: $0, result: .pending)
    }

    var allPassed: Bool {
        PreflightCheck.allPassed(checks)
    }

    var canProceedToConsent: Bool {
        PreflightCheck.canProceedToConsent(checks)
    }

    func run(for folderURL: URL) async {
        checks = PreflightCheck.runAll(for: folderURL)
    }
}
