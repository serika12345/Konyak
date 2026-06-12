# Progress

This file records Konyak's current active work and completed state so the
project can be resumed without relying on chat history.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot, completed milestone summaries, and
handoff notes.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-06-12 21:51 JST
- State: `completed`
- Branch: `main`
- Related work: macOS Wine launch window detection without process
  environment access
- Purpose: replace the non-working `WINEPREFIX` environment-variable filter
  with a macOS window owner process filter that can detect real Wine GUI
  windows when the launch overlay is still visible.
- Completed:
  - Verified locally that `KERN_PROCARGS2` does not expose a child process
    `WINEPREFIX` environment variable in this environment, so the previous
    prefix-based filter could not be relied on.
  - Changed Flutter launch detection to baseline existing Wine-process windows
    before launch and dismiss only when a new matching window appears.
  - Changed the macOS window bridge to match windows by the original
    CLI-process descendant filter or by Wine-like owner process identity.
  - Added native checks for `kCGWindowOwnerName` and `proc_pidpath` so windows
    owned by processes such as `wine`, `wine64`, `wine-preloader`,
    `wine64-preloader`, or CrossOver-derived executables can be detected.
  - Kept unrelated non-Wine app windows from clearing the launch overlay, and
    kept preexisting Wine windows from clearing it immediately.
- Remaining:
  - Linux still does not have equivalent X11/XWayland/Wayland-aware window
    detection.
  - Concurrent launch of another Wine app from outside Konyak could still
    dismiss the overlay because this fallback is process-kind scoped rather than
    bottle-prefix scoped.
- Next: manually smoke a real macOS Wine installer launch and confirm the
  overlay disappears when the Wine program window appears while unrelated
  non-Wine apps do not dismiss it.
- Verification:
  - `swift` probe of `KERN_PROCARGS2` against a child process with
    `WINEPREFIX=/tmp/konyak-prefix-test`: returned no `WINEPREFIX`, confirming
    the prefix-based implementation was not viable in this environment.
  - `cd apps/konyak && xcrun swiftc -parse-as-library -typecheck
    macos/Runner/AppDelegate.swift -F build/macos/Build/Products/Debug`:
    passed.
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program hides launch progress for a new Wine process window"`:
    passed.
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program ignores preexisting Wine process windows"`:
    passed.
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program ignores unrelated external windows while launch is pending"`:
    passed.
  - `cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS app exposes visible external window ids to Flutter"`:
    passed.
  - `dart format apps/konyak/lib/src/app/programs/program_window_probe.dart
    apps/konyak/lib/src/home_loader_parts/home_loader_programs.part.dart
    apps/konyak/test/widget_test.dart apps/konyak/test/widget_programs.part.dart
    apps/konyak/test/macos_window_metrics_test.dart`: passed.
  - `just flutter-format-check`: passed.
  - `just flutter-analyze`: passed.
  - `just flutter-test`: passed.
  - `just swift-lint`: passed; note the current SwiftLint configuration
    excludes `apps/konyak/macos/Runner/AppDelegate.swift`.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

- Timestamp: 2026-06-12 21:39 JST
- State: `completed`
- Branch: `main`
- Related work: macOS Wine launch window detection after process reparenting
- Purpose: make the launch overlay disappear for real macOS Wine GUI windows
  even when the window owner is no longer a descendant of the pending
  `run-program` CLI process.
- Completed:
  - Reviewed the current PID-descendant-only launch window detection and the
    reported behavior where the overlay remains visible.
  - Added a widget regression test for a newly visible Wine window from the
    launched bottle prefix whose owner is not associated with the CLI PID.
  - Added a widget regression test that preexisting windows from the same
    bottle prefix do not immediately dismiss the overlay.
  - Changed Flutter launch detection to snapshot existing windows for the
    bottle path before running the CLI, then dismiss only when a new matching
    window appears.
  - Extended the macOS window bridge to accept `winePrefixPath` alongside root
    process IDs.
  - Added native `KERN_PROCARGS2` environment parsing so CGWindow owner
    processes or their ancestors can match `WINEPREFIX=<bottle path>`.
  - Kept the previous PID-descendant filter as an additional match path, while
    preserving unrelated non-Wine app filtering.
- Remaining:
  - Linux still does not have equivalent X11/XWayland/Wayland-aware window
    detection.
  - A real macOS Wine launch smoke is still useful to confirm the target runtime
    processes expose `WINEPREFIX` through `KERN_PROCARGS2` in the packaged app.
- Next: manually smoke a real macOS Wine installer launch and confirm the
  overlay disappears when the Wine program window appears while unrelated apps
  do not dismiss it.
- Verification:
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program hides launch progress for a new bottle Wine window"`:
    failed before implementation because the PID-only filter kept the overlay
    visible; passed after implementation.
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program ignores preexisting bottle Wine windows"`:
    passed.
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program ignores unrelated external windows while launch is pending"`:
    passed.
  - `cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS app exposes visible external window ids to Flutter"`:
    passed.
  - `dart format apps/konyak/lib/src/app/programs/program_window_probe.dart
    apps/konyak/lib/src/home_loader_parts/home_loader_programs.part.dart
    apps/konyak/test/widget_test.dart apps/konyak/test/widget_programs.part.dart
    apps/konyak/test/macos_window_metrics_test.dart`: passed.
  - `cd apps/konyak && xcrun swiftc -parse-as-library -typecheck
    macos/Runner/AppDelegate.swift -F build/macos/Build/Products/Debug`:
    passed.
  - `just flutter-format-check`: passed.
  - `just flutter-analyze`: passed.
  - `just flutter-test`: passed.
  - `just swift-lint`: passed; note the current SwiftLint configuration
    excludes `apps/konyak/macos/Runner/AppDelegate.swift`.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

- Timestamp: 2026-06-12 21:23 JST
- State: `completed`
- Branch: `main`
- Related work: macOS program launch window false-positive reduction
- Purpose: prevent unrelated macOS application windows from dismissing the
  Windows program launch overlay while `run-program --json` is still pending.
- Completed:
  - Reviewed the existing launch overlay polling, macOS window-list bridge, and
    Flutter CLI process runner boundary.
  - Added a widget regression test that opens an unrelated external window while
    launch is pending and expects the overlay to remain visible.
  - Added started-process callbacks to the Flutter CLI process runner so
    `run-program` launch tracking can capture the just-started CLI PID.
  - Changed Flutter launch window polling to query only windows owned by
    descendant processes of that CLI PID.
  - Changed the macOS `visibleExternalWindowIds` bridge to accept root process
    IDs and filter CGWindow owners by walking parent PIDs with
    `sysctl(KERN_PROC_PID)`.
  - Kept unrelated external application windows from clearing the launch
    overlay while preserving early dismissal when a window from the launched
    process tree appears.
- Remaining:
  - Linux still does not have equivalent X11/XWayland/Wayland-aware window
    detection.
  - Real macOS Wine launch smoke is still needed to confirm Wine windows remain
    descendants of the pending `run-program` CLI process in the packaged app.
- Next: manually smoke a real macOS Wine installer launch and confirm the
  overlay ignores unrelated apps but disappears for the Wine program window.
- Verification:
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program ignores unrelated external windows while launch is pending"`:
    failed before implementation because any new external window dismissed the
    overlay; passed after implementation.
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program hides launch progress when a new macOS window opens"`:
    passed.
  - `cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "run-program reports the started CLI process id"`:
    passed.
  - `cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "Dart process runner reports the started process id"`:
    passed.
  - `cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS app exposes visible external window ids to Flutter"`:
    passed.
  - `dart format apps/konyak/lib/src/cli/konyak_cli_client.dart
    apps/konyak/lib/src/cli/konyak_cli_process_runner.dart
    apps/konyak/lib/src/cli/konyak_cli_program_commands.dart
    apps/konyak/lib/src/app/programs/program_window_probe.dart
    apps/konyak/lib/src/home_loader_parts/home_loader_programs.part.dart
    apps/konyak/test/widget_test.dart apps/konyak/test/widget_programs.part.dart
    apps/konyak/test/cli/konyak_cli_client_test.dart
    apps/konyak/test/app/immutability_test.dart
    apps/konyak/test/macos_window_metrics_test.dart`: passed.
  - `just flutter-format-check`: passed.
  - `just flutter-analyze`: passed.
  - `just flutter-test`: passed.
  - `just swift-lint`: passed; note the current SwiftLint configuration
    excludes `apps/konyak/macos/Runner/AppDelegate.swift`.
  - `cd apps/konyak && xcrun swiftc -parse-as-library -typecheck
    macos/Runner/AppDelegate.swift -F build/macos/Build/Products/Debug`:
    passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.
  - `cd apps/konyak && flutter build macos --debug`: attempted as extra Swift
    build validation, but failed before Runner compilation because Flutter's
    `debug_unpack_macos` phase could not create a `FlutterMacOS.lipo` temporary
    file inside the generated `FlutterMacOS.framework`; this is not one of the
    required gates for this change.

