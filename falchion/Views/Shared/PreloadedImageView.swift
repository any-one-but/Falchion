import AppKit
import SwiftUI

struct PreloadedImageView: View {
    let url: URL
    var preserveCurrentFrameDuringSwap: Bool = true

    @State private var image: NSImage?
    @State private var loadTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black

            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: url.path) {
            await loadImage()
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
        }
    }

    private func loadImage() async {
        loadTask?.cancel()

        if let cached = await MediaImageService.shared.cachedImage(for: url) {
            await MainActor.run {
                image = cached
            }
        } else if !preserveCurrentFrameDuringSwap {
            await MainActor.run {
                image = nil
            }
        }

        loadTask = Task {
            let loaded = await MediaImageService.shared.image(for: url)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.08)) {
                    image = loaded
                }
            }
        }

        await loadTask?.value
    }
}
