import Combine
import Foundation

enum FolderTrailPromptRunStatus: Equatable {
    case idle
    case running
    case done
    case failed
}

@MainActor
final class FolderTrailPromptRunModel: ObservableObject {
    typealias RunPipeline = (String, URL) async throws -> FolderTrailRunResult

    @Published private(set) var status: FolderTrailPromptRunStatus = .idle
    @Published private(set) var result: FolderTrailRunResult?
    @Published private(set) var errorMessage: String?

    private let runPipeline: RunPipeline

    init(
        runPipeline: @escaping RunPipeline = { prompt, sourceFolderURL in
            try await FolderTrailRunPipeline(planner: CodexPlannerAdapter())
                .run(prompt: prompt, sourceFolderURL: sourceFolderURL)
        }
    ) {
        self.runPipeline = runPipeline
    }

    func run(prompt: String, sourceFolderURL: URL) async {
        guard status != .running else { return }

        status = .running
        result = nil
        errorMessage = nil

        do {
            result = try await runPipeline(prompt, sourceFolderURL)
            status = .done
        } catch {
            errorMessage = Self.message(for: error)
            status = .failed
        }
    }

    private static func message(for error: Error) -> String {
        switch error {
        case PlannerAdapterError.authFailure:
            return "Codex 로그인 후 다시 시도해 주세요."
        case PlannerAdapterError.invalidJSON, PlannerAdapterError.schemaMismatch:
            return "다시 시도해 주세요."
        default:
            return "다시 시도해 주세요."
        }
    }
}
