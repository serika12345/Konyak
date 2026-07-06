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

- Complete GPTK/D3DMetal import compatibility work tracked in
  `docs/gptk-d3dmetal-import-progress.md`. The active blocker is deciding the
  macOS D3D10 contract after GPTK/D3DMetal render/readback failed dynamically;
  do not continue GPTK4 import until G1-P4 is resolved or explicitly deferred.
- Capture end-to-end DLSS/MetalFX rendering proof with a redistributable or
  user-provided DLSS-capable Windows program.
  - Use Konyak's public `run-program --json` path, record backend environment,
    selected runtime/component paths, process/log evidence, and Metal HUD or
    equivalent evidence where practical.
  - Do not add proprietary or nonredistributable game payloads to CI.

## Public Shell CLI Milestones

Goal: make Konyak usable as a first-class command from a user's normal shell on
macOS and Linux, while preserving the existing Flutter-to-CLI process boundary,
versioned JSON contracts, exit codes, persisted bottle metadata, and managed
runtime ownership rules.

The final user-facing command surface should prefer a canonical hierarchical
shape:

- `konyak bottle <list|show|create|rename|move|delete|export|import>`
- `konyak program <list|run|pin|unpin|rename|settings>`
- `konyak runtime <list|validate|install|reinstall|update|import>`
- `konyak winetricks <list|run>`
- `konyak process <list|kill|kill-all>`
- `konyak update <check|install>`
- `konyak shell install|uninstall|status`

Compatibility rule: do not remove or silently change the existing flat commands
used by Flutter and release smokes, such as `list-bottles --json`,
`run-program ... --json`, `install-macos-wine --json`, or
`launch-pinned-program --json`, until a later explicit compatibility-removal
gate exists and has its own migration plan.

Automatic progression policy:

- `/advance-pr` targets the first unfinished `PR Gate` in this section when the
  current work snapshot points at Public Shell CLI work or the user names CLI
  shell work.
- `/advance-small` advances the next coherent small milestone inside the active
  Public Shell CLI `PR Gate`.
- `/review-gate` summarizes the current Public Shell CLI branch without
  implementing more work.
- Stop at each Public Shell CLI review gate. Do not continue into the next gate
  unless the user explicitly asks to continue.
- If the next required shell-CLI step is not represented here, update this
  section before implementation.

### C1: Canonical Command Grammar and Compatibility

Purpose: introduce the public `konyak` command grammar, help/version behavior,
and hierarchical command aliases without changing the existing JSON schemas or
Flutter-facing flat commands.

Small milestones:

- [ ] C1-S1: Define the canonical command taxonomy, alias policy, and command
  help model in a maintained CLI contract document or registry.
- [ ] C1-S2: Add `konyak --help`, `konyak help`, and `konyak --version` with
  successful exit behavior.
- [ ] C1-S3: Add hierarchical bottle and runtime command aliases that dispatch
  to the existing command handlers and preserve `--json` payloads.
- [ ] C1-S4: Add hierarchical program, winetricks, process, update, and shell
  command aliases that dispatch to the existing command handlers and preserve
  `--json` payloads.

#### PR Gate: C1-P1 Shell CLI Contract and Command Registry

status: planned
branch: `task/cli-shell-c1-contract-registry`

Completion criteria:

- Add or update a maintained CLI shell contract document that names the
  canonical user-facing command tree, compatibility aliases, JSON requirements,
  exit-code expectations, and deprecation policy.
- Introduce a small command registry or equivalent source of truth for help text
  and alias mapping if that reduces duplication before parser implementation.
- Add command-level tests for the contract surface selected in this gate,
  focused on help metadata or parser dispatch, without changing command
  behavior.
- Keep all existing flat commands and JSON payloads behavior-compatible.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Human-readable data output for list/show commands.
- Packaged shell launcher installation.
- Removing or warning on legacy flat commands.
- Runtime installation behavior changes.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C1-P2.

#### PR Gate: C1-P2 Global Help and Version

status: planned
branch: `task/cli-shell-c1-help-version`

Completion criteria:

- `konyak --help`, `konyak help`, and command-group help return exit code `0`
  and useful usage text.
- `konyak --version` returns the effective Konyak app or CLI version available
  to release builds and development runs.
- Unknown commands and invalid arguments continue to use stable failure exit
  codes and diagnostics.
- Tests cover direct Dart execution and the compiled executable path where
  practical.
- Existing Flutter-facing flat commands remain behavior-compatible.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Hierarchical command aliases beyond the help/version surface.
- Human-readable list/show output.
- Shell installation or package-manager integration.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C1-P3.

#### PR Gate: C1-P3 Bottle and Runtime Hierarchical Commands

status: planned
branch: `task/cli-shell-c1-bottle-runtime`

Completion criteria:

- Add canonical aliases for bottle commands:
  `bottle list`, `bottle show`, `bottle create`, `bottle rename`,
  `bottle move`, `bottle delete`, `bottle export`, and `bottle import`.
- Add canonical aliases for runtime commands:
  `runtime list`, `runtime validate`, `runtime install`, `runtime reinstall`,
  `runtime update check`, `runtime update install`, and `runtime import gptk`.
