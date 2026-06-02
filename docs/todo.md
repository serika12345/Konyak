# TODO

This list tracks the next implementation work after the initial Flutter shell
and CLI boundary. Keep completed items in commits and update this file when a
task changes scope.

## Current Direction

- Konyak owns its runtime, metadata, and distribution decisions.
- arm64 macOS is the first complete runtime target.
- x86_64 Linux is the second complete runtime target.
- macOS uses a Konyak-managed Wine launch plan for Windows program execution.
- macOS targets a Konyak-managed runtime stack assembled from explicit
  components.
- Linux uses the Linux Wine/Proton path and stays Vulkan-oriented.
- Flutter continues to call the backend through a separate CLI process.
- Runtime-specific details stay behind CLI/backend platform services.
- The Flutter app and Dart CLI are the source of truth for application
  behavior.
- Konyak app settings are implemented for the first app-level settings:
  close-time Wine process termination, default bottle path selection, update
  checks, and update installation triggers.

## Completed Foundation

- [x] Establish the Konyak project foundation.
  - [x] Add Konyak-owned README, contribution guidance, issue templates, and CI
    metadata.
  - [x] Keep repository scope focused on the Flutter app, Dart CLI, runtime
    packaging, and release automation.
- [x] Split initial run planning from process execution in
  `packages/konyak_cli`.
  - Pure planning should produce executable, argv, environment, runner kind,
    and log path without touching the filesystem or starting processes.
  - Process execution should consume that plan through the existing
    `ProgramRunner` boundary.
- [x] Add the first platform-aware runner selection layer.
  - macOS: use Konyak-managed macOS Wine.
  - Linux: use Linux Wine/Proton.
  - Tests must cover platform selection without relying on the host platform.
- [x] Implement the first macOS Wine startup planner.
  - Use Konyak-managed macOS Wine `wine64` instead of plain `wine`.
  - Launch programs as `wine64 start /unix <program>`.

## Next Tasks

- [x] Complete the macOS Wine startup path.
  - [x] Preserve macOS bottle environment behavior: `WINEPREFIX`, `WINEDEBUG`,
    `GST_DEBUG`, and bottle settings environment variables.
  - [x] Preserve Konyak log output for failed and completed launches.
- [x] Add Konyak-managed macOS Wine acquisition.
  - [x] Use an upstream Wine archive source:
    `https://github.com/Gcenx/macOS_Wine_builds/releases/download/11.9/wine-devel-11.9-osx64.tar.xz`.
  - [x] Use upstream release metadata:
    `https://api.github.com/repos/Gcenx/macOS_Wine_builds/releases/latest`.
  - [x] Install using the Konyak runtime layout:
    `Runtimes/macos-wine/bin/wine64`.
  - [x] Keep download and extraction behind the CLI/backend runtime service.
  - [x] Extract `.tar.xz` archives through the runtime service.
  - [x] Add archive verification behind the CLI/backend runtime service.
  - [x] Add update checks behind the CLI/backend runtime service.
- [x] Move macOS runtime acquisition toward a Konyak-managed component stack.
  - [x] Expose the initial macOS runtime stack manifest from
    `list-runtimes --json` and `install-macos-wine --json`.
  - [x] Validate component presence for Wine, Wine32-on-64 support,
    DXVK-macOS, MoltenVK, GStreamer, wine-mono, winetricks, and macOS-only
    GPTK/D3DMetal when the runtime package provides it.
  - [x] Add component version detection to the runtime manifest.
  - [x] Treat Gcenx Wine as an initial bootstrap runtime, not the final full
    Konyak macOS runtime package.
  - [x] Add runtime validation that checks required dylib search paths and
    loader behavior.
  - [x] Treat GPTK/D3DMetal like Whisky's D3DMetal layer: it belongs to the
    selected macOS runtime package, not to a separate user-facing install flow.
  - [x] Normalize Konyak runtime component archives for DXVK-macOS, MoltenVK,
    GStreamer, wine-mono, winetricks, and macOS-only GPTK/D3DMetal, and allow
    incomplete Wine-only runtime installs to be repaired from a full stack
    archive.
  - [x] Start runtime stack construction from separate component archives by
    layering Wine, DXVK-macOS, MoltenVK, GStreamer, wine-mono, winetricks, and
    macOS-only GPTK/D3DMetal archives during `install-macos-wine`.
  - [x] Build the macOS development winetricks component from a real,
    checksum-verified upstream winetricks script and verb catalog, not a stub.
  - [x] Define a checksum-validated component source manifest that maps each
    stack component to its archive URL, version, and checksum.
  - [x] Install a full stack from a component source manifest and use source
    manifests for runtime updates when release metadata points at one.
  - [x] Document the release-time manifest handoff for default runtime stack
    manifests once full Konyak component archives exist.
