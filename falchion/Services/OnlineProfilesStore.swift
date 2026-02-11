import Foundation

actor OnlineProfilesStore {
    private let fileManager = FileManager.default

    private var fileURL: URL {
        let appSupportBase = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)

        let bundleID = Bundle.main.bundleIdentifier ?? "com.anyone-but.falchion"
        return appSupportBase
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("online-profiles.json", isDirectory: false)
    }

    func load() -> [OnlineProfileRecord] {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode([OnlineProfileRecord].self, from: data)
        } catch {
            return []
        }
    }

    func save(_ profiles: [OnlineProfileRecord]) {
        let destination = fileURL
        let directory = destination.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(profiles)
            try data.write(to: destination, options: [.atomic])
        } catch {
            return
        }
    }
}
