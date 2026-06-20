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
  - Use Konyak-managed macOS Wine `wineloader` instead of plain `wine`.
  - Launch programs as `wineloader start /unix <program>`.

## Next Tasks

- [x] Remove runtime verification masking and prove prefix/addon integrity.
  - [x] Remove `mscoree,mshtml=` from application-owned macOS prefix
    initialization and update CLI contract tests so prefix creation exercises
    Wine's normal Mono/Gecko addon probing.
  - [x] Package the Mono and Gecko MSI payloads expected by the built
    CrossOver/Wine runtime, with runtime-submodule checks for the embedded
    expected versions, file names, and checksums.
  - [x] Replace parent runtime completeness checks for wine-mono with exact
    payload checks, add a required wine-gecko component, and stop using marker
    files as addon fixtures.
  - [x] Make macOS full runtime install/update fail when the required runtime
    stack is incomplete after layout normalization.
  - [x] Make `validate-runtime` report stack completeness and keep loader-only
    checks labeled as loader-only checks.
  - [x] Require the configured macOS runtime source manifest asset during
    release/update checks instead of silently falling back to arbitrary archive
    assets when manifest metadata is missing.
  - [x] Split raw Wine runtime diagnostics from app-owned CLI smoke coverage,
    and ensure app behavior gates use the public CLI execution path.
  - [x] Keep backend smoke coverage as a component diagnostic that launches
    probes from the selected runtime backend directory instead of copying
    backend DLLs into the prefix, while preventing it from hiding Mono/Gecko
    prefix initialization failures.
- [x] Align macOS backend selection with the CrossOver-derived runtime stack.
  - [x] Treat Konyak macOS Wine as the default CrossOver-derived runtime, not
    as a GPTK Wine replacement target.
  - [x] Keep D3DMetal/GPTK, DXMT, and DXVK as mutually exclusive backend
    component directories selected at run time.
  - [x] Use CrossOver-style backend search paths:
    `lib/wine`, `lib/dxmt`, and `lib/dxvk` when those components
    are selected.
  - [x] Preserve GPTK imports as user-provided D3DMetal backend files only; do
    not replace the default macOS Wine executable with imported GPTK Wine.
  - [x] Isolate GPTK imports under `components/gptk-d3dmetal` so base
    `lib/wine/*` files are not overwritten, and preserve that component across
    macOS runtime reinstall/update operations.
  - [x] Validate the run plan with CLI contract tests before changing the
    planner.
- [x] Complete the macOS Wine startup path.
  - [x] Preserve macOS bottle environment behavior: `WINEPREFIX`, `WINEDEBUG`,
    `GST_DEBUG`, and bottle settings environment variables.
  - [x] Preserve Konyak log output for failed and completed launches.
- [x] Add Konyak-managed macOS Wine acquisition.
  - [x] Use the Konyak-managed macOS runtime release source manifest:
    `https://github.com/serika12345/konyak-macos-runtime/releases/download/crossover-26.1.0-konyak.0/konyak-macos-wine-runtime-stack-source.json`.
  - [x] Keep the release reference metadata in
    `runtime/macos-wine-release.json` as the single source of truth for the
    default repository, release tag, and manifest file name.
  - [x] Install using the Konyak runtime layout:
    `Runtimes/macos-wine/bin/wineloader`.
  - [x] Keep download and extraction behind the CLI/backend runtime service.
  - [x] Extract `.tar.xz` archives through the runtime service.
  - [x] Add archive verification behind the CLI/backend runtime service.
  - [x] Add update checks behind the CLI/backend runtime service.
