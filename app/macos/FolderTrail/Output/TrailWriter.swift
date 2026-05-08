import Foundation

struct TrailArtifacts: Equatable {
    let trailJSON: URL
    let summaryMarkdown: URL
    let runtimeStatusJSON: URL
}

struct TrailCounters: Codable, Equatable {
    let folders_created: Int
    let files_moved: Int
    let files_renamed: Int
    let review_needed: Int
}

struct FolderTrailRecord: Codable, Equatable {
    let foldertrail_version: String
    let run_id: String
    let started_at: String
    let completed_at: String
    let interrupted: Bool
    let source_folder: String
    let workspace_folder: String
    let user_prompt: String
    let provider: String
    let model: String
    let manifest_detail_level: String
    let actions_executed: [ActionExecutionLog]
    let rejected_actions: [RejectedAction]
    let validation_errors: [ValidationError]
    let summary: TrailCounters
}

struct RuntimeStatusRecord: Codable, Equatable {
    let run_id: String
    let workspace: String
    let source: String
    let current_status: String
    let counters: TrailCounters
}

final class TrailWriter {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func write(
        trail: ExecutionTrail,
        workspaceURL: URL,
        sourceFolderPath: String,
        userPrompt: String,
        provider: String,
        model: String,
        manifestDetailLevel: String,
        summaryText: String
    ) throws -> TrailArtifacts {
        let folderTrailURL = workspaceURL.appendingPathComponent(".foldertrail", isDirectory: true)
        try fileManager.createDirectory(at: folderTrailURL, withIntermediateDirectories: true)

        let runID = makeRunID()
        let now = ISO8601DateFormatter().string(from: Date())
        let counters = Self.counters(from: trail)
        let record = FolderTrailRecord(
            foldertrail_version: "0.1",
            run_id: runID,
            started_at: now,
            completed_at: now,
            interrupted: trail.interrupted,
            source_folder: sourceFolderPath,
            workspace_folder: workspaceURL.path,
            user_prompt: userPrompt,
            provider: provider,
            model: model,
            manifest_detail_level: manifestDetailLevel,
            actions_executed: trail.action_logs,
            rejected_actions: trail.rejected_actions,
            validation_errors: trail.validation_errors,
            summary: counters
        )

        let trailJSON = folderTrailURL.appendingPathComponent("trail.json")
        let summaryMarkdown = folderTrailURL.appendingPathComponent("summary.md")
        let runtimeStatusJSON = folderTrailURL.appendingPathComponent("runtime_status.json")

        let encoder = JSONEncoder()
        try encoder.encode(record).write(to: trailJSON)
        try koreanSummary(summaryText, counters: counters, interrupted: trail.interrupted)
            .write(to: summaryMarkdown, atomically: true, encoding: .utf8)
        try encoder.encode(
            RuntimeStatusRecord(
                run_id: runID,
                workspace: workspaceURL.lastPathComponent,
                source: "foldertrail_app",
                current_status: trail.interrupted ? "interrupted" : "done",
                counters: counters
            )
        ).write(to: runtimeStatusJSON)

        return TrailArtifacts(
            trailJSON: trailJSON,
            summaryMarkdown: summaryMarkdown,
            runtimeStatusJSON: runtimeStatusJSON
        )
    }

    static func parseTrailCounters(from trailJSON: URL) throws -> TrailCounters {
        let data = try Data(contentsOf: trailJSON)
        return try JSONDecoder().decode(FolderTrailRecord.self, from: data).summary
    }

    static func parseTrailCountersOrFallback(from trailJSON: URL) -> TrailCounters {
        (try? parseTrailCounters(from: trailJSON)) ?? TrailCounters(
            folders_created: 0,
            files_moved: 0,
            files_renamed: 0,
            review_needed: 0
        )
    }

    private static func counters(from trail: ExecutionTrail) -> TrailCounters {
        let successes = trail.action_logs.filter { $0.status == "success" }
        return TrailCounters(
            folders_created: successes.filter { $0.type == "create_folder" }.count,
            files_moved: successes.filter { $0.type == "move" }.count,
            files_renamed: successes.filter { $0.type == "rename" }.count,
            review_needed: successes.filter { $0.type == "mark_review_needed" }.count
        )
    }

    private func makeRunID() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd"
        return "ft_\(formatter.string(from: Date()))_\(UUID().uuidString.prefix(6))"
    }

    private func koreanSummary(
        _ summaryText: String,
        counters: TrailCounters,
        interrupted: Bool
    ) -> String {
        """
        # FolderTrail 결과

        \(interrupted ? "작업이 중단되었습니다." : summaryText)

        - 생성한 폴더: \(counters.folders_created)
        - 이동한 파일: \(counters.files_moved)
        - 이름 변경: \(counters.files_renamed)
        - 검토 필요: \(counters.review_needed)
        """
    }
}