- [x] Use Konyak-owned macOS bottle metadata.
  - [x] Drop live external plist metadata from the supported spec.
  - [x] Store macOS bottle records as Konyak `metadata.json`.
  - [x] Keep run planning backed by the Konyak bottle record model.
  - [x] Add write/create support for Konyak bottle metadata.
  - [x] Create the initial `drive_c` directory when creating bottles.
  - [x] Delete bottles through the CLI and remove their Konyak metadata
    directories.
  - [x] Expose Windows version choices in Flutter:
    XP, 7, 8, 8.1, 10, and 11.
  - [x] Persist Konyak runtime settings from Flutter Bottle
    Configuration: Enhanced Sync, AVX advertising, DXVK, DXVK HUD, Metal HUD,
    Metal Trace, and DXR.
  - [x] Move Bottle Configuration into a separate Flutter detail screen with
    Wine, DXVK, and Metal sections plus Control Panel, Registry Editor, and
    Wine Configuration actions.
  - [x] Add registry-backed Bottle Configuration fields for Windows Version,
    Retina Mode, and DPI Scaling.
- [x] Add macOS setup checks.
  - [x] Detect whether Konyak-managed macOS Wine is installed.
  - [x] Detect Rosetta when required by the selected runtime.
  - [x] Return machine-readable JSON errors for missing prerequisites.
- [x] Add first macOS bottle utility commands.
  - [x] Launch Wine configuration through `run-bottle-command`.
  - [x] Launch Registry Editor through `run-bottle-command`.
  - [x] Launch Control Panel through `run-bottle-command`.
  - [x] Open the Konyak C drive and bottle folder through
    `open-bottle-location`.
  - [x] Expose the bottle utility menu in Flutter.
  - [x] Confirm and delete bottles from the Flutter utility menu.
- [x] Add first Start Menu shortcut support.
  - [x] Treat `.lnk` files as runnable program inputs.
  - [x] Expose global and user Start Menu shortcuts through
    `list-bottle-programs`.
  - [x] Expose installed program listing in Flutter.
  - [x] Launch installed programs from the Flutter listing.
- [x] Add first pinned program support.
  - [x] Read and write Konyak pinned program metadata.
  - [x] Expose `pin-program <id> --name <name> --program <path> --json`.
  - [x] Show pinned programs in Flutter and launch them through `run-program`.
  - [x] Keep Apple-provided CLI helpers on the macOS system path where
    applicable, such as `/usr/bin/open`.
- [x] Add first Wine prefix and PE metadata support.
  - [x] Initialize bottle prefixes through `wineboot --init` after bottle
    creation.
  - [x] Extract PE architecture and version string metadata for listed
    programs.
  - [x] Extract PE group icon resources into Konyak's icon cache.
  - [x] Surface extracted metadata and icons through
    `list-bottle-programs --json` and the Flutter installed-program dialog.
- [x] Add Winetricks verb support.
  - [x] Expose parsed Winetricks verbs through `list-winetricks-verbs`.
  - [x] Run selected verbs through `run-winetricks`.
  - [x] Expose a Flutter verb picker from the Konyak bottom bar.
- [x] Add Konyak app settings.
  - [x] Load and persist app settings through versioned CLI JSON.
  - [x] Terminate Wine processes on app close when the setting is enabled.
  - [x] Check for Konyak and Konyak Wine updates on startup when enabled.
  - [x] Install available Konyak Wine runtime updates automatically.
  - [x] Download and apply available Konyak app update artifacts automatically.
- [x] Keep Linux Wine/Proton behavior separate.
  - [x] Hide macOS-only runtime controls, including Konyak macOS Wine
    installation, when the Flutter UI is running on Linux.
  - [x] Do not expose GPTK, D3DMetal, Metal HUD/capture, or Rosetta controls in
    Linux defaults.
  - [x] Keep Linux graphics defaults oriented around DXVK and vkd3d-proton.
- [x] Add runtime management.
  - [x] Define the first bootstrap/update metadata exposed through the CLI.
  - [x] Download and verify runtime archives.
  - [x] Install runtimes into platform-specific Konyak data directories.
  - [x] Make updates rollback-safe.
  - [x] Expose automatic update installation through the Flutter startup path.
- [x] Complete packaged Konyak app update installation.
  - [x] Check release metadata through `check-app-update --json`.
  - [x] Download and apply release artifacts through `install-app-update --json`.
  - [x] Verify update artifact checksums before install.
  - [x] Fix the macOS packaged updater handoff format by producing ad-hoc
    signed, unnotarized zip artifacts with SHA-256 release metadata.
