import AppKit
import Combine
import Foundation
import SwiftUI

enum PreviewDirectorySortOption: String, CaseIterable, Identifiable {
    case nameAscending
    case mostMedia

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nameAscending:
            return "Folder: Name"
        case .mostMedia:
            return "Folder: Most Media"
        }
    }
}

enum PreviewMediaFilterOption: String, CaseIterable, Identifiable {
    case all
    case images
    case videos

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .images:
            return "Images"
        case .videos:
            return "Videos"
        }
    }
}

enum PreviewMediaSortOption: String, CaseIterable, Identifiable {
    case nameAscending
    case nameDescending
    case newestFirst
    case oldestFirst
    case largestFirst
    case smallestFirst

    var id: String { rawValue }

    var title: String {
        switch self {
        case .nameAscending:
            return "Media: Name A-Z"
        case .nameDescending:
            return "Media: Name Z-A"
        case .newestFirst:
            return "Media: Newest"
        case .oldestFirst:
            return "Media: Oldest"
        case .largestFirst:
            return "Media: Largest"
        case .smallestFirst:
            return "Media: Smallest"
        }
    }
}

enum PreviewCardSizeOption: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small:
            return "S"
        case .medium:
            return "M"
        case .large:
            return "L"
        }
    }

    var gridMinimum: CGFloat {
        switch self {
        case .small:
            return 170
        case .medium:
            return 220
        case .large:
            return 280
        }
    }

    var thumbnailHeight: CGFloat {
        switch self {
        case .small:
            return 110
        case .medium:
            return 140
        case .large:
            return 180
        }
    }
}

@MainActor
final class FalchionAppState: ObservableObject {
    @Published var sidebarWidth: CGFloat = 340
    @Published var folderSearchText: String = ""
    @Published var profileURLText: String = ""

    @Published var showMenuOverlay: Bool = false
    @Published var showViewerOverlay: Bool = false
    @Published var menuTab: FalchionMenuTab = .options

    @Published var previewDirectorySort: PreviewDirectorySortOption = .nameAscending
    @Published var previewMediaFilter: PreviewMediaFilterOption = .all
    @Published var previewMediaSort: PreviewMediaSortOption = .nameAscending
    @Published var previewCardSize: PreviewCardSizeOption = .medium
    @Published var showHiddenMedia: Bool = false

    @Published var optionsStatusText: String = "Saved automatically"
    @Published var keybindStatusText: String = "Saved automatically"
    @Published var onlineProfileStatusText: String = "-"

    @Published var showDeleteMediaConfirmation: Bool = false
    @Published var showDeleteDirectoryConfirmation: Bool = false
    @Published var showOperationAlert: Bool = false
    @Published var operationAlertTitle: String = "Falchion"
    @Published var operationAlertMessage: String = ""

    @Published var selectedMoveDestinationDirectoryID: String?
    @Published var selectedSavedResponseID: UUID?

    @Published private(set) var roots: [LibraryRoot] = []
    @Published private(set) var snapshot: LibrarySnapshot = .empty
    @Published private(set) var selectedDirectoryID: String?
    @Published private(set) var selectedMediaID: String?
    @Published private(set) var statusMessage: String = "Choose Root to begin."
    @Published private(set) var isIndexing: Bool = false

    @Published private(set) var metadataByKey: [String: MediaMetadata] = [:]
    @Published private(set) var viewerStatusText: String = "No media selected"

    @Published private(set) var preferences: AppPreferences = .default
    @Published private(set) var onlineProfiles: [OnlineProfileRecord] = []
    @Published private(set) var onlineResponseLog: [OnlineResponseLogEntry] = []

    private let bookmarkStore: SecurityScopedBookmarkStore
    private let scanner: LibraryScanner
    private let metadataStore: MediaMetadataStore
    private let preferencesStore: AppPreferencesStore
    private let onlineProfilesStore: OnlineProfilesStore
    private let fileOperations: FileOperationsService
    private let onlineService: OnlineProfileService

    private var didBootstrap: Bool = false
    private var indexTask: Task<Void, Never>?
    private var metadataPersistTask: Task<Void, Never>?
    private var preferencesPersistTask: Task<Void, Never>?
    private var onlineProfilesPersistTask: Task<Void, Never>?

    private var pendingDeleteMedia: MediaItem?
    private var pendingDeleteDirectory: LibraryDirectory?
    private var pendingSelectedMediaPath: String?
    private var pendingSelectedDirectoryPath: String?
    private var pendingPostRefreshStatus: String?

    init(
        bookmarkStore: SecurityScopedBookmarkStore,
        scanner: LibraryScanner,
        metadataStore: MediaMetadataStore,
        preferencesStore: AppPreferencesStore,
        onlineProfilesStore: OnlineProfilesStore,
        fileOperations: FileOperationsService,
        onlineService: OnlineProfileService
    ) {
        self.bookmarkStore = bookmarkStore
        self.scanner = scanner
        self.metadataStore = metadataStore
        self.preferencesStore = preferencesStore
        self.onlineProfilesStore = onlineProfilesStore
        self.fileOperations = fileOperations
        self.onlineService = onlineService
    }

