import SwiftUI

struct SidebarPaneView: View {
    @EnvironmentObject private var appState: FalchionAppState

    var body: some View {
        VStack(spacing: 0) {
            titlePane
            directoriesPane
            statusBar
        }
        .background(Color.falchionPane)
    }

    private var titlePane: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 10) {
                Text(appState.titleText)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.falchionTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Button("Refresh") {
                        appState.refreshLibrary()
                    }
                    .buttonStyle(FalchionMiniButtonStyle())

                    Button("⚙") {
                        appState.showMenuOverlay.toggle()
                    }
                    .buttonStyle(FalchionMiniButtonStyle())

                    Button("Choose Root") {
                        appState.chooseRootFolder()
                    }
                    .buttonStyle(FalchionMiniButtonStyle())
                }
            }

            HStack(spacing: 6) {
                TextField("Search folder", text: $appState.folderSearchText)
                    .textFieldStyle(FalchionInputStyle())

                Button("X") {
                    appState.folderSearchText = ""
                }
                .buttonStyle(FalchionMiniButtonStyle())
            }

            HStack(spacing: 6) {
                TextField("Enter URL", text: $appState.profileURLText)
                    .textFieldStyle(FalchionInputStyle())

                Button("Add Profile") {
                    Task {
                        await appState.addOnlineProfile(mode: .profile)
                    }
                }
                    .buttonStyle(FalchionMiniButtonStyle())

                Button("Add Posts") {
                    Task {
                        await appState.addOnlineProfile(mode: .posts)
                    }
                }
                    .buttonStyle(FalchionMiniButtonStyle())

                Text(appState.onlineProfileStatusText)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private var directoriesPane: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text("Directories")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.falchionTextSecondary)

                Spacer()

                Menu {
                    Picker("Sort", selection: $appState.previewDirectorySort) {
                        ForEach(PreviewDirectorySortOption.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .menuStyle(.borderlessButton)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.falchionTextSecondary)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 2)

            HStack {
                Text(appState.directoryPaneSummary)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)

            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(appState.filteredDirectories) { directory in
                        directoryRow(directory)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
            }
        }
    }

    private func directoryRow(_ directory: LibraryDirectory) -> some View {
        let isSelected = directory.id == appState.selectedDirectoryID

        return Button {
            appState.selectDirectory(directory.id)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: directory.relativePath.isEmpty ? "externaldrive.fill" : "folder.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 18)
                    .foregroundStyle(Color.falchionTextSecondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(directory.displayPath)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.falchionTextPrimary)
                        .lineLimit(1)
                    Text("\(directory.directFileCount) direct • \(directory.recursiveFileCount) total")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.falchionTextSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(appState.directoryMetadataText(directory))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.falchionTextSecondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.falchionCardSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.falchionBorder, lineWidth: 1)
                    }
                    .cornerRadius(3)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Color.falchionRowSelected : Color.falchionRow)
            .overlay {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(isSelected ? Color.falchionBorderStrong : Color.clear, lineWidth: 1)
            }
            .cornerRadius(3)
        }
        .buttonStyle(.plain)
    }

    private var statusBar: some View {
        HStack(spacing: 8) {
            Text(appState.statusMessage)
                .font(.system(size: 11))
                .foregroundStyle(Color.falchionTextSecondary)
                .lineLimit(1)

            Spacer()

            Text(appState.selectedDirectory?.displayPath ?? "No folder selected")
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
