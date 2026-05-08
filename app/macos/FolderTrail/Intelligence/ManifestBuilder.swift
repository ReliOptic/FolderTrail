import Foundation

enum ManifestDetailLevel: String, Codable, Equatable {
    case level_3_metadata
    case level_2_path_summary
    case level_1_directory_summary
    case level_0_confirm
}

struct FolderManifest: Codable, Equatable {
    let manifest_version: String
    let workspace_name: String
    let source_folder: String
    let total_files: Int
    let total_directories: Int
    let detail_level: ManifestDetailLevel
    let privacy_filter_applied: Bool
    let files: [ManifestFile]
    let directory_summary: [ManifestDirectorySummary]
    let review_excluded: [ManifestReviewExcluded]
}

struct ManifestFile: Codable, Equatable {
    let path: String
    let name: String
    let `extension`: String
    let size_bytes: Int?
    let size_bucket: String?
    let modified_date_bucket: String?
    let text_preview: String?
}

struct ManifestDirectorySummary: Codable, Equatable {
    let path: String
    let file_count: Int
    let extension_breakdown: [String: Int]
}

struct ManifestReviewExcluded: Codable, Equatable {
    let path: String
    let reason: String
}

final class ManifestBuilder {
    private static let manifestVersion = "0.1"
    private static let previewEligibleExtensions = ["md", "txt", "csv", "json", "yaml", "yml", "rtf"]
    private static let sensitiveExactNames = [".env", ".DS_Store"]
    private static let sensitiveExtensions = ["pem", "key", "p12", "mobileprovision"]
    private static let sensitivePrefixes = ["credentials", "secret", "token", "password"]

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func build(
        workspaceURL: URL,
        sourceFolderPath: String
    ) throws -> FolderManifest {
        var previewBudget = 20_000
        let scan = try scanWorkspace(workspaceURL)
        let detailLevel = detailLevel(for: scan.includedFiles.count)

        return FolderManifest(
            manifest_version: Self.manifestVersion,
            workspace_name: workspaceURL.lastPathComponent,
            source_folder: sourceFolderPath,
            total_files: scan.includedFiles.count,
            total_directories: scan.directories.count,
            detail_level: detailLevel,
            privacy_filter_applied: true,
            files: files(
                for: scan.includedFiles,
                workspaceURL: workspaceURL,
                detailLevel: detailLevel,
                previewBudget: &previewBudget
            ),
            directory_summary: directorySummary(
                directories: scan.directories,
                files: scan.includedFiles,
                workspaceURL: workspaceURL
            ),
            review_excluded: scan.excluded
        )
    }

    private func detailLevel(for totalFiles: Int) -> ManifestDetailLevel {
        switch totalFiles {
        case 0...200:
            return .level_3_metadata
        case 201...1000:
            return .level_2_path_summary
        case 1001...5000:
            return .level_1_directory_summary
        default:
            return .level_0_confirm
        }
    }

