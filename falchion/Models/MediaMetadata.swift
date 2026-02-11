import Foundation

struct MediaMetadata: Codable, Hashable {
    var tags: [String]
    var isFavorite: Bool
    var isHidden: Bool
    var updatedAt: Date

    static let empty = MediaMetadata(tags: [], isFavorite: false, isHidden: false, updatedAt: .distantPast)

    var isEmpty: Bool {
        tags.isEmpty && !isFavorite && !isHidden
    }
}