- Timestamp: 2026-06-11 22:36 JST
- State: `completed`
- Branch: `main`
- Related work: macOS program launch window detection
- Purpose: dismiss the Windows program launch overlay when the first Wine GUI
  window appears, because GUI `run-program --json` invocations can remain
  pending until the Windows program exits.
- Completed:
  - Confirmed the previous Flutter-only launch progress state waited for the
    CLI process result, which is insufficient for GUI Windows programs that
    keep the Wine command alive.
  - Added a widget regression test that keeps `run-program --json` pending and
    verifies the launch overlay disappears when the mocked macOS window list
    gains a new external window ID.
  - Added a macOS Runner source test for the native window-list method exposed
    to Flutter.
  - Added `visibleExternalWindowIds` on the existing `konyak/menu`
    MethodChannel, backed by `CGWindowListCopyWindowInfo` with filtering for
    onscreen, layer-0, non-Konyak, non-desktop windows with practical minimum
    dimensions.
  - Changed Flutter launch tracking to use per-launch IDs so CLI completion and
    native window detection can both clear the same launch without corrupting
    concurrent launch state.
- Remaining:
  - Linux does not yet have equivalent X11/XWayland/Wayland-aware window
    detection.
  - The CLI process is still allowed to finish normally later; latest-log
    availability remains tied to the eventual CLI result.
- Next: manually smoke a real macOS Wine installer launch and confirm the
  overlay disappears when the Wine window appears.
- Verification:
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program hides launch progress when a new macOS window opens"`:
    failed before implementation because the launch overlay stayed visible
    while the CLI Future was pending; passed after implementation.
  - `cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS app exposes visible external window ids to Flutter"`:
    passed after implementation.
  - `dart format apps/konyak/lib/src/app/konyak_app.dart
    apps/konyak/lib/src/home_loader/home_loader.dart
    apps/konyak/lib/src/home_loader_parts/home_loader_programs.part.dart
    apps/konyak/lib/src/app/programs/program_window_probe.dart
    apps/konyak/test/widget_test.dart apps/konyak/test/widget_programs.part.dart
    apps/konyak/test/macos_window_metrics_test.dart`: passed.
  - `just swift-lint`: passed.
  - `just flutter-format-check`: passed.
  - `just flutter-analyze`: passed.
  - `just flutter-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

- Timestamp: 2026-06-11 22:24 JST
- State: `completed`
- Branch: `main`
- Related work: Flutter program launch feedback
- Purpose: make Windows program launches visibly active after the user starts
  an executable so the app does not look idle while the CLI launch request is
  pending.
- Completed:
  - Reviewed the existing Flutter `run-program` flow, CLI client run-result
    parsing, blocking progress overlay, and program feedback tests.
  - Added a widget regression test that holds the `run-program --json` command
    pending and asserts that launch progress is shown until the CLI result
    returns.
  - Added a counted launch-progress state in `KonyakHomeLoader` and displayed
    the existing blocking progress overlay with `Launching program...` while
    one or more program launches are active.
  - Left the CLI JSON contract unchanged; this is a minimal Flutter feedback
    pass and does not yet detect native Wine window creation.
- Remaining:
  - True "until the first app window appears" detection still needs a later
    backend/platform probe, likely macOS window-list polling first and a
    Linux-specific strategy that accounts for X11/XWayland versus Wayland.
- Next: decide whether to add a CLI/platform window-detection contract after
  this minimal UI feedback is manually tried with real macOS Wine launches.
- Verification:
  - `cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program shows launch progress while the CLI is pending"`:
    failed before implementation because the launch overlay did not exist;
    passed after implementation.
  - `dart format apps/konyak/lib/src/home_loader/home_loader.dart
    apps/konyak/lib/src/home_loader_parts/home_loader_programs.part.dart
    apps/konyak/test/widget_programs.part.dart`: passed with no changes.
  - `just flutter-format-check`: passed.
  - `just flutter-analyze`: passed.
  - `just flutter-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

- Timestamp: 2026-06-11 21:59 JST
- State: `completed`
- Branch: `main`
- Related work: parent macOS published-runtime CLI smoke CI
- Purpose: add parent-repository CI coverage for the CrossOver-derived macOS
  runtime consumer path so future prefix-initialization regressions, including
  Wine Mono/Gecko installer prompts during bottle creation, are caught before
  release.
- Completed:
  - Reviewed the existing Linux-only `Konyak Verify` workflow, macOS runtime
    source manifest helper, CLI runtime JSON contracts, and submodule backend
    smoke helpers.
  - Added `scripts/run_macos_runtime_cli_smoke.zsh`, which installs the
    published macOS runtime source manifest through `install-macos-wine
    --reinstall`, validates the installed runtime and required backend component
    availability through CLI JSON contracts, and runs a timeout-bounded
    `create-bottle` smoke against an isolated data/config/runtime root.
  - Added `.github/workflows/macos-runtime-cli-smoke.yml` as an independent
    macOS `macos-15` workflow so the parent consumer path can be rerun without
    rerunning the Linux verify job or rebuilding the runtime submodule.
  - Split the parent runtime-smoke TODO so published-runtime install/catalog/
    prefix-init coverage is complete while CLI-bound DXVK/DXMT/vkd3d executable
    probe smoke remains explicit follow-up work.
- Remaining:
  - Parent CLI-bound DXVK/DXMT/vkd3d executable probe smoke is still pending;
    this change validates backend component availability, not actual D3D device
    creation through `run-program`.
- Next: add the parent CLI-bound backend probe smoke after the runner path is
  confirmed headless and non-flaky on GitHub-hosted arm64 macOS.
- Verification:
  - `zsh -n scripts/run_macos_runtime_cli_smoke.zsh`: passed.
  - `nix shell nixpkgs#actionlint -c actionlint
    .github/workflows/macos-runtime-cli-smoke.yml .github/workflows/verify.yml`:
    passed.
  - `./scripts/run_macos_runtime_cli_smoke.zsh`: passed; it installed the
    published `crossover-26.1.0-konyak.0` runtime manifest, validated
    `list-runtimes`, `validate-runtime`, and completed `create-bottle --name
    "CI Prefix Smoke"` without Wine Mono/Gecko prompts.
  - `dart format packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart
    packages/konyak_cli/test/cli_contract_program_execution.part.dart`:
    passed with no changes.
  - `just cli-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

- Timestamp: 2026-06-11 21:30 JST
- State: `completed`
- Branch: `main`
- Related work: macOS bottle prefix initialization with CrossOver runtime
- Purpose: stop the Wine Mono installer prompt from appearing during bottle
  creation when using the Konyak CrossOver-derived macOS runtime stack.
- Completed:
  - Confirmed the macOS Wine prefix initialization plan used the Konyak runtime
    `wine64 wineboot --init` path but did not expose the runtime stack's
    `share/wine` data directory to Wine.
  - Confirmed Wine's addon lookup supports `WINEDATADIR`, while the packaged
    Wine binaries retain a build-time Nix store data-dir reference that is not
    present in redistributed runtime installs.
  - Added `WINEDATADIR=<runtime>/share/wine` to the shared macOS Wine
    environment so Wine can find bundled addon payloads such as wine-mono.
  - Added prefix-initialization-only `WINEDLLOVERRIDES=mscoree,mshtml=` so
    bottle creation cannot show Wine Mono/Gecko installer prompts.
  - Added CLI contract coverage for both environment values on macOS prefix
    initialization.
  - Updated the macOS runtime smoke follow-up TODO so parent CI coverage must
    include a headless `create-bottle` prefix-initialization smoke. No GitHub
    Actions workflow was changed in this fix because the parent repository does
    not yet install the published runtime and run real macOS Wine smoke tests;
    that gap remains tracked under `docs/todo.md`.
- Remaining: none for the immediate installer prompt fix.
- Next: add the parent-side published-runtime CLI smoke workflow, including
  `create-bottle`, when continuing macOS runtime automated smoke coverage.
- Verification:
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart
    --plain-name "prefix initialization uses Konyak macOS Wine on macOS"`:
    failed before implementation because `WINEDATADIR` and
    `WINEDLLOVERRIDES=mscoree,mshtml=` were missing; passed after
    implementation.
  - `KONYAK_DATA_HOME="$tmp/data" KONYAK_CONFIG_HOME="$tmp/config"
    KONYAK_MACOS_WINE_HOME="$runtime" timeout 180s dart run
    packages/konyak_cli/bin/konyak.dart create-bottle --name MonoSmoke2
    --json`: passed against the local development macOS runtime in about 24
    seconds with no Wine installer prompt.
  - `dart format packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart
    packages/konyak_cli/test/cli_contract_program_execution.part.dart`:
    passed with no changes.
  - `just cli-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-11 19:38 JST
