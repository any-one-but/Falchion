# Feature Inventory (Electron -> Swift)

## Purpose

This document inventories known Electron behaviors and records how they should map into the Swift migration.

## Behavior Inventory

### Local Library Access

- Electron behavior: user picks folders, app remembers access, scans media recursively.
- Swift target: folder picker + persistent access + indexed scan flow.
- Candidate frameworks: AppKit (`NSOpenPanel`), security-scoped bookmarks, FileManager.

### Media Grid Browsing

- Electron behavior: thumbnail grid, quick scrolling, sort/filter controls.
- Swift target: responsive grid with stable ordering and cache-aware thumbnail loading.
- Candidate frameworks: SwiftUI (`LazyVGrid` style architecture), QuickLookThumbnailing.

### Viewer and Navigation

- Electron behavior: open item, arrow key navigation, fullscreen mode.
- Swift target: single-item viewer with keyboard and fullscreen parity.
- Candidate frameworks: SwiftUI + AppKit window/keyboard integration.

### Video Playback

- Electron behavior: embedded media playback with timeline/seek.
- Swift target: reliable playback and seeking for supported formats.
- Candidate frameworks: AVFoundation.

### Metadata, Tags, Favorites

- Electron behavior: edit/display metadata, assign tags, mark favorites.
- Swift target: equivalent metadata UX and persistence strategy.
- Candidate frameworks: SwiftUI for UI, FileManager and model layer for persistence.

### File Operations

- Electron behavior: rename and delete from app with clear confirmation/error handling.
- Swift target: safe operations, conflict checks, and reversible workflow policy.
- Candidate frameworks: FileManager, AppKit dialogs.

### Online Profiles

- Electron behavior: profile/account-linked capabilities.
- Swift target: account integration after local parity is stable.
- Candidate frameworks: SwiftUI + Foundation networking stack.

## Parity Notes To Capture In Phase 0

- Sort order defaults and tie-breaking behavior.
- Supported image/video types and fallback behavior.
- Metadata precedence and conflict handling.
- Keyboard shortcut parity.
- Error messages and recoverability expectations.
