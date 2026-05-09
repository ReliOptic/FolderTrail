import Darwin
import Foundation

struct WorkspaceCopyResult: Equatable {
    let sourceFolderURL: URL
    let workspaceURL: URL
}

enum WorkspaceCopyProgress: Equatable {
    case started(sourceFolderURL: URL, workspaceURL: URL)
    case copied(relativePath: String)
    case skipped(relativePath: String)
    case completed(WorkspaceCopyResult)
    case failed(reason: String)
}

enum WorkspaceCopyError: LocalizedError {
    case sourceIsNotReadableDirectory(String)
    case copyFailed(String)

    var errorDescription: String? {
        switch self {
        case .sourceIsNotReadableDirectory(let path):
            return "Source folder is not a readable directory: \(path)"
        case .copyFailed(let reason):
            return reason
        }
    }
}

final class WorkspaceCopyService: @unchecked Sendable {
    private static let excludedItemNames = [
        ".git",
        "node_modules",
        ".DS_Store",
        ".Trash",
        ".foldertrail",
    ]

    private let fileManager: FileManager
    private let shouldCancel: () -> Bool
    private(set) var readOnlySourceFolderURL: URL?

    init(
        fileManager: FileManager = .default,
        shouldCancel: @escaping () -> Bool = { Task.isCancelled }
    ) {
        self.fileManager = fileManager
        self.shouldCancel = shouldCancel
    }

    static func workspaceFolderName(for sourceFolderURL: URL) -> String {
        let baseName = sourceFolderURL.lastPathComponent.isEmpty
            ? "Folder"
            : sourceFolderURL.lastPathComponent
        return "\(baseName)_FolderTrail_Workspace"
    }

    func workspaceURL(for sourceFolderURL: URL) -> URL {
        uniqueWorkspaceURL(for: sourceFolderURL)
    }

    func startCopy(sourceFolderURL: URL) -> AsyncStream<WorkspaceCopyProgress> {
        AsyncStream { continuation in
            Task {
                do {
                    let result = try copyWorkspace(sourceFolderURL: sourceFolderURL) { progress in
                        continuation.yield(progress)
                    }
                    continuation.yield(.completed(result))
                } catch is CancellationError {
                    continuation.yield(.failed(reason: "cancelled"))
                } catch {
                    continuation.yield(.failed(reason: error.localizedDescription))
                }
                continuation.finish()
            }
        }
    }

    func copyWorkspace(sourceFolderURL: URL) throws -> WorkspaceCopyResult {
        try copyWorkspace(sourceFolderURL: sourceFolderURL, onProgress: nil)
    }

    private func copyWorkspace(
        sourceFolderURL: URL,
        onProgress: ((WorkspaceCopyProgress) -> Void)?
    ) throws -> WorkspaceCopyResult {
        try checkCancellation()

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceFolderURL.path, isDirectory: &isDirectory),
              isDirectory.boolValue,
              fileManager.isReadableFile(atPath: sourceFolderURL.path)
        else {
            throw WorkspaceCopyError.sourceIsNotReadableDirectory(sourceFolderURL.path)
        }

        readOnlySourceFolderURL = sourceFolderURL
        let destinationURL = uniqueWorkspaceURL(for: sourceFolderURL)
        onProgress?(.started(sourceFolderURL: sourceFolderURL, workspaceURL: destinationURL))

        do {
            try checkCancellation()
            try fileManager.createDirectory(
                at: destinationURL,
                withIntermediateDirectories: false
            )
            try copyContents(
                from: sourceFolderURL,
                to: destinationURL,
                relativePath: "",
                onProgress: onProgress
            )
            return WorkspaceCopyResult(
                sourceFolderURL: sourceFolderURL,
                workspaceURL: destinationURL
            )
        } catch is CancellationError {
            try? fileManager.removeItem(at: destinationURL)
            throw CancellationError()
        } catch {
            try? fileManager.removeItem(at: destinationURL)
            throw WorkspaceCopyError.copyFailed(error.localizedDescription)
        }
    }

    private func copyContents(
        from sourceURL: URL,
        to destinationURL: URL,
        relativePath: String,
        onProgress: ((WorkspaceCopyProgress) -> Void)?
    ) throws {
        try checkCancellation()

        let items = try fileManager.contentsOfDirectory(
            at: sourceURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: []
        )

        for itemURL in items {
            try checkCancellation()

            let itemName = itemURL.lastPathComponent
            let itemRelativePath = relativePath.isEmpty
                ? itemName
                : "\(relativePath)/\(itemName)"

            if Self.excludedItemNames.contains(itemName) {
                onProgress?(.skipped(relativePath: itemRelativePath))
                continue
            }

            let resourceValues = try itemURL.resourceValues(forKeys: [.isDirectoryKey])
            let destinationItemURL = destinationURL.appendingPathComponent(
                itemName,
                isDirectory: resourceValues.isDirectory == true
            )

            if resourceValues.isDirectory == true {
                try fileManager.createDirectory(
                    at: destinationItemURL,
                    withIntermediateDirectories: false
                )
                try copyContents(
                    from: itemURL,
                    to: destinationItemURL,
                    relativePath: itemRelativePath,
                    onProgress: onProgress
                )
            } else {
                try copyFile(from: itemURL, to: destinationItemURL)
                onProgress?(.copied(relativePath: itemRelativePath))
            }
        }
    }

    private func copyFile(from sourceURL: URL, to destinationURL: URL) throws {
        try checkCancellation()

        if clonefile(sourceURL.path, destinationURL.path, 0) == 0 {
            return
        }

        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }

    private func checkCancellation() throws {
        if shouldCancel() {
            throw CancellationError()
        }
    }

    private func uniqueWorkspaceURL(for sourceFolderURL: URL) -> URL {
        let parentURL = sourceFolderURL.deletingLastPathComponent()
        let baseName = Self.workspaceFolderName(for: sourceFolderURL)
        var candidate = parentURL.appendingPathComponent(baseName, isDirectory: true)
        var suffix = 2

        while fileManager.fileExists(atPath: candidate.path) {
            candidate = parentURL.appendingPathComponent("\(baseName)_\(suffix)", isDirectory: true)
            suffix += 1
        }

        return candidate
    }
}
