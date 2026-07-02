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

This section tracks the next cleanup pass for compatibility interfaces that were
kept temporarily to land earlier refactoring safely. These gates should remove
one compatibility surface at a time, keep external behavior stable, and stop at
each review gate.

Automatic progression policy:

- `/advance-pr` targets the first unfinished `PR Gate` in this section unless
  the user names another gate.
- `/advance-small` advances the next coherent small milestone inside the
  current `PR Gate`.
- `/review-gate` summarizes the current branch without implementing more work.
- If a required compatibility cleanup is not represented below, add or refine
  the milestone before implementation.

### I1: Compatibility Interface Cleanup

Purpose: remove nullable or primitive compatibility wrappers that were kept to
avoid broad call-site churn during the previous boundary refactoring. Keep the
true external boundaries explicit, but stop preserving internal compatibility
interfaces once call sites can use `Option`, sealed dispatch, or typed value
objects directly.

Small milestones:

- No active I1 small milestones remain.

#### PR Gate: I1-P1 CLI Parser Compatibility Wrappers

status: completed
branch: `task/interface-i1-cli-parser-wrappers`

Completion criteria:

- CLI command-selection call sites use `Option`-returning parser APIs directly
  for at least the runtime and location parser families.
- Nullable parser compatibility wrappers are removed for the converted
  families, or kept only where an external API boundary still requires a
  nullable projection and that reason is documented in code or tests.
- Focused parser or command-selection tests cover missing/incomplete arguments
  without depending on nullable return values.
- Governance is updated so the converted parser families cannot regress to
  nullable compatibility wrappers.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Runtime behavior changes.
- Public CLI JSON schema changes.
- Broad parser rewrites outside the converted families.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I1-P2.

#### PR Gate: I1-P2 CLI Command Dispatch

status: completed
branch: `task/interface-i1-cli-command-dispatch`

Completion criteria:

- Nullable `CliResult?` command handlers and `firstCliResult` dispatch are
  replaced with explicit command-match or command-dispatch variants for the
  converted command groups.
- Missing command matches are modeled as explicit absence or dispatch variants,
  not as `null`.
- Command contract tests cover both matched and unmatched dispatch paths.
- Governance is updated so converted command groups do not reintroduce nullable
  command dispatch.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime installation behavior changes.
- Flutter UI changes.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I1-P3.

#### PR Gate: I1-P3 Flutter Dialog and Picker Decisions

status: completed
branch: `task/interface-i1-flutter-dialog-decisions`

Completion criteria:

- Konyak-owned dialog, picker, and decision helpers expose explicit variants to
  app code; nullable values remain only at `showDialog`, platform picker, or
  Flutter framework adapter calls.
- Widget tests assert explicit decision or picker variants rather than using
  `null` as the expected application state.
- Any visible behavior remains unchanged; add widget or golden coverage only if
  visible behavior changes.
- Governance is updated so converted app decision helpers do not regress to
  nullable compatibility bridges.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- CLI backend changes.
- Visual redesign.
- Runtime behavior changes.

Verification:

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before I1-P4.

#### PR Gate: I1-P4 Flutter JSON DTO Optional Fields

status: completed
branch: `task/interface-i1-flutter-json-dtos`

Completion criteria:

- Flutter CLI JSON parser outputs distinguish invalid, absent, and present
  optional fields with explicit parse/app result models where those fields are
  consumed by application state.
- Nullable `Object?` remains only at JSON decoding and validation boundaries.
- Tests cover absent optional fields and invalid optional field types without
  treating both as the same nullable state unless that is the explicit contract.
- Governance is updated so converted DTOs do not reintroduce nullable app-facing
  summary fields.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- Runtime behavior changes.
- Large UI rewrites.

Verification:

- `just flutter-format-check`
- `just flutter-analyze`
- `just flutter-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before any new
  milestone is added.

#### PR Gate: I1-P5 Refactoring Governance Allowance Cleanup

status: completed
branch: `task/interface-i1-governance-allowances`

Completion criteria:

- Audit the I1-P1 through I1-P4 governance checks and custom lint allowlists for
  temporary compatibility allowances that only existed to land the earlier
  wrapper removals incrementally.
- Remove stale allowances or replace brittle compatibility-specific string
  checks with stable boundary checks that describe the current app and CLI
  contracts.
- Confirm remaining nullable, primitive, and JSON boundary exceptions are
  limited to framework, platform, parser, or serialization adapters and are
  enforced or documented by governance.
- Update governance tests or script checks so removed compatibility wrappers
  cannot regress without preserving obsolete implementation details as the
  contract.
- `docs/progress.md` records the gate state, latest commit, verification, and
  next action.

Not included:

- Public CLI JSON schema changes.
- App or runtime behavior changes.
- Broad nullable cleanup outside stale governance allowances.
- Starting the next refactoring milestone after I1.

Verification:

- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`
- `just konyak-lints-test` if custom lint implementation or lint tests change.

review gate:

- Commit and push the branch, open a draft PR, then stop before adding or
  starting any post-I1 milestone.

## Deferred

- Boundary-hardening follow-up candidates outside the current compatibility
  cleanup gates:
  - Replace additional semantic planner/request primitives with value objects
    only where the invariant has become stable.
  - Split `ProgramRunPlanner` host-platform, runner-kind, and graphics-backend
    policies only if the current switch logic grows enough to justify it.
  - Remove hand-written `part` usage from CLI contract tests once that can be
    done without normalizing a large-file escape hatch.
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