    convenience init() {
        self.init(
            bookmarkStore: SecurityScopedBookmarkStore(),
            scanner: LibraryScanner(),
            metadataStore: MediaMetadataStore(),
            preferencesStore: AppPreferencesStore(),
            onlineProfilesStore: OnlineProfilesStore(),
            fileOperations: FileOperationsService(),
            onlineService: OnlineProfileService()
        )
    }

    deinit {
        indexTask?.cancel()
        metadataPersistTask?.cancel()
        preferencesPersistTask?.cancel()
        onlineProfilesPersistTask?.cancel()
    }

    func bootstrapIfNeeded() async {
        guard !didBootstrap else {
            return
        }

        didBootstrap = true
        metadataByKey = await metadataStore.load()

        preferences = await preferencesStore.load()
        if let size = PreviewCardSizeOption(rawValue: preferences.previewCardSizeRaw) {
            previewCardSize = size
        }
        FalchionThemeRuntime.apply(theme: preferences.theme, retroMode: preferences.retroMode)

        onlineProfiles = await onlineProfilesStore.load()
        onlineProfiles.sort { $0.fetchedAt > $1.fetchedAt }

        roots = bookmarkStore.restorePersistedRoots()
        guard !roots.isEmpty else {
            snapshot = .empty
            selectedDirectoryID = nil
            selectedMediaID = nil
            statusMessage = "Choose Root to begin."
            return
        }

        refreshLibrary(reason: "Indexing restored roots...")
    }

    func chooseRootFolder() {
        guard let addedRoot = bookmarkStore.pickAndPersistFolder() else {
            return
        }

        roots = bookmarkStore.currentRoots
        statusMessage = "Added root: \(addedRoot.displayName)"
        refreshLibrary(reason: "Indexing \(roots.count) root(s)...")
    }

