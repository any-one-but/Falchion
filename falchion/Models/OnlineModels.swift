import Foundation

enum OnlineImportMode: String, CaseIterable, Codable, Identifiable {
    case profile
    case posts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile:
            return "Profile"
        case .posts:
            return "Posts"
        }
    }
}

enum OnlineServiceKind: String, CaseIterable, Codable, Identifiable {
    case reddit
    case deviantart
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reddit:
            return "Reddit"
        case .deviantart:
            return "DeviantArt"
        case .custom:
            return "Custom"
        }
    }
}

struct OnlineProfileDescriptor: Codable, Hashable, Identifiable {
    var service: OnlineServiceKind
    var userID: String
    var origin: String
    var sourceURL: String
    var profileKey: String
    var dataRoot: String

    var id: String { profileKey }
}

struct OnlinePostMedia: Codable, Hashable, Identifiable {
    var url: String
    var isVideo: Bool

    var id: String { url }
}

struct OnlinePost: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var user: String
    var publishedAt: Date?
    var media: [OnlinePostMedia]
}

struct OnlineResponseLogEntry: Codable, Hashable, Identifiable {
    var id: UUID
    var timestamp: Date
    var source: String
    var url: String
    var page: Int
    var statusCode: Int
    var parseOK: Bool
    var error: String
    var responsePreview: String
    var responseBytes: Int
    var truncated: Bool

    nonisolated init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: String,
        url: String,
        page: Int,
        statusCode: Int,
        parseOK: Bool,
        error: String,
        responsePreview: String,
        responseBytes: Int,
        truncated: Bool
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.url = url
        self.page = page
        self.statusCode = statusCode
        self.parseOK = parseOK
        self.error = error
        self.responsePreview = responsePreview
        self.responseBytes = responseBytes
        self.truncated = truncated
    }
}

struct OnlineFetchResult {
    var posts: [OnlinePost]
    var responses: [OnlineResponseLogEntry]
    var errorCode: String?
}

struct OnlineImportResult {
    var importedFiles: Int
    var importedPosts: Int
    var baseRelativePath: String
}

struct OnlineProfileRecord: Codable, Hashable, Identifiable {
    var descriptor: OnlineProfileDescriptor
    var importMode: OnlineImportMode
    var rootID: UUID
    var baseRelativePath: String
    var postCount: Int
    var fileCount: Int
    var fetchedAt: Date

    var id: String { descriptor.profileKey }
}
