# Falchion

Falchion is an in-progress Swift migration of an existing Electron desktop media workflow.

This repository is currently in planning/bootstrap mode only. No app features are implemented as part of this stage.

## Current Scope

- Verify Git/GitHub wiring.
- Establish repository hygiene (`.gitignore`, docs structure).
- Define phased migration plan from Electron behavior to Apple-native frameworks.

## Migration Phases

1. Phase 0: parity definition + fixtures
2. Phase 1: local folder picker + media grid
3. Phase 2: viewer/fullscreen/navigation
4. Phase 3: metadata/tags/favorites/rename/delete
5. Phase 4: online profile integrations

Detailed planning artifacts are in `docs/`:

- `docs/PORTING_PLAN.md`
- `docs/FEATURE_INVENTORY.md`
- `docs/ARCHITECTURE_SWIFT.md`
- `docs/MIGRATION_BACKLOG.md`

## Framework Direction

Old Electron behavior is planned to map to these Apple technologies:

- SwiftUI for primary UI composition
- AppKit for macOS-specific panels, menus, and window control
- AVFoundation for video playback and timeline behavior
- QuickLookThumbnailing for fast thumbnail generation
- FileManager for local file scanning and operations
- Security-scoped bookmarks for persistent folder access permissions
- Core Image and optional Metal acceleration for image transforms/performance hotspots

## Non-Goals For This Stage

- No production app feature implementation
- No UI implementation beyond planning design notes
- No schema migrations or data model hardening yet