- State: `completed`
- Branch: `main`
- Related work: Process Manager active-prefix filtering
- Purpose: avoid Process Manager timeouts by not starting `winedbg info proc`
  for bottles that do not appear in the host process table.
- Completed:
  - Confirmed the previous performance pass still used `winedbg` for every
    bottle selected by the catalog, so slow inactive prefixes could still time
    out.
  - Added host process snapshot reading through `ps eww -axo command=` with a
    short timeout and no administrator privileges.
  - Filtered the async `list-wine-processes --json` path so only bottles whose
    paths appear in the host process snapshot are probed with `winedbg`.
  - Returned an empty process list immediately when no bottle appears active,
    avoiding slow Wine debugger startup for inactive prefixes.
  - Added path-boundary matching so `/bottles/a2` does not cause `/bottles/a`
    to be probed.
  - Added regression coverage for active-prefix filtering, empty fast return,
    and prefix-boundary matching.
- Remaining: none for this timeout follow-up.
- Next: manually smoke the Process Manager against real running macOS Wine
  programs, then continue with Dock/pinned launcher icon alignment.
- Verification:
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart
    --plain-name "runCliStreaming list-wine-processes"`: failed before
    implementation because `HostProcessSnapshotReader` and the injection point
    did not exist; passed after implementation.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart`: passed.
  - `just cli-test`: passed.
  - `just flutter-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.
  - `cd packages/konyak_cli && time dart run bin/konyak.dart
    list-wine-processes --json`: passed in about 1.2 seconds with an empty
    process list on the current inactive local environment.

- Timestamp: 2026-06-11 19:05 JST
- State: `completed`
- Branch: `main`
- Related work: Process Manager performance
- Purpose: keep the Process Manager GUI behavior stable while replacing the
  Wine process listing path's serial and synchronous work with async bounded
  concurrency and cached metadata resolution.
- Completed:
  - Reviewed the current Process Manager CLI, Flutter dialog, process metadata,
    Wine runner, and pinned launcher icon paths.
  - Added `runCliStreaming list-wine-processes` contract coverage proving
    bottle probes are started concurrently while JSON process order remains
    catalog-stable.
  - Added contract coverage proving duplicate process host paths reuse one
    metadata/icon extraction within a single listing request.
  - Added async program runner and async program metadata extractor boundaries
    for the streaming CLI path.
  - Routed `runCliStreaming` `list-wine-processes --json` through async bounded
    concurrency without changing the Flutter-visible JSON contract.
  - Added a 4-second timeout to the async process runner used by the streaming
    process listing path so a stuck Wine probe is killed and reported through
    the existing `wineProcessListFailed` error shape.
  - Cached per-bottle external launch index and `latest.log` reads during
    process host-path resolution.
- Remaining: none for this performance pass.
- Next: continue with the next Process Manager improvement, such as aligning
  displayed process icons with the Dock/pinned launcher icon source.
- Verification:
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart
    --plain-name "runCliStreaming list-wine-processes"`: failed before
    implementation because the async runner/extractor API and fast-path CLI
    parameters did not exist; passed after implementation.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart`: passed.
  - `just cli-test`: passed.
  - `just flutter-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

- Timestamp: 2026-06-11 18:28 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime automated smoke coverage
- Purpose: prove the Konyak macOS runtime works through Wine execution and
  backend device probes rather than by comparing CrossOver file hashes or
  layouts.
- Completed:
  - Reviewed the current runtime roadmap, progress notes, submodule TODO, and
    runtime Actions jobs.
  - Split the runtime submodule TODO into payload checks, Wine32-on-64 launch
    smoke, backend device smoke jobs, MoltenVK follow-up, and manual
    GPTK/D3DMetal coverage.
  - Added a parent roadmap item for macOS runtime automated smoke coverage,
    separating submodule artifact smoke from parent CLI install/run coverage.
  - Added runtime submodule mingw-built Windows probes for D3D11 and D3D12
    backend smoke tests.
  - Added `scripts/smoke-backend-device.zsh`, which creates an isolated
    prefix, suppresses Wine mono/gecko installer prompts, applies macOS backend
    DLL overrides, syncs native override DLLs into `system32`/`syswow64`, and
    runs DXVK D3D11, DXMT D3D11, or vkd3d D3D12 probes.
  - Added separate runtime Actions jobs for `smoke-dxvk-d3d11`,
    `smoke-dxmt-d3d11`, and `smoke-vkd3d-d3d12`, and wired release publishing
    to require those smoke jobs.
  - Fixed the parent macOS run environment so DXMT runs include
    `lib/dxmt/x86_64-unix` in `DYLD_LIBRARY_PATH`; the new DXMT smoke exposed
    this missing runtime path as a real load failure.
  - Committed and pushed the runtime submodule change as
    `cb7f2cdcee87cca162c73357976626518166b8ec`
    (`Add macOS runtime backend smoke tests`) to
    `serika12345/konyak-macos-runtime@main`.
  - Confirmed runtime submodule GitHub Actions run `27335407227` completed
    successfully, including the new DXVK D3D11, DXMT D3D11, and vkd3d D3D12
    backend smoke jobs plus Wine32-on-64 launch smoke, metadata generation, and
    release publishing.
  - Re-fetched the published macOS runtime source manifest from the default
    release and reinstalled the runtime into the parent repository development
    runtime root through `install-macos-wine --reinstall`.
  - Verified the installed published runtime locally with parent CLI runtime
    validation, component layout checks, DXVK D3D11 smoke, DXMT D3D11 smoke,
    vkd3d D3D12 smoke, and Wine32-on-64 launch smoke.
- Remaining:
  - Add parent repository coverage that installs the published macOS runtime
    manifest and runs the same probes through the CLI boundary.
  - Add MoltenVK/Vulkan-only smoke and manual GPTK/D3DMetal smoke coverage.
- Next: add parent-side CI coverage that installs the published runtime and
  runs the backend probes through the CLI boundary.
- Verification:
  - `zsh -n runtime/konyak-macos-runtime/scripts/build-backend-probes.zsh
    runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh
    runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh
    runtime/konyak-macos-runtime/scripts/assemble-runtime-stack.zsh`: passed.
  - `cd runtime/konyak-macos-runtime && nix develop -c zsh -lc
    "./scripts/build-backend-probes.zsh .dart_tool/backend-probes && file
    .dart_tool/backend-probes/*.exe"`: passed; both probes identify as PE32+
    x86-64 Windows executables.
  - `cd runtime/konyak-macos-runtime && nix flake check -L --show-trace`:
    passed for the current host system.
  - `runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh
    .dart_tool/konyak/dev-runtime/macos-wine dxvk-d3d11`: passed after the
    runner copied DXVK override DLLs into the temporary prefix.
  - `runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh
    .dart_tool/konyak/dev-runtime/macos-wine dxmt-d3d11`: passed after adding
    `lib/dxmt/x86_64-unix` to `DYLD_LIBRARY_PATH`.
  - `runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh
    .dart_tool/konyak/dev-runtime/macos-wine vkd3d-d3d12`: passed.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart`: passed.
  - `just cli-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.
  - `git diff --check && git -C runtime/konyak-macos-runtime diff --check`:
    passed.
  - Runtime submodule GitHub Actions run `27335407227` passed for commit
    `cb7f2cdcee87cca162c73357976626518166b8ec`; the run completed validate,
    binary component packaging, Wine runtime artifact build, DXMT component
    build and verification, vkd3d component build and verification, Wine32-on-64
    launch smoke, DXVK D3D11 backend smoke, DXMT D3D11 backend smoke, vkd3d
    D3D12 backend smoke, release metadata generation, and release publishing.
  - `scripts/prepare_macos_dev_runtime_stack.zsh --force --print-manifest-path`
    refreshed the published source manifest from
    `https://github.com/serika12345/konyak-macos-runtime/releases/download/crossover-26.1.0-konyak.0/konyak-macos-wine-runtime-stack-source.json`.
  - `cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development
    KONYAK_MACOS_WINE_HOME="$runtime_path"
    KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$manifest_path" dart run
    bin/konyak.dart install-macos-wine --reinstall --source-manifest
    "$manifest_path" --progress-json --json`: passed; final runtime JSON
    reported `isInstalled: true`, stack `isComplete: true`, and DXVK, DXMT,
    GPTK/D3DMetal, and vkd3d backends available.
  - `runtime/konyak-macos-runtime/scripts/check-dxmt-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-vkd3d-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-dxvk-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-gstreamer-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development
    KONYAK_MACOS_WINE_HOME="$runtime_path" dart run bin/konyak.dart
    validate-runtime konyak-macos-wine --json`: passed with `isValid: true`.
  - `cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development
    KONYAK_MACOS_WINE_HOME="$runtime_path" dart run bin/konyak.dart
    list-runtimes --json`: passed; the installed macOS runtime reported stack
    complete and DXVK, DXMT, GPTK/D3DMetal, and vkd3d backends available.
  - `cd runtime/konyak-macos-runtime && nix develop -c zsh -lc
    "./scripts/build-backend-probes.zsh .dart_tool/backend-probes &&
    ./scripts/smoke-backend-device.zsh ../../.dart_tool/konyak/dev-runtime/macos-wine
    dxvk-d3d11 .dart_tool/backend-probes &&
    ./scripts/smoke-backend-device.zsh ../../.dart_tool/konyak/dev-runtime/macos-wine
    dxmt-d3d11 .dart_tool/backend-probes &&
    ./scripts/smoke-backend-device.zsh ../../.dart_tool/konyak/dev-runtime/macos-wine
    vkd3d-d3d12 .dart_tool/backend-probes &&
    ./scripts/smoke-wine32on64-launch.zsh ../../.dart_tool/konyak/dev-runtime/macos-wine"`:
    passed.

