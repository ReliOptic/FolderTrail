import SwiftUI

struct CompactStatusView: View {
    @ObservedObject var stateMachine: CompactStatusStateMachine
    let onStop: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label(for: stateMachine.state))
                .font(.headline)
            Text(stateMachine.message)
                .foregroundStyle(.secondary)

            if let counters = stateMachine.counters {
                Text("성공 \(counters.succeeded) · 건너뜀 \(counters.skipped) · 검토 \(counters.rejected)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if stateMachine.isRunning {
                Button("작업 중단", action: onStop)
            }
        }
    }

    private func label(for state: CompactStatusState) -> String {
        switch state {
        case .idle:
            return "대기"
        case .preflight:
            return "안전 확인"
        case .copying_workspace:
            return "복사본 생성"
        case .scanning:
            return "스캔"
        case .planning:
            return "계획"
        case .organizing:
            return "정리"
        case .writing_trail:
            return "기록"
        case .done:
            return "완료"
        case .needs_review:
            return "검토 필요"
        case .error:
            return "오류"
        }
    }
}
