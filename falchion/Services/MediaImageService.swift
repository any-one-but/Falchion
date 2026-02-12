import AppKit
import Foundation

actor MediaImageService {
    static let shared = MediaImageService()

    private var cache: [String: NSImage] = [:]
    private var inFlight: [String: Task<NSImage?, Never>] = [:]

    func cachedImage(for url: URL) -> NSImage? {
        cache[url.standardizedFileURL.path]
    }

    func image(for url: URL) async -> NSImage? {
        let key = url.standardizedFileURL.path

        if let cached = cache[key] {
            return cached
        }

        if let running = inFlight[key] {
            return await running.value
        }

        let task = Task<NSImage?, Never> {
            await Task.detached(priority: .userInitiated) {
                NSImage(contentsOf: url)
            }.value
        }

        inFlight[key] = task
        let loaded = await task.value
        inFlight[key] = nil

        if let loaded {
            cache[key] = loaded
        }

        return loaded
    }

    func preload(_ urls: [URL]) {
        for url in urls {
            Task {
                _ = await image(for: url)
            }
        }
    }
}
