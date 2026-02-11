import Foundation

actor LibraryScanner {
    private let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "gif", "webp", "tiff", "tif", "bmp", "avif"]
    private let videoExtensions: Set<String> = ["mp4", "m4v", "mov", "wmv", "flv", "avi", "webm", "mkv"]

    func buildSnapshot(for roots: [LibraryRoot]) -> LibrarySnapshot {
        var snapshot = LibrarySnapshot.empty

        for root in roots {
            let rootResult = scanRoot(root)

            snapshot.rootDirectoryIDs.append(rootResult.rootDirectoryID)
            snapshot.directoriesByID.merge(rootResult.directoriesByID) { current, _ in current }
            snapshot.childDirectoryIDsByParentID.merge(rootResult.childDirectoryIDsByParentID) { current, _ in current }
            snapshot.filesByDirectoryID.merge(rootResult.filesByDirectoryID) { current, _ in current }
        }

        for (parentID, childIDs) in snapshot.childDirectoryIDsByParentID {
            snapshot.childDirectoryIDsByParentID[parentID] = childIDs.sorted {
                let leftName = snapshot.directoriesByID[$0]?.name ?? ""
                let rightName = snapshot.directoriesByID[$1]?.name ?? ""
                return leftName.localizedCaseInsensitiveCompare(rightName) == .orderedAscending
            }
        }

        for (directoryID, files) in snapshot.filesByDirectoryID {
            snapshot.filesByDirectoryID[directoryID] = files.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }

        snapshot.rootDirectoryIDs.sort {
            let left = snapshot.directoriesByID[$0]?.displayPath ?? ""
            let right = snapshot.directoriesByID[$1]?.displayPath ?? ""
            return left.localizedCaseInsensitiveCompare(right) == .orderedAscending
        }

        return snapshot
    }

    private func scanRoot(_ root: LibraryRoot) -> RootScanResult {
        struct MutableDirectory {
            var relativePath: String
            var name: String
            var parentRelativePath: String?
            var childRelativePaths: Set<String>
            var directFileCount: Int
        }

        let fileManager = FileManager.default
        let rootURL = root.url.standardizedFileURL
        let rootPath = rootURL.path

        var directoriesByRelativePath: [String: MutableDirectory] = [:]
        var filesByDirectoryID: [String: [MediaItem]] = [:]

        func parentPath(for relativePath: String) -> String? {
            guard !relativePath.isEmpty else {
                return nil
            }

            let rawParent = (relativePath as NSString).deletingLastPathComponent
            if rawParent.isEmpty || rawParent == "." {
                return ""
            }

            return rawParent
        }

        func directoryName(for relativePath: String) -> String {
            if relativePath.isEmpty {
                return root.displayName
            }

            return (relativePath as NSString).lastPathComponent
        }

        func ensureDirectory(_ relativePath: String) {
            if directoriesByRelativePath[relativePath] != nil {
                return
            }

            let parent = parentPath(for: relativePath)
            if let parent {
                ensureDirectory(parent)
            }

            directoriesByRelativePath[relativePath] = MutableDirectory(
                relativePath: relativePath,
                name: directoryName(for: relativePath),
                parentRelativePath: parent,
                childRelativePaths: [],
                directFileCount: 0
            )

            if let parent {
                directoriesByRelativePath[parent]?.childRelativePaths.insert(relativePath)
            }
        }

        func relativePath(for absoluteURL: URL) -> String {
            let standardized = absoluteURL.standardizedFileURL.path
            guard standardized.hasPrefix(rootPath) else {
                return ""
            }

            var relative = String(standardized.dropFirst(rootPath.count))
            if relative.hasPrefix("/") {
                relative.removeFirst()
            }
            return relative
        }

        ensureDirectory("")

        let resourceKeys: [URLResourceKey] = [
            .isDirectoryKey,
            .isRegularFileKey,
            .fileSizeKey,
            .contentModificationDateKey
        ]

        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsPackageDescendants]
        let enumerator = fileManager.enumerator(
            at: rootURL,
            includingPropertiesForKeys: resourceKeys,
            options: options,
            errorHandler: { _, _ in true }
        )

        while let nextObject = enumerator?.nextObject() {
            guard let itemURL = nextObject as? URL else {
                continue
            }

            let relative = relativePath(for: itemURL)
            if relative.isEmpty {
                continue
            }

            let values = try? itemURL.resourceValues(forKeys: Set(resourceKeys))

            if values?.isDirectory == true {
                ensureDirectory(relative)
                continue
            }

            guard values?.isRegularFile == true else {
                continue
            }

            let ext = itemURL.pathExtension.lowercased()
            let kind: MediaKind
            if imageExtensions.contains(ext) {
                kind = .image
            } else if videoExtensions.contains(ext) {
                kind = .video
            } else {
                continue
            }

            let rawDir = (relative as NSString).deletingLastPathComponent
            let directoryRelativePath = (rawDir == ".") ? "" : rawDir
            ensureDirectory(directoryRelativePath)

            let directoryID = makeDirectoryID(rootID: root.id, relativePath: directoryRelativePath)
            let mediaItem = MediaItem(
                id: "\(root.id.uuidString)::\(relative)",
                rootID: root.id,
                directoryID: directoryID,
                relativePath: relative,
                name: itemURL.lastPathComponent,
                kind: kind,
                url: itemURL,
                sizeBytes: values?.fileSize.map { Int64($0) },
                modifiedAt: values?.contentModificationDate
            )

            filesByDirectoryID[directoryID, default: []].append(mediaItem)
            directoriesByRelativePath[directoryRelativePath]?.directFileCount += 1
        }

        var recursiveCounts: [String: Int] = [:]
        let allPathsByDepth = directoriesByRelativePath.keys.sorted { lhs, rhs in
            lhs.split(separator: "/").count > rhs.split(separator: "/").count
        }

        for relativePath in allPathsByDepth {
            guard let mutableDirectory = directoriesByRelativePath[relativePath] else {
                continue
            }

            let childTotal = mutableDirectory.childRelativePaths.reduce(0) { partialResult, childRelativePath in
                partialResult + (recursiveCounts[childRelativePath] ?? 0)
            }

            recursiveCounts[relativePath] = mutableDirectory.directFileCount + childTotal
        }

        var directoriesByID: [String: LibraryDirectory] = [:]
        var childDirectoryIDsByParentID: [String: [String]] = [:]

        for (relativePath, mutableDirectory) in directoriesByRelativePath {
            let directoryID = makeDirectoryID(rootID: root.id, relativePath: relativePath)
            let parentID = mutableDirectory.parentRelativePath.map { parentRelativePath in
                makeDirectoryID(rootID: root.id, relativePath: parentRelativePath)
            }

            let displayPath = relativePath.isEmpty
                ? root.displayName
                : "\(root.displayName)/\(relativePath)"

            let directory = LibraryDirectory(
                id: directoryID,
                rootID: root.id,
                relativePath: relativePath,
                displayPath: displayPath,
                name: mutableDirectory.name,
                parentID: parentID,
                directFileCount: mutableDirectory.directFileCount,
                recursiveFileCount: recursiveCounts[relativePath] ?? mutableDirectory.directFileCount
            )

            directoriesByID[directoryID] = directory

            if let parentID {
                childDirectoryIDsByParentID[parentID, default: []].append(directoryID)
            }
        }

        let rootDirectoryID = makeDirectoryID(rootID: root.id, relativePath: "")

        return RootScanResult(
            rootDirectoryID: rootDirectoryID,
            directoriesByID: directoriesByID,
            childDirectoryIDsByParentID: childDirectoryIDsByParentID,
            filesByDirectoryID: filesByDirectoryID
        )
    }
}

private struct RootScanResult {
    let rootDirectoryID: String
    let directoriesByID: [String: LibraryDirectory]
    let childDirectoryIDsByParentID: [String: [String]]
    let filesByDirectoryID: [String: [MediaItem]]
}