- [x] Move macOS runtime acquisition toward a Konyak-managed component stack.
  - [x] Expose the initial macOS runtime stack manifest from
    `list-runtimes --json` and `install-macos-wine --json`.
  - [x] Validate component presence for Wine, Wine32-on-64 support,
    DXVK-macOS, vkd3d, MoltenVK, GStreamer, wine-mono, wine-gecko,
    winetricks, and macOS-only GPTK/D3DMetal when the runtime package provides
    it.
  - [x] Include DXMT x86_64 NVIDIA shim DLLs `nvapi64.dll` and `nvngx.dll`
    in the submodule build/release checks and parent runtime completeness
    contract.
  - [x] Add component version detection to the runtime manifest.
  - [x] Treat Gcenx Wine as an initial bootstrap runtime, not the final full
    Konyak macOS runtime package.
  - [x] Add runtime validation that checks required dylib search paths and
    loader behavior.
  - [x] Treat GPTK/D3DMetal like Whisky's D3DMetal layer: it belongs to the
    selected macOS runtime package, not to a separate user-facing install flow.
  - [x] Normalize Konyak runtime component archives for DXVK-macOS, vkd3d,
    MoltenVK, GStreamer, wine-mono, wine-gecko, winetricks, and macOS-only
    GPTK/D3DMetal, and allow incomplete Wine-only runtime installs to be
    repaired from a full stack archive.
  - [x] Start runtime stack construction from separate component archives by
    layering Wine, DXVK-macOS, vkd3d, MoltenVK, GStreamer, wine-mono,
    wine-gecko, winetricks, and macOS-only GPTK/D3DMetal archives during
    `install-macos-wine`.
  - [x] Keep macOS development runtime manifests sourced from the
    `runtime/konyak-macos-runtime` produced stack instead of generating or
    overlaying runtime components in the parent repository.
  - [x] Define a checksum-validated component source manifest that maps each
    stack component to its archive URL, version, and checksum.
  - [x] Install a full stack from a component source manifest and use source
    manifests for runtime updates when release metadata points at one.
  - [x] Document the release-time manifest handoff for default runtime stack
    manifests once full Konyak component archives exist.
  - [x] Change the public macOS runtime distribution to a single assembled stack
    archive while keeping component archives as internal build, verification,
    and rerun units.
  - [x] Verify the assembled macOS runtime stack through the normal
    `wineloader start /unix <program>` GUI `.exe` launch path, without relying
    on smoke-only fallback dylib search paths.
  - [x] Keep macOS enhanced sync mode environment generation explicit:
    `msync` sets `WINEMSYNC=1`, and `esync` sets `WINEESYNC=1`.
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
- [ ] Add a Bottle Tools launcher surface for Wine built-in utilities.
  - [ ] Keep the current Winetricks placement unchanged in the first pass.
  - [ ] Group bottle-scoped utility launchers behind a Tools action, dialog,
    or sheet instead of mixing them into Installed Programs.
  - [ ] Preserve the existing Wine Configuration, Registry Editor, Control
    Panel, Terminal, and location actions while giving them a clearer shared
    home.
  - [ ] Extend `run-bottle-command` through explicit allowlist command IDs,
    not arbitrary shell strings, for utilities such as `uninstaller`,
    `taskmgr`, `cmd`, `explorer`, `dxdiag`, and `winver`.
  - [ ] Treat Uninstall Programs as the Wine uninstaller or Add/Remove
    Programs path, separate from the Start Menu shortcut launcher list.
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
  - [x] Install the bundled macOS Wine Mono MSI silently before `wineboot --init`
    so user bottle creation exercises the real addon payload without showing
    Wine's addon installer UI.
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
  - [x] Show launch progress while Flutter is waiting for `run-program --json`
    to return.
  - [x] On macOS, hide launch progress when a visible external window owned by
    the launched CLI process tree or a Wine-like process is detected, even if
    the GUI `run-program --json` process is still pending.
  - [ ] On Linux, hide launch progress when a newly visible Wine/Proton window
    is detected, using an X11/XWayland-aware implementation first and a
    documented Wayland fallback.
- [x] Add process manager UI.
  - [x] Expose Wine process listing through the CLI.
  - [x] Show executable icons in the Process Manager when metadata is available.
    - Shortcut-launched processes resolve the shortcut target before matching
      the reported Wine executable, so Start Menu `.lnk` launches can surface
      target PE metadata and icons.
  - [x] Kill one Wine process at a time from Flutter.
- [x] Improve Process Manager listing performance.
  - [x] Keep the existing Flutter-visible process list and termination behavior
    stable.
  - [x] Replace serial Wine process listing across bottles with bounded async
    execution.
  - [x] Skip Wine debugger probing for bottles that do not appear in the host
    process table.
  - [x] Avoid repeated process metadata and icon extraction work within one
    listing request.
