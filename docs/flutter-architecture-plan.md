# Flutter Architecture Plan

This document records the current architecture and implementation state. For
the actionable backlog, use `docs/todo.md`.

## Decisions

- Product name: Konyak.
- Project identity: Konyak owns its runtime, bottle metadata, repository
  identity, and build system.
- Repository layout: add the Flutter app as `apps/konyak`.
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

- The Flutter application lives in `apps/konyak`.
- The Dart CLI backend lives in `packages/konyak_cli`.
- Flutter consumes the CLI through versioned JSON stdout and does not parse
  human-readable output.
- Konyak bottle records are stored as versioned JSON metadata. Live external
  plist metadata is outside the supported data model.
- macOS support uses Konyak-managed Wine behind the CLI boundary.
- Runtime stack construction can layer component archives or consume a
  checksum-validated source manifest.
- App settings and runtime update checks can trigger automatic install/open
  behavior through the CLI boundary.

## Phase 1: Guardrails

- Completed: add `AGENTS.md` as the repository contract.
- Completed: add `flake.nix` and `.envrc`.
- Completed: add `justfile` commands for verification.
- Completed: add a governance verifier so rules are checked mechanically.
- Completed: keep repository metadata, CI, and application code aligned with
  the Flutter app and Dart CLI source of truth.

## Phase 2: Flutter Shell

- Completed: create `apps/konyak`.
- Completed: enable Linux and macOS desktop targets.
- Completed: add strict analysis options before adding feature code.
- Completed: add widget and contract tests for user-visible behavior.
- Completed: implement the Konyak bottle shell, settings, dialogs, pinned
  programs, installed programs, and runtime actions.

## Phase 3: CLI Contract

- Completed: define a versioned JSON command contract.
- Completed: add command tests before implementation.
- Completed: implement read-only commands first:
  - list bottles
  - inspect bottle
  - list known runtimes
- Completed: keep human output separate from machine output.

## Phase 4: MVP Behavior

- Create bottle.
- List bottles.
- Delete bottle.
- Run EXE, MSI, and BAT files.
- Change Windows version.
- Change Konyak runtime settings from a separate Bottle Configuration screen:
  registry-backed Windows Version, High Resolution Mode backed by
  `RetinaMode`, Enhanced Sync, Windows DPI backed by `LogPixels`, AVX
  advertising, DXVK, DXVK HUD, Metal HUD, Metal Trace, and DXR.
- Run bottle utility commands such as Wine configuration, Registry Editor, and
  Control Panel through the same logged CLI execution boundary.
- Open bottle locations such as the root folder and `drive_c` through an
  explicit host path-opening boundary.
- Discover Start Menu `.lnk` shortcuts through `list-bottle-programs --json`
  and treat `.lnk` files as runnable program inputs.
- Show logs.

macOS run support uses `wineloader start /unix` through a Konyak-managed macOS
Wine runtime, with macOS Wine environment construction kept behind the
CLI/backend platform service. Linux run support uses the Linux Wine/Proton path
and remains Vulkan-oriented.

macOS bottle creation, deletion, Windows-version updates, and runtime-setting
updates write Konyak `metadata.json` records under the configured bottle
directory while the runtime backend continues to own process execution.

The macOS target is a Konyak-managed runtime stack assembled from explicit,
versioned components. The runtime may come from Konyak-built or third-party
components as long as the resulting stack exposes the required operational
capabilities: `wineloader`, Wine32-on-64 where needed, DXVK-macOS, MoltenVK,
GStreamer support, wine-mono, wine-gecko, winetricks, Rosetta-aware x86
execution, and the GPTK/D3DMetal files when the selected macOS runtime package
provides them.
Konyak treats GPTK/D3DMetal like Whisky treats D3DMetal: it is part of the
macOS runtime package, not a separate in-app installation flow. The CLI still
validates the expected files when present and the Flutter UI only enables DXR
when the `gptk-d3dmetal` runtime component is installed. GPTK/D3DMetal must
stay macOS-only and behind the platform/runtime service boundary.

Winetricks, Start Menu shortcuts, PE metadata, and icon extraction now flow
through the same CLI and Flutter boundaries as program launching. Linux
managed runtime stacks can now layer `vkd3d-proton` through component archives
or source manifests. The process manager UI now lists Wine processes with
executable metadata and terminates individual processes through the same CLI
boundary.

## Phase 5: Runtime Management

- Add runtime channel metadata.
- Expose a versioned runtime stack manifest through the CLI so the UI can see
  which macOS stack components are installed or missing.
- Expose runtime update checks through
  `check-runtime-update <runtime-id> --json`.
- Validate macOS runtime loader prerequisites through
  `validate-runtime <runtime-id> --json`, including dylib search paths and a
  `wineloader --version` loader probe.
- Validate host setup prerequisites through `check-macos-setup --json`,
  including Rosetta availability and Konyak-managed runtime installation
  status.
- Download and verify Wine/Proton runtime archives.
- Install runtimes into platform-specific Konyak data directories.
- Add update checks and rollback-safe installation.

The initial runtime management implementation is in place for the bootstrap
macOS Wine path, including startup-triggered update installation when enabled
in app settings. Konyak app update checks and artifact download/open behavior
are also in place through the CLI boundary. The macOS runtime installer can now
construct a stack by layering separate component archives onto a Wine archive,
or by resolving a checksum-validated source manifest that lists the component
archive URLs and versions. Runtime updates use that source-manifest path when
release metadata points at a manifest artifact. The Linux runtime installer now
supports the same pattern for `vkd3d-proton`-aware managed stacks. The
remaining runtime work is publishing the default Konyak stack manifest/public
key, removing the bootstrap Wine-only fallback, and rounding out packaged app
updater behavior across distribution formats.

## Phase 6: Platform Expansion

- arm64 macOS is the first complete target.
- x86_64 Linux is the second complete target and reuses the UI and CLI boundary
  while keeping Linux-specific runtime behavior behind platform services.
- Linux ARM64 remains a separate research track because x86 Windows execution
  needs FEX, Box64, QEMU, or another translation strategy.
