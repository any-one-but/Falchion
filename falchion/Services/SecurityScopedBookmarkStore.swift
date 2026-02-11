import AppKit
import Foundation

@MainActor
final class SecurityScopedBookmarkStore {
    private struct StoredBookmark: Codable {
        let id: UUID
        let displayName: String
        let bookmarkData: Data
    }

    private let defaultsKey = "falchion.securityScopedBookmarks.v1"
    private var activeURLs: [UUID: URL] = [:]
    private var bookmarkDataByID: [UUID: Data] = [:]

    private(set) var currentRoots: [LibraryRoot] = []

    deinit {
        for url in activeURLs.values {
            url.stopAccessingSecurityScopedResource()
        }
    }

    func restorePersistedRoots() -> [LibraryRoot] {
        releaseAllAccess()

        let stored = loadStoredBookmarks()
        var roots: [LibraryRoot] = []
        var seenPaths: Set<String> = []

        for entry in stored {
            do {
                var bookmarkIsStale = false
                let resolvedURL = try URL(
                    resolvingBookmarkData: entry.bookmarkData,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &bookmarkIsStale
                ).standardizedFileURL

                guard resolvedURL.startAccessingSecurityScopedResource() else {
                    continue
                }

                if seenPaths.contains(resolvedURL.path) {
                    resolvedURL.stopAccessingSecurityScopedResource()
                    continue
                }

                seenPaths.insert(resolvedURL.path)

                let displayName = entry.displayName.isEmpty ? resolvedURL.lastPathComponent : entry.displayName
                let root = LibraryRoot(id: entry.id, displayName: displayName, url: resolvedURL)
                roots.append(root)
                activeURLs[root.id] = resolvedURL

                if bookmarkIsStale {
                    let refreshed = try? resolvedURL.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    bookmarkDataByID[root.id] = refreshed ?? entry.bookmarkData
                } else {
                    bookmarkDataByID[root.id] = entry.bookmarkData
                }
            } catch {
                continue
            }
        }

        currentRoots = roots.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
        persistCurrentRoots()
        return currentRoots
    }

    func pickAndPersistFolder() -> LibraryRoot? {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Root"
        panel.message = "Select a root folder for Falchion."

        guard panel.runModal() == .OK, let selectedURL = panel.url?.standardizedFileURL else {
            return nil
        }

        if let existing = currentRoots.first(where: { $0.url.path == selectedURL.path }) {
            return existing
        }

        guard selectedURL.startAccessingSecurityScopedResource() else {
            return nil
        }

        do {
            let bookmarkData = try selectedURL.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            let root = LibraryRoot(displayName: selectedURL.lastPathComponent, url: selectedURL)
            currentRoots.append(root)
            currentRoots.sort {
                $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
            activeURLs[root.id] = selectedURL
            bookmarkDataByID[root.id] = bookmarkData
            persistCurrentRoots()
            return root
        } catch {
            selectedURL.stopAccessingSecurityScopedResource()
            return nil
        }
    }

    private func loadStoredBookmarks() -> [StoredBookmark] {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([StoredBookmark].self, from: data)
        } catch {
            return []
        }
    }

    private func persistCurrentRoots() {
        let stored = currentRoots.compactMap { root -> StoredBookmark? in
            guard let bookmarkData = bookmarkDataByID[root.id] else {
                return nil
            }

            return StoredBookmark(
                id: root.id,
                displayName: root.displayName,
                bookmarkData: bookmarkData
            )
        }

        do {
            let data = try JSONEncoder().encode(stored)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            return
        }
    }

    private func releaseAllAccess() {
        for url in activeURLs.values {
            url.stopAccessingSecurityScopedResource()
        }

        activeURLs.removeAll()
        bookmarkDataByID.removeAll()
        currentRoots.removeAll()
    }
}
