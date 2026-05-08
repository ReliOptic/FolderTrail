import Foundation

final class WorkspaceCopyService {
    static func workspaceFolderName(for sourceFolderURL: URL) -> String {
        let baseName = sourceFolderURL.lastPathComponent.isEmpty
            ? "FolderTrail Workspace"
            : sourceFolderURL.lastPathComponent
        return "\(baseName) FolderTrail Workspace"
    }

    func workspaceURL(for sourceFolderURL: URL) -> URL {
        sourceFolderURL
            .deletingLastPathComponent()
            .appendingPathComponent(Self.workspaceFolderName(for: sourceFolderURL), isDirectory: true)
    }

    func startCopy(sourceFolderURL: URL) -> URL {
        workspaceURL(for: sourceFolderURL)
    }
}