- Timestamp: 2026-06-11 16:40 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime parity with CrossOver
- Purpose: include DXMT's x86_64 NVIDIA compatibility shim DLLs in the
  Konyak-managed macOS runtime component and parent runtime completeness
  contract.
- Completed:
  - Enabled DXMT's `nvapi` and `nvngx` Meson options for the win64 build while
    keeping the win32 DXMT build limited to the existing DLL set.
  - Packaged `x86_64-windows/nvapi64.dll` and
    `x86_64-windows/nvngx.dll` in the DXMT component, recorded the NVIDIA
    NVAPI license, and made the submodule DXMT component checker require both
    files as PE32+ DLLs.
  - Updated the parent CLI runtime platform support contract, install/update
    fixtures, missing-path tests, and component archive fixtures so DXMT is
    incomplete without the new shim DLLs.
  - Updated runtime submodule DXMT documentation and parent runtime roadmap
    notes to keep the release contract aligned with the generated component.
  - Refreshed the local development runtime DXMT component under
    `.dart_tool/konyak/dev-runtime/macos-wine/lib/dxmt` with the generated
    `nvapi64.dll` and `nvngx.dll`.
  - Committed and pushed the runtime submodule change as
    `47c3dad54851665069ae4e3a7e3e202c8c435e06`
    (`Add DXMT NVIDIA shim DLLs`) to
    `serika12345/konyak-macos-runtime@main`.
  - Published the refreshed runtime release assets from GitHub Actions run
    `27325858054`.
  - Reinstalled the published macOS runtime release into the parent repository
    development runtime root from the refreshed source manifest.
- Remaining: none.
- Verification:
  - Pre-implementation `cd packages/konyak_cli && dart test test/cli_contract_test.dart`:
    failed as expected because the parent runtime contract did not yet include
    the new DXMT paths.
  - Pre-implementation
    `runtime/konyak-macos-runtime/scripts/check-dxmt-component.zsh .dart_tool/konyak/dev-runtime/macos-wine`:
    failed as expected because the installed development runtime did not yet
    contain `x86_64-windows/nvapi64.dll`.
  - `cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT="$PWD/../../.dart_tool/konyak/dev-runtime/macos-wine" KONYAK_METAL_TOOLCHAIN_BIN="$metal_bin" nix build --impure .#packages.x86_64-darwin.konyak-macos-dxmt -L --show-trace --out-link result-dxmt && ./scripts/check-dxmt-component.zsh result-dxmt`:
    passed; `result-dxmt/x86_64-windows/nvapi64.dll` and
    `result-dxmt/x86_64-windows/nvngx.dll` were generated.
  - `zsh -n runtime/konyak-macos-runtime/scripts/check-dxmt-component.zsh`:
    passed.
  - `git diff --check && git -C runtime/konyak-macos-runtime diff --check`:
    passed.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart`: passed.
  - `just cli-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.
  - Local development runtime DXMT overlay from the cached Nix build plus
    `runtime/konyak-macos-runtime/scripts/check-dxmt-component.zsh .dart_tool/konyak/dev-runtime/macos-wine/lib/dxmt`:
    passed; both new DLLs identify as PE32+ x86-64 Windows DLLs.
  - Runtime submodule GitHub Actions run `27325858054` passed for commit
    `47c3dad54851665069ae4e3a7e3e202c8c435e06`; the run completed validate,
    binary component packaging, Wine runtime artifact build, DXMT component
    build and verification, vkd3d component build and verification, assembled
    Wine32-on-64 smoke, release metadata generation, and release publishing.
  - `scripts/prepare_macos_dev_runtime_stack.zsh --force --print-manifest-path
    --print-runtime-path` refreshed the published source manifest for
    `crossover-26.1.0-konyak.0`.
  - `cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development
    KONYAK_MACOS_WINE_HOME="$runtime_path"
    KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$manifest_path" dart run
    bin/konyak.dart install-macos-wine --reinstall --source-manifest
    "$manifest_path" --progress-json --json` installed the published release
    into `.dart_tool/konyak/dev-runtime/macos-wine`; the final runtime JSON
    reported DXMT installed, DXMT backend available, and no DXMT missing paths.
  - Refreshed source manifest DXMT component:
    `https://github.com/serika12345/konyak-macos-runtime/releases/download/crossover-26.1.0-konyak.0/konyak-macos-dxmt.tar.zst`
    with SHA-256
    `995a4ea7bfb18aa14e78f68e29e2f0662ed607d83283ba5fd844891781504cf3`.
  - `runtime/konyak-macos-runtime/scripts/check-dxmt-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-vkd3d-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-dxvk-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-gstreamer-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
  - `file .dart_tool/konyak/dev-runtime/macos-wine/lib/dxmt/x86_64-windows/nvapi64.dll
    .dart_tool/konyak/dev-runtime/macos-wine/lib/dxmt/x86_64-windows/nvngx.dll`:
    both files identify as PE32+ x86-64 Windows DLLs.
  - `cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development
    KONYAK_MACOS_WINE_HOME="$runtime_root" dart run bin/konyak.dart
    validate-runtime konyak-macos-wine --json`: passed with `isValid: true`.
  - `cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development
    KONYAK_MACOS_WINE_HOME="$runtime_root" dart run bin/konyak.dart
    list-runtimes --json`: passed; `konyak-macos-wine` reported DXMT installed
    with no missing paths and the DXMT backend available.
  - `runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh
    .dart_tool/konyak/dev-runtime/macos-wine`: passed.
- Next: commit the parent repository changes if requested.

- Timestamp: 2026-06-11 13:31 JST
- State: `runtime_backend_state_exposed`
- Branch: `main`
- Related work: runtime backend availability contract
- Purpose: make graphics backend availability explicit in the CLI/runtime
  state instead of forcing Flutter to infer backend usability from individual
  component paths.
- Completed:
  - Added `stack.backends` to runtime JSON with backend id, role, dependent
    component ids, missing component ids, missing paths, and `isAvailable`.
  - Added macOS backend states for DXVK-macOS, DXMT, GPTK/D3DMetal, and vkd3d;
    added Linux backend states for DXVK and vkd3d-proton.
  - Updated Flutter runtime parsing to accept `backends` while preserving
    compatibility with older runtime payloads that only expose `components`.
  - Updated bottle runtime control availability to prefer explicit backend
    availability and fall back to component availability for old payloads.
- Verification:
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart test/domain_immutability_test.dart`:
    passed.
  - `cd apps/konyak && flutter test test/cli/runtime_list_contract_test.dart test/app/bottle_runtime_control_availability_test.dart`:
    passed.
  - `just cli-test`: passed.
  - `just flutter-format-check`: passed.
  - `just flutter-analyze`: passed.
  - `just flutter-test`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `git diff --check`: passed.
- Next: commit the backend state representation change if requested.

- Timestamp: 2026-06-11 13:14 JST
- State: `gptk_import_isolated_and_preserved`
- Branch: `main`
- Related work: GPTK/D3DMetal component isolation
- Purpose: keep user-imported GPTK/D3DMetal as an optional runtime component
  without overwriting the base Wine payload, and preserve that import across
  macOS runtime reinstall/update operations.
