import Foundation

enum MediaKind: String, Hashable {
    case image
    case video
}

struct LibraryRoot: Identifiable, Hashable {
    let id: UUID
    let displayName: String
    let url: URL

    init(id: UUID = UUID(), displayName: String, url: URL) {
        self.id = id
        self.displayName = displayName
        self.url = url.standardizedFileURL
    }
}

struct LibraryDirectory: Identifiable, Hashable {
    let id: String
    let rootID: UUID
    let relativePath: String
    let displayPath: String
    let name: String
    let parentID: String?
    let directFileCount: Int
    let recursiveFileCount: Int
}

struct MediaItem: Identifiable, Hashable {
    let id: String
    let rootID: UUID
    let directoryID: String
    let relativePath: String
    let name: String
    let kind: MediaKind
    let url: URL
    let sizeBytes: Int64?
    let modifiedAt: Date?

    var metadataStorageKey: String {
        url.standardizedFileURL.path
    }
}

struct LibrarySnapshot {
    var directoriesByID: [String: LibraryDirectory] = [:]
    var childDirectoryIDsByParentID: [String: [String]] = [:]
    var filesByDirectoryID: [String: [MediaItem]] = [:]
    var rootDirectoryIDs: [String] = []

    static let empty = LibrarySnapshot()

    var allDirectories: [LibraryDirectory] {
        directoriesByID.values.sorted {
            $0.displayPath.localizedCaseInsensitiveCompare($1.displayPath) == .orderedAscending
        }
    }
}

nonisolated func makeDirectoryID(rootID: UUID, relativePath: String) -> String {
    "\(rootID.uuidString)::\(relativePath)"
}
