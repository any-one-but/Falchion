import AppKit
import Foundation
import QuickLookThumbnailing

actor ThumbnailService {
    static let shared = ThumbnailService()

    private var cache: [String: NSImage] = [:]
    private var inFlight: [String: Task<NSImage?, Never>] = [:]

    func thumbnail(for item: MediaItem, maxPixelSize: CGFloat, scale: CGFloat) async -> NSImage? {
        let sizeKey = Int((maxPixelSize * scale).rounded())
        let cacheKey = "\(item.id)::\(sizeKey)"

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
