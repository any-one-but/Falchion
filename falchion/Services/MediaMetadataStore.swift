import Foundation

actor MediaMetadataStore {
    private let fileManager = FileManager.default

    private var metadataFileURL: URL {
        let appSupportBase = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)

        let bundleID = Bundle.main.bundleIdentifier ?? "com.anyone-but.falchion"
        return appSupportBase
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("media-metadata.json", isDirectory: false)
    }

    func load() -> [String: MediaMetadata] {
        let fileURL = metadataFileURL

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([String: MediaMetadata].self, from: data)
        } catch {
            return [:]
        }
    }

    func save(_ metadataByKey: [String: MediaMetadata]) {
        let fileURL = metadataFileURL
        let directoryURL = fileURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(metadataByKey)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            return
        }
    }
}
