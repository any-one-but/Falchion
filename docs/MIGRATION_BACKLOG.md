# Migration Backlog

## Purpose

Track prioritized planning tasks and readiness gates for the phased migration.

## Phase 0: Parity Definition + Fixtures

- [ ] Document all current Electron user flows end-to-end.
- [ ] Define parity acceptance criteria per flow.
- [ ] Build fixture set list: images, videos, mixed folders, edge-case filenames.
- [ ] Record baseline expected results for sorting, filtering, and navigation.
- [ ] Define failure scenarios: missing files, permission denial, corrupt media.

## Phase 1: Local Folder Picker + Media Grid

- [ ] Specify folder authorization UX and bookmark lifecycle.
- [ ] Define scan/index strategy for large folders.
- [ ] Define thumbnail generation and cache policy.
- [ ] Define grid state model (loading/empty/error/populated).
- [ ] Write parity checks against Phase 0 fixtures.

## Phase 2: Viewer / Fullscreen / Navigation

- [ ] Define viewer navigation model and keyboard command map.
- [ ] Define fullscreen behavior for macOS windows/spaces.
- [ ] Define image render strategy for large assets.
- [ ] Define video playback requirements and supported formats.
- [ ] Write parity checks for transitions and navigation continuity.

## Phase 3: Metadata / Tags / Favorites / Rename / Delete

- [ ] Define metadata schema and source-of-truth policy.
- [ ] Define tag/favorite interaction behavior and persistence.
- [ ] Define safe rename/delete flows including conflict handling.
- [ ] Define undo/recovery expectations for destructive actions.
- [ ] Write parity checks for mutation workflows and error handling.

## Phase 4: Online Profile Integrations

- [ ] Define account/auth lifecycle requirements.
- [ ] Define remote profile API boundary and data contracts.
- [ ] Define sync policy and conflict resolution strategy.
- [ ] Define offline mode behavior and retry policy.
- [ ] Write parity checks for online/offline transitions.

## Cross-Phase Readiness

- [ ] Decide telemetry/logging requirements for debugging parity gaps.
- [ ] Define regression checklist run at each phase exit.
- [ ] Define release gating criteria before implementation starts.