    func refreshLibrary(reason: String = "Refreshing library...") {
        guard !roots.isEmpty else {
            snapshot = .empty
            selectedDirectoryID = nil
            selectedMediaID = nil
            statusMessage = "Choose Root to begin."
            return
        }

        indexTask?.cancel()

        isIndexing = true
        statusMessage = reason

        let rootsSnapshot = roots
        indexTask = Task { [scanner] in
            let builtSnapshot = await scanner.buildSnapshot(for: rootsSnapshot)
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self.snapshot = builtSnapshot
                self.isIndexing = false

                self.restorePendingSelectionAfterRefresh()
                self.syncSelectionAfterRefresh()
                self.reconcileSelectionAfterVisibilityChanges()

                if let pendingPostRefreshStatus = self.pendingPostRefreshStatus {
                    self.statusMessage = pendingPostRefreshStatus
                    self.pendingPostRefreshStatus = nil
                } else {
                    self.statusMessage = "Indexed \(self.totalMediaCount) media files across \(rootsSnapshot.count) root(s)."
                }
            }
        }
    }

    func selectDirectory(_ directoryID: String) {
        selectedDirectoryID = directoryID
        selectedMoveDestinationDirectoryID = directoryID
        reconcileSelectionAfterVisibilityChanges()
    }

    func selectMedia(_ mediaID: String?) {
        selectedMediaID = mediaID
        updateViewerStatusText()
    }

    func openViewer(with mediaID: String?) {
        if let mediaID {
            selectMedia(mediaID)
        }

        if selectedMediaItem == nil {
            reconcileSelectionAfterVisibilityChanges()
        }

        guard selectedMediaItem != nil else {
            statusMessage = "No media available to open."
            return
        }

        withAnimation(.easeInOut(duration: 0.2)) {
            showViewerOverlay = true
        }
    }

    func closeViewer() {
        withAnimation(.easeInOut(duration: 0.16)) {
            showViewerOverlay = false
        }
    }

    func handleKeyboardEvent(_ event: NSEvent) -> Bool {
        guard let token = KeyToken.from(event: event),
              let action = preferences.action(for: token)
        else {
            return false
        }

        switch action {
        case .nextMedia:
            navigateToNextMedia()
        case .previousMedia:
            navigateToPreviousMedia()
        case .openViewer:
            openViewer(with: selectedMediaID)
        case .closeOverlay:
            if showViewerOverlay {
                closeViewer()
            } else if showMenuOverlay {
                showMenuOverlay = false
            }
        case .nextDirectory:
            navigateToNextDirectory()
        case .previousDirectory:
            navigateToPreviousDirectory()
        case .toggleMenu:
            showMenuOverlay.toggle()
        case .refresh:
            refreshLibrary()
        }

        return true
    }

    func navigateToNextMedia() {
        guard let currentDirectoryID = selectedDirectoryID else {
            return
        }

        let currentFiles = visibleFiles(in: currentDirectoryID)

        if currentFiles.isEmpty {
            if let nextDirectory = nextDirectoryWithVisibleMedia(after: currentDirectoryID) {
                selectedDirectoryID = nextDirectory
                selectMedia(visibleFiles(in: nextDirectory).first?.id)
            }
            return
        }

        if let selectedMediaID,
           let currentIndex = currentFiles.firstIndex(where: { $0.id == selectedMediaID }),
           currentIndex < currentFiles.count - 1 {
            selectMedia(currentFiles[currentIndex + 1].id)
            return
        }

        if let nextDirectory = nextDirectoryWithVisibleMedia(after: currentDirectoryID) {
            selectedDirectoryID = nextDirectory
            selectMedia(visibleFiles(in: nextDirectory).first?.id)
        } else {
            selectMedia(currentFiles.first?.id)
        }
    }

    func navigateToPreviousMedia() {
        guard let currentDirectoryID = selectedDirectoryID else {
            return
        }

        let currentFiles = visibleFiles(in: currentDirectoryID)

        if currentFiles.isEmpty {
            if let previousDirectory = previousDirectoryWithVisibleMedia(before: currentDirectoryID) {
                selectedDirectoryID = previousDirectory
                selectMedia(visibleFiles(in: previousDirectory).last?.id)
            }
            return
        }

        if let selectedMediaID,
           let currentIndex = currentFiles.firstIndex(where: { $0.id == selectedMediaID }),
           currentIndex > 0 {
            selectMedia(currentFiles[currentIndex - 1].id)
            return
        }

        if let previousDirectory = previousDirectoryWithVisibleMedia(before: currentDirectoryID) {
            selectedDirectoryID = previousDirectory
            selectMedia(visibleFiles(in: previousDirectory).last?.id)
        } else {
            selectMedia(currentFiles.last?.id)
        }
    }

    func navigateToNextDirectory() {
        guard let currentDirectoryID = selectedDirectoryID else {
            return
        }

        let directoryIDs = filteredDirectories.map(\.id)
        guard let currentIndex = directoryIDs.firstIndex(of: currentDirectoryID), currentIndex < directoryIDs.count - 1 else {
            return
        }

        let nextID = directoryIDs[currentIndex + 1]
        selectedDirectoryID = nextID
        selectedMoveDestinationDirectoryID = nextID
        reconcileSelectionAfterVisibilityChanges()
    }

    func navigateToPreviousDirectory() {
        guard let currentDirectoryID = selectedDirectoryID else {
            return
        }

        let directoryIDs = filteredDirectories.map(\.id)
        guard let currentIndex = directoryIDs.firstIndex(of: currentDirectoryID), currentIndex > 0 else {
            return
        }

        let previousID = directoryIDs[currentIndex - 1]
        selectedDirectoryID = previousID
        selectedMoveDestinationDirectoryID = previousID
        reconcileSelectionAfterVisibilityChanges()
    }

    func requestDeleteSelectedMedia() {
        guard let selected = selectedMediaItem else {
            return
        }

        pendingDeleteMedia = selected
        showDeleteMediaConfirmation = true
    }

    func confirmDeleteSelectedMedia() async {
        showDeleteMediaConfirmation = false

        guard let target = pendingDeleteMedia else {
            return
        }
        pendingDeleteMedia = nil

        do {
            try await fileOperations.delete(item: target)
            pendingPostRefreshStatus = "Deleted '\(target.name)'."
            refreshLibrary(reason: "Refreshing after delete...")
        } catch {
            presentOperationError("Delete failed for '\(target.name)'.")
        }
    }

    func renameSelectedMedia(to nextName: String) async {
        guard let selected = selectedMediaItem else {
            return
        }

        do {
            let destinationURL = try await fileOperations.rename(item: selected, to: nextName, policy: preferences.defaultConflictPolicy)
            pendingSelectedMediaPath = destinationURL.standardizedFileURL.path
            pendingPostRefreshStatus = "Renamed to '\(destinationURL.lastPathComponent)'."
            refreshLibrary(reason: "Refreshing after rename...")
        } catch FileOperationError.conflict(let existing) {
            presentOperationError("Rename conflict: '\(existing)' already exists.")
        } catch {
            presentOperationError("Rename failed.")
        }
    }

    func moveSelectedMedia(to destinationDirectoryID: String) async {
        guard let selected = selectedMediaItem,
              let destinationDirectory = snapshot.directoriesByID[destinationDirectoryID],
              let destinationURL = url(for: destinationDirectory)
        else {
            return
        }

        do {
            let destinationFileURL = try await fileOperations.move(item: selected, to: destinationURL, policy: preferences.defaultConflictPolicy)
            pendingSelectedMediaPath = destinationFileURL.standardizedFileURL.path
            pendingSelectedDirectoryPath = destinationURL.standardizedFileURL.path
            pendingPostRefreshStatus = "Moved '\(selected.name)' to '\(destinationDirectory.name)'."
            refreshLibrary(reason: "Refreshing after move...")
        } catch FileOperationError.conflict(let existing) {
            presentOperationError("Move conflict: '\(existing)' already exists.")
        } catch {
            presentOperationError("Move failed.")
        }
    }

    func reorderSelectedMedia(_ direction: ReorderDirection) async {
        guard let selected = selectedMediaItem else {
            return
        }

        let siblings = previewFilesForDisplay
        do {
            let destinationURL = try await fileOperations.reorder(item: selected, among: siblings, direction: direction)
            pendingSelectedMediaPath = destinationURL.standardizedFileURL.path
            pendingPostRefreshStatus = "Updated file order in folder."
            refreshLibrary(reason: "Refreshing after reorder...")
        } catch {
            presentOperationError("Reorder failed.")
        }
    }

    func requestDeleteSelectedDirectory() {
        guard let directory = selectedDirectory, !directory.relativePath.isEmpty else {
            presentOperationError("Root directories cannot be deleted from the app shell.")
            return
        }

        pendingDeleteDirectory = directory
        showDeleteDirectoryConfirmation = true
    }

    func confirmDeleteSelectedDirectory() async {
        showDeleteDirectoryConfirmation = false

        guard let directory = pendingDeleteDirectory,
              let directoryURL = url(for: directory)
        else {
            pendingDeleteDirectory = nil
            return
        }
        pendingDeleteDirectory = nil

        do {
            try await fileOperations.deleteDirectory(at: directoryURL)
            if let parentID = directory.parentID,
               let parentDirectory = snapshot.directoriesByID[parentID],
               let parentURL = url(for: parentDirectory) {
                pendingSelectedDirectoryPath = parentURL.standardizedFileURL.path
            }
            pendingPostRefreshStatus = "Deleted folder '\(directory.name)'."
            refreshLibrary(reason: "Refreshing after folder delete...")
        } catch {
            presentOperationError("Folder delete failed.")
        }
    }

    func renameSelectedDirectory(to nextName: String) async {
        guard let directory = selectedDirectory,
              !directory.relativePath.isEmpty,
              let directoryURL = url(for: directory)
        else {
            presentOperationError("Root directories cannot be renamed from the app shell.")
            return
        }

        do {
            let destinationURL = try await fileOperations.renameDirectory(at: directoryURL, to: nextName, policy: preferences.defaultConflictPolicy)
            pendingSelectedDirectoryPath = destinationURL.standardizedFileURL.path
            pendingPostRefreshStatus = "Renamed folder to '\(destinationURL.lastPathComponent)'."
            refreshLibrary(reason: "Refreshing after folder rename...")
        } catch FileOperationError.conflict(let existing) {
            presentOperationError("Folder rename conflict: '\(existing)' already exists.")
        } catch {
            presentOperationError("Folder rename failed.")
        }
    }

    func addOnlineProfile(mode: OnlineImportMode) async {
        let raw = profileURLText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            onlineProfileStatusText = "Enter a profile URL."
            return
        }

        guard let root = onlineImportRoot() else {
            onlineProfileStatusText = "Choose a root folder before importing online media."
            return
        }

        onlineProfileStatusText = "Fetching \(mode.title.lowercased())..."

        do {
            let descriptor = try await onlineService.parseProfileURL(raw)
            let fetchResult = await onlineService.fetchPosts(for: descriptor, loadMode: preferences.onlineLoadMode)
            appendOnlineResponses(fetchResult.responses)

            if let errorCode = fetchResult.errorCode {
                onlineProfileStatusText = onlineErrorMessage(errorCode)
                return
            }

            guard !fetchResult.posts.isEmpty else {
                onlineProfileStatusText = "No posts found for this profile."
                return
            }

            if mode == .profile, let existing = onlineProfiles.first(where: { $0.descriptor.profileKey == descriptor.profileKey }) {
                await deleteOnlineProfile(existing, suppressRefresh: true)
            }

            let importResult = try await onlineService.importPosts(
                profile: descriptor,
                posts: fetchResult.posts,
                mode: mode,
                into: root.url,
                conflictPolicy: preferences.defaultConflictPolicy
            )

            if importResult.importedFiles == 0 {
                onlineProfileStatusText = "Fetched posts but no media files were imported."
                return
            }

            let record = OnlineProfileRecord(
                descriptor: descriptor,
                importMode: mode,
                rootID: root.id,
                baseRelativePath: importResult.baseRelativePath,
                postCount: importResult.importedPosts,
                fileCount: importResult.importedFiles,
                fetchedAt: Date()
            )

            upsertOnlineProfileRecord(record)
            onlineProfileStatusText = "Imported \(importResult.importedFiles) files from \(descriptor.service.title)."
            pendingPostRefreshStatus = onlineProfileStatusText
            refreshLibrary(reason: "Indexing imported online media...")
            renderOnlineTabIfVisible()
        } catch FileOperationError.conflict(let existing) {
            onlineProfileStatusText = "Import conflict: '\(existing)' exists."
        } catch {
            onlineProfileStatusText = "Online import failed."
        }
    }

    func refreshOnlineProfile(_ record: OnlineProfileRecord) async {
        guard let root = roots.first(where: { $0.id == record.rootID }) else {
            onlineProfileStatusText = "Root for this profile is no longer available."
            return
        }

        onlineProfileStatusText = "Refreshing \(record.descriptor.userID)..."
        let fetchResult = await onlineService.fetchPosts(for: record.descriptor, loadMode: preferences.onlineLoadMode)
        appendOnlineResponses(fetchResult.responses)

        if let errorCode = fetchResult.errorCode {
            onlineProfileStatusText = onlineErrorMessage(errorCode)
            return
        }

        guard !fetchResult.posts.isEmpty else {
            onlineProfileStatusText = "No posts found during refresh."
            return
        }

        do {
            let importResult = try await onlineService.importPosts(
                profile: record.descriptor,
                posts: fetchResult.posts,
                mode: record.importMode,
                into: root.url,
                conflictPolicy: .keepBoth
            )

            var updated = record
            updated.fileCount += importResult.importedFiles
            updated.postCount = max(updated.postCount, importResult.importedPosts)
            updated.fetchedAt = Date()
            upsertOnlineProfileRecord(updated)

            onlineProfileStatusText = "Refresh imported \(importResult.importedFiles) new files."
            pendingPostRefreshStatus = onlineProfileStatusText
            refreshLibrary(reason: "Refreshing library after online refresh...")
        } catch {
            onlineProfileStatusText = "Refresh failed."
        }
    }

    func replaceOnlineProfile(_ record: OnlineProfileRecord) async {
        await deleteOnlineProfile(record, suppressRefresh: true)
        profileURLText = record.descriptor.sourceURL
        await addOnlineProfile(mode: record.importMode)
    }

    func deleteOnlineProfile(_ record: OnlineProfileRecord, suppressRefresh: Bool = false) async {
        guard let root = roots.first(where: { $0.id == record.rootID }) else {
            onlineProfiles.removeAll { $0.id == record.id }
            persistOnlineProfiles()
            return
        }

        let folderURL = root.url.appendingPathComponent(record.baseRelativePath, isDirectory: true).standardizedFileURL

        do {
            if FileManager.default.fileExists(atPath: folderURL.path) {
                try await fileOperations.deleteDirectory(at: folderURL)
            }

            onlineProfiles.removeAll { $0.id == record.id }
            persistOnlineProfiles()

            onlineProfileStatusText = "Deleted profile import '\(record.descriptor.userID)'."
            if !suppressRefresh {
                pendingPostRefreshStatus = onlineProfileStatusText
                refreshLibrary(reason: "Refreshing library after online delete...")
            }
        } catch {
            onlineProfileStatusText = "Failed to delete profile import."
        }
    }

    func clearOnlineResponses() {
        onlineResponseLog.removeAll()
    }

    func addSavedResponse(title: String, body: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else {
            return
        }

        let finalTitle = trimmedTitle.isEmpty ? "Untitled" : trimmedTitle
        let template = SavedResponseTemplate(title: finalTitle, body: trimmedBody)
        preferences.savedResponses.insert(template, at: 0)
        persistPreferences()
    }

    func removeSavedResponse(_ id: UUID) {
        preferences.savedResponses.removeAll { $0.id == id }
        if selectedSavedResponseID == id {
            selectedSavedResponseID = nil
        }
        persistPreferences()
    }

    func resetSavedResponses() {
        preferences.savedResponses.removeAll()
        selectedSavedResponseID = nil
        persistPreferences()
    }

    func setTheme(_ theme: FalchionThemeOption) {
        preferences.theme = theme
        applyThemeFromPreferences()
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func setRetroMode(_ enabled: Bool) {
        preferences.retroMode = enabled
        applyThemeFromPreferences()
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func setThumbnailFitMode(_ mode: ThumbnailFitMode) {
        preferences.thumbnailFitMode = mode
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func setPreviewCardSizePreference(_ size: PreviewCardSizeOption) {
        previewCardSize = size
        preferences.previewCardSizeRaw = size.rawValue
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func setConflictPolicy(_ policy: FileConflictPolicy) {
        preferences.defaultConflictPolicy = policy
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func setOptionDescriptionsVisible(_ visible: Bool) {
        preferences.showOptionDescriptions = visible
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func setKeybindDescriptionsVisible(_ visible: Bool) {
        preferences.showKeybindDescriptions = visible
        keybindStatusText = "Saved"
        persistPreferences()
    }

    func setOnlineLoadMode(_ mode: OnlineLoadMode) {
        preferences.onlineLoadMode = mode
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func setListOnlineFoldersFirst(_ enabled: Bool) {
        preferences.listOnlineFoldersFirst = enabled
        optionsStatusText = "Saved"
        persistPreferences()
    }

    func updateKeyBinding(action: KeybindAction, token: KeyToken?) {
        preferences.setBinding(token, for: action)
        keybindStatusText = "Saved"
        persistPreferences()
    }

    func resetKeyBindings() {
        preferences.keyBindings = AppPreferences.default.keyBindings
        keybindStatusText = "Reset"
        persistPreferences()
    }

    func resetAllOptions() {
        let oldSavedResponses = preferences.savedResponses
        preferences = .default
        preferences.savedResponses = oldSavedResponses
        if let size = PreviewCardSizeOption(rawValue: preferences.previewCardSizeRaw) {
            previewCardSize = size
        }
        applyThemeFromPreferences()
        optionsStatusText = "Reset"
        persistPreferences()
    }

    func metadata(for item: MediaItem) -> MediaMetadata {
        metadataByKey[item.metadataStorageKey] ?? .empty
    }

    func setFavorite(_ value: Bool, for item: MediaItem) {
        mutateMetadata(for: item) { metadata in
            metadata.isFavorite = value
        }
    }

    func toggleFavorite(for item: MediaItem) {
        mutateMetadata(for: item) { metadata in
            metadata.isFavorite.toggle()
        }
    }

    func setHidden(_ value: Bool, for item: MediaItem) {
        mutateMetadata(for: item) { metadata in
            metadata.isHidden = value
        }

        reconcileSelectionAfterVisibilityChanges()
    }

    func toggleHidden(for item: MediaItem) {
        mutateMetadata(for: item) { metadata in
            metadata.isHidden.toggle()
        }

        reconcileSelectionAfterVisibilityChanges()
    }

    func addTag(_ rawTag: String, for item: MediaItem) {
        let normalized = normalizeTag(rawTag)
        guard !normalized.isEmpty else {
            return
        }

        mutateMetadata(for: item) { metadata in
            if !metadata.tags.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
                metadata.tags.append(normalized)
                metadata.tags.sort { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            }
        }
    }

    func removeTag(_ tag: String, for item: MediaItem) {
        mutateMetadata(for: item) { metadata in
            metadata.tags.removeAll { $0.caseInsensitiveCompare(tag) == .orderedSame }
        }
    }

    func clearTags(for item: MediaItem) {
        mutateMetadata(for: item) { metadata in
            metadata.tags.removeAll()
        }
    }

    func setShowHidden(_ value: Bool) {
        showHiddenMedia = value
        reconcileSelectionAfterVisibilityChanges()
    }

    var titleText: String {
        selectedDirectory?.name ?? "Falchion"
    }

    var selectedDirectory: LibraryDirectory? {
        guard let selectedDirectoryID else {
            return nil
        }

        return snapshot.directoriesByID[selectedDirectoryID]
    }

    var selectedMediaItem: MediaItem? {
        guard let selectedMediaID else {
            return nil
        }

        return previewFilesForDisplay.first { $0.id == selectedMediaID }
    }

    var totalDirectoryCount: Int {
        snapshot.allDirectories.count
    }

    var totalMediaCount: Int {
        snapshot.filesByDirectoryID.values.reduce(0) { partialResult, files in
            partialResult + files.count
        }
    }

    var directoryPaneSummary: String {
        "\(filteredDirectories.count)/\(totalDirectoryCount) dirs - \(visibleMediaCount) visible - \(roots.count) roots"
    }

    var visibleMediaCount: Int {
        snapshot.filesByDirectoryID.values.flatMap { files in
            files.filter(shouldShowMedia)
        }.count
    }

    var thumbnailFitMode: ThumbnailFitMode {
        preferences.thumbnailFitMode
    }

    var keyBindingRows: [KeyBinding] {
        let byAction = Dictionary(uniqueKeysWithValues: preferences.keyBindings.map { ($0.action, $0) })
        return KeybindAction.allCases.compactMap { action in
            byAction[action] ?? KeyBinding(action: action, token: nil)
        }
    }

    func keyToken(for action: KeybindAction) -> KeyToken? {
        preferences.token(for: action)
    }

    var configurationSummaryJSON: String {
        struct ConfigSummary: Codable {
            var theme: String
            var retroMode: Bool
            var thumbnailFitMode: String
            var defaultConflictPolicy: String
            var onlineLoadMode: String
            var listOnlineFoldersFirst: Bool
            var keyBindings: [String: String]
            var savedResponses: Int
            var onlineProfiles: Int
        }

        var map: [String: String] = [:]
        for binding in preferences.keyBindings {
            map[binding.action.rawValue] = binding.token?.rawValue ?? ""
        }

        let summary = ConfigSummary(
            theme: preferences.theme.rawValue,
            retroMode: preferences.retroMode,
            thumbnailFitMode: preferences.thumbnailFitMode.rawValue,
            defaultConflictPolicy: preferences.defaultConflictPolicy.rawValue,
            onlineLoadMode: preferences.onlineLoadMode.rawValue,
            listOnlineFoldersFirst: preferences.listOnlineFoldersFirst,
            keyBindings: map,
            savedResponses: preferences.savedResponses.count,
            onlineProfiles: onlineProfiles.count
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(summary),
           let text = String(data: data, encoding: .utf8) {
            return text
        }

        return "{}"
    }

    func directoryMetadataText(_ directory: LibraryDirectory) -> String {
        let allFiles = snapshot.filesByDirectoryID[directory.id] ?? []
        let favoriteCount = allFiles.filter { metadata(for: $0).isFavorite }.count
        let hiddenCount = allFiles.filter { metadata(for: $0).isHidden }.count

        return "\(directory.recursiveFileCount) - *\(favoriteCount) - H\(hiddenCount)"
    }

    var filteredDirectories: [LibraryDirectory] {
        let query = folderSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let directories = snapshot.allDirectories

        let filtered: [LibraryDirectory]
        if query.isEmpty {
            filtered = directories
        } else {
            filtered = directories.filter { directory in
                directory.displayPath.localizedCaseInsensitiveContains(query)
                    || directory.name.localizedCaseInsensitiveContains(query)
            }
        }

        return filtered.sorted { lhs, rhs in
            let leftIsOnline = isOnlineDirectory(lhs)
            let rightIsOnline = isOnlineDirectory(rhs)
            if preferences.listOnlineFoldersFirst, leftIsOnline != rightIsOnline {
                return leftIsOnline && !rightIsOnline
            }

            switch previewDirectorySort {
            case .nameAscending:
                return lhs.displayPath.localizedCaseInsensitiveCompare(rhs.displayPath) == .orderedAscending
            case .mostMedia:
                if lhs.recursiveFileCount != rhs.recursiveFileCount {
                    return lhs.recursiveFileCount > rhs.recursiveFileCount
                }
                return lhs.displayPath.localizedCaseInsensitiveCompare(rhs.displayPath) == .orderedAscending
            }
        }
    }

    var previewDirectoriesForDisplay: [LibraryDirectory] {
        guard let selectedDirectoryID else {
            return []
        }

        let childIDs = snapshot.childDirectoryIDsByParentID[selectedDirectoryID] ?? []
        let directories = childIDs.compactMap { snapshot.directoriesByID[$0] }

        return directories.sorted { lhs, rhs in
            switch previewDirectorySort {
            case .nameAscending:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .mostMedia:
                if lhs.recursiveFileCount != rhs.recursiveFileCount {
                    return lhs.recursiveFileCount > rhs.recursiveFileCount
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }

    var previewFilesForDisplay: [MediaItem] {
        guard let selectedDirectoryID else {
            return []
        }

        return visibleFiles(in: selectedDirectoryID)
    }

    var viewerPositionLabel: String {
        let files = previewFilesForDisplay
        guard
            let selectedMediaID,
            let index = files.firstIndex(where: { $0.id == selectedMediaID })
        else {
            return "0 / \(files.count)"
        }

        return "\(index + 1) / \(files.count)"
    }

    func reconcileSelectionAfterVisibilityChanges() {
        guard let selectedDirectoryID else {
            selectedMediaID = nil
            updateViewerStatusText()
            return
        }

        let files = visibleFiles(in: selectedDirectoryID)

        if files.isEmpty {
            selectedMediaID = nil
            if showViewerOverlay {
                closeViewer()
            }
            updateViewerStatusText()
            return
        }

        if let selectedMediaID, files.contains(where: { $0.id == selectedMediaID }) {
            updateViewerStatusText()
            return
        }

        selectedMediaID = files.first?.id
        updateViewerStatusText()
    }

    private func visibleFiles(in directoryID: String) -> [MediaItem] {
        let rawFiles = snapshot.filesByDirectoryID[directoryID] ?? []

        let filtered = rawFiles.filter { shouldShowMedia($0) }

        return filtered.sorted { lhs, rhs in
            switch previewMediaSort {
            case .nameAscending:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .nameDescending:
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending
            case .newestFirst:
                let leftDate = lhs.modifiedAt ?? .distantPast
                let rightDate = rhs.modifiedAt ?? .distantPast
                if leftDate != rightDate {
                    return leftDate > rightDate
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .oldestFirst:
                let leftDate = lhs.modifiedAt ?? .distantFuture
                let rightDate = rhs.modifiedAt ?? .distantFuture
                if leftDate != rightDate {
                    return leftDate < rightDate
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .largestFirst:
                let leftSize = lhs.sizeBytes ?? -1
                let rightSize = rhs.sizeBytes ?? -1
                if leftSize != rightSize {
                    return leftSize > rightSize
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            case .smallestFirst:
                let leftSize = lhs.sizeBytes ?? Int64.max
                let rightSize = rhs.sizeBytes ?? Int64.max
                if leftSize != rightSize {
                    return leftSize < rightSize
                }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
        }
    }

    private func shouldShowMedia(_ item: MediaItem) -> Bool {
        let metadata = metadata(for: item)

        if !showHiddenMedia && metadata.isHidden {
            return false
        }

        switch previewMediaFilter {
        case .all:
            return true
        case .images:
            return item.kind == .image
        case .videos:
            return item.kind == .video
        }
    }

    private func nextDirectoryWithVisibleMedia(after directoryID: String) -> String? {
        let directoryIDs = filteredDirectories.map(\.id)
        guard let currentIndex = directoryIDs.firstIndex(of: directoryID) else {
            return nil
        }

        for index in (currentIndex + 1)..<directoryIDs.count {
            let candidateID = directoryIDs[index]
            if !visibleFiles(in: candidateID).isEmpty {
                return candidateID
            }
        }

        return nil
    }

    private func previousDirectoryWithVisibleMedia(before directoryID: String) -> String? {
        let directoryIDs = filteredDirectories.map(\.id)
        guard let currentIndex = directoryIDs.firstIndex(of: directoryID), currentIndex > 0 else {
            return nil
        }

        for index in stride(from: currentIndex - 1, through: 0, by: -1) {
            let candidateID = directoryIDs[index]
            if !visibleFiles(in: candidateID).isEmpty {
                return candidateID
            }
        }

        return nil
    }

    private func mutateMetadata(for item: MediaItem, _ mutate: (inout MediaMetadata) -> Void) {
        let key = item.metadataStorageKey
        var metadata = metadataByKey[key] ?? .empty

        mutate(&metadata)
        metadata.updatedAt = Date()

        if metadata.isEmpty {
            metadataByKey.removeValue(forKey: key)
        } else {
            metadataByKey[key] = metadata
        }

        scheduleMetadataPersist()
        updateViewerStatusText()
    }

    private func scheduleMetadataPersist() {
        metadataPersistTask?.cancel()
        let snapshot = metadataByKey

        metadataPersistTask = Task { [metadataStore] in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else {
                return
            }

            await metadataStore.save(snapshot)
        }
    }

    private func normalizeTag(_ rawTag: String) -> String {
        rawTag
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "|", with: "")
    }

    private func updateViewerStatusText() {
        guard let selectedMediaItem else {
            viewerStatusText = "No media selected"
            return
        }

        let metadata = metadata(for: selectedMediaItem)
        var parts: [String] = [viewerPositionLabel, selectedMediaItem.kind == .video ? "Video" : "Image"]
        if metadata.isFavorite {
            parts.append("* Favorite")
        }
        if metadata.isHidden {
            parts.append("Hidden")
        }
        if !metadata.tags.isEmpty {
            parts.append("#\(metadata.tags.count)")
        }

        viewerStatusText = parts.joined(separator: " - ")
    }

    private func syncSelectionAfterRefresh() {
        if let selectedDirectoryID, snapshot.directoriesByID[selectedDirectoryID] != nil {
            return
        }

        selectedDirectoryID = snapshot.rootDirectoryIDs.first
        selectedMoveDestinationDirectoryID = selectedDirectoryID
    }

    private func restorePendingSelectionAfterRefresh() {
        if let pendingSelectedMediaPath {
            let normalized = URL(fileURLWithPath: pendingSelectedMediaPath).standardizedFileURL.path
            for (directoryID, files) in snapshot.filesByDirectoryID {
                if let media = files.first(where: { $0.url.standardizedFileURL.path == normalized }) {
                    selectedDirectoryID = directoryID
                    selectedMediaID = media.id
                    selectedMoveDestinationDirectoryID = directoryID
                    self.pendingSelectedMediaPath = nil
                    self.pendingSelectedDirectoryPath = nil
                    return
                }
            }
            self.pendingSelectedMediaPath = nil
        }

        if let pendingSelectedDirectoryPath {
            let normalized = URL(fileURLWithPath: pendingSelectedDirectoryPath).standardizedFileURL.path
            for directory in snapshot.allDirectories {
                guard let directoryURL = url(for: directory) else {
                    continue
                }

                if directoryURL.standardizedFileURL.path == normalized {
                    selectedDirectoryID = directory.id
                    selectedMoveDestinationDirectoryID = directory.id
                    break
                }
            }
            self.pendingSelectedDirectoryPath = nil
        }
    }

    private func url(for directory: LibraryDirectory) -> URL? {
        guard let root = roots.first(where: { $0.id == directory.rootID }) else {
            return nil
        }

        if directory.relativePath.isEmpty {
            return root.url
        }

        return root.url.appendingPathComponent(directory.relativePath, isDirectory: true)
    }

    private func onlineImportRoot() -> LibraryRoot? {
        if let selectedDirectory,
           let root = roots.first(where: { $0.id == selectedDirectory.rootID }) {
            return root
        }

        return roots.first
    }

    private func appendOnlineResponses(_ entries: [OnlineResponseLogEntry]) {
        guard !entries.isEmpty else {
            return
        }

        onlineResponseLog.append(contentsOf: entries)
        if onlineResponseLog.count > 250 {
            onlineResponseLog = Array(onlineResponseLog.suffix(250))
        }
    }

    private func onlineErrorMessage(_ errorCode: String) -> String {
        if errorCode == "invalid_json" {
            return "Source returned invalid JSON. Check Responses tab."
        }

        if errorCode == "invalid_xml" {
            return "Source returned invalid XML. Check Responses tab."
        }

        if errorCode == "network_error" {
            return "Network error while fetching profile."
        }

        if errorCode.hasPrefix("http_") {
            return "Remote source error (\(errorCode.dropFirst(5)))."
        }

        return "Online source error (\(errorCode))."
    }

    private func upsertOnlineProfileRecord(_ record: OnlineProfileRecord) {
        if let index = onlineProfiles.firstIndex(where: { $0.id == record.id }) {
            onlineProfiles[index] = record
        } else {
            onlineProfiles.append(record)
        }

        onlineProfiles.sort { $0.fetchedAt > $1.fetchedAt }
        persistOnlineProfiles()
    }

    private func persistPreferences() {
        preferencesPersistTask?.cancel()
        let snapshot = preferences

        preferencesPersistTask = Task { [preferencesStore] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else {
                return
            }

            await preferencesStore.save(snapshot)
        }
    }

    private func persistOnlineProfiles() {
        onlineProfilesPersistTask?.cancel()
        let snapshot = onlineProfiles

        onlineProfilesPersistTask = Task { [onlineProfilesStore] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard !Task.isCancelled else {
                return
            }

            await onlineProfilesStore.save(snapshot)
        }
    }

    private func applyThemeFromPreferences() {
        FalchionThemeRuntime.apply(theme: preferences.theme, retroMode: preferences.retroMode)
    }

    private func presentOperationError(_ message: String) {
        operationAlertTitle = "Falchion"
        operationAlertMessage = message
        showOperationAlert = true
        statusMessage = message
    }

    private func isOnlineDirectory(_ directory: LibraryDirectory) -> Bool {
        let path = directory.displayPath.lowercased()
        return path.contains("online imports")
    }

    private func renderOnlineTabIfVisible() {
        if menuTab == .online {
            objectWillChange.send()
        }
    }
}

enum FalchionMenuTab: String, CaseIterable, Identifiable {
    case options
    case online
    case responses
    case keybinds

    var id: String { rawValue }

    var title: String {
        switch self {
        case .options:
            return "Options"
        case .online:
            return "Online"
        case .responses:
            return "Responses"
        case .keybinds:
            return "Keybinds"
        }
    }
}
