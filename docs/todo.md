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
  `Runtimes/macos-wine/bin/wineloader`; host paths launch through
  `wineloader start /unix`, while Windows executable paths launch directly.
- macOS targets a Konyak-managed component stack produced by
  `serika12345/konyak-macos-runtime`; the macOS runtime stack manifest and
  runtime-owner-produced artifacts remain the source of truth.
- Linux uses the Linux Wine/Proton path and stays Vulkan-oriented.
- Flutter continues to call the backend through a separate CLI process.
- Runtime-specific details stay behind CLI/backend platform services.
- The Flutter app and Dart CLI are the source of truth for application
  behavior.
- GPTK4 D3DMetal is treated as supported for the D3DMetal/D3D12 render path
  proven by Konyak's maintained preflight, but GPTK4 plus DLSS/MetalFX is not
  supported for now because the supported path requires macOS 27.
- The primary maintainer must keep macOS 26 available while developing another
  Rosetta 2 based project, so Konyak will not implement GPTK4 plus DLSS/MetalFX
  support until that host constraint changes.
- Drop live external plist metadata from the supported model. Konyak-owned
  bottle metadata is the source of truth.
- Remove runtime verification masking and prove prefix/addon integrity through
  normal application-owned CLI execution paths.

## Next Tasks

- Build a distributable compatibility profile system.
  - Define a versioned canonical profile manifest format, with JSON as the
    normalized CLI/import/export contract and optional authoring syntaxes left
    for later.
  - Extend Profile Manager to create and edit a profile manifest, import a
    validated manifest file, and export a selected profile as canonical JSON.
    Every editing, import, and export path must use the same JSON Schema and
    Dart semantic validation as the built-in catalog; imported profiles must
    not introduce arbitrary code execution.
  - Define declarative installer resources in a profile. Resources must use
    bounded resource kinds and include enough immutable source identity for
    audit and verification, such as a URL or local import identity plus a
    SHA-256 digest. Profile installation may fetch or select only declared
    resources and must never execute an arbitrary shell command or script.
  - Add a generic profile-install operation that resolves the declared
    installer resource, installs it into the selected bottle, then runs the
    profile's declared winetricks dependencies with recorded progress and
    failure results. Keep dependency ordering explicit in the manifest
    contract before exposing it to profile authors.
  - Once installer resources, dependency winetricks, and the profile-install
    user flow are complete, add an independently rerunnable macOS CI E2E gate
    for the entire declarative profile path. Use a repository-owned,
    redistributable synthetic installer and profile with an immutable digest;
    do not depend on Steam payloads, authentication, or live third-party
    downloads. Exercise the public Konyak CLI path used by the GUI to validate
    and resolve the resource, reject a digest mismatch before execution, create
    or select a bottle, run the installer, run a deterministic declared
    winetricks dependency in manifest order, record the installed profile
    binding, and launch the installed program normally.
  - The profile-install E2E fixture must install a launcher and child executable
    that record received argv. Verify that launching the pinned executable and
    an actual Windows `.lnk` automatically activates the bound profile's
    child-process rules without a profile-specific launch command. Also retain
    contract coverage proving that `apply-program-profile` for a manual install
    performs no resource download, installer execution, or dependency
    winetricks run. Make this E2E gate required for changes to the installer
    resource schema, profile-install orchestration, profile binding/launch
    behavior, or the macOS child-process runtime contract after its runtime and
    flake rate are established.
  - Preserve `apply-program-profile` as the manual-install path: it binds a
    selected executable and may pin it, but must not download an installer,
    execute an installer, or run winetricks dependencies.
  - Add profile validation, import, export, and listing commands that load both
    Konyak-shipped profiles and user-installed profiles through a shared
    provider interface.
  - Store profile bindings in Konyak-owned bottle metadata with enough source
    information to make external profiles auditable: schema version, profile
    id/version, profile digest, source kind/path, managed executable path, and
    compatibility profile id/version.
  - Keep profile manifests declarative. Profiles may request supported
    compatibility capabilities such as Windows version, winetricks
    dependencies, completion policy, registry values, DLL overrides, and
    child-process argv rules, but must not run arbitrary scripts.
  - Add repository/share workflow support only after import validation and
    profile binding are stable. Shared profiles must be reviewed as data and
    should not require runtime/app code changes for each application.
