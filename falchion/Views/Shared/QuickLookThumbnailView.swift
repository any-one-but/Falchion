import AppKit
import SwiftUI

struct QuickLookThumbnailView: View {
    let item: MediaItem
    let height: CGFloat
    let fitMode: ThumbnailFitMode

    @Environment(\.displayScale) private var displayScale

    @State private var image: NSImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.falchionCardSurface

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .modifier(ThumbnailFitModifier(mode: fitMode))
            } else {
                placeholder
            }
        }
        .frame(height: height)
        .clipped()
        .task(id: "\(item.id)-\(Int(height))") {
            await loadThumbnail()
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private var placeholder: some View {
        Image(systemName: item.kind == .video ? "film" : "photo")
            .font(.system(size: 28))
            .foregroundStyle(Color.falchionTextSecondary)
    }

    private func loadThumbnail() async {
        loadTask?.cancel()
        loadTask = Task {
            let maxPixel = max(height * 2.2, 240)
            if let cached = await ThumbnailService.shared.cachedThumbnail(for: item, maxPixelSize: maxPixel, scale: max(displayScale, 1)) {
                await MainActor.run {
                    self.image = cached
                }
            }

            let generated = await ThumbnailService.shared.thumbnail(for: item, maxPixelSize: maxPixel, scale: max(displayScale, 1))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self.image = generated
            }
        }

        await loadTask?.value
    }
}

private struct ThumbnailFitModifier: ViewModifier {
    let mode: ThumbnailFitMode

    func body(content: Content) -> some View {
        switch mode {
        case .cover:
            content.scaledToFill()
        case .contain:
            content.scaledToFit()
        }
    }
}
