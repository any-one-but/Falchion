import Foundation

enum FileOperationError: Error {
    case invalidName
    case notFound
    case conflict(String)
    case unsupported
    case operationFailed(String)
}

enum ReorderDirection {
    case previous
    case next
}

actor FileOperationsService {
    private let fileManager = FileManager.default

    func rename(item: MediaItem, to newName: String, policy: FileConflictPolicy) throws -> URL {
        let cleaned = sanitizeFileName(newName)
        guard isValidFileName(cleaned) else {
            throw FileOperationError.invalidName
        }

        let sourceURL = item.url.standardizedFileURL
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.notFound
        }

        let directoryURL = sourceURL.deletingLastPathComponent()
        var destinationURL = directoryURL.appendingPathComponent(cleaned, isDirectory: false)
        if destinationURL.path == sourceURL.path {
            return sourceURL
        }

        destinationURL = try resolveConflict(for: destinationURL, policy: policy, reservedNames: [])

        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            throw FileOperationError.operationFailed("rename_failed")
        }
    }

    func move(item: MediaItem, to destinationDirectoryURL: URL, policy: FileConflictPolicy) throws -> URL {
        let sourceURL = item.url.standardizedFileURL
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.notFound
        }

        let destinationDirectory = destinationDirectoryURL.standardizedFileURL
        guard fileManager.fileExists(atPath: destinationDirectory.path) else {
            throw FileOperationError.notFound
        }

        var destinationURL = destinationDirectory.appendingPathComponent(sourceURL.lastPathComponent, isDirectory: false)
        if destinationURL.path == sourceURL.path {
            return sourceURL
        }

        destinationURL = try resolveConflict(for: destinationURL, policy: policy, reservedNames: [])

        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            throw FileOperationError.operationFailed("move_failed")
        }
    }

    func delete(item: MediaItem) throws {
        let sourceURL = item.url.standardizedFileURL
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.notFound
        }

        do {
            var resultingURL: NSURL?
            try fileManager.trashItem(at: sourceURL, resultingItemURL: &resultingURL)
        } catch {
            throw FileOperationError.operationFailed("delete_failed")
        }
    }

    func renameDirectory(at directoryURL: URL, to newName: String, policy: FileConflictPolicy) throws -> URL {
        let cleaned = sanitizeFileName(newName)
        guard isValidFileName(cleaned) else {
            throw FileOperationError.invalidName
        }

        let sourceURL = directoryURL.standardizedFileURL
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.notFound
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw FileOperationError.unsupported
        }

        let parentURL = sourceURL.deletingLastPathComponent()
        var destinationURL = parentURL.appendingPathComponent(cleaned, isDirectory: true)
        if destinationURL.path == sourceURL.path {
            return sourceURL
        }

        destinationURL = try resolveConflict(for: destinationURL, policy: policy, reservedNames: [])

        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
            return destinationURL
        } catch {
            throw FileOperationError.operationFailed("directory_rename_failed")
        }
    }

    func deleteDirectory(at directoryURL: URL) throws {
        let sourceURL = directoryURL.standardizedFileURL
        guard fileManager.fileExists(atPath: sourceURL.path) else {
            throw FileOperationError.notFound
        }

        do {
            var resultingURL: NSURL?
            try fileManager.trashItem(at: sourceURL, resultingItemURL: &resultingURL)
        } catch {
            throw FileOperationError.operationFailed("directory_delete_failed")
        }
    }

    func reorder(item: MediaItem, among siblings: [MediaItem], direction: ReorderDirection) throws -> URL {
        guard siblings.count > 1 else {
            return item.url
        }

        var ordered = siblings
        guard let currentIndex = ordered.firstIndex(where: { $0.id == item.id }) else {
            return item.url
        }

        let targetIndex: Int
        switch direction {
        case .previous:
            targetIndex = currentIndex - 1
        case .next:
            targetIndex = currentIndex + 1
        }

        guard targetIndex >= 0, targetIndex < ordered.count else {
            return item.url
        }

        ordered.swapAt(currentIndex, targetIndex)

        let selectedDirectory = item.url.deletingLastPathComponent().standardizedFileURL
        let directoryContents = (try? fileManager.contentsOfDirectory(atPath: selectedDirectory.path)) ?? []
        let existingNames = Set(directoryContents)
        let participantNames = Set(ordered.map { $0.url.lastPathComponent })
        let occupiedNames = existingNames.subtracting(participantNames)

        let width = max(3, String(ordered.count).count)
        var usedNames: Set<String> = []
        var renameMap: [(source: URL, destinationName: String)] = []

        for (index, media) in ordered.enumerated() {
            let oldName = media.url.lastPathComponent
            let parts = splitNameExtension(oldName)
            let cleanBase = stripIndexPrefix(parts.base).isEmpty ? "item" : stripIndexPrefix(parts.base)
            let prefix = String(format: "%0*d", width, index + 1)
            let preferredBase = "\(prefix) - \(cleanBase)"

            var candidateBase = preferredBase
            var suffixIndex = 2
            var candidate = candidateBase + parts.extensionWithDot

            while occupiedNames.contains(candidate) || usedNames.contains(candidate) {
                candidateBase = "\(preferredBase) (\(suffixIndex))"
                candidate = candidateBase + parts.extensionWithDot
                suffixIndex += 1
            }

            usedNames.insert(candidate)

            if candidate != oldName {
                renameMap.append((source: media.url.standardizedFileURL, destinationName: candidate))
            }
        }

        guard !renameMap.isEmpty else {
            return item.url
        }

        var temporaryMoves: [(temp: URL, final: URL)] = []

        for entry in renameMap {
            let tempName = ".__falchion_tmp_\(UUID().uuidString)_\(entry.source.lastPathComponent)"
            let tempURL = selectedDirectory.appendingPathComponent(tempName, isDirectory: false)
            do {
                try fileManager.moveItem(at: entry.source, to: tempURL)
                let finalURL = selectedDirectory.appendingPathComponent(entry.destinationName, isDirectory: false)
                temporaryMoves.append((temp: tempURL, final: finalURL))
            } catch {
                throw FileOperationError.operationFailed("reorder_stage_one_failed")
            }
        }

        for move in temporaryMoves {
            do {
                try fileManager.moveItem(at: move.temp, to: move.final)
            } catch {
                throw FileOperationError.operationFailed("reorder_stage_two_failed")
            }
        }

        if let renamedSelected = renameMap.first(where: { $0.source.path == item.url.standardizedFileURL.path }) {
            return selectedDirectory.appendingPathComponent(renamedSelected.destinationName, isDirectory: false)
        }

        return item.url
    }

    private func sanitizeFileName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func isValidFileName(_ value: String) -> Bool {
        if value.isEmpty || value == "." || value == ".." {
            return false
        }

        return !value.contains("/") && !value.contains("\\")
    }

    private func splitNameExtension(_ name: String) -> (base: String, extensionWithDot: String) {
        let nsName = name as NSString
        let ext = nsName.pathExtension
        guard !ext.isEmpty else {
            return (name, "")
        }

        let base = nsName.deletingPathExtension
        return (base, ".\(ext)")
    }

    private func stripIndexPrefix(_ value: String) -> String {
        let pattern = "^\\d+\\s-\\s"
        return value.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    private func resolveConflict(for destinationURL: URL, policy: FileConflictPolicy, reservedNames: Set<String>) throws -> URL {
        guard fileManager.fileExists(atPath: destinationURL.path) else {
            if reservedNames.contains(destinationURL.lastPathComponent) {
                return uniqueURL(for: destinationURL, reservedNames: reservedNames)
            }
            return destinationURL
        }

        switch policy {
        case .abort:
            throw FileOperationError.conflict(destinationURL.lastPathComponent)
        case .replace:
            do {
                try fileManager.removeItem(at: destinationURL)
                return destinationURL
            } catch {
                throw FileOperationError.operationFailed("replace_failed")
            }
        case .keepBoth:
            return uniqueURL(for: destinationURL, reservedNames: reservedNames)
        }
    }

    private func uniqueURL(for originalURL: URL, reservedNames: Set<String>) -> URL {
        let directory = originalURL.deletingLastPathComponent()
        let parts = splitNameExtension(originalURL.lastPathComponent)
        let base = parts.base
        let ext = parts.extensionWithDot

        var index = 1
        while true {
            let suffix = index == 1 ? " copy" : " copy \(index)"
            let candidateName = "\(base)\(suffix)\(ext)"
            let candidateURL = directory.appendingPathComponent(candidateName, isDirectory: false)
            if !fileManager.fileExists(atPath: candidateURL.path) && !reservedNames.contains(candidateName) {
                return candidateURL
            }
            index += 1
        }
    }
}
