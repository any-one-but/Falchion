import AppKit
import Foundation
import QuickLookThumbnailing

actor ThumbnailService {
    static let shared = ThumbnailService()

    private var cache: [String: NSImage] = [:]
    private var inFlight: [String: Task<NSImage?, Never>] = [:]

    func thumbnail(for item: MediaItem, maxPixelSize: CGFloat, scale: CGFloat) async -> NSImage? {
        let cacheKey = Self.cacheKey(for: item, maxPixelSize: maxPixelSize, scale: scale)

        if let cached = cache[cacheKey] {
            return cached
        }

        if let running = inFlight[cacheKey] {
            return await running.value
        }

        let task = Task<NSImage?, Never> {
            let image = await generateThumbnail(for: item.url, maxPixelSize: maxPixelSize, scale: scale)
            return image
        }

        inFlight[cacheKey] = task
        let generated = await task.value
        inFlight[cacheKey] = nil

        if let generated {
            cache[cacheKey] = generated
        }

        return generated
    }

    func cachedThumbnail(for item: MediaItem, maxPixelSize: CGFloat, scale: CGFloat) -> NSImage? {
        let cacheKey = Self.cacheKey(for: item, maxPixelSize: maxPixelSize, scale: scale)
        return cache[cacheKey]
    }

    func preload(items: [MediaItem], maxPixelSize: CGFloat, scale: CGFloat) {
        for item in items {
            Task {
                _ = await thumbnail(for: item, maxPixelSize: maxPixelSize, scale: scale)
            }
        }
    }

    private static func cacheKey(for item: MediaItem, maxPixelSize: CGFloat, scale: CGFloat) -> String {
        let sizeKey = Int((maxPixelSize * scale).rounded())
        return "\(item.id)::\(sizeKey)"
    }

    private func generateThumbnail(for url: URL, maxPixelSize: CGFloat, scale: CGFloat) async -> NSImage? {
        await withCheckedContinuation { continuation in
            let request = QLThumbnailGenerator.Request(
                fileAt: url,
                size: CGSize(width: maxPixelSize, height: maxPixelSize),
                scale: scale,
                representationTypes: .thumbnail
            )

            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { representation, _ in
                continuation.resume(returning: representation?.nsImage)
            }
        }
    }
}
