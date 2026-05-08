import Foundation

struct ExecutionTrail: Codable, Equatable {
    let plan_version: String
    var interrupted: Bool
    var action_logs: [ActionExecutionLog]
    var rejected_actions: [RejectedAction]
    var validation_errors: [ValidationError]
}

struct ActionExecutionLog: Codable, Equatable {
    let type: String
    let status: String
    let path: String?
    let from: String?
    let to: String?
    let reason: String?
}

struct RejectedAction: Codable, Equatable {
    let type: String
    let reason: String
}

struct ValidationError: Codable, Equatable {
    let type: String
    let path: String
    let reason: String
}

final class SafeExecutor {
    private static let allowedActionTypes = [
        "create_folder",
        "move",
        "rename",
        "copy",
        "write_summary",
        "mark_review_needed",
    ]

    private let workspaceURL: URL
    private let fileManager: FileManager
    private let shouldStop: () -> Bool

    init(
        workspaceURL: URL,
        fileManager: FileManager = .default,
        shouldStop: @escaping () -> Bool = { false }
    ) {
        self.workspaceURL = workspaceURL.standardizedFileURL
        self.fileManager = fileManager
        self.shouldStop = shouldStop
    }

    func execute(_ plan: ActionPlan) throws -> ExecutionTrail {
        var trail = ExecutionTrail(
            plan_version: plan.plan_version,
            interrupted: false,
            action_logs: [],
            rejected_actions: [],
            validation_errors: []
        )

        let validations = validate(plan.actions)
        trail.rejected_actions = validations.rejected
        trail.validation_errors = validations.errors

        for action in validations.allowed {
            if shouldStop() {
                trail.interrupted = true
                trail.action_logs.append(
                    ActionExecutionLog(
                        type: action.type,
                        status: "skipped",
                        path: action.path,
                        from: action.from,
                        to: action.to,
                        reason: "interrupted"
                    )
                )
                break
            }

            do {
                try executeAllowed(action)
                trail.action_logs.append(
                    ActionExecutionLog(
                        type: action.type,
                        status: "success",
                        path: action.path,
                        from: action.from,
                        to: action.to,
                        reason: nil
                    )
                )
            } catch {
                trail.action_logs.append(
                    ActionExecutionLog(
                        type: action.type,
                        status: "error",
                        path: action.path,
                        from: action.from,
                        to: action.to,
                        reason: error.localizedDescription
                    )
                )
            }
        }

        try writeTrail(trail)
        return trail
    }

    private func validate(_ actions: [PlanAction]) -> (
        allowed: [PlanAction],
        rejected: [RejectedAction],
        errors: [ValidationError]
    ) {
        var allowed: [PlanAction] = []
        var rejected: [RejectedAction] = []
        var errors: [ValidationError] = []

        for action in actions {
            guard Self.allowedActionTypes.contains(action.type) else {
                rejected.append(RejectedAction(type: action.type, reason: "action_type_not_allowed"))
                continue
            }

            let paths = [action.path, action.from, action.to].compactMap { $0 }
            let invalidPath = paths.first { !isPathInsideWorkspace($0) }
            if let invalidPath {
                errors.append(
                    ValidationError(
                        type: action.type,
                        path: invalidPath,
                        reason: "path_outside_workspace"
                    )
                )
                continue
            }

            allowed.append(action)
        }

        return (allowed, rejected, errors)
    }

    private func executeAllowed(_ action: PlanAction) throws {
        switch action.type {
        case "create_folder":
            try fileManager.createDirectory(
                at: resolvedURL(action.path),
                withIntermediateDirectories: true
            )
        case "move", "rename":
            try fileManager.moveItem(at: resolvedURL(action.from), to: resolvedURL(action.to))
        case "copy":
            try fileManager.copyItem(at: resolvedURL(action.from), to: resolvedURL(action.to))
        case "write_summary":
            let targetURL = try resolvedURL(action.path)
            try fileManager.createDirectory(
                at: targetURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try (action.content ?? "").write(to: targetURL, atomically: true, encoding: .utf8)
        case "mark_review_needed":
            try fileManager.createDirectory(
                at: reviewDirectoryURL,
                withIntermediateDirectories: true
            )
            let sourceURL = try resolvedURL(action.path)
            let destinationURL = reviewDirectoryURL.appendingPathComponent(sourceURL.lastPathComponent)
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
        default:
            break
        }
    }

    private var reviewDirectoryURL: URL {
        workspaceURL.appendingPathComponent("_review_before_delete", isDirectory: true)
    }

    private func resolvedURL(_ path: String?) throws -> URL {
        guard let path else {
            throw CocoaError(.fileNoSuchFile)
        }
        return workspaceURL.appendingPathComponent(path).standardizedFileURL
    }

    private func isPathInsideWorkspace(_ path: String) -> Bool {
        guard !path.hasPrefix("/") else { return false }
        guard !path.split(separator: "/").contains("..") else { return false }

        let resolved = workspaceURL.appendingPathComponent(path).standardizedFileURL.path
        let root = workspaceURL.standardizedFileURL.path
        return resolved == root || resolved.hasPrefix(root + "/")
    }

    private func writeTrail(_ trail: ExecutionTrail) throws {
        let data = try JSONEncoder().encode(trail)
        try data.write(to: workspaceURL.appendingPathComponent("trail.json"))
    }
}