- [x] Restore macOS 32-bit Windows executable support.
  - [x] Treat CrossOver's observed macOS layout as the compatibility target for
    32-bit Windows execution:
    `lib/wine/i386-windows`, `lib/wine/x86_64-windows`, and
    `lib/wine/x86_64-unix` are present; `lib/wine/i386-unix` is not required.
  - [x] Fix the `runtime/konyak-macos-runtime` submodule first so the Konyak
    macOS Wine artifact is not a `--enable-win64`-only build when the parent
    repository claims Wine32-on-64 support.
  - [x] Add submodule-side build/release checks for the actual Wine32-on-64
    payload, including at least `lib/wine/i386-windows/ntdll.dll`,
    `lib/wine/x86_64-windows/wow64.dll`,
    `lib/wine/x86_64-windows/wow64cpu.dll`,
    `lib/wine/x86_64-windows/wow64win.dll`, and
    the host Unix `ntdll.so` under `lib/wine/x86_64-unix` for release
    artifacts. CrossOver's `winewrapper.exe` is not a Konyak required payload
    because the upstream Wine build used by the runtime submodule does not
    install it.
  - [x] Update the parent CLI runtime stack contract so `wine32on64`
    completeness is validated by the real Wine32-on-64 files, not only by
    `bin/wine`.
  - [x] Align the macOS launch environment with the CrossOver wrapper where it
    matters for Wine32-on-64 by always setting a base `WINEDLLPATH` containing
    `i386-windows`, `x86_64-windows`, and `lib/wine`, even when no graphics
    override is selected. Konyak launches the runtime-owned
    `bin/wineloader` entry point and sets `WINELOADER` and `WINESERVER`
    explicitly.
  - [x] Keep D3DMetal/GPTK x86_64-only unless a 32-bit-capable payload is
    explicitly produced. Do not claim 32-bit D3DMetal support from the parent
    repository.
  - [x] Preserve the current DXVK-macOS 32-bit path by keeping
    `lib/dxvk/i386-windows` required and covered by install/repair tests.
  - [x] Add regression coverage before implementation:
    submodule checks for the built runtime layout and architecture; parent CLI
    contract tests for install, repair, and runtime listing; and run-plan tests
    for the macOS Wine32-on-64 environment.
  - [x] Add a real Wine32-on-64 smoke test in the runtime submodule that runs
    the runtime's 32-bit `cmd.exe` against an assembled runtime stack.
  - [x] Verify with submodule script/build checks, parent `just cli-test`,
    `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint`.
- [x] Complete the macOS DXVK component payload for D3D10.
  - [x] Keep `runtime/konyak-macos-runtime` as the runtime component artifact
    SSOT and keep the parent repository's Nix flake free of runtime library
    dependencies.
  - [x] Confirm the pinned Gcenx DXVK-macOS payload lacks `d3d10.dll` and
    `d3d10_1.dll`.
  - [x] Supplement only `d3d10.dll` and `d3d10_1.dll` from upstream DXVK
    `v1.10.3` for both `i386-windows` and `x86_64-windows`.
  - [x] Validate the DXVK component archive with
    `runtime/konyak-macos-runtime/scripts/check-dxvk-component.zsh`.
  - [x] Include DXVK component verification in runtime Actions and the
    assembled Wine32-on-64 smoke runtime.
  - [x] Update the parent CLI runtime contract, dev runtime source helper, and
    macOS DXVK `WINEDLLOVERRIDES` so install/repair/listing and launch plans
    require and use `d3d10.dll` and `d3d10_1.dll`.
  - [x] Republish the `crossover-26.1.0-konyak.0` macOS runtime release assets
    from the runtime submodule Actions run.
- [x] Complete the macOS GStreamer runtime component payload.
  - [x] Keep the component in `runtime/konyak-macos-runtime`; do not move
    media runtime dependencies into the parent Nix flake.
  - [x] Package GStreamer plugin dylibs under `lib/gstreamer-1.0`, including
    representative core, playback/typefind, MP4/WAV, and Apple media plugins.
  - [x] Package `libexec/gstreamer-1.0/gst-plugin-scanner`.
  - [x] Add submodule-side component verification that rejects missing plugins,
    missing scanner, wrong architecture, and unpackaged Nix store dylib
    references.
  - [x] Add runtime Actions coverage for the packaged GStreamer component and
    assembled smoke runtime.
  - [x] Update the parent CLI runtime contract and macOS launch environment so
    Wine receives `GST_PLUGIN_SYSTEM_PATH`, `GST_PLUGIN_SCANNER`, and a
    bottle-local `GST_REGISTRY`.
- [x] Align GPTK/D3DMetal NVIDIA shim handling with CrossOver 26.1.
  - [x] Treat `runtime/konyak-macos-runtime` and imported GPTK/D3DMetal payloads
    as the SSOT for runtime files; do not add GPTK dependencies to the parent
    Nix flake.
  - [x] Accept CrossOver.app's
    `Contents/SharedSupport/CrossOver/lib64/apple_gptk` layout as an import
    source.
  - [x] Require and validate `nvapi64.dll`, `nvngx.dll`, `nvapi64.so`, and
    `nvngx.so` in the GPTK/D3DMetal payload.
  - [x] Use `nvngx.dll` / `nvngx.so` as the canonical runtime layout while
    accepting older `nvngx-on-metalfx` source names and normalizing them during
    import.
  - [x] Keep GPTK/D3DMetal D3D10 out of the required payload; D3D10 remains
    covered by DXVK/DXMT components.
  - [x] Include `nvapi64` and `nvngx` in the D3DMetal `WINEDLLOVERRIDES` and
    bottle DLL override repair path.
