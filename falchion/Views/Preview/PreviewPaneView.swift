import SwiftUI

struct PreviewPaneView: View {
    @EnvironmentObject private var appState: FalchionAppState

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: appState.previewCardSize.gridMinimum), spacing: 10)]
    }

    var body: some View {
        Group {
            if appState.isPreviewingMediaSelection, let selectedMedia = appState.selectedMediaItem {
                mediaViewer(selectedMedia)
            } else {
                thumbnailsView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(appState.isPreviewingMediaSelection ? Color.black : Color.falchionPane)
    }

    private var thumbnailsView: some View {
        ScrollView {
            VStack(spacing: 12) {
                if !appState.previewDirectoriesForDisplay.isEmpty {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(appState.previewDirectoriesForDisplay) { directory in
                            directoryCard(directory)
                        }
                    }
                }

                if !appState.previewFilesForDisplay.isEmpty {
                    LazyVGrid(columns: gridColumns, spacing: 10) {
                        ForEach(appState.previewFilesForDisplay) { item in
                            mediaCard(item)
                        }
                    }
                }

                if appState.previewDirectoriesForDisplay.isEmpty && appState.previewFilesForDisplay.isEmpty {
                    emptyStateCard
                }
            }
            .padding(10)
        }
        .background(Color.falchionPane)
    }

    private func mediaViewer(_ item: MediaItem) -> some View {
        ZStack {
            Color.black

            if item.kind == .video {
                PlainVideoSurfaceView(url: item.url)
            } else {
                PreloadedImageView(url: item.url)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func directoryCard(_ directory: LibraryDirectory) -> some View {
        Button {
            appState.selectDirectory(directory.id)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.falchionTextSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(directory.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.falchionTextPrimary)
                        .lineLimit(1)

                    Text("\(directory.directFileCount) direct • \(directory.recursiveFileCount) total")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.falchionCardBase)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.falchionBorder, lineWidth: 1)
            }
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onTapGesture(count: 2) {
            appState.enterDirectory(directory.id)
        }
    }

    private func mediaCard(_ item: MediaItem) -> some View {
        let metadata = appState.metadata(for: item)
        let isSelected = appState.selectedMediaID == item.id && appState.isPreviewingMediaSelection

        return VStack(spacing: 0) {
            QuickLookThumbnailView(item: item, height: appState.previewCardSize.thumbnailHeight, fitMode: appState.thumbnailFitMode)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(item.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.falchionTextPrimary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    HStack(spacing: 4) {
                        if metadata.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                        if metadata.isHidden {
                            Image(systemName: "eye.slash.fill")
                                .foregroundStyle(Color.falchionTextSecondary)
                        }
                        Text(item.kind == .video ? "VID" : "IMG")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.falchionTextSecondary)
                    }
                }

                Text(item.relativePath)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.falchionCardBase)
        }
        .opacity(metadata.isHidden ? 0.72 : 1)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.falchionAccent : Color.falchionBorder, lineWidth: isSelected ? 1.5 : 1)
        }
        .cornerRadius(8)
        .contentShape(Rectangle())
        .onTapGesture {
            appState.selectMedia(item.id)
        }
        .onTapGesture(count: 2) {
            appState.openViewer(with: item.id)
        }
    }

    private var emptyStateCard: some View {
        HStack {
            Text("No media found in this directory for the current filter.")
                .font(.system(size: 12))
                .foregroundStyle(Color.falchionTextSecondary)
            Spacer()
        }
        .padding(12)
        .background(Color.falchionCardBase)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.falchionBorder, lineWidth: 1)
        }
        .cornerRadius(8)
    }
}