- Completed:
  - Moved GPTK/D3DMetal import output to
    `components/gptk-d3dmetal/lib/...` for CLI import, runtime stack component
    normalization, and the runtime submodule import script.
  - Updated macOS launch environment generation so D3DMetal uses the isolated
    component's `WINEDLLPATH`, `DYLD_LIBRARY_PATH`,
    `DYLD_FRAMEWORK_PATH`, and `CX_APPLEGPTK_LIBD3DSHARED_PATH`.
  - Added runtime package preservation logic that keeps `gptk-d3dmetal` during
    full reinstall/update and migrates older `lib/external` +
    `lib/wine/x86_64-*` overlay imports into the isolated component layout.
  - Updated bottle DLL override repair/sync to read D3DMetal DLLs from the
    component layout, with legacy overlay paths only as a read fallback.
  - Updated CLI, Flutter contract tests, release/distribution docs, runtime
    import contract docs, and the runtime submodule Wine build-info contract.
- Verification:
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart`: passed.
  - `zsh -n runtime/konyak-macos-runtime/scripts/import-gptk-d3dmetal-redist.zsh`:
    passed.
  - `just cli-test`: passed.
  - `just flutter-test`: passed.
  - `just format-check`: passed.
  - `just verify-governance`: passed.
  - `just lint`: passed.
  - `just verify-safety`: passed.
  - Runtime submodule import script smoke using
    `/Users/masato/Downloads/CrossOver.app` into a temporary runtime root:
    passed; the payload landed under `components/gptk-d3dmetal`, and
    `lib/wine/x86_64-windows/nvapi64.dll` was not created in the base Wine
    tree.
  - `git diff --check && git -C runtime/konyak-macos-runtime diff --check`:
    passed.
- Next: commit parent and runtime submodule changes together, then run CI if
  requested.

- Timestamp: 2026-06-11 12:49 JST
- State: `macos_vkd3d_runtime_component_implemented`
- Branch: `main`
- Related work: macOS runtime parity with CrossOver
- Purpose: add CrossOver-derived vkd3d DLLs to the Konyak macOS runtime stack
  without adding runtime dependencies to the parent Nix flake.
- Completed:
  - Added a runtime submodule vkd3d Nix package that builds from the pinned
    CrossOver FOSS source archive and reuses the extracted Wine runtime
    artifact for `widl` without rebuilding the Wine runtime.
  - Added a separate runtime Actions job so vkd3d can be rebuilt or rerun
    without rebuilding Wine.
  - Added parent CLI runtime completeness requirements for
    `libvkd3d-1.dll`, `libvkd3d-shader-1.dll`, and `libvkd3d-utils-1.dll` on
    both `i386-windows` and `x86_64-windows`.
  - Updated the macOS development runtime stack source flow to consume the
    submodule vkd3d component archive instead of sourcing vkd3d from the parent
    flake.
- Verification:
  - `cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT="$PWD/../../.dart_tool/konyak/dev-runtime/macos-wine" nix build --impure .#packages.x86_64-darwin.konyak-macos-vkd3d -L --show-trace --out-link result-vkd3d && ./scripts/check-vkd3d-component.zsh result-vkd3d`:
    passed.
  - Runtime vkd3d component `tar.zst` package/extract smoke check: passed.
  - Runtime vkd3d dry-run check confirmed `konyak-macos-wine-runtime` is not
    rebuilt when `KONYAK_WINE_RUNTIME_ROOT` is set.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart`: passed.
  - `zsh -n` for touched macOS runtime and parent runtime-prep scripts: passed.
  - `just cli-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.
  - Runtime submodule commit `43f53bb` was pushed, and runtime Actions run
    `27321085521` completed successfully, including vkd3d build, smoke, release
    metadata, and publish jobs.
  - Parent-side verification passed after the runtime Actions release was
    published: `cd packages/konyak_cli && dart test test/cli_contract_test.dart`,
    `just cli-test`, `just verify-governance`, `just verify-safety`,
    `just format-check`, and `just lint`.
- Next: push the parent Konyak commit and run parent CI when ready.

- Timestamp: 2026-06-11 09:21 JST
- State: `gptk_d3dmetal_nvidia_shim_implemented`
- Branch: `main`
- Related work: GPTK/D3DMetal NVIDIA shim compatibility
- Purpose: align Konyak's GPTK/D3DMetal import and launch contract with the
  actual CrossOver 26.1 `apple_gptk` payload so NVIDIA shim DLLs are imported,
  validated, copied into bottle overrides, and enabled at launch.
- Completed:
  - Confirmed the CrossOver 26.1 payload lives under
    `Contents/SharedSupport/CrossOver/lib64/apple_gptk` and includes
    `nvapi64.dll`, `nvngx.dll`, `nvapi64.so`, and `nvngx.so`.
  - Updated the parent GPTK/D3DMetal runtime contract to require canonical
    `nvngx.dll` / `nvngx.so`, not the older `nvngx-on-metalfx` file names.
  - Removed obsolete GPTK/D3DMetal `d3d10` requirements from the GPTK contract;
    D3D10 remains owned by DXVK/DXMT components instead.
  - Updated the CLI importer to resolve CrossOver.app's `apple_gptk` layout,
    validate NVIDIA shim PE/Mach-O or symlink payloads, and normalize older
    `nvngx-on-metalfx` inputs to canonical `nvngx` runtime paths.
  - Updated macOS D3DMetal bottle override repair/run behavior to copy
    `nvapi64.dll` and `nvngx.dll`, and to remove stale
    `nvngx-on-metalfx.dll` overrides when switching graphics backends.
  - Updated the D3DMetal launch override to
    `dxgi,d3d11,d3d12,nvapi64,nvngx=n,b`.
  - Updated the runtime submodule import script and build-info contract to use
    the same canonical `nvngx` layout and CrossOver.app source path.