- [ ] Restore normal Wine compatibility in the CrossOver-derived macOS
  runtime.
  - Reference:
    `runtime/konyak-macos-runtime/docs/crossover-runtime-compatibility.md`
    records the CrossOver/nixpkgs comparison, the public single-archive
    decision, the adopted dylib layout policy, and the phased repair order.
  - [x] Phase 1: remove unnecessary `--without-*` build flags from
    `runtime/konyak-macos-runtime/nix/wine-crossover.nix`.
    - Keep `--enable-archs=i386,x86_64`, `--with-vulkan`, and `--without-x`
      as the Wine32-on-64 and macOS display baseline.
    - Use nixpkgs Darwin `wineWow64Packages.stable` and CrossOver 26.1 source
      as the compatibility baseline instead of a minimal hand-pruned feature
      set.
    - Re-enable Wine feature probes that nixpkgs or CrossOver expect on
      Darwin, starting with `inotify`, `unwind`, `usb`, `krb5`, and related
      support unless a source-level incompatibility is demonstrated.
    - Keep every remaining `--without-*` justified by a macOS limitation,
      missing redistributable dependency, or intentional product decision.
    - [x] Add a runtime-submodule configure flag check that rejects unapproved
      `--without-*` and `--disable-*` flags and requires every adopted
      `--with-*` flag.
    - [x] Remove the current hard-pruned `--without-*` flags other than
      `--without-x`, remove `--disable-win16`, and add the adopted
      `--with-coreaudio`, `--with-cups`, `--with-ffmpeg`, `--with-gettext`,
      `--with-gssapi`, `--with-inotify`, `--with-krb5`, `--with-mingw`,
      `--with-opencl`, `--with-pthread`, `--with-unwind`, and `--with-usb`
      flags plus their Nix inputs.
    - [x] Keep `--with-opengl` out of the adopted Darwin flag set because Wine
      11 requires EGL development files when that flag is explicit, while
      nixpkgs Darwin Wine does not enable OpenGL support dependencies on
      Darwin.
    - [x] Verify the updated CrossOver Wine derivation with a full x86_64-darwin
      build before marking Phase 1 complete.
  - [x] Phase 2: fix missing dependencies and runtime dylib placement.
    - Add the dependencies needed by the re-enabled feature probes in the
      runtime submodule, with nixpkgs Darwin Wine's dependency set as the first
      reference point.
    - Ensure Wine's dlopen users can resolve their runtime libraries without
      relying on host shell state. In particular, `secur32` and `bcrypt` must
      find `libgnutls.30.dylib` from the packaged runtime root.
    - Align the packaged dylib layout and Mach-O `LC_RPATH` checks with the
      CrossOver.app pattern where Unix-side Wine modules can find common
      runtime libraries from the shared library root.
    - Extend runtime component checks so they validate dlopen-facing dylibs,
      `LC_RPATH`, and closure placement, not only `otool -L` Nix store
      references.
    - Update parent runtime contracts and source manifests when new required
      runtime files become part of the macOS Wine component.
    - Preserve separate component build and verification jobs, but assemble the
      verified Wine, DXVK-macOS, DXMT, vkd3d, MoltenVK, GStreamer, FreeType,
      wine-mono, wine-gecko, and winetricks payloads into one public runtime
      archive.
  - [ ] Phase 3: normalize launch and smoke behavior around the repaired
    runtime.
    - Compare Konyak's normal `.exe` path with CrossOver's observed wrapper
      behavior and decide whether plain executable launch should continue to
      use `start /unix` or a more direct run path.
    - Add regression and smoke coverage for a regular GUI `.exe`, not only
      backend probe executables or prefix initialization.
    - Make CI smoke launch with the same dylib search environment used by the
      app; remove `DYLD_FALLBACK_LIBRARY_PATH` or other smoke-only search paths
      that can hide packaging mistakes.
    - Keep runtime Actions rerun units narrow: dependency packaging, Wine
      build, component assembly, launch smoke, backend smoke, and publish work
      must remain independently rerunnable where practical.
    - [x] Review `WINEMSYNC` and `WINEESYNC` handling so Konyak does not enable
      incompatible sync modes together blindly; document the default and keep
      bottle settings explicit.
    - [x] Remove parent-side winetricks download/list-all fallback; the app path
      requires the submodule-produced winetricks executable and verb catalog.
    - [x] Rename parent raw Wine/Vulkan smoke targets as low-level diagnostics
      so app behavior proof stays on the CLI smoke route.
