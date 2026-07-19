# Flutter Architecture Plan

This document records stable architecture decisions and the current system
shape. For the actionable backlog, use `docs/todo.md`.

## Decisions

- Product name: Konyak.
- Project identity: Konyak owns its runtime, bottle metadata, repository
  identity, and build system.
- Repository layout: the Flutter app lives in `apps/konyak`, and the Dart CLI
  backend lives in `packages/konyak_cli`.
- UI strategy: Flutter desktop, with arm64 macOS first and x86_64 Linux second.
- Backend strategy: Flutter calls a CLI backend. Keep the process boundary
  simple, testable, and JSON-based.
- Runtime strategy: Konyak manages bundled, updateable Wine/Proton runtimes.
- macOS run strategy: use a Konyak-managed Wine launch plan behind the CLI
  boundary. The Flutter UI must not directly embed Swift runtime code or Wine
  process details.
- macOS runtime target: Konyak should own its runtime package while keeping the
  practical layers needed for Windows application support: Wine, Wine32-on-64
  support where required, DXVK-macOS, MoltenVK, GStreamer runtime pieces,
  wine-mono, wine-gecko, winetricks, and GPTK/D3DMetal when a macOS runtime
  package is allowed to carry that component.
- Bottle metadata: Konyak-owned versioned JSON is the source of truth. External
  plist metadata is not part of the supported data model.
- Development environment: Nix flake plus direnv.
- Development method: TDD, with formatters, linters, and tests treated as
  mechanical gates.
- Code style: prefer functional programming, immutable domain values, explicit
  failures, and isolated I/O boundaries.

## Current State

- Flutter consumes the CLI through versioned JSON stdout and does not parse
  human-readable output.
- Konyak bottle records are stored as versioned JSON metadata.
- Runtime stack construction can consume checksum-validated source manifests on
  macOS and Linux.
- Default macOS and Linux runtime releases are resolved through repository
  release locators.
- Packaged Linux builds bundle the selected runtime source manifest, signature,
  and public key when available.
- App settings, runtime update checks, packaged app update handoffs, bottle
  utilities, Start Menu shortcuts, PE metadata, icon extraction, and process
  management all run through the CLI boundary.
- macOS uses the Konyak-managed runtime stack and launches Windows programs
  through the CLI-owned Wine plan. Linux uses the Linux Wine/Proton path and
  remains Vulkan-oriented.
- macOS runtime components may be layered from source manifests or supplied as
  complete runtime-owner-produced stacks. GPTK/D3DMetal stays macOS-only and
  behind the platform/runtime service boundary.

## Runtime Management

- Runtime source manifests are the preferred acquisition contract, and the
  runtime stack manifest remains the stable UI-facing runtime state concept.
- Runtime validation must prove stack completeness, not only loader startup.
- Runtime installers must keep download, checksum verification, extraction,
  staging, validation, and root replacement behind explicit I/O boundaries.
- macOS and Linux runtime differences belong in platform specifications:
  runtime id, stack id, required paths, optional components, normalization
  rules, and default source selection.
- The UI may show runtime capability state, but platform-specific runtime
  behavior stays behind CLI/backend services.
- Packaged app update handoff uses macOS DMG artifacts and Linux AppImage
  artifacts through `install-app-update --json`.

## Compatibility Profile Management

- The versioned JSON profile manifest and its JSON Schema are the single
  import, edit, export, validation, and persistence contract. Display
  projections returned to Flutter are not reconstructed into manifests.
- Public field documentation is generated deterministically from annotations
  in that runtime Schema and committed as a versioned reference. Constraints
  enforced only by Dart domain constructors have stable semantic rule IDs,
  behavioral tests, and generated reference entries; authored guides describe
  workflows and version policy without becoming a second validation source.
- Public profile documentation sources live under `docs/public`, separate from
  internal roadmap, progress, audit, and personal documents. Pages artifact
  staging remains a distinct deployment concern and must publish only that
  curated source set plus explicitly selected product-page assets.
- The profile catalog merges immutable bundled profiles with user-owned
  manifests stored under Konyak's platform data home `profiles` directory.
  A user manifest cannot shadow a bundled id, and an invalid user file is
  isolated as a catalog diagnostic instead of hiding the bundled catalog.
- Profile library mutations stay behind versioned CLI JSON commands. Flutter
  selects files or edits canonical JSON, while the CLI performs size, UTF-8,
  schema, semantic, and declarative-capability validation before atomic writes.
  Canonical JSON edited in memory is staged only through the app's explicit
  temporary-manifest I/O service and is removed after the CLI command returns.
- User updates and deletion require the currently inspected SHA-256 manifest
  digest. A stale editor therefore fails instead of overwriting a concurrent
  change. Bundled profiles are never updated or deleted; the UI offers
  duplication into a new user profile instead.
- Profile library actions execute through injected callbacks while Profile
  Manager remains mounted. Successful catalog mutations replace only the
  dialog's immutable catalog snapshot and selection; export and every cancelled
  picker, editor, or confirmation leave its visible state unchanged. Action
  results return feedback to the dialog-owned ScaffoldMessenger so completion
  and failure notifications render above the modal route.
- The manifest editor treats CLI validation as UI state. Any edit disables Save
  until debounced validation succeeds; validation and persistence failures stay
  inline with the current input, and only a completed mutation closes the
  editor and returns to Profile Manager.
- Applying a profile snapshots its complete launch completion and
  child-process compatibility policy into Konyak-owned bottle metadata. Later
  user-profile edits or deletion cannot silently change newly applied bottle
  behavior; legacy bindings without a snapshot retain catalog fallback for
  persisted-data compatibility.

## Remaining Architecture Work

- Capture end-to-end DLSS/MetalFX rendering proof through the public Konyak
  execution path.
- Split remaining large Flutter UI files after backend boundaries are small
  enough that widgets can stay focused on rendering and event wiring.
- Research Linux ARM64 Windows execution separately from the current x86_64
  Linux target because x86 Windows execution needs FEX, Box64, QEMU, or another
  translation strategy.
- Design Linux executable thumbnail support for sandboxed file managers without
  mutating `/nix/store` or creating Nix GC roots on app startup.
- Choose an E2E test target that balances behavioral confidence, runtime cost,
  and flake rate.
- Harden Linux runtime packaging-owner build/check workflows before the next
  runtime version bump.
