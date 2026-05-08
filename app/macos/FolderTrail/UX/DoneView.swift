import AppKit
import SwiftUI

struct DoneView: View {
    let workspaceURL: URL
    let sourceFolderURL: URL
    let counters: TrailCounters
    let interrupted: Bool
    @ObservedObject var stateMachine: CompactStatusStateMachine

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if interrupted {
                Text("작업이 중단되었습니다")
                    .font(.headline)
                    .foregroundStyle(.orange)
            }

            Text("완료")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("folders_created: \(counters.folders_created)")
                Text("files_moved: \(counters.files_moved)")
                Text("files_renamed: \(counters.files_renamed)")
                Text("review_needed: \(counters.review_needed)")
            }

            HStack {
                Button("결과 폴더 열기") {
                    NSWorkspace.shared.open(workspaceURL)
                }

                Button("이 폴더로 다시 실행") {
                    stateMachine.resetToIdle()
                }

                Button("닫기") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(20)
    }
}