- Preserve existing JSON schemas, argv boundaries, exit codes, persisted
  metadata, runtime source-manifest handling, and installer progress behavior.
- Add command-level compatibility tests that compare canonical aliases with the
  existing flat commands for representative success and failure paths.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Program launch, winetricks, process, or app-update aliases.
- Human-readable data output.
- Runtime recipe, artifact, or source-manifest generation changes.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C1-P4.

#### PR Gate: C1-P4 Program, Winetricks, Process, Update, and Shell Aliases

status: planned
branch: `task/cli-shell-c1-program-update`

Completion criteria:

- Add canonical aliases for program commands:
  `program list`, `program run`, `program pin`, `program unpin`,
  `program rename`, `program settings get`, and `program settings set`.
- Add canonical aliases for winetricks commands:
  `winetricks list` and `winetricks run`.
- Add canonical aliases for process commands:
  `process list`, `process kill`, and `process kill-all`.
- Add canonical aliases for app update commands:
  `update check` and `update install`.
- Reserve the `shell` command group for launcher installation work without
  implementing host-file mutations in this gate.
- Preserve existing JSON schemas, argv boundaries, exit codes, launcher
  contracts, process-management behavior, and Wine execution paths.
- Add command-level compatibility tests for representative success, missing
  argument, and unsupported-host paths.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Packaged shell launcher installation.
- Human-readable output.
- Removing or warning on legacy flat commands.
- Runtime or Wine behavior changes.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C2-P1.

### C2: Shell-Installable Distribution

Purpose: make the canonical CLI reachable from normal shells in development,
Nix, macOS app, and Linux AppImage contexts without depending on Flutter
internals or transient build paths.

Small milestones:

- [ ] C2-S1: Add a stable development/Nix entry point for invoking the CLI as
  `konyak` or `konyak-cli` from the repository shell.
- [ ] C2-S2: Define the packaged CLI executable and wrapper naming contract for
  macOS and Linux.
- [ ] C2-S3: Implement user-level shell launcher install, uninstall, and status
  commands for packaged builds.
- [ ] C2-S4: Add packaged smoke coverage that invokes the installed or generated
  shell command through the public CLI path.

#### PR Gate: C2-P1 Development and Nix CLI Entrypoint

status: planned
branch: `task/cli-shell-c2-dev-entrypoint`

Completion criteria:

- Add a maintained development entry point that lets contributors run the public
  CLI command from the Nix dev shell without remembering
  `dart run bin/konyak.dart`.
- Add a flake app, package, `just` target, or documented equivalent that runs
  the compiled or Dart-backed CLI through the same public command parser.
- Keep project tools and verification inside the Nix dev shell.
- Add smoke or command-level tests proving the development entry point reaches
  the same JSON contract as the direct Dart script.
- Update `README.md`, `docs/cli-distribution.md`, or a dedicated CLI guide with
  the supported development invocation.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Installing files outside the repository.
- Packaged macOS or AppImage shell launcher installation.
- Human-readable output redesign.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C2-P2.

#### PR Gate: C2-P2 Packaged Shell Launcher Commands

status: planned
branch: `task/cli-shell-c2-packaged-launcher`

Completion criteria:

- Implement `konyak shell install`, `konyak shell uninstall`, and
  `konyak shell status` for user-level shell integration on supported hosts.
- macOS launcher installation must use the packaged `.app` resources or an
  explicit user-selected prefix; it must not silently require administrator
  writes.
- Linux launcher installation must prefer a user-level path such as
  `~/.local/bin/konyak` or a user-selected prefix and must preserve the stable
  AppImage `--konyak-cli` execution path when the CLI is reached from an
  AppImage.
- The launcher must preserve argv boundaries and pass through the canonical CLI
  parser rather than building shell command strings for application behavior.
- Add command-level and packaged-smoke coverage for install, status, uninstall,
  moved-AppImage, and missing-packaged-context cases where practical.
- Update release and distribution docs with the supported shell installation
  behavior.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- System-wide `/usr/local/bin` installation without an explicit user action.
- Package-manager recipes.
- Removing legacy flat commands.
- Changing pinned Windows program launcher contracts except where they share a
  tested wrapper helper.

Verification:

- `just cli-test`
- `just smoke-macos-app-cli-bridge` on macOS when macOS launcher behavior
  changes
- `just linux-release-check` on Linux when AppImage launcher behavior changes
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C2-P3.

#### PR Gate: C2-P3 Release Workflow Shell CLI Coverage

status: planned
branch: `task/cli-shell-c2-release-coverage`

Completion criteria:

- Update the relevant GitHub Actions workflow so CI exercises the same shell CLI
  path proven by local packaged smoke verification.
- Keep rerun units narrow: shell launcher smoke, release metadata, runtime
  smoke, and expensive runtime builds must remain independently rerunnable
  where the existing workflow split allows it.
- Add or update local smoke scripts so macOS and Linux release artifacts prove
  the packaged shell command can invoke at least `--help`, `--version`, and a
  read-only JSON command from a clean environment.