    private func scanWorkspace(_ workspaceURL: URL) throws -> WorkspaceScan {
        guard let enumerator = fileManager.enumerator(
            at: workspaceURL,
            includingPropertiesForKeys: [.isRegularFileKey, .isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: []
        ) else {
            return WorkspaceScan(includedFiles: [], directories: [], excluded: [])
        }

        var files: [URL] = []
        var directories: [URL] = []
        var excluded: [ManifestReviewExcluded] = []

        for case let url as URL in enumerator {
            let relativePath = self.relativePath(for: url, root: workspaceURL)
            let resourceValues = try url.resourceValues(forKeys: [.isRegularFileKey, .isDirectoryKey])

            if shouldExclude(url) {
                excluded.append(
                    ManifestReviewExcluded(path: relativePath, reason: "sensitive_filename_pattern")
                )
                if resourceValues.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            if resourceValues.isDirectory == true {
                directories.append(url)
            } else if resourceValues.isRegularFile == true {
                files.append(url)
            }
        }

        return WorkspaceScan(includedFiles: files, directories: directories, excluded: excluded)
    }

    private func files(
        for urls: [URL],
        workspaceURL: URL,
        detailLevel: ManifestDetailLevel,
        previewBudget: inout Int
    ) -> [ManifestFile] {
        let selectedURLs = detailLevel == .level_1_directory_summary
            ? sampledFilesByExtension(urls)
            : urls

        if detailLevel == .level_0_confirm {
            return []
        }

        return selectedURLs.map { url in
            let extensionValue = url.pathExtension.lowercased()
            let size = fileSize(url)

            return ManifestFile(
                path: relativePath(for: url, root: workspaceURL),
                name: url.lastPathComponent,
                extension: extensionValue,
                size_bytes: detailLevel == .level_3_metadata ? size : nil,
                size_bucket: sizeBucket(for: size),
                modified_date_bucket: modifiedDateBucket(for: url),
                text_preview: detailLevel == .level_3_metadata
                    ? textPreview(for: url, extensionValue: extensionValue, previewBudget: &previewBudget)
                    : nil
            )
        }
    }

    private func directorySummary(
        directories: [URL],
        files: [URL],
        workspaceURL: URL
    ) -> [ManifestDirectorySummary] {
        directories.map { directory in
            let relativeDirectoryPath = relativePath(for: directory, root: workspaceURL)
            let childFiles = files.filter { fileURL in
                relativePath(for: fileURL, root: workspaceURL).hasPrefix("\(relativeDirectoryPath)/")
            }
            var breakdown: [String: Int] = [:]
            for file in childFiles {
                let extensionValue = file.pathExtension.lowercased()
                breakdown[extensionValue, default: 0] += 1
            }
            return ManifestDirectorySummary(
                path: relativeDirectoryPath,
                file_count: childFiles.count,
                extension_breakdown: breakdown
            )
        }
    }

    private func sampledFilesByExtension(_ urls: [URL]) -> [URL] {
        var countsByExtension: [String: Int] = [:]
        return urls.filter { url in
            let extensionValue = url.pathExtension.lowercased()
            let count = countsByExtension[extensionValue, default: 0]
            guard count < 5 else { return false }
            countsByExtension[extensionValue] = count + 1
            return true
        }
    }

    private func shouldExclude(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        let extensionValue = url.pathExtension.lowercased()

        if Self.sensitiveExactNames.contains(name) || Self.sensitiveExtensions.contains(extensionValue) {
            return true
        }

        return Self.sensitivePrefixes.contains { prefix in
            name.hasPrefix(prefix)
        }
    }

    private func textPreview(
        for url: URL,
        extensionValue: String,
        previewBudget: inout Int
    ) -> String? {
        guard previewBudget > 0,
              Self.previewEligibleExtensions.contains(extensionValue),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else {
            return nil
        }

        let allowedCount = min(1_000, previewBudget)
        let preview = String(text.prefix(allowedCount))
        previewBudget -= preview.count
        return preview
    }

    private func fileSize(_ url: URL) -> Int {
        let values = try? url.resourceValues(forKeys: [.fileSizeKey])
        return values?.fileSize ?? 0
    }

    private func sizeBucket(for size: Int) -> String {
        switch size {
        case 0..<1_024:
            return "<1KB"
        case 1_024..<(1024 * 1024):
            return "1KB-1MB"
        case (1024 * 1024)..<(5 * 1024 * 1024):
            return "1MB-5MB"
        default:
            return "5MB+"
        }
    }

    private func modifiedDateBucket(for url: URL) -> String {
        guard let modifiedDate = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
            return "unknown"
        }

        let age = Date().timeIntervalSince(modifiedDate)
        if age < 60 * 60 * 24 * 30 {
            return "recent"
        }
        if age < 60 * 60 * 24 * 365 {
            return "this_year"
        }
        return "older"
    }

    private func relativePath(for url: URL, root: URL) -> String {
        let rootPath = root.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(rootPath) else {
            return url.lastPathComponent
        }
        return String(path.dropFirst(rootPath.count))
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }
}

private struct WorkspaceScan {
    let includedFiles: [URL]
    let directories: [URL]
    let excluded: [ManifestReviewExcluded]
}