- Continue Steam black-screen remediation from GitHub issue #44.
  - Keep the Steam profile aligned with the current CrossOver definition.
    CrossOver's installer-scoped `WINE_WAIT_CHILD_PIPE_IGNORE=steam.exe` is not
    a normal Steam launch workaround. CrossOver also has installer-phase
    AppDefaults `wineoss.drv` and font/DWrite registry setup; represent those
    as generic declarative registry actions before applying them. The current
    CEF argv rule is independently verified Konyak profile data, not a
    CrossOver reproduction; future profile values require equivalent evidence.
  - The observed failure is generic: CEF's D3DMetal GPU process fails command
    buffer creation and crashes in `CrGpuMain` with `0xc0000005`, leaving the
    login window black. Reproduce it with a non-Steam CEF/Chromium D3D11 or
    D3DMetal test program, then correct the minimal generic runtime/backend
    contract.
  - The normal pinned path now canonicalizes an executable in a bottle's
    `drive_c` to the equivalent Windows path before macOS Wine launches it.
    This makes the Profile Manager binding activate for either path notation;
    keep this behavior generic and do not make the launch route Steam-specific.
  - A DXMT comparison did not retain a Steam client process or login window, so
    it is not a validated fallback for the D3DMetal CEF failure.
  - CrossOver's GPTK 3 payload and `CX_ROOT` loader contract did not remove the
    failure when tested with Konyak Wine. Do not treat copying CrossOver's
    payload, loader, or private compatibility database as a profile remedy.
  - Keep child-process argv delivery generic through the Konyak Wine
    `CreateProcess` hook. A bound profile supplies data-only
    `<executable suffix><TAB><argument>` rules through
    `KONYAK_CHILD_PROCESS_RULES`; the hook appends only missing arguments. It
    must remain free of application branches, profile databases, arbitrary
    script execution, and CrossOver compatibility data. Steam is only the
    initial built-in profile and dynamic validation target. Keep the versioned
    limits and runtime verification aligned with
    `runtime/konyak-macos-runtime/docs/profile-child-process-rules.md`.
  - Current platform scope: `childProcessRules` is implemented only by the
    Konyak macOS Wine runtime. The Linux request builder does not propagate
    `KONYAK_CHILD_PROCESS_RULES`, and the Linux Wine runtime does not contain
    the `CreateProcess` hook. Therefore a Linux profile can be represented in
    the manifest but its child-process argv rules do not take effect. Before
    claiming Linux support, add the generic hook to a Konyak-managed Linux Wine
    build, propagate the validated environment through the Linux request
    builder, add a Linux child-process argv integration test, and enforce a
    profile's declared `platforms` at binding and launch.
- Capture end-to-end DLSS/MetalFX rendering proof with a redistributable or
  user-provided DLSS-capable Windows program.
  - Do not target GPTK4 for this proof while the project support matrix treats
    GPTK4 plus DLSS/MetalFX as requiring macOS 27. GPTK4 work remains limited
    to D3DMetal import and D3D12/D3DMetal render-path validation.
  - Use the maintained local smoke entry point
    `scripts/run_macos_dlss_metalfx_cli_smoke.zsh` with user-provided
    GPTK/D3DMetal input and a DLSS-capable Windows executable.
  - The repo-owned `tests/fixtures/windows/dlss_metalfx_preflight` fixture is
    only launch-contract preflight coverage for D3D12, D3DMetal MetalFX
    environment, and NVIDIA shim loading. Do not count preflight success as
    end-to-end DLSS rendering proof.
  - Use Konyak's public `run-program --json` path, record backend environment,
    selected runtime/component paths, process/log evidence, and Metal HUD or
    equivalent evidence where practical.
  - Do not add proprietary or nonredistributable game payloads to CI.
- When a Gcenx GPTK4 binary release becomes available, strengthen
  `runtime/konyak-macos-runtime` CI to verify GPTK4 automatically.
  - Keep the existing GPTK3 smoke coverage and add a separate GPTK4 smoke gate
    for D3DMetal import and D3D12/D3DMetal backend behavior rather than
    replacing GPTK3 validation.
  - Do not add a GPTK4 DLSS/MetalFX gate until macOS 27 is available in the
    supported development and verification matrix.
  - Pin the Gcenx GPTK4 release tag, archive name, and SHA-256 in
    `prepare-gptk-d3dmetal-ci-smoke.zsh` or a narrowly scoped wrapper.
  - Exercise the same runtime CI backend probes:
    `gptk-d3d10-unsupported`, `gptk-d3d11-device`, and `gptk-d3d12-device`.
  - Continue to treat the GPTK/D3DMetal payload as transient CI input only; do
    not upload it as a Konyak artifact or include it in runtime release assets.

## Compatibility Profile Installation Milestones

Goal: let an explicitly selected compatibility profile acquire its declared
Windows installer, verify that immutable payload, run it through Konyak's
public CLI execution path, apply declared winetricks dependencies in manifest
order, and bind the installed program only after every stage succeeds.

Compatibility policy: compatibility profiles and profile bindings have not
shipped yet. Until the first release containing this feature, update the
current profile schema and persisted profile-binding shape directly instead of
adding migration branches for repository-only development formats.

Delivery policy: complete the remaining installation gates on
`task/profile-installer-flow` and open one pull request only after the full
automatic installation feature, Flutter flow, macOS E2E, and required
verification are complete.

Small milestones:

- [ ] IP-S6: Add an independently rerunnable macOS public-CLI E2E using a
  repository-owned synthetic installer. Cover digest rejection, installer and
  dependency ordering, binding, pinned EXE launch, real `.lnk` launch, and
  automatic child-process rule activation without Steam or live third-party
  downloads.

#### Implementation Gate: IP-P4 macOS Profile Installation E2E

branch: `task/profile-installer-flow`

Completion criteria:

- Complete IP-S6 with a maintained local script and a separately rerunnable
  GitHub Actions job using the same public CLI path.
- Keep the synthetic fixture redistributable and independent of authentication
  and live third-party installer downloads.

Required verification:

- `just verify`
- The maintained macOS profile-install CLI smoke.
- The corresponding GitHub Actions workflow syntax and path filters.

Completion stop: after dynamic command, process, log, and artifact evidence and
all required verification are complete, open the feature pull request. If
runtime files or loader behavior must change, coordinate that work with
`runtime/konyak-macos-runtime` in a separate implementation and audit
workstream before declaring this gate complete.

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