- [x] Package distribution builds.
  - [x] Build the CLI executable.
  - [x] Bundle it with the Flutter app.
  - [x] Pass the bundled path through `KONYAK_CLI_EXECUTABLE` in packaged
    builds.
  - [x] Generate license and third-party notice materials for bundled components.
- [x] Improve run feedback in the Flutter UI.
  - [x] Show runner kind and resolved executable in failure details.
  - [x] Link directly to the latest log when available.
  - [x] Keep the compact snackbar for short errors.
- [x] Add process manager UI.
  - [x] Expose Wine process listing through the CLI.
  - [x] Show executable icons in the Process Manager when metadata is available.
  - [x] Kill one Wine process at a time from Flutter.

## Deferred

- CLI refactoring cleanup.
  - [x] Replace remaining handler-level argv indexing with parser request
    objects.
  - [x] Move app/program settings and bottle metadata/path helpers out of
    `konyak_cli.dart`.
  - [x] Move macOS pinned launcher helpers out of `konyak_cli.dart`.
  - [x] Move Linux desktop launcher and file-association helpers out of
    `konyak_cli.dart`.
  - [x] Move bottle archive and filesystem replacement helpers out of
    `konyak_cli.dart`.
  - [x] Move low-level JSON, path, and binary helpers out of `konyak_cli.dart`.
- Runtime installation rework before adding more install UI.
  - [x] Split runtime data into separate concepts:
    `RuntimeDefinition`, `InstalledRuntimeState`, `RuntimeSourceManifest`, and
    `RuntimeCapabilities`.
  - [x] Keep source manifests as installer inputs. `list-runtimes --json`
    should expose installed state and capabilities, not release/source
    manifest mechanics.
  - [x] Replace the current multi-purpose installer request shape with explicit
    operations: full runtime install, runtime repair, component install, and
    runtime update install.
    - [x] Record update installs and component installs as explicit internal
      request operations.
  - [x] Move shared download, checksum verification, extraction, staging,
    validation, and runtime-root replacement behind one runtime package
    installer service.
    - [x] Share source-manifest component archive download and checksum
      resolution between macOS and Linux installers.
  - [x] Keep macOS and Linux differences in small platform specifications:
    runtime id, stack id, required paths, optional components, normalization
    rules, and default source selection.
    - [x] Move runtime stack component ids, roles, and required paths into
      platform component definitions.
    - [x] Move runtime ids, stack ids, runtime names, and runner kinds into
      platform runtime specifications.
  - [x] Make component installation transactional. Stage the next runtime root,
    validate it, then replace the current runtime root; do not overlay directly
    into the live runtime directory.
  - [x] Add a runtime install lock so concurrent installs, repairs, and updates
    cannot mutate the same runtime root.
  - [x] Treat required stack completeness as part of install no-op detection on
    Linux and macOS; the presence of the Wine executable alone is not enough.
- Runtime install and update product flow rework.
  - [x] Startup update checks must not mutate app or runtime state. They should
    only check and notify unless a separate explicit auto-install setting is
    introduced.
  - [x] Put first-time runtime installation behind an explicit onboarding or
    Settings action.
    - [x] Add the Linux Settings runtime install/repair action.
    - [x] Add the macOS Settings runtime install/repair action.
  - [x] Add Settings install buttons only after the runtime capability contract
    and transactional installer are in place.
    - [x] Wire the Linux Settings button to `install-linux-wine --json`.
    - [x] Wire the macOS Settings button to `install-macos-wine --json`.
  - [x] Disable bottle-level graphics/runtime toggles when the required runtime
    capability is missing or unknown.
- Development runtime profile rework.
  - [x] Add an explicit development runtime profile instead of using release
    source-manifest environment variables for local fixtures.
  - [x] Prepare a macOS development runtime stack source manifest and connect it
    to the Nix/VSCode launch path through `KONYAK_DEV_MACOS_WINE_STACK_MANIFEST`.
  - [x] Keep fixture manifests separate from published runtime stack manifests,
    so update checks cannot accidentally consume component-only development
    inputs as full runtime update sources.
  - [x] Make VSCode and Nix dev-shell launch paths use the same documented
    development profile.
  - [x] Remove Nix-provided Wine, winetricks, and vkd3d-proton from the Linux
    dev shell. Linux development runtime contents now come only from managed
    install archives or source manifests.
  - [x] Split Flake packages by release build, verification/workflow, host
    runtime support, and development runtime source roles; remove unused
    convenience/archive tools from the dev shell.
