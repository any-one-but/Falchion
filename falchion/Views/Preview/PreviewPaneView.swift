import SwiftUI

struct PreviewPaneView: View {
    @EnvironmentObject private var appState: FalchionAppState

    @State private var tagDraft: String = ""
    @State private var renameDraft: String = ""
    @State private var directoryRenameDraft: String = ""

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: appState.previewCardSize.gridMinimum), spacing: 10)]
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            controlsBar

            HStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 14) {
                        if !appState.previewDirectoriesForDisplay.isEmpty {
                            sectionHeader("Folders")
                            LazyVGrid(columns: gridColumns, spacing: 10) {
                                ForEach(appState.previewDirectoriesForDisplay) { directory in
                                    directoryCard(directory)
                                }
                            }
                        }

                        if !appState.previewFilesForDisplay.isEmpty {
                            sectionHeader("Media")
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

                Rectangle()
                    .fill(Color.falchionBorder)
                    .frame(width: 1)

                metadataPanel
                    .frame(width: 320)
                    .background(Color.falchionCardSurface)
            }
        }
        .background(Color.falchionPane)
        .onAppear {
            if let selected = appState.selectedMediaItem {
                renameDraft = selected.name
            }
            directoryRenameDraft = appState.selectedDirectory?.name ?? ""
            if appState.selectedMoveDestinationDirectoryID == nil {
                appState.selectedMoveDestinationDirectoryID = appState.selectedDirectoryID
            }
        }
        .onChange(of: appState.previewMediaFilter) { _, _ in
            appState.reconcileSelectionAfterVisibilityChanges()
        }
        .onChange(of: appState.previewMediaSort) { _, _ in
            appState.reconcileSelectionAfterVisibilityChanges()
        }
        .onChange(of: appState.showHiddenMedia) { _, _ in
            appState.reconcileSelectionAfterVisibilityChanges()
        }
        .onChange(of: appState.selectedMediaID) { _, _ in
            tagDraft = ""
            renameDraft = appState.selectedMediaItem?.name ?? ""
        }
        .onChange(of: appState.selectedDirectoryID) { _, _ in
            directoryRenameDraft = appState.selectedDirectory?.name ?? ""
            if appState.selectedMoveDestinationDirectoryID == nil {
                appState.selectedMoveDestinationDirectoryID = appState.selectedDirectoryID
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 8) {
            Text("Preview")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.falchionTextPrimary)

            Text(appState.selectedDirectory?.displayPath ?? "No directory selected")
                .font(.system(size: 11))
                .foregroundStyle(Color.falchionTextSecondary)
                .lineLimit(1)

            Spacer()

            Text("\(appState.previewDirectoriesForDisplay.count) folders - \(appState.previewFilesForDisplay.count) media")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.falchionTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.falchionPane)
    }

    private var controlsBar: some View {
        HStack(spacing: 8) {
            Picker("Filter", selection: $appState.previewMediaFilter) {
                ForEach(PreviewMediaFilterOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 190)

            Picker("Size", selection: Binding(
                get: { appState.previewCardSize },
                set: { appState.setPreviewCardSizePreference($0) }
            )) {
                ForEach(PreviewCardSizeOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 120)

            Toggle(isOn: Binding(
                get: { appState.showHiddenMedia },
                set: { appState.setShowHidden($0) }
            )) {
                Text("Show Hidden")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.falchionTextSecondary)
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            Menu {
                Picker("Media Sort", selection: $appState.previewMediaSort) {
                    ForEach(PreviewMediaSortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }

                Divider()

                Picker("Folder Sort", selection: $appState.previewDirectorySort) {
                    ForEach(PreviewDirectorySortOption.allCases) { option in
                        Text(option.title).tag(option)
                    }
                }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
            .buttonStyle(FalchionMiniButtonStyle())

            Spacer()

            Button {
                Task {
                    await appState.renameSelectedDirectory(to: directoryRenameDraft)
                }
            } label: {
                Label("Rename Folder", systemImage: "folder.badge.gearshape")
            }
            .buttonStyle(FalchionMiniButtonStyle())
            .disabled(appState.selectedDirectory?.relativePath.isEmpty ?? true)

            Button {
                appState.requestDeleteSelectedDirectory()
            } label: {
                Label("Delete Folder", systemImage: "trash")
            }
            .buttonStyle(FalchionMiniButtonStyle())
            .disabled(appState.selectedDirectory?.relativePath.isEmpty ?? true)

            Button {
                appState.navigateToPreviousMedia()
            } label: {
                Label("Prev", systemImage: "chevron.left")
            }
            .buttonStyle(FalchionMiniButtonStyle())
            .disabled(appState.selectedMediaItem == nil)

            Button {
                appState.navigateToNextMedia()
            } label: {
                Label("Next", systemImage: "chevron.right")
            }
            .buttonStyle(FalchionMiniButtonStyle())
            .disabled(appState.selectedMediaItem == nil)

            Button("Open Viewer") {
                appState.openViewer(with: appState.selectedMediaID)
            }
            .buttonStyle(FalchionMiniButtonStyle())
            .disabled(appState.selectedMediaItem == nil)
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .background(Color.falchionPane)
    }

    private var metadataPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Inspector")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)

                Spacer()

                if let selectedMedia = appState.selectedMediaItem {
                    let metadata = appState.metadata(for: selectedMedia)
                    if metadata.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                    }
                    if metadata.isHidden {
                        Image(systemName: "eye.slash.fill")
                            .foregroundStyle(Color.falchionTextSecondary)
                    }
                }
            }

            if let selectedMedia = appState.selectedMediaItem {
                metadataEditor(for: selectedMedia)
            } else {
                Text("Select a media item to view metadata and file actions.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.falchionTextSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private func metadataEditor(for item: MediaItem) -> some View {
        let metadata = appState.metadata(for: item)

        return ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(item.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.falchionTextPrimary)
                    .lineLimit(2)

                Text(item.relativePath)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Button {
                        appState.toggleFavorite(for: item)
                    } label: {
                        Label(metadata.isFavorite ? "Favorite" : "Mark Favorite", systemImage: metadata.isFavorite ? "star.fill" : "star")
                    }
                    .buttonStyle(FalchionMiniButtonStyle(isActive: metadata.isFavorite))

                    Button {
                        appState.toggleHidden(for: item)
                    } label: {
                        Label(metadata.isHidden ? "Hidden" : "Hide", systemImage: metadata.isHidden ? "eye.slash.fill" : "eye")
                    }
                    .buttonStyle(FalchionMiniButtonStyle(isActive: metadata.isHidden))
                }

                fileOperationsSection(for: item)

                if item.kind == .video {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Video Preview")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.falchionTextSecondary)

                        VideoPlaybackView(url: item.url, layout: .compact)
                    }
                }

                tagSection(for: item, metadata: metadata)

                folderSection
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func fileOperationsSection(for item: MediaItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("File Operations")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.falchionTextSecondary)

            HStack(spacing: 6) {
                TextField("Rename file", text: $renameDraft)
                    .textFieldStyle(FalchionInputStyle())

                Button("Rename") {
                    Task {
                        await appState.renameSelectedMedia(to: renameDraft)
                    }
                }
                .buttonStyle(FalchionMiniButtonStyle())
                .disabled(renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            HStack(spacing: 6) {
                Picker("Move", selection: Binding(
                    get: { appState.selectedMoveDestinationDirectoryID ?? appState.selectedDirectoryID ?? "" },
                    set: { appState.selectedMoveDestinationDirectoryID = $0.isEmpty ? nil : $0 }
                )) {
                    ForEach(appState.filteredDirectories) { directory in
                        Text(directory.displayPath).tag(directory.id)
                    }
                }
                .labelsHidden()

                Button("Move") {
                    if let destinationID = appState.selectedMoveDestinationDirectoryID {
                        Task {
                            await appState.moveSelectedMedia(to: destinationID)
                        }
                    }
                }
                .buttonStyle(FalchionMiniButtonStyle())
                .disabled(appState.selectedMoveDestinationDirectoryID == nil)
            }

            HStack(spacing: 6) {
                Button {
                    Task {
                        await appState.reorderSelectedMedia(.previous)
                    }
                } label: {
                    Label("Reorder Up", systemImage: "arrow.up")
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button {
                    Task {
                        await appState.reorderSelectedMedia(.next)
                    }
                } label: {
                    Label("Reorder Down", systemImage: "arrow.down")
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Spacer(minLength: 0)

                Button(role: .destructive) {
                    appState.requestDeleteSelectedMedia()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(FalchionMiniButtonStyle())
            }
        }
    }

    private func tagSection(for item: MediaItem, metadata: MediaMetadata) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tags")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.falchionTextSecondary)

                Spacer()

                if !metadata.tags.isEmpty {
                    Button("Clear") {
                        appState.clearTags(for: item)
                    }
                    .buttonStyle(FalchionMiniButtonStyle())
                }
            }

            HStack(spacing: 6) {
                TextField("Add tag", text: $tagDraft)
                    .textFieldStyle(FalchionInputStyle())

                Button("Add") {
                    let newTag = tagDraft
                    tagDraft = ""
                    appState.addTag(newTag, for: item)
                }
                .buttonStyle(FalchionMiniButtonStyle())
                .disabled(tagDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if metadata.tags.isEmpty {
                Text("No tags")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(metadata.tags, id: \.self) { tag in
                        HStack(spacing: 6) {
                            Text(tag)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.falchionTextPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.falchionCardBase)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 3)
                                        .stroke(Color.falchionBorder, lineWidth: 1)
                                }
                                .cornerRadius(3)

                            Button {
                                appState.removeTag(tag, for: item)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.falchionTextSecondary)

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
    }

    private var folderSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Folder")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.falchionTextSecondary)

            TextField("Rename selected folder", text: $directoryRenameDraft)
                .textFieldStyle(FalchionInputStyle())

            HStack(spacing: 6) {
                Button("Rename Folder") {
                    Task {
                        await appState.renameSelectedDirectory(to: directoryRenameDraft)
                    }
                }
                .buttonStyle(FalchionMiniButtonStyle())
                .disabled(appState.selectedDirectory?.relativePath.isEmpty ?? true)

                Button("Delete Folder", role: .destructive) {
                    appState.requestDeleteSelectedDirectory()
                }
                .buttonStyle(FalchionMiniButtonStyle())
                .disabled(appState.selectedDirectory?.relativePath.isEmpty ?? true)
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.falchionTextSecondary)
            Spacer()
        }
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
                    Text("\(directory.directFileCount) direct - \(directory.recursiveFileCount) total")
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
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.falchionBorder, lineWidth: 1)
            }
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    private func mediaCard(_ item: MediaItem) -> some View {
        let metadata = appState.metadata(for: item)
        let isSelected = appState.selectedMediaID == item.id

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

                HStack(spacing: 6) {
                    Text(byteCountText(item.sizeBytes))
                    Text("-")
                    Text(modifiedDateText(item.modifiedAt))
                }
                .font(.system(size: 10))
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
            RoundedRectangle(cornerRadius: 4)
                .stroke(isSelected ? Color.falchionAccent : Color.falchionBorder, lineWidth: isSelected ? 1.5 : 1)
        }
        .cornerRadius(4)
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
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.falchionBorder, lineWidth: 1)
        }
        .cornerRadius(4)
    }

    private func byteCountText(_ bytes: Int64?) -> String {
        guard let bytes else {
            return "Unknown size"
        }

        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        return formatter.string(fromByteCount: bytes)
    }

    private func modifiedDateText(_ date: Date?) -> String {
        guard let date else {
            return "Unknown date"
        }

        return date.formatted(date: .abbreviated, time: .shortened)
    }
}