- Document any platform limitation that CI cannot mirror in `docs/progress.md`
  and leave an explicit follow-up if needed.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Human-readable output.
- Runtime recipe changes or runtime artifact generation in the parent repo.
- Package-manager publishing.

Verification:

- `just cli-test`
- Relevant local packaged smoke target added or changed by the gate
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C3-P1.

### C3: Human-Facing CLI Experience

Purpose: make canonical commands useful without forcing users to parse JSON,
while keeping `--json` as the stable machine contract used by Flutter and
automation.

Small milestones:

- [ ] C3-S1: Add human-readable output for safe read-only canonical commands.
- [ ] C3-S2: Add concise human-readable mutation and launch summaries.
- [ ] C3-S3: Add command-specific usage examples and shell completion support
  where the parser model can generate or validate it.
- [ ] C3-S4: Document the CLI as a supported product surface in user-facing
  docs.

#### PR Gate: C3-P1 Human Output for Read-Only Commands

status: planned
branch: `task/cli-shell-c3-human-read-output`

Completion criteria:

- Canonical read-only commands such as `bottle list`, `bottle show`,
  `program list`, `runtime list`, `runtime validate`, `winetricks list`,
  `process list`, and `update check` produce readable text by default.
- `--json` keeps the existing versioned JSON schema and remains suitable for
  Flutter and scripts.
- Legacy flat commands retain their current output requirements unless an
  explicit compatibility test proves the change is behavior-neutral.
- Add tests for empty, single-record, multi-record, and failure output where
  relevant.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Human-readable mutation output.
- Shell launcher installation.
- JSON schema changes.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C3-P2.

#### PR Gate: C3-P2 Human Output for Mutations and Launches

status: planned
branch: `task/cli-shell-c3-human-mutations`

Completion criteria:

- Canonical mutation and launch commands produce concise readable success and
  failure summaries by default.
- Runtime installation progress remains available as streaming JSON for Flutter
  and automation, with any human progress output clearly separated from the
  machine contract.
- Program launch output includes enough diagnostic context for users to find
  the runner, argv, exit code, and log path without weakening JSON contracts.
- Add command-level tests for representative bottle mutation, program run,
  winetricks, runtime install failure, and update command output.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Interactive prompts that would block Flutter or scripts.
- Runtime behavior changes.
- Removing legacy flat commands.

Verification:

- `just cli-test`
- Runtime smoke target when a runtime install or launch path is changed
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C3-P3.

#### PR Gate: C3-P3 User CLI Documentation and Completion

status: planned
branch: `task/cli-shell-c3-docs-completion`

Completion criteria:

- Add user-facing CLI documentation that covers installation, data locations,
  JSON mode, common bottle/program/runtime workflows, exit-code expectations,
  and runtime ownership boundaries.
- Update `README.md` to point power users at the supported CLI entry points.
- Add shell completion generation or static completion files if the command
  registry can support them without duplicating command metadata.
- Add tests or generation checks that keep documented command names aligned
  with the command registry.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Package-manager publishing.
- Removing legacy flat commands.
- Large runtime or Flutter UI changes.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before C4-P1.

### C4: Compatibility Governance and Release Readiness

Purpose: lock the shell CLI as a maintained product surface and make future
changes intentional, tested, and reflected in release automation.

Small milestones:

- [ ] C4-S1: Add governance checks for canonical command coverage and legacy
  alias compatibility.
- [ ] C4-S2: Audit release docs, smoke scripts, and workflows for the final
  shell CLI path.
- [ ] C4-S3: Decide whether any legacy flat commands should remain permanent
  Flutter-only contracts or enter a documented deprecation path.

#### PR Gate: C4-P1 Shell CLI Governance and Compatibility Audit

status: planned
branch: `task/cli-shell-c4-governance`

Completion criteria:

- Add governance or focused tests that require each canonical command group to
  have help coverage, JSON coverage where applicable, and documented legacy
  alias behavior.
- Audit remaining flat commands and classify them as permanent Flutter/internal
  contracts, public compatibility aliases, or candidates for a future
  deprecation milestone.
- Update release, CLI distribution, and progress docs so the supported shell
  CLI paths are clear for development, macOS release, and Linux AppImage users.
- Keep all existing public JSON schemas and persisted data compatible.
- `docs/progress.md` records the gate state, latest commit when known,
  verification, and next action.

Not included:

- Removing any existing flat command.
- Adding new runtime components or parent-repo runtime overlays.
- Package-manager publishing.

Verification:

- `just cli-test`
- `just verify-governance`
- `just verify-safety`
- `just format-check`
- `just lint`

review gate:

- Commit and push the branch, open a draft PR, then stop before any future
  compatibility-removal, package-manager, or runtime-related milestone.

## Refactoring Milestones

No active refactoring milestones are planned. Completed I1 compatibility
cleanup, I2 boundary hardening, and I3 type-safety hardening gates have been
removed from this backlog after verification. Their durable records live in
commits, focused tests, audit documents, and governance checks.

Before starting a future refactoring series, add fresh large milestones, small
milestones, and `PR Gate` blocks here, then stop for review if the plan changes
the current product or architecture direction.

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