- Verification:
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart` passed.
  - `zsh -n scripts/prepare_macos_dev_runtime_stack.zsh
    runtime/konyak-macos-runtime/scripts/import-gptk-d3dmetal-redist.zsh`
    passed.
  - CLI import from `/Users/masato/Downloads/CrossOver.app` into a temporary
    runtime root passed and preserved the NVIDIA shim symlinks.
  - Runtime submodule `scripts/import-gptk-d3dmetal-redist.zsh` import from
    `/Users/masato/Downloads/CrossOver.app` into a temporary runtime root
    passed and preserved the NVIDIA shim symlinks.
  - `just cli-test` passed.
  - `git diff --check && git -C runtime/konyak-macos-runtime diff --check`
    passed.
  - `just verify-governance` passed.
  - `just verify-safety` passed.
  - `just format-check` passed.
  - `just lint` passed.
- Next: continue with vkd3d and remaining backend probes.

- Timestamp: 2026-06-10 23:13 JST
- State: `gstreamer_plugins_release_verified`
- Branch: `main`
- Related work: macOS runtime media component completeness
- Purpose: make the macOS GStreamer runtime component usable for Wine media
  playback by shipping plugin dylibs and the plugin scanner, not only
  `libgstreamer-1.0.0.dylib`.
- Completed:
  - Updated runtime component packaging to include GStreamer core, base, good,
    and bad plugin roots in `lib/gstreamer-1.0`.
  - Added `libexec/gstreamer-1.0/gst-plugin-scanner` to the GStreamer component.
  - Added `scripts/check-gstreamer-component.zsh` in the runtime submodule to
    require representative playback/demux/plugin files and reject unpackaged
    `/nix/store/*.dylib` references.
  - Updated runtime Actions to pass the plugin roots, verify the GStreamer
    component archive, and verify the assembled smoke runtime.
  - Updated the parent runtime completeness contract to require the plugin
    directory and scanner.
  - Updated macOS launch planning to set `GST_PLUGIN_SYSTEM_PATH`,
    `GST_PLUGIN_SCANNER`, and a bottle-local `GST_REGISTRY`.
  - Updated the parent local development source helper to mirror the same
    GStreamer payload shape when explicit plugin roots are provided.
  - Installed the published macOS runtime release into the local development
    runtime root from the refreshed source manifest and verified the parent CLI
    sees the complete GStreamer component.
- Verification:
  - Runtime submodule Actions run `27280426574` passed through release
    publishing for commit `799dae2`.
  - `scripts/prepare_macos_dev_runtime_stack.zsh --print-manifest-path
    --print-runtime-path` refreshed the release source manifest.
  - `cd packages/konyak_cli && dart run bin/konyak.dart install-macos-wine
    --reinstall --source-manifest <manifest> --progress-json --json` installed
    the published release into `.dart_tool/konyak/dev-runtime/macos-wine`.
  - `runtime/konyak-macos-runtime/scripts/check-gstreamer-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine` passed.
  - `runtime/konyak-macos-runtime/scripts/check-dxvk-component.zsh
    .dart_tool/konyak/dev-runtime/macos-wine` passed.
  - `runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh
    .dart_tool/konyak/dev-runtime/macos-wine` passed.
  - `cd packages/konyak_cli && dart run bin/konyak.dart validate-runtime
    konyak-macos-wine --json` passed with `isValid: true`.
  - `runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh
    .dart_tool/konyak/dev-runtime/macos-wine` passed.
  - `zsh -n scripts/prepare_macos_dev_runtime_stack.zsh
    runtime/konyak-macos-runtime/scripts/package-binary-components.zsh
    runtime/konyak-macos-runtime/scripts/check-gstreamer-component.zsh
    runtime/konyak-macos-runtime/scripts/make-source-manifest.zsh` passed.
  - `cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c
    actionlint .github/workflows/build-runtime.yml` passed.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart` passed.
  - Runtime binary component packaging succeeded locally using x86_64-darwin
    GStreamer core/base/good/bad plugin roots.
  - `runtime/konyak-macos-runtime/scripts/check-gstreamer-component.zsh` passed
    for the extracted GStreamer component.
  - `just cli-test` passed.
  - `git diff --check && git -C runtime/konyak-macos-runtime diff --check`
    passed.
  - `just verify-governance` passed.
  - `just verify-safety` passed.
  - `just format-check` passed.
  - `just lint` passed.
- Next: continue with the remaining runtime component checks such as NVIDIA shim
  and vkd3d.

- Timestamp: 2026-06-10 21:52 JST
- State: `docs_refreshed`
- Branch: `main`
- Related work: macOS runtime component documentation
- Purpose: make the repository documentation match the current runtime state
  after the DXVK D3D10 component update and release republish, so the next
  continuation can resume from docs without relying on chat history.
- Completed:
  - Documented that the macOS runtime release is the SSOT for Wine, DXMT,
    DXVK-macOS, and binary runtime components.
  - Documented that `dxvk-macos` is currently built from the Gcenx DXVK-macOS
    payload plus upstream DXVK `v1.10.3` only for `d3d10.dll` and
    `d3d10_1.dll`.
  - Brought the runtime submodule DXMT/DXVK TODO state up to date: DXMT build,
    Metal toolchain handoff, Actions coverage, DXVK independence, and
    backend-specific launch environment generation are complete.
  - Left the remaining runtime follow-ups explicit: GPTK import must stop
    overwriting `lib/wine/*`, backend selection still needs an explicit enum,
    and backend-specific probes are still missing.
- Verification:
  - `git diff --check` passed for the parent repository and runtime submodule.
  - `just verify-governance` passed.
  - `just verify-safety` passed.
  - `just format-check` passed.
  - `just lint` passed.
- Next: commit this documentation update if requested.

- Timestamp: 2026-06-10 21:35 JST
- State: `dxvk_d3d10_runtime_updated`
- Branch: `main`
- Related work: macOS DXVK runtime component completeness
- Purpose: include DXVK's `d3d10.dll` and `d3d10_1.dll` in the macOS runtime
  stack without moving runtime dependencies into the parent Nix flake. The
  `runtime/konyak-macos-runtime` submodule remains the release artifact SSOT;
  the parent dev-runtime source helper is only kept in sync with the same DXVK
  component payload shape.
- Completed:
  - Confirmed the pinned Gcenx `dxvk-macOS-async-v1.10.3-20230507` archive has
    `dxgi.dll`, `d3d9.dll`, `d3d10core.dll`, and `d3d11.dll`, but not
    `d3d10.dll` or `d3d10_1.dll`.
  - Confirmed upstream DXVK `v1.10.3` contains `d3d10.dll` and `d3d10_1.dll`
    for both `x32` and `x64`.
  - Updated runtime binary component packaging to keep the Gcenx DXVK-macOS
    DLLs and supplement only `d3d10.dll` / `d3d10_1.dll` from upstream DXVK
    `v1.10.3`.
  - Added `scripts/check-dxvk-component.zsh` in the runtime submodule to verify
    both i386 and x86_64 DXVK DLL payloads and file types.
  - Updated runtime Actions to verify the DXVK component archive immediately
    after packaging and again after assembling the smoke runtime stack.
  - Updated the parent dev runtime source helper to package the same DXVK
    D3D10 DLLs for local dev sources.
  - Updated the parent CLI runtime contract so `dxvk-macos` completeness and
    macOS DXVK DLL overrides include `d3d10.dll` and `d3d10_1.dll`.
  - Pushed runtime submodule commit
    `a390185 feat: include DXVK D3D10 loader DLLs`.
  - GitHub Actions run `27274534375` passed and republished the
    `crossover-26.1.0-konyak.0` runtime release assets.
  - Refreshed the local development runtime source manifest and reinstalled
    `.dart_tool/konyak/dev-runtime/macos-wine` from that release.
- Verification:
  - Runtime binary component packaging succeeded using `/tmp` dist/cache.
  - `scripts/check-dxvk-component.zsh` passed for the extracted DXVK component.
  - Release Wine/DXMT archives plus the locally generated binary components
    assembled successfully; Wine32-on-64, DXMT, and DXVK layout checks passed.
  - `scripts/smoke-wine32on64-launch.zsh` passed against the assembled runtime
    stack.
  - Runtime Actions jobs passed: validate, Wine artifact, binary components
    with DXVK component verification, DXMT artifact, release metadata,
    Wine32-on-64 smoke, and release publish.
  - Local `install-macos-wine --reinstall --source-manifest ... --json`
    completed and reported `dxvk-macos` version
    `v1.10.3-20230507+dxvk-1.10.3-d3d10`.
  - The reinstalled dev runtime passed `scripts/check-dxvk-component.zsh`, and
    `list-runtimes --json` reported all four added DXVK D3D10 paths.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart` passed
    after the parent CLI contract update.
  - `zsh -n`, `git diff --check`, and `actionlint` passed.
  - `just verify-governance`, `just verify-safety`, `just format-check`, and
    `just lint` passed after this progress note was added.
- Next: no active follow-up for this change.

- Timestamp: 2026-06-08 23:46 JST
- State: `actions_passed`
- Branch: `main`
- Latest known parent commit:
  `98cc340 docs: track arm64 runtime smoke rerun`
- Latest known macOS runtime submodule commit:
  `e00e1da ci: publish release without checkout`
- Related work: macOS 32-bit Windows executable support
- Purpose: restore macOS 32-bit Windows executable support while keeping the
  `runtime/konyak-macos-runtime` submodule as the runtime artifact SSOT. The
  parent repository must validate and consume the submodule-produced Wine32-on-64
  payload instead of adding runtime dependencies to the parent Nix flake. Runtime
  Actions must keep expensive Wine builds, DXMT builds, binary component
  packaging, metadata generation, smoke, and publish work in separate rerunnable
  jobs so a failed component, metadata, smoke, or publish rerun does not force a
  successful Wine runtime build to run again.
- Completed:
  - Compared `/Users/masato/Downloads/CrossOver.app` with Konyak's runtime
    contract.
  - Confirmed CrossOver carries `lib/wine/i386-windows`,
    `lib/wine/x86_64-windows`, and `lib/wine/x86_64-unix`, with no
    `lib/wine/i386-unix`.
  - Updated the submodule runtime recipe to build Wine with
    `--enable-archs=i386,x86_64` and fail the build if the Wine32-on-64 payload
    is missing.
  - Added a submodule release/workflow check for the required Wine32-on-64
    files: `bin/wine`, `lib/wine/i386-windows/ntdll.dll`,
    `lib/wine/x86_64-windows/wow64.dll`,
    `lib/wine/x86_64-windows/wow64cpu.dll`,
    `lib/wine/x86_64-windows/wow64win.dll`, and host Unix `ntdll.so`.
  - Confirmed `winewrapper.exe` is not a Konyak required payload because the
    upstream Wine build used by the submodule does not install it. Konyak
    continues to launch the runtime-owned `bin/wine` or `bin/wine64`
    entrypoint.
  - Updated the parent CLI runtime completeness contract so `wine32on64` is
    backed by actual Wine32-on-64 files, not only `bin/wine`.
  - Updated macOS run planning to always set base `WINEDLLPATH` for Wine,
    including `x86_64-windows`, `i386-windows`, and `lib/wine`; DXMT and DXVK
    prepend their own x86_64/i386 Windows DLL paths when selected.
  - Added `scripts/smoke-wine32on64-launch.zsh` in the runtime submodule. It
    verifies the assembled runtime stack, confirms FreeType is x86_64, and runs
    the runtime's 32-bit `cmd.exe` through Wine32-on-64.
  - Added release CI coverage that overlays runtime component archives before
    running the 32-bit launch smoke.
  - Fixed the runtime FreeType component packaging contract so it ships
    `lib/libfreetype.6.dylib`, the `lib/libfreetype.dylib` alias, and the
    needed Nix dylib closure.
  - Made binary component packaging reject non-x86_64 macOS GStreamer and
    FreeType dylibs, so Apple Silicon local runs do not accidentally package
    arm64 dylibs for the x86_64 Wine runtime.
  - Patched Wine's macOS FreeType late-loading path in the runtime submodule so
    it can load the Konyak runtime stack FreeType from the assembled runtime
    instead of relying on parent Nix dependencies.
  - Kept D3DMetal/GPTK x86_64-only unless a 32-bit-capable payload is produced.
  - Removed the external release archive dependency from the macOS source
    manifest failure contract test; the release manifest URL remains covered by
    the repository SSOT test.
  - Investigated failed GitHub Actions run `27113459002`: the runtime build,
    Wine32-on-64 payload check, Wine runtime package, DXMT build, and component
    packaging passed, then `Verify Wine32-on-64 launch smoke` failed because
    `result` had been overwritten by the DXMT build output before smoke
    assembly.
  - Updated the runtime workflow to use separate out-links:
    `result-wine-runtime` for Wine and `result-dxmt` for DXMT, so the launch
    smoke always copies the Wine runtime before overlaying component archives.
  - Cancelled obsolete manual run `27113613086` and pushed the submodule fix,
    starting push run `27116103755`.
  - Split the runtime workflow into `validate`, `build-and-package`,
    `smoke-wine32on64`, and `publish-release` jobs.
  - Added the Determinate Systems magic Nix cache action to the runtime workflow
    jobs so repeated Actions runs can reuse cached Nix work where available.
  - Made the build job upload the assembled `dist/` runtime artifacts, then made
    smoke and publish jobs download those artifacts instead of depending on the
    mutable local `result` out-link.
  - Pushed submodule commit `95fa51a`, starting push run `27116433190`.
  - Submitted a cancellation request for obsolete push run `27116103755`.
  - Investigated failed GitHub Actions run `27116433190`: `Verify
    Wine32-on-64 launch smoke` failed on the clean runner with
    `wine: could not load kernel32.dll, status c0000135`.
  - Confirmed the cause was the Wine runtime artifact retaining `/nix/store`
    dylib references in Mach-O files such as `bin/wine`, `ntdll.so`, and
    `winegstreamer.so`. Local smoke runs were masked by this machine's local
    Nix store, but the extracted CI artifact did not contain those store paths.
  - Updated the runtime submodule build to copy the needed Nix dylib closure
    into `$out/lib`, rewrite Mach-O load commands to runtime-relative
    `@loader_path` or `@rpath`, and fail the build if packaged Wine files still
    reference `/nix/store/*.dylib`.
  - Updated the runtime payload checker to reject unpackaged Nix dylib
    references under `bin` and `lib`.
  - Built the Wine runtime locally, checked representative `otool -L` output,
    and ran the Wine32-on-64 launch smoke with the Wine runtime tarball plus the
    FreeType component overlay.
  - Pushed submodule commit `6dc7bb6`, starting push run `27125217605`.
  - Investigated failed GitHub Actions run `27125217605`: Wine runtime build,
    runtime payload check, artifact packaging, and DXMT build passed, then the
    assembled launch smoke failed again with
    `wine: could not load kernel32.dll, status c0000135`.
  - Downloaded Actions artifact `7476762619` and confirmed the Wine runtime
    archive itself contained the required `kernel32.dll` files and passed
    `check-wine32on64-runtime.zsh`.
  - Reproduced the real failure surface by overlaying all component archives:
    `lib/libgstreamer-1.0.0.dylib` and
    `lib/dxmt/x86_64-unix/winemetal.so` still referenced unpackaged
    `/nix/store/*.dylib` dependencies.
  - Updated GStreamer component packaging to copy and rewrite its Nix dylib
    closure instead of copying only `libgstreamer-1.0.0.dylib`.
  - Added a component packaging guard that rejects Mach-O files with
    unpackaged `/nix/store/*.dylib` references before creating component
    archives.
  - Updated the DXMT derivation to copy `winemetal.so`'s Nix dylib closure into
    `x86_64-unix`, rewrite references to `@loader_path`, and fail if any
    unpackaged Nix dylib references remain.
  - Updated the runtime workflow smoke job to run
    `check-wine32on64-runtime.zsh` after overlaying component archives, before
    launching the Wine32-on-64 smoke.
  - Pushed submodule commit `b7a3e8b`, starting push run `27131441556`.
  - Cancelled Actions run `27131441556` after noticing the workflow still kept
    Wine runtime build, DXMT build, binary component packaging, metadata, and
    artifact upload inside one `build-and-package` job. That previous split was
    insufficient because a DXMT or component packaging failure still forced a
    successful Wine runtime build to be rerun.
  - Reworked the runtime workflow into narrower jobs:
    `build-wine-runtime`, `build-dxmt-component`, `package-binary-components`,
    `generate-release-metadata`, `smoke-wine32on64`, and `publish-release`.
  - Added the rerun-unit rule to `AGENTS.md`: runtime Actions must not combine
    expensive Wine builds, DXMT builds, binary component packaging, metadata,
    smoke, and publish work into one monolithic job.
  - Updated the DXMT package path to accept `KONYAK_WINE_RUNTIME_ROOT`, allowing
    CI to build DXMT against an already extracted Wine runtime artifact instead
    of depending on the CrossOver Wine derivation.
  - Updated `build-dxmt-component` to download `konyak-macos-wine-runtime`,
    extract it into `$RUNNER_TEMP`, validate it with
    `check-wine32on64-runtime.zsh`, and pass that path to Nix via
    `KONYAK_WINE_RUNTIME_ROOT`.
  - Made uploaded runtime artifacts explicit rerun inputs by setting
    `if-no-files-found: error` and `retention-days: 14` on Wine, DXMT, binary
    component, and release metadata artifact uploads.
  - Tightened `AGENTS.md` so downstream runtime jobs must download and use the
    uploaded Wine runtime artifact instead of depending on the CrossOver Wine
    derivation in a way that can rebuild CrossOver during a rerun.
  - Investigated failed GitHub Actions run `27135965212`: `build-wine-runtime`,
    `build-dxmt-component`, `package-binary-components`, and
    `generate-release-metadata` succeeded and retained artifacts, but
    `smoke-wine32on64` failed on `macos-15-intel` after the assembled runtime
    layout check passed. The failing launch timed out with
    `wine: could not load kernel32.dll, status c0000135`.
  - Downloaded the `27135965212` runtime artifacts and confirmed the same
    artifact stack passed `check-wine32on64-runtime.zsh` and
    `smoke-wine32on64-launch.zsh` locally under both `/tmp` and
    `/Users/masato/work/_temp`, so the artifact set itself is not missing the
    required Wine32-on-64 files.
  - Added `scripts/assemble-runtime-stack.zsh` so CI and local smoke tests
    assemble the Wine runtime, DXMT, DXVK-macOS, MoltenVK, GStreamer, FreeType,
    wine-mono, and winetricks archives through one shared path.
  - Updated `build-runtime.yml` smoke to assemble under `/tmp` and call the
    shared runtime stack assembly script before layout and launch checks.
  - Added `smoke-runtime-artifacts.yml`, a `workflow_dispatch` smoke-only
    workflow that accepts an `artifact_run_id` and downloads retained artifacts
    from a previous run. Use this for smoke/debug reruns so CrossOver Wine does
    not rebuild when the build artifact already exists.
  - Tightened the runtime layout check to require both i386 and x86_64
    `kernel32.dll` and `cmd.exe` payloads.
  - Updated the launch smoke to initialize the fresh prefix through the x86_64
    `cmd.exe`, wait for wineserver, then run the i386 `cmd.exe` sentinel. It now
    prints targeted runtime diagnostics if `kernel32.dll` resolution fails again.
  - Pushed submodule commit `740dc6a`, starting `Build runtime` run
    `27141947475`.
  - Triggered smoke-only artifact run `27141987789` against retained artifacts
    from failed run `27135965212` to verify the downstream path without rebuilding
    CrossOver.
  - Smoke-only artifact run `27141987789` reproduced the CI-only problem without
    rebuilding CrossOver: all artifacts downloaded and layout verification
    passed, but the Intel `macos-15-intel` runner hung during fresh Wine prefix
    initialization for 300 seconds. Diagnostics confirmed both i386 and x86_64
    `kernel32.dll`, `ntdll.dll`, and `cmd.exe` files were present with the
    expected PE formats.
  - Cancelled full build run `27141947475` after the smoke-only reproduction,
    because the same smoke path would fail and there was no value in continuing a
    known-bad run.
  - Moved Wine32-on-64 launch smoke jobs to the `macos-15` arm64 runner and added
    explicit Rosetta installation. The expensive Wine, DXMT, and component build
    jobs remain on `macos-15-intel`; only the launch smoke now runs on the primary
    arm64 macOS target with the downloaded x86_64 runtime artifacts.
  - Pushed submodule commit `a9dece7`, starting full `Build runtime` run
    `27142828121`.
  - Triggered smoke-only artifact run `27142850162` against retained artifacts
    from failed run `27135965212`; it passed in 4m1s without rebuilding CrossOver.
  - Investigated failed full `Build runtime` run `27142828121`: Wine runtime
    build, DXMT build, binary component packaging, release metadata generation,
    and arm64 Wine32-on-64 smoke passed; only `publish-release` failed because
    the job intentionally had no checkout, so `gh release` had no repository
    context.
  - Updated runtime release publishing to pass `--repo "$GITHUB_REPOSITORY"` to
    every `gh release` command, keeping the no-checkout publish job while
    removing its dependency on a local Git worktree.
  - Pushed submodule commit `e00e1da`, starting full `Build runtime` run
    `27144374021`; the full workflow passed, including publish, in about 21
    minutes.
- Remaining:
  - Update the development runtime if needed from the newly published runtime
    release.
  - Track GitHub's Node.js 20 action deprecation warnings separately; they are
    annotations only and did not fail the runtime workflow.
- Next action: consume the newly published runtime in the development
  environment if another local verification pass is required.
- Verification performed:
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml .github/workflows/smoke-runtime-artifacts.yml'`:
    passed after the publish `--repo` fix.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/assemble-runtime-stack.zsh scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed after the publish `--repo` fix.
  - GitHub Actions full `Build runtime` run `27144374021`: passed; Wine runtime
    build, DXMT build, binary component packaging, release metadata generation,
    arm64 Wine32-on-64 smoke, and publish all completed successfully.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml .github/workflows/smoke-runtime-artifacts.yml'`:
    passed after moving smoke jobs to arm64 macOS runners.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/assemble-runtime-stack.zsh scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed after moving smoke jobs to arm64 macOS runners.
  - GitHub Actions smoke-only artifact run `27142850162`: passed; it downloaded
    retained artifacts from run `27135965212`, installed Rosetta on the arm64
    macOS runner, assembled the runtime stack, and passed Wine32-on-64 launch
    smoke without rebuilding CrossOver.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/assemble-runtime-stack.zsh scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed after adding the shared artifact assembly script and smoke
    diagnostics.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml .github/workflows/smoke-runtime-artifacts.yml'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && set -euo pipefail; smoke_root=/tmp/konyak-wine32on64-smoke-runtime-script; ./scripts/assemble-runtime-stack.zsh /tmp/konyak-runtime-artifact-27135965212/dist "$smoke_root"; ./scripts/check-wine32on64-runtime.zsh "$smoke_root"; ./scripts/smoke-wine32on64-launch.zsh "$smoke_root"'`:
    passed with the downloaded artifacts from failed Actions run `27135965212`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check -L --show-trace --all-systems'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT=/tmp/konyak-runtime-artifact-27125217605/runtime nix build --impure --dry-run .#packages.x86_64-darwin.konyak-macos-dxmt 2>&1 | tee /tmp/konyak-dxmt-artifact-root-dry-run.log && if rg "konyak-macos-wine-runtime" /tmp/konyak-dxmt-artifact-root-dry-run.log; then echo "DXMT dry-run still wants to build the Wine runtime" >&2; exit 1; fi'`:
    passed; with a Wine runtime artifact root supplied, the dry-run listed only
    the DXMT derivation and did not list `konyak-macos-wine-runtime`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml'`:
    passed after adding artifact extraction and retention settings.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed after adding the Wine artifact root override.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check -L --show-trace --all-systems'`:
    passed after adding `KONYAK_WINE_RUNTIME_ROOT` support.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml'`:
    passed for the narrowed runtime workflow jobs.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed after the workflow split.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed for the component closure fix.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml'`:
    passed for the overlay-after-check workflow change.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build --dry-run .#packages.x86_64-darwin.konyak-macos-dxmt'`:
    passed; this verified DXMT derivation evaluation without requiring the
    local machine to have the GitHub runner's Metal toolchain.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check -L --show-trace'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check -L --show-trace --all-systems'`:
    passed.
  - Local GStreamer component-only package test: passed; the generated
    `konyak-macos-gstreamer.tar.zst` included the GStreamer dylib closure and
    had no unpackaged `/nix/store/*.dylib` references.
  - Local DXMT closure rewrite reproduction using the failed Actions artifact:
    passed; `winemetal.so` and copied dylibs had no unpackaged
    `/nix/store/*.dylib` references after applying the same rewrite logic.
  - Assembled runtime smoke using the failed Actions artifact plus fixed
    GStreamer and DXMT payloads: passed; `check-wine32on64-runtime.zsh` passed
    after all overlays, then `scripts/smoke-wine32on64-launch.zsh` launched the
    runtime's 32-bit `cmd.exe` through Wine32-on-64.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --show-trace --out-link result-wine-runtime'`:
    passed; produced
    `/nix/store/bw07d68rqzq9q0ryw79hwwjnf1yzfc2r-konyak-macos-wine-runtime-crossover-26.1.0-konyak.0`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-wine32on64-runtime.zsh result-wine-runtime'`:
    passed.
  - Representative `otool -L` checks for `bin/wine`,
    `lib/wine/x86_64-unix/ntdll.so`,
    `lib/wine/x86_64-unix/winegstreamer.so`, and
    `lib/libgstreamer-1.0.0.dylib`: passed; no `/nix/store/*.dylib`
    references remained.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && runtime_out="$(nix build --no-link --print-out-paths .#packages.x86_64-darwin.konyak-macos-wine-runtime)" && ./scripts/check-wine32on64-runtime.zsh "$runtime_out"'`:
    passed.
  - Temporary local smoke assembly with Wine runtime tarball plus the FreeType
    component overlay: passed; `scripts/smoke-wine32on64-launch.zsh` launched
    the runtime's 32-bit `cmd.exe` through Wine32-on-64.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --no-link'`:
    passed; verified output
    `/nix/store/4gx8261mak5j6kpa9s4agv2qfhyh19fa-konyak-macos-wine-runtime-crossover-26.1.0-konyak.0`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && runtime_root="$(nix path-info .#packages.x86_64-darwin.konyak-macos-wine-runtime)" && ./scripts/check-wine32on64-runtime.zsh "$runtime_root" && zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed.
  - Runtime smoke with FreeType + wine-mono components overlaid on the built
    x86_64 runtime: passed.
  - Runtime smoke with DXVK-macOS, MoltenVK, GStreamer, FreeType, wine-mono,
    and winetricks components overlaid on the built x86_64 runtime: passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check -L --show-trace'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check -L --show-trace --all-systems'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed for the workflow out-link fix.
  - Local workflow assembly check using `result-wine-runtime` passed:
    `check-wine32on64-runtime.zsh result-wine-runtime` succeeded, and copying
    `result-wine-runtime` into a smoke runtime root preserved `bin/wine` and
    `bin/wineserver` even with a separate `result-dxmt` out-link present.
  - Local DXMT build was not used as verification for this workflow-only fix
    because this machine lacks the `metal` tool. The failed Actions run already
    showed DXMT builds on the GitHub macOS runner after its Metal toolchain
    setup step.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-wine32on64-launch.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh && git diff --check'`:
    passed for the split workflow change.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml'`:
    passed.
  - Local workflow artifact smoke path check passed: the Wine runtime archive was
    extracted into a fresh smoke root, packaged binary component archives were
    overlaid, and `scripts/smoke-wine32on64-launch.zsh` launched the runtime's
    32-bit `cmd.exe` through Wine32-on-64. The local DXMT archive was represented
    by a placeholder because this machine lacks the `metal` tool; GitHub Actions
    still builds the real DXMT component after installing the Metal toolchain.

## Completed Milestones

- 2026-06-07: Bara-style progress handoff discipline was added through
  `docs/progress.md` and `AGENTS.md`, so active work and continuation state can
  be recovered without chat history.
- 2026-06-07: FreeType was added to the macOS runtime stack contract in the
  parent repository and packaged as a separate component in the
  `runtime/konyak-macos-runtime` submodule. The parent repository consumes the
  submodule-produced runtime stack as the source of truth instead of adding
  runtime dependencies to the parent Nix flake.
