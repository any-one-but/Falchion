# Falchion Porting Plan

## Goal

Port behavior from the Electron app to a native macOS Swift app while preserving user workflows first, then improving performance and UX.

## Ground Rules

- Behavior parity is prioritized before redesign.
- Each phase has explicit entry/exit criteria.
- Test fixtures are defined early and reused across phases.
- Implementation tasks are not executed in this planning-only stage.

## Phase 0: Parity Definition + Fixtures

### Objectives

- Define what "parity" means for each existing Electron workflow.
- Capture representative media fixture sets (images, videos, nested folders, edge-case filenames).
- Document baseline behavior: sorting, filtering, navigation, metadata handling, error states.

### Deliverables

- Feature-by-feature parity checklist.
- Fixture manifest with expected outcomes.
- Baseline acceptance criteria for phases 1-4.

### Exit Criteria

- Team can evaluate any future Swift behavior against written parity checks.

## Phase 1: Local Folder Picker + Media Grid

### Objectives

- Allow users to choose local folders.
- Persist folder access safely across launches.
- Display media as a performant grid with thumbnails.

### Framework Mapping

- SwiftUI: grid layout, state-driven filtering/sorting presentation.
- AppKit: NSOpenPanel integration for folder selection.
- FileManager: directory traversal and metadata reads.
- Security-scoped bookmarks: persistent folder permissions.
- QuickLookThumbnailing: thumbnail generation and caching inputs.

### Exit Criteria

- User can reopen app and retain authorized folder access.
- Grid correctness matches Phase 0 fixture expectations.

## Phase 2: Viewer / Fullscreen / Navigation

### Objectives

- Open selected media in focused viewer mode.
- Support fullscreen viewing and keyboard navigation.
- Ensure smooth handling of large image and video assets.

### Framework Mapping

- SwiftUI: viewer composition and navigation state.
- AppKit: fullscreen window behavior and keyboard event bridges.
- AVFoundation: video playback control and media timing.
- Core Image (optional Metal): image scaling and rendering optimizations.

### Exit Criteria

- Keyboard and fullscreen behavior pass parity scenarios.
- Viewer transitions remain stable across fixture media types.

## Phase 3: Metadata / Tags / Favorites / Rename / Delete

### Objectives

- Port non-destructive metadata workflows.
- Add tagging/favorites behavior parity.
- Support safe file operations (rename/delete) with confirmations and undo strategy definition.

### Framework Mapping

- SwiftUI: metadata panels and action flows.
- FileManager: rename/delete operations and conflict detection.
- AppKit: native confirmation dialogs where needed.

### Exit Criteria

- Metadata and file operation behavior match parity checklist.
- Error handling documented and validated against edge cases.

## Phase 4: Online Profile Integrations

### Objectives

- Recreate Electron online profile/account flows.
- Define API boundaries, auth lifecycle, and offline behavior.
- Introduce sync expectations and conflict resolution policy.

### Framework Mapping

- SwiftUI: account/settings surfaces.
- AppKit: macOS-specific auth panel handoff if needed.
- Foundation networking stack: remote profile API interactions.

### Exit Criteria

- Online profile flows meet parity criteria.
- Failure and reconnect behavior defined and tested.

## Milestone Review Cadence

- End of each phase: parity review against fixtures.
- Any scope change requires written impact note in backlog.
