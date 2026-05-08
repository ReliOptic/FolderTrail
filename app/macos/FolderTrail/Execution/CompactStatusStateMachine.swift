import Foundation

enum CompactStatusState: String, Equatable {
    case idle
    case preflight
    case copying_workspace
    case scanning
    case planning
    case organizing
    case writing_trail
    case done
    case needs_review
    case error
}

struct CompactStatusCounters: Equatable {
    let succeeded: Int
    let skipped: Int
    let errors: Int
    let rejected: Int
}

@MainActor
final class CompactStatusStateMachine: ObservableObject {
    private let minimumStagedDuration: TimeInterval = 10

    @Published private(set) var state: CompactStatusState = .idle
    @Published private(set) var counters: CompactStatusCounters?
    @Published private(set) var message = "대기 중"

    var isRunning: Bool {
        switch state {
        case .preflight, .copying_workspace, .scanning, .planning, .organizing, .writing_trail:
            return true
        case .idle, .done, .needs_review, .error:
            return false
        }
    }

    func beginPreflight() {
        transition(to: .preflight, message: "안전 조건을 확인하고 있습니다")
    }

    func beginCopyingWorkspace() {
        transition(to: .copying_workspace, message: "안전 복사본을 만들고 있습니다")
    }

    func beginScanning() {
        transition(to: .scanning, message: "폴더 구조를 살펴보고 있습니다")
    }

    func beginProviderExecution() {
        transition(to: .planning, message: "정리 계획을 준비하고 있습니다")
    }

    func advanceStagedActivity(elapsed: TimeInterval) {
        guard elapsed >= minimumStagedDuration else { return }

        switch state {
        case .planning:
            transition(to: .organizing, message: "안전한 작업 폴더에서 정리하고 있습니다")
        case .organizing:
            transition(to: .writing_trail, message: "작업 기록을 정리하고 있습니다")
        default:
            break
        }
    }

    func finish(trail: ExecutionTrail, elapsed: TimeInterval) {
        counters = CompactStatusCounters(
            succeeded: trail.action_logs.filter { $0.status == "success" }.count,
            skipped: trail.action_logs.filter { $0.status == "skipped" }.count,
            errors: trail.action_logs.filter { $0.status == "error" }.count,
            rejected: trail.rejected_actions.count + trail.validation_errors.count
        )

        if trail.interrupted || counters?.errors ?? 0 > 0 {
            transition(to: .error, message: "작업이 중단되었거나 오류가 있습니다")
            return
        }

        if (counters?.rejected ?? 0) > 0 {
            transition(to: .needs_review, message: "검토가 필요한 항목이 있습니다")
            return
        }

        if elapsed < minimumStagedDuration {
            transition(to: .done, message: "정리가 완료되었습니다")
            return
        }

        transition(to: .done, message: "정리가 완료되었습니다")
    }

    func fail(_ reason: String) {
        counters = nil
        transition(to: .error, message: reason)
    }

    private func transition(to newState: CompactStatusState, message: String) {
        state = newState
        self.message = message
    }
}
