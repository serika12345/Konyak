# TODO

This list tracks remaining implementation work and deferred decisions. Fully
completed work belongs in commits, tests, release artifacts, and audited
verification output instead of checked-off backlog entries.

## Current Direction

- Konyak owns its runtime, metadata, and distribution decisions.
- arm64 macOS is the first complete runtime target.
- x86_64 Linux is the second complete runtime target.
- macOS uses a Konyak-managed macOS Wine launch plan for Windows program
  execution.
- The macOS runtime layout keeps the loader at
  `Runtimes/macos-wine/bin/wineloader` and launches programs through
  `wineloader start /unix`.
- macOS targets a Konyak-managed component stack produced by
  `serika12345/konyak-macos-runtime`; the macOS runtime stack manifest and
  runtime-owner-produced artifacts remain the source of truth.
- Linux uses the Linux Wine/Proton path and stays Vulkan-oriented.
- Flutter continues to call the backend through a separate CLI process.
- Runtime-specific details stay behind CLI/backend platform services.
- The Flutter app and Dart CLI are the source of truth for application
  behavior.
- Drop live external plist metadata from the supported model. Konyak-owned
  bottle metadata is the source of truth.
- Remove runtime verification masking and prove prefix/addon integrity through
  normal application-owned CLI execution paths.

## Next Tasks

- Capture end-to-end DLSS/MetalFX rendering proof with a redistributable or
  user-provided DLSS-capable Windows program.
  - Use Konyak's public `run-program --json` path, record backend environment,
    selected runtime/component paths, process/log evidence, and Metal HUD or
    equivalent evidence where practical.
  - Do not add proprietary or nonredistributable game payloads to CI.

## Refactoring Milestones

This section turns the deferred functional-core / OOP-extension cleanup into
reviewable large milestones and PR-sized gates. Refactoring work should stay
separate from runtime feature work unless the refactor is required to make a
feature change safe. Completed small milestones are removed after their
implementation, verification, and review are complete.

Automatic progression policy:

- `/advance-pr` targets the first unfinished `PR Gate` in this section unless
  the user names another gate.
- `/advance-large` targets the current large refactoring milestone and stops at
  that milestone's review gate.
- `/advance-small` advances the next coherent small milestone inside the
  current `PR Gate`.
- If a required step is not represented below, add or refine the milestone
  before implementation.

### R1: Explicit Boundary State

Purpose: finish the current nullable-hardening pass by replacing semantic
absence and optional action dispatch with explicit parser, availability,
dispatch, or result variants at the CLI and Flutter boundaries.

Small milestones:

- [ ] R1-S2: Audit CLI command handlers that probe nullable request values and
  split command selection from command execution where that removes semantic
  null checks without broad rewrites.
- [ ] R1-S4: Classify remaining nullable UI values as framework-boundary,
  presentation-only, or domain-significant. Convert only the
  domain-significant cases in this milestone.
- [ ] R1-S5: Add or tighten a governance baseline for new domain-facing
  nullable or primitive exposures once the converted boundary is stable.

### R2: Domain Boundary Value Objects

Purpose: replace remaining semantic primitives in domain-facing planner,
request, and serialization APIs with domain value objects or explicit result
variants while keeping I/O, serialization, and UI adapter boundaries narrow.

Small milestones:

- [ ] R2-S2: Replace semantic planner/request primitives with existing or new
  value objects where the invariant is stable.
- [ ] R2-S3: Keep `ProgramRunPlanner` externally pure and split host platform,
  runner-kind, and graphics-backend decisions into narrow policy objects only
  when the current switch logic has grown enough to justify the split.
- [ ] R2-S4: Move JSON `toJson` projection out of domain models into CLI or
  serialization boundary libraries where compatibility permits.
- [ ] R2-S5: Remove hand-written `part` usage from CLI contract tests so tests
  no longer normalize that shape as a large-file escape hatch.

#### PR Gate: R2-P2 Serialization Boundary

branch: `task/refactor-r2-serialization-boundary`

Completion criteria:

- JSON projection is moved out of at least one stable domain model family into
  a CLI or serialization boundary without changing persisted or CLI output
  compatibility.
- Contract tests prove the JSON shape remains stable.
- Remaining domain-model `toJson` projections are either converted or tracked
  by a follow-up small milestone.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public schema changes.
- Runtime artifact or manifest format changes.
- UI redesign.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before R3.

### R3: Flutter Home and Bottle UI Decomposition

Purpose: split remaining large Flutter UI and loader surfaces after backend and
action boundaries are explicit, keeping widgets focused on rendering and event
wiring.

Small milestones:

- [ ] R3-S1: Extract pure `KonyakHomeLoaderState` transitions into immutable
  state/update helpers while keeping the `StatefulWidget` as the lifecycle and
  I/O shell.
- [ ] R3-S2: Keep the `KonyakHome` boundary grouped by responsibility-scoped
  state and action contracts instead of flat props or a single giant props
  object.
- [ ] R3-S3: Move bottle, program, and runtime view models and action
  selection out of `home_screen.dart`, `sidebar.dart`,
  `program_configuration_view.dart`, and `bottle_configuration_view.dart`.
- [ ] R3-S4: Split remaining large UI files only after the extracted contracts
  are stable.
- [ ] R3-S5: Add focused widget or golden tests when visible behavior changes.

#### PR Gate: R3-P1 Home Loader State Extraction

branch: `task/refactor-r3-home-loader-state`

Completion criteria:

- Home loader state transitions that do not require I/O live in pure helper
  modules with focused tests.
- `KonyakHomeLoaderState` keeps lifecycle, async orchestration, and platform
  service calls only.
- Existing UI behavior remains stable.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Broad widget tree restructuring.
- Visual redesign.
- CLI process service rewrites.

Verification:

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before R3-P2.

#### PR Gate: R3-P2 Bottle View Model Extraction

branch: `task/refactor-r3-bottle-view-models`

Completion criteria:

- Bottle, program, and runtime view model construction and action selection are
  moved out of large rendering widgets into focused helpers.
- Widgets remain responsible for rendering and event wiring.
- Focused tests cover view model construction and action selection; widget or
  golden tests cover any visible behavior changes.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- CLI backend changes.
- Runtime behavior changes.
- Large visual redesign.

Verification:

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before R4.

### R4: Refactoring Governance and Completion

Purpose: make the refactored boundaries stay stable by adding reviewed
baselines and cleanup rules once R1 through R3 have narrowed the major
surfaces.

Small milestones:

- [ ] R4-S1: Add or tighten governance checks for new domain-facing primitive
  exposures, planner file growth, and UI loader state growth.
- [ ] R4-S2: Remove stale refactoring handoff entries from `docs/progress.md`
  once the durable record exists in commits, tests, or artifacts.
- [ ] R4-S3: Re-audit `docs/todo.md` and architecture documents so completed
  refactoring work is removed and remaining work is represented by active
  gates.

#### PR Gate: R4-P1 Refactoring Governance

branch: `task/refactor-r4-governance`

Completion criteria:

- Governance checks cover the refactoring boundaries stabilized by R1 through
  R3 without weakening existing gates.
- Documentation reflects the current refactoring state without stale completed
  slices.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- New product features.
- Broad formatting-only churn.
- Runtime packaging changes.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop for final refactoring
  milestone review.

## Deferred

- Linux ARM64 Windows execution research.
- Linux executable thumbnails for sandboxed file managers.
  - Do not make the AppImage or normal app startup mutate `/nix/store` or
    create Nix GC roots on the user's behalf.
  - Treat GNOME/Nautilus thumbnailer sandboxing as normal behavior, not as a
    user configuration problem. The thumbnailer executable must be visible from
    the file manager's sandbox when on-demand thumbnails are supported.
  - Keep the existing Windows executable file association and launcher
    registration separate from thumbnail generation.
  - Design a NixOS integration path, such as a Nix package, Home Manager
    module, or NixOS module, that installs a sandbox-visible Konyak thumbnail
    helper and registers the Freedesktop `.thumbnailer` entry.
  - Consider an app-owned pre-generation path that writes Freedesktop thumbnail
    cache PNGs for executables Konyak has already inspected, while documenting
    that this is not a substitute for arbitrary Nautilus on-demand thumbnails.
  - Preserve the dynamic finding that home-directory AppImage/wrapper
    thumbnailers are not visible to GNOME's `bwrap` thumbnailer sandbox on the
    tested NixOS/Nautilus setup.
- Add E2E tests.
  - Decide the target level before implementation: Flutter integration tests
    with a fake CLI, real CLI tests against temporary directories, or a small
    full-stack Flutter plus real CLI smoke suite.
  - Keep the E2E target separate from the default fast verification gate until
    its runtime cost and flake rate are known.
- Linux runtime packaging-owner build/check hardening.
  - Add submodule-side workflows that build and verify Linux runtime components
    from pinned source recipes before the next runtime version bump.
  - Mirror or explicitly verify the Wine archive when Konyak stops referencing
    the upstream Kron4ek release asset.
  - Keep the parent repository consuming only runtime-owner-produced complete
    source manifests and archives.