- [ ] Strengthen macOS runtime automated smoke coverage.
  - [x] Keep layout/hash comparisons out of the required gate; test runtime
    behavior through Wine execution instead.
  - [x] Add runtime submodule Windows probe executables for headless D3D11 and
    D3D12 device creation.
  - [x] Add runtime submodule smoke runners for DXVK D3D11, DXMT D3D11, and
    vkd3d D3D12 against an assembled runtime artifact stack.
  - [x] Split runtime Actions smoke jobs by backend so failed backend checks can
    be rerun without rebuilding Wine or unrelated components.
  - [x] Fix parent macOS DXMT launch environment so `lib/dxmt/x86_64-unix` is
    present in `DYLD_LIBRARY_PATH` when DXMT is selected.
  - [x] Add parent repository coverage that installs the published macOS runtime
    manifest, validates required backend component availability through the CLI
    runtime catalog, and includes a headless `create-bottle`
    prefix-initialization smoke that catches Wine Mono/Gecko installer prompts.
  - [x] Add packaged macOS app smoke coverage that finalizes debug and release
    bundles through the same helper/tool layout, verifies runtime archive
    extraction without the Nix dev shell `PATH`, and locally checks
    LaunchServices/Finder `.exe` launch behavior against the packaged debug
    app.
  - [x] Add a checksum-pinned PuTTY Windows executable fixture for local and
    CI Finder/LaunchServices/Quick Look packaged app smoke coverage without
    vendoring sample `.exe` binaries into the repository.
  - [ ] Add parent CLI-bound DXVK/DXMT/vkd3d backend probe execution smoke once
    the probe runner path can stay headless and non-flaky on GitHub-hosted
    arm64 macOS.
  - [x] Add GPTK/D3DMetal smoke as CI-only external-payload workflow coverage.
    The runtime submodule downloads the pinned Gcenx Game Porting Toolkit
    release asset into runner-local temporary storage, verifies its SHA-256,
    imports it only into the unpacked smoke runtime, and rejects runtime release
    archives that contain GPTK/D3DMetal payload paths.
    - [x] Add the runtime-owned GPTK/D3DMetal loader shim that uses CrossOver
      Wine's public `ntdll` exports instead of proprietary `cxcompatdb.so`.
    - [x] Locally verify GPTK D3D11 and GPTK D3D12 backend device smokes
      against a dev runtime with the user-imported GPTK payload.
    - [x] Republish the macOS runtime release assets from the runtime submodule
      Actions run after GPTK/D3DMetal CI smoke completed.
    - [x] Add `nix run .#gptk-d3dmetal-local-smoke` for local smoke execution
      against an assembled runtime root or published runtime stack archive.

## Deferred

- Strengthen typed domain maps.
  - [x] Replace runtime component version maps with a dedicated
    `RuntimeComponentVersions` value object.
  - [ ] Replace process and host environment maps in CLI/domain code with
    dedicated environment value objects, converting to `Map<String, String>`
    only at I/O boundaries.
  - [x] Replace program settings environment maps with a dedicated
    `ProgramEnvironmentOverrides` value object.
  - [ ] Add governance checks that forbid raw `Map<String, String>` in
    CLI/domain layers except for approved boundary adapters.
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
  - [x] Remove parent-side macOS local component generation from
    `scripts/prepare_macos_dev_runtime_stack.zsh`; it now resolves only complete
    manifests produced by the macOS runtime submodule.
  - [x] Remove parent-side Linux development component generation from
    `scripts/prepare_linux_dev_runtime_source.zsh`; it now validates and caches
    only explicitly supplied complete Linux runtime source manifests.
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
- Add E2E tests.
  - Decide the target level before implementation: Flutter integration tests
    with a fake CLI, real CLI tests against temporary directories, or a small
    full-stack Flutter + real CLI smoke suite.
  - Keep the E2E target separate from the default fast verification gate until
    its runtime cost and flake rate are known.
- Publication and signing of the default Linux runtime stack manifest and
  public key, once the Linux runtime packaging owner produces complete stack
  artifacts outside the parent repository.
- Removal of any remaining bootstrap Wine-only fallback only after each target
  platform has a complete default runtime stack manifest as its release input.
