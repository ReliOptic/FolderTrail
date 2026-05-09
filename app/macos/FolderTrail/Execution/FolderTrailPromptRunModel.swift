import Combine
import Foundation

enum FolderTrailPromptRunStatus: Equatable {
    case idle
    case running
    case done
    case failed
    case cancelled
}

@MainActor
final class FolderTrailPromptRunModel: ObservableObject {
    typealias RunPipeline = (String, URL, @escaping FolderTrailRunPipeline.StateObserver) async throws -> FolderTrailRunResult

    @Published private(set) var status: FolderTrailPromptRunStatus = .idle
    @Published private(set) var result: FolderTrailRunResult?
    @Published private(set) var errorMessage: String?
    @Published private(set) var stepText = "대기 중"
    @Published private(set) var elapsedSeconds = 0

    private let runPipeline: RunPipeline
    private var activeRunTask: Task<Void, Never>?
    private var elapsedTask: Task<Void, Never>?

    init(
        runPipeline: @escaping RunPipeline = { prompt, sourceFolderURL, onState in
            try await FolderTrailRunPipeline(
                planner: CodexPlannerAdapter(),
                onState: onState
            )
                .run(prompt: prompt, sourceFolderURL: sourceFolderURL)
        }
    ) {
        self.runPipeline = runPipeline
    }

    deinit {
        activeRunTask?.cancel()
        elapsedTask?.cancel()
    }

    func run(prompt: String, sourceFolderURL: URL) async {
        start(prompt: prompt, sourceFolderURL: sourceFolderURL)
        await activeRunTask?.value
    }

    func start(prompt: String, sourceFolderURL: URL) {
        guard status != .running else { return }

        status = .running
        result = nil
        errorMessage = nil
        elapsedSeconds = 0
        stepText = "준비 중"
        startElapsedTimer()

        activeRunTask?.cancel()
        activeRunTask = Task { [runPipeline] in
            do {
                let runResult = try await runPipeline(prompt, sourceFolderURL) { state in
                    Task { @MainActor in
                        self.apply(state)
                    }
                }
                guard !Task.isCancelled else {
                    finishCancelled()
                    return
                }
                result = runResult
                stepText = "완료"
                status = .done
                stopElapsedTimer()
            } catch is CancellationError {
                finishCancelled()
            } catch {
                errorMessage = Self.message(for: error)
                status = .failed
                stopElapsedTimer()
            }
        }
    }

    func cancel() {
        guard status == .running else { return }
        activeRunTask?.cancel()
        finishCancelled()
    }

    private func startElapsedTimer() {
        elapsedTask?.cancel()
        elapsedTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }
                elapsedSeconds += 1
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTask?.cancel()
        elapsedTask = nil
    }

    private func finishCancelled() {
        activeRunTask?.cancel()
        errorMessage = "취소했습니다."
        stepText = "취소됨"
        status = .cancelled
        stopElapsedTimer()
    }

    private func apply(_ state: FolderTrailRunState) {
        guard status == .running else { return }
        stepText = Self.stepText(for: state)
    }

    private static func stepText(for state: FolderTrailRunState) -> String {
        switch state {
        case .promptReceived:
            return "요청 확인 중"
        case .workspaceReady:
            return "복사본 준비 중"
        case .manifestBuilt:
            return "목록 확인 중"
        case .planReady:
            return "계획 준비됨"
        case .executing:
            return "정리 적용 중"
        case .trailWritten:
            return "기록 저장 중"
        case .done:
            return "완료"
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