- Required tests for the rework.
  - [x] Linux install repairs an incomplete runtime when required components are
    missing even if `bin/wine` exists.
  - [x] Component install failure leaves the previous runtime root unchanged.
  - [x] Component-only development manifests cannot be used as full runtime
    update manifests.
  - [x] Startup update checks do not call install commands.
  - [x] Runtime-dependent UI controls are disabled when capabilities are
    missing or unknown.
- Large refactor design plan before more feature work.
  - [x] Split `FileBottleRepository` into a stable facade and operation
    collaborators.
    - Keep the public `BottleRepository` contract and `FileBottleRepository`
      constructor stable.
    - Extract bottle read/list enrichment, create/delete/rename/move/update,
      pinned program mutation, program settings mutation, and archive
      import/export into separate files.
    - Keep metadata validation and path planning pure where possible; keep
      directory creation, deletion, rename, archive, and metadata writes behind
      explicit I/O helpers.
    - Preserve command-level behavior for list/create/delete/rename/move,
      archive import/export, pinning, and program settings.
    - Verify with targeted CLI contract tests first, then `just cli-test`,
      `just verify-governance`, `just format-check`, and `just lint`.
  - [x] Split runtime install request/result models from install execution.
    - Move operation models, macOS request factories, Linux request factories,
      and install results into small model files.
    - Keep request accessors pure and shared; do not let filesystem, process,
      download, or platform probes enter model files.
    - Preserve `install-macos-wine` and `install-linux-wine` JSON output and
      exit-code behavior.
    - Verify with runtime install command tests, `just cli-test`,
      `just verify-governance`, `just format-check`, and `just lint`.
  - [x] Extract runtime install decision planning before simplifying macOS and
    Linux installers.
    - Add a pure planner that consumes host platform, current runtime state,
      request operation, explicit source inputs, default archive/source-manifest
      configuration, and component archive paths.
    - Return explicit decisions such as unsupported platform, already
      installed, incomplete runtime without repair source, install from source
      manifest, install from local archive, and download-then-install.
    - Let sync and streaming installers execute those decisions through the
      existing runtime package installer and download boundaries.
    - Keep progress emission at the installer boundary, not inside the planner.
    - Verify existing no-op, repair, incomplete runtime, source manifest,
      archive, and streaming progress tests before removing duplicated code.
  - [x] Split registry settings planning and parsing.
    - Move registry update/query argument construction into a pure planning
      file.
    - Move `reg query` stdout parsing and runtime settings merge logic into a
      parser file with final-state tests.
    - Keep tests focused on resulting `BottleRecord` and
      `BottleRuntimeSettings`, not on incidental command count unless command
      count is the public contract.
    - Verify with bottle configuration command tests plus `just cli-test`.
  - [x] Split large pure parser/helper buckets only after the higher-risk I/O
    boundaries are stable.
    - [x] `runtime_release_metadata_parsers.dart`: separate release asset parsing
      from source-manifest metadata parsing.
    - [x] `cli_program_parsers.dart`: separate Start Menu shortcut parsing, PE
      metadata conversion, and JSON response conversion.
    - [x] `common_helpers.dart` and `platform_paths.dart`: keep only generic,
      dependency-free helpers; move platform-specific helpers next to their
      platform services.
    - Treat these as mechanical behavior-preserving moves with analyzer and
      command-level tests as the safety net.
  - [ ] Split Flutter large UI files after backend boundaries are smaller.
    - Keep widgets responsible for rendering and event wiring only.
    - Move bottle/program/runtime view models and action selection out of
      `home_screen.dart`, `sidebar.dart`, `program_configuration_view.dart`,
      and `bottle_configuration_view.dart`.
    - Keep CLI process launch and failure mapping behind the existing Flutter
      CLI service boundary.
    - Verify with `just flutter-format-check`, `just flutter-analyze`, and
      `just flutter-test`; add focused widget tests when visible behavior
      changes.
    - [x] Split `sidebar.dart` into sidebar layout, collapsed/animated sidebar
      chrome, and bottle-row/context-menu widgets.
    - [x] Split `home_screen.dart` by extracting rendering surfaces while
      keeping selection state and event orchestration in `KonyakHome`.
    - [x] Move Bottle Configuration runtime-control availability into a pure
      view model and split the visible configuration sections.
    - [x] Split Program Configuration form environment editing from the
      surrounding program settings screen.
- Linux ARM64 Windows execution research.
- Publication of the actual default Konyak runtime stack manifest and public
  key, once the full component archives are produced.
- Removal of the bootstrap Wine-only fallback after that runtime stack
  manifest becomes the default release input.
