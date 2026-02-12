import SwiftUI

struct SidebarPaneView: View {
    @EnvironmentObject private var appState: FalchionAppState

    private var rowVerticalPadding: CGFloat {
        appState.preferences.compactSidebarRows ? 3 : 6
    }

    var body: some View {
        VStack(spacing: 0) {
            headerPane
            listPane
            statusBar
        }
        .background(Color.falchionPane)
        .onChange(of: appState.folderSearchText) { _, _ in
            appState.reconcileSelectionAfterVisibilityChanges()
        }
        .onChange(of: appState.sidebarSort) { _, _ in
            appState.reconcileSelectionAfterVisibilityChanges()
        }
    }

    private var headerPane: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Button {
                    appState.showMenuOverlay = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button {
                    appState.refreshLibrary()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Button {
                    appState.chooseRootFolder()
                } label: {
                    Label("Choose Root", systemImage: "folder.badge.plus")
                }
                .buttonStyle(FalchionMiniButtonStyle())

                Spacer(minLength: 0)
            }

            TextField("Search folders or media", text: $appState.folderSearchText)
                .textFieldStyle(FalchionInputStyle())

            Text(appState.currentDirectory?.displayPath ?? "No root selected")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.falchionTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var listPane: some View {
        if appState.currentDirectory == nil {
            VStack(alignment: .leading, spacing: 6) {
                Text("No root selected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.falchionTextPrimary)
                Text("Choose Root to load folders and media.")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(12)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(appState.sidebarEntries) { entry in
                            sidebarEntryRow(entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .background(Color.clear)
                .onAppear {
                    guard let selectedID = appState.selectedSidebarEntryID else {
                        return
                    }
                    DispatchQueue.main.async {
                        proxy.scrollTo(selectedID, anchor: .center)
                    }
                }
                .onChange(of: appState.selectedSidebarEntryID) { _, selectedID in
                    guard let selectedID else {
                        return
                    }
                    proxy.scrollTo(selectedID, anchor: .center)
                }
            }
        }
    }

    private func sidebarEntryRow(_ entry: SidebarListEntry) -> some View {
        Button {
            appState.selectSidebarEntry(entry)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: entry.kind == .directory ? "folder" : (entry.media?.kind == .video ? "film" : "photo"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .frame(width: 16)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entryTitle(entry))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.falchionTextPrimary)
                        .lineLimit(1)

                    Text(entrySubtitle(entry))
                        .font(.system(size: 10))
                        .foregroundStyle(Color.falchionTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, rowVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(appState.isSidebarEntrySelected(entry) ? Color.accentColor.opacity(0.22) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if let directoryID = entry.directory?.id {
                appState.enterDirectory(directoryID)
            }
        }
    }

    private func entryTitle(_ entry: SidebarListEntry) -> String {
        if let directory = entry.directory {
            return directory.name
        }

        if let media = entry.media {
            if appState.preferences.showFileExtensions {
                return media.name
            }
            return URL(fileURLWithPath: media.name).deletingPathExtension().lastPathComponent
        }

        return "Unknown"
    }

    private func entrySubtitle(_ entry: SidebarListEntry) -> String {
        if let directory = entry.directory {
            if !appState.preferences.showMetadataBadges {
                return "\(directory.directFileCount) direct • \(directory.recursiveFileCount) total"
            }
            return "\(directory.directFileCount) direct • \(directory.recursiveFileCount) total • \(appState.directoryMetadataText(directory))"
        }

        if let media = entry.media {
            if appState.preferences.showPathsInSidebar {
                return appState.mediaListMetadataText(media)
            }
            return media.kind == .video ? "Video" : "Image"
        }

        return ""
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Text(appState.directoryPaneSummary)
                .font(.system(size: 11))
                .foregroundStyle(Color.falchionTextSecondary)
                .lineLimit(1)

            Spacer()

            Text(appState.statusMessage)
                .font(.system(size: 10))
                .foregroundStyle(Color.falchionTextSecondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.falchionCardSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.falchionBorder)
                .frame(height: 1)
        }
    }
}
