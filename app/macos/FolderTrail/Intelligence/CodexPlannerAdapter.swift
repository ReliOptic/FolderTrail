import Foundation

struct CodexPlannerAdapter: PlannerAdapter {
    struct CLIRequest {
        let executableURL: URL
        let arguments: [String]
        let prompt: String
        let outputURL: URL
        let workingDirectoryURL: URL
    }

    typealias CommandRunner = (CLIRequest) async throws -> String

    static let defaultModel = "codex-cli"
    private static let commandTimeout: TimeInterval = 300

    private let executableURL: URL
    private let workingDirectoryURL: URL
    private let commandRunner: CommandRunner

    init(
        executableURL: URL = URL(fileURLWithPath: "/bin/zsh"),
        workingDirectoryURL: URL = FileManager.default.temporaryDirectory,
        commandRunner: @escaping CommandRunner = CodexPlannerAdapter.runCodex
    ) {
        self.executableURL = executableURL
        self.workingDirectoryURL = workingDirectoryURL
        self.commandRunner = commandRunner
    }

    func plan(prompt: String, manifest: FolderManifest) async throws -> ActionPlan {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("foldertrail-codex-plan-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        let request = CLIRequest(
            executableURL: executableURL,
            arguments: [
                "-lc",
                "codex exec --sandbox read-only --ask-for-approval never --skip-git-repo-check --output-last-message \(Self.shellQuote(outputURL.path)) -",
            ],
            prompt: Self.plannerPrompt(userPrompt: prompt, manifest: manifest),
            outputURL: outputURL,
            workingDirectoryURL: workingDirectoryURL
        )

        let output: String
        do {
            output = try await commandRunner(request)
        } catch PlannerAdapterError.networkFailure {
            throw PlannerAdapterError.networkFailure
        } catch PlannerAdapterError.authFailure {
            throw PlannerAdapterError.authFailure
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw PlannerAdapterError.networkFailure
        }

        guard let data = Self.extractJSONData(from: output) else {
            throw PlannerAdapterError.invalidJSON
        }

        return try OpenRouterPlannerAdapter.decodeActionPlan(from: data)
    }

    private static func plannerPrompt(userPrompt: String, manifest: FolderManifest) -> String {
        let manifestData = (try? JSONEncoder().encode(manifest)) ?? Data("{}".utf8)
        let manifestJSON = String(data: manifestData, encoding: .utf8) ?? "{}"

        return """
        You are FolderTrail Planner.
        Return only ActionPlan JSON.

        Rules:
        - Use plan_version "0.1".
        - Use provider "codex" and model "\(defaultModel)".
        - Do not include delete actions. Use mark_review_needed instead.
        - Only reference paths from the FolderManifest JSON.
        - Do not access parent directories or external paths.
        - Write summary_ko in Korean unless the user explicitly asks otherwise.

        User prompt:
        \(userPrompt)

        FolderManifest JSON:
        \(manifestJSON)
        """
    }

    private static func extractJSONData(from output: String) -> Data? {
        if let direct = output.data(using: .utf8),
           (try? JSONDecoder().decode(ActionPlan.self, from: direct)) != nil {
            return direct
        }

        guard let start = output.firstIndex(of: "{"),
              let end = output.lastIndex(of: "}"),
              start <= end
        else {
            return nil
        }

        return String(output[start...end]).data(using: .utf8)
    }

    private static func shellQuote(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func runCodex(_ request: CLIRequest) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            let stdinPipe = Pipe()

            process.executableURL = request.executableURL
            process.arguments = request.arguments
            process.currentDirectoryURL = request.workingDirectoryURL
            process.standardInput = stdinPipe
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            do {
                try process.run()
                stdinPipe.fileHandleForWriting.write(Data(request.prompt.utf8))
                try? stdinPipe.fileHandleForWriting.close()

                let deadline = Date().addingTimeInterval(commandTimeout)
                while process.isRunning, Date() < deadline {
                    if Task.isCancelled {
                        process.terminate()
                        throw CancellationError()
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)
                }

                if process.isRunning {
                    process.terminate()
                    throw PlannerAdapterError.networkFailure
                }

                let stdout = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderr = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                guard process.terminationStatus == 0 else {
                    let message = String(data: stderr, encoding: .utf8) ?? ""
                    if message.localizedCaseInsensitiveContains("login") {
                        throw PlannerAdapterError.authFailure
                    }
                    throw PlannerAdapterError.networkFailure
                }

                if let lastMessage = try? String(contentsOf: request.outputURL, encoding: .utf8),
                   !lastMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return lastMessage
                }

                return String(data: stdout, encoding: .utf8) ?? ""
            } catch let error as PlannerAdapterError {
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                throw PlannerAdapterError.networkFailure
            }
        }.value
    }
}
