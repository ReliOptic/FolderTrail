import AppKit

enum FolderTrailServiceSelection {
    static func firstExistingFolderURL(
        from urls: [URL],
        fileManager: FileManager = .default
    ) -> URL? {
        urls.first { url in
            var isDirectory: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
        }
    }
}

@MainActor
final class FolderTrailServiceProvider: NSObject {
    @objc func openFolderTrail(
        _ pasteboard: NSPasteboard,
        userData: String?,
        error: AutoreleasingUnsafeMutablePointer<NSString?>
    ) {
        guard let folderURL = firstFolderURL(from: pasteboard) else {
            let message = "폴더를 선택한 뒤 New FolderTrail을 실행해 주세요."
            error.pointee = message as NSString
            FolderTrailAppController.shared.showError(message)
            return
        }

        FolderTrailAppController.shared.openPrompt(for: folderURL)
    }

    private func firstFolderURL(from pasteboard: NSPasteboard) -> URL? {
        let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: nil)
        let urls = objects?
            .compactMap { object in
                if let url = object as? URL { return url }
                return (object as? NSURL) as URL?
            }
        return FolderTrailServiceSelection.firstExistingFolderURL(from: urls ?? [])
    }
}
