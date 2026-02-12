import Foundation

actor AppPreferencesStore {
    private let fileManager = FileManager.default

    private var fileURL: URL {
        let appSupportBase = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support", isDirectory: true)

        let bundleID = Bundle.main.bundleIdentifier ?? "com.anyone-but.falchion"
        return appSupportBase
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("app-preferences.json", isDirectory: false)
    }

    func load() async -> AppPreferences {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return .default
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try await MainActor.run {
                try JSONDecoder().decode(AppPreferences.self, from: data)
            }
        } catch {
            return .default
        }
    }

    func save(_ preferences: AppPreferences) async {
        let destination = fileURL
        let directory = destination.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try await MainActor.run {
                try JSONEncoder().encode(preferences)
            }
            try data.write(to: destination, options: [.atomic])
        } catch {
            return
        }
    }
}
