# Swift Architecture Plan

## Objective

Define a Swift-native architecture that preserves Electron behavior while aligning with macOS platform patterns.

## High-Level Layers

### Presentation Layer

- SwiftUI screens for library, grid, viewer, metadata, and settings surfaces.
- AppKit bridges for macOS-specific interactions (open panel, window/fullscreen control, command handling).

### Domain Layer

- Use-case-oriented services (scan library, build media index, navigate sequence, mutate metadata, execute file ops).
- Behavior contracts driven by Phase 0 parity definitions.

### Data and System Layer

- FileManager adapters for filesystem traversal and mutation.
- Security-scoped bookmark manager for long-lived folder authorization.
- Thumbnail pipeline using QuickLookThumbnailing.
- Playback pipeline using AVFoundation.
- Optional image processing pipeline with Core Image and Metal acceleration only where profiling justifies it.

## Electron Behavior Mapping

- Electron renderer process UI -> SwiftUI view hierarchy.
- Electron main process OS integrations -> AppKit bridge services.
- Node filesystem access -> FileManager + bookmark authorization layer.
- Electron media/DOM playback -> AVFoundation-backed media engine.
- Electron thumbnail generation path -> QuickLookThumbnailing service.

## State and Flow Principles

- Single source of truth per major screen domain.
- Explicit state transitions for loading, ready, empty, and error states.
- Non-blocking file scan and thumbnail operations.
- Cancellation-aware navigation and background work.

## Security and Permissions

- Folder access is user-driven and explicit.
- Persist only required bookmark data.
- Validate bookmark resolution at startup and handle stale bookmarks gracefully.

## Performance Guidelines

- Prioritize lazy loading for grids and viewer assets.
- Cache thumbnails and invalidate deterministically.
- Defer Core Image/Metal optimization unless measured bottlenecks appear.

## Test Strategy (Planning)

- Fixture-based parity tests from Phase 0.
- File operation tests with temp directories and conflict scenarios.
- Navigation and playback smoke checks for representative media sets.
