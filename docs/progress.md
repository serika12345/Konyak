# Progress

This file records Konyak's current active work and completed state so the
project can be resumed without relying on chat history.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot, completed milestone summaries, and
handoff notes.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-06-23 21:01 JST
- State: `completed`
- Branch: `main`
- Related work: Linux file-manager wording
- Purpose: replace Linux-visible `Show in Finder` UI text with generic
  file-manager wording while keeping macOS Finder wording intact.
- Completed:
  - Added platform-owned location UI wording so macOS shows
    `Show in Finder` and Linux shows `Show in File Manager`.
  - Routed the platform through bottle context menus, pinned-program context
    menus, and pinned-program configuration bottom bars.
  - Added widget coverage for Linux bottle menu, pinned-program menu, and
    pinned-program configuration button wording.
- Remaining:
  - None.
- Next: commit the Linux file-manager wording change if desired.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux bottle context menu uses file manager wording"'`:
    failed before implementation because Linux still displayed
    `Show in Finder`, then passed after the platform label wiring.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "pinned program context menu runs and opens the program folder"'`:
    passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "pinned program context menu opens and saves program config"'`:
    passed after implementation.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-23 20:35 JST
- State: `completed`
- Branch: `main`
- Related work: Linux About dialog layout fix
- Purpose: fix the Linux About dialog so `MIT License` is shown in the normal
  body flow after the remaining runtime-license note.
- Completed:
  - Replaced the default `showAboutDialog` layout with a Konyak-owned
    `AlertDialog` body that keeps the icon/title header, runtime-license note,
    and `MIT License` in a stable vertical order.
  - Removed stale `Linux preview` and product-description expectations from
    the About dialog widget test after the dialog copy was trimmed.
  - Kept the `View licenses` action by dispatching to Flutter's license page.
  - Added widget coverage asserting the license line appears after the
    runtime-license note.
- Remaining:
  - None.
- Next: visually confirm the About dialog in the running Linux app if desired.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux screen menu exposes the about dialog"'`:
    failed before implementation because `MIT License` was positioned above
    the runtime-license note, then passed after the custom dialog layout.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-23 18:18 JST
- State: `completed`
- Branch: `main`
- Related work: Linux visible pinned program launchers
- Purpose: make pinned Windows programs appear in the Linux desktop
  environment launcher, matching the macOS pinned `.app` behavior while
  preserving Konyak's public CLI execution path as the source of truth.
- Completed:
  - Added Linux pinned-program launcher synchronization for `pin-program`,
    `unpin-program`, `rename-pinned-program`, and `list-bottles --json`.
  - Generated visible user-level `.desktop` files under
    `$XDG_DATA_HOME/applications/app.konyak.Konyak.pinned.<id>.desktop`, with
    launcher manifests and wrapper scripts under
    `$XDG_DATA_HOME/konyak/launchers/linux-pinned/<id>/`.
  - Kept generated Linux pinned launchers on
    `launch-pinned-program --manifest <manifest> --json` instead of direct
    Wine execution.
  - Added AppImage `AppRun --konyak-cli` dispatch and made Linux pinned
    launchers prefer the stable `KONYAK_APPIMAGE_PATH` entry point over
    transient bundled CLI mount paths.
  - Added CLI contract coverage for Linux launcher creation, AppImage dispatch
    preference, `list-bottles` refresh, rename updates, and unpin cleanup.
  - Added a maintained Linux pinned launcher smoke and wired it into `just
    verify`, the Linux release check, and the release workflow.
- Remaining:
  - None for Linux visible pinned program launcher generation and AppImage
    dispatch.
- Next: manually pin a real Windows program from the AppImage build on a target
  desktop environment when validating end-user launcher indexing behavior.
- Verification:
  - Sub-agent read-only audit confirmed the macOS/Linux launcher code points
    and identified the AppImage transient mount risk before finalizing the
    AppImage dispatch design.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "pin-program --json on Linux writes an app launcher entry"'`:
    failed before implementation because no visible Linux launcher was
    generated, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "pin-program --json on Linux prefers stable AppImage launcher dispatch"'`:
    failed before changing Linux command resolution because the generated
    wrapper embedded a transient bundled CLI path, then passed after preferring
    `KONYAK_APPIMAGE_PATH --konyak-cli`.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "Linux"'`:
    passed.
  - `nix develop -c zsh -lc './scripts/smoke_linux_pinned_launcher_integration.zsh'`:
    passed.
  - `nix develop -c zsh -lc './scripts/smoke_linux_appimage_apprun_env.zsh'`:
    failed against the previously built AppDir because it predated the new
    `AppRun --konyak-cli` dispatch; this was expected before rebuilding.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.
  - `nix develop -c zsh -lc 'just linux-release-check'`: passed. It rebuilt
    the Linux AppImage, reran release metadata, AppRun runtime/CLI dispatch,
    desktop integration, pinned launcher integration, bundled manifest
    signature, and runtime install smokes.
  - `nix develop -c zsh -lc 'just verify'`: passed, including governance,
    architecture, format, lint, safety, Flutter tests, CLI tests, Linux loader
    check, desktop integration smoke, and pinned launcher smoke.

- Timestamp: 2026-06-23 13:04 JST
- State: `completed`
- Branch: `main`
- Related work: Linux AppImage desktop integration
- Purpose: make Konyak own the Linux AppImage desktop integration path so
  users only need to launch the AppImage, after which Konyak re-syncs the
  launcher entry, application icon, and Windows executable MIME defaults.
- Completed:
  - Extended the Linux startup CLI integration command to copy the Konyak icon
    into the user hicolor icon theme, update the user-level desktop entry, and
    refresh desktop/icon caches when the host tools are available.
  - Preserved AppImage relocation behavior by preferring
    `KONYAK_APPIMAGE_PATH` for the registered desktop entry `Exec=` path, and
    added a maintained isolated XDG smoke that registers one AppImage path,
    re-registers a moved path, and asserts the desktop entry updates.
  - Added `KONYAK_APP_ICON_PATH` propagation from AppRun through Flutter to the
    CLI, and changed the AppDir desktop entry to `Exec=AppRun %f` so file
    arguments are preserved when desktop environments consume the embedded
    entry.
  - Quoted Linux-generated external program launcher executables so runtime
    paths with spaces do not break generated `.desktop` launchers.
  - Wired `scripts/smoke_linux_desktop_integration.zsh` into `just verify`,
    `just linux-release-check`, and the Linux release workflow.
  - Updated release/TODO documentation and governance checks for the new
    Linux desktop integration smoke coverage.
- Remaining:
  - Nautilus still will not reliably show the AppImage file itself with the
    embedded icon unless a desktop integration/thumbnailer tool is present;
    this change covers launcher registration, Konyak app icon resolution, and
    `.exe` default handling after Konyak is launched.
- Next: place the AppImage at the desired user location, launch it once, then
  `.exe` opening and the app launcher should use that path until the AppImage
  is moved and launched again.
- Verification:
  - Sub-agent audit checked the Linux AppImage desktop integration path and
    identified the embedded desktop `Exec=AppRun` argument gap and launcher
    quoting risk.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "install-linux-file-associations --json writes XDG MIME associations"'`:
    failed before implementation because no icon was copied, then passed after
    the integration changes.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-program --json on Linux writes a desktop launcher for external executables"'`:
    failed before implementation because the generated Wine executable path was
    unquoted, then passed after quoting it.
  - `nix develop -c zsh -lc './scripts/smoke_linux_desktop_integration.zsh'`:
    passed and verified desktop entry, icon, `mimeapps.list`, `xdg-mime`, and
    relocation re-sync behavior in an isolated XDG home.
  - `nix develop -c zsh -lc 'just linux-release-check'`: passed. It rebuilt
    the AppImage, verified release metadata, AppRun environment and argument
    forwarding, desktop integration, bundled runtime manifest signature, and
    Linux runtime install through the public CLI smoke.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check && just flutter-analyze && just flutter-test'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed after replacing a
    collection-if JSON payload field with a helper.

- Timestamp: 2026-06-23 00:38 JST
- State: `completed`
- Branch: `main`
- Related work: Linux AppImage build convenience
- Purpose: make local Linux release build and runtime install verification easy
  from both VSCode tasks and one `just` target while preserving the default
  remote runtime release contract.
- Completed:
  - Added `scripts/run_linux_release_check.zsh` as the high-level local Linux
    check entry point for AppImage build, release metadata smoke, AppRun
    runtime environment smoke, bundled runtime manifest signature verification,
    and public CLI runtime install smoke.
  - Added `just linux-release-check`.
  - Added VSCode tasks for building the Linux AppImage, smoking Linux runtime
    install, and running the combined AppImage build plus runtime install
    smoke.
  - Documented the VSCode and command-line Linux release check paths.
  - Kept CI coverage split across the existing release workflow and Linux
    Runtime CLI Smoke workflow, and made Linux runtime smoke trigger on changes
    to the new local release-check wrapper.
- Remaining:
  - None for the local Linux build convenience entry points.
- Next: use `Tasks: Run Task -> Konyak: Build Linux AppImage + Runtime Install
  Smoke` or `nix develop -c zsh -lc 'just linux-release-check'` for the full
  local Linux package/runtime check.
- Verification:
  - `nix develop -c zsh -lc 'jq empty .vscode/tasks.json && zsh -n scripts/run_linux_release_check.zsh && git diff --check'`:
    passed.
  - `nix develop -c zsh -lc 'just --list | sed -n "1,140p"'`: passed and
    showed `linux-release-check`.
  - `nix develop -c zsh -lc 'just linux-release-check'`: passed. It built the
    Linux AppImage from the default runtime release, ran release metadata and
    AppRun environment smokes, verified the bundled runtime source manifest
    signature, and completed the public CLI Linux runtime install smoke.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-22 23:01 JST
- State: `completed`
- Branch: `main`
- Related work: Linux runtime submodule and remote install
- Purpose: create the minimal Linux runtime submodule, publish the default
  remote runtime manifest/assets, and prove Konyak can install from the default
  remote locator without an explicit local manifest override.
- Completed:
  - Created `serika12345/konyak-linux-runtime` and added it as
    `runtime/konyak-linux-runtime`.
  - Added minimal submodule release tooling that stages a complete Linux
    runtime source manifest, rewrites local component archive paths to GitHub
    Release asset URLs, validates checksums, and signs the staged manifest.
  - Pushed submodule commit `7e6dd4f Add initial Linux runtime release
    tooling`.
  - Published
    `https://github.com/serika12345/konyak-linux-runtime/releases/tag/linux-wine-runtime-stack-0.1.0`
    with the default manifest, signature, public key, and `winetricks`,
    `wine-mono`, `dxvk`, and `vkd3d-proton` component archives.
  - Confirmed the parent default resolver downloads the remote manifest when
    local development manifest overrides are unset.
  - Confirmed `scripts/run_linux_runtime_cli_smoke.zsh` installs and validates
    the runtime from the default remote locator when local development manifest
    overrides are unset.
  - Confirmed `nix run .#linux-release` downloads the default remote manifest,
    signature, and public key, then bundles them into the AppImage release
    output.
  - Updated the Linux runtime CLI smoke workflow so normal PR/push runs use the
    default remote locator when no override input or repository variable is
    supplied.
  - Fixed the Linux runtime CLI smoke script so an unmaterialized default
    development manifest path from the Nix dev shell falls back to resolving
    the default remote source manifest. This matches GitHub Actions' clean
    workspace behavior while still failing explicit missing manifest paths.
- Remaining:
  - The initial Linux runtime submodule is deliberately minimal. It stages and
    republishes a proven manifest/component set, but does not yet build all
    Linux components from pinned source recipes in submodule CI.
  - The Wine archive remains referenced from the upstream Kron4ek release
    rather than mirrored into the Konyak Linux runtime release.
- Next: add submodule-side Linux component build/check workflows before the
  next runtime version bump.
- Verification:
  - `nix develop -c zsh -lc 'cd runtime/konyak-linux-runtime && zsh -n scripts/stage-release.zsh && openssl dgst -sha256 -verify releases/linux-wine-runtime-stack-0.1.0/konyak-runtime-stack-public-key.pem -signature releases/linux-wine-runtime-stack-0.1.0/konyak-linux-wine-runtime-stack-source.json.sig releases/linux-wine-runtime-stack-0.1.0/konyak-linux-wine-runtime-stack-source.json && git diff --cached --check'`:
    passed before the submodule commit.
  - `nix develop -c zsh -lc 'unset KONYAK_DEV_LINUX_WINE_STACK_MANIFEST KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST KONYAK_LINUX_WINE_STACK_MANIFEST KONYAK_RUNTIME_STACK_SOURCE_MANIFEST; rm -rf .dart_tool/konyak/remote-linux-runtime-proof; KONYAK_DEV_LINUX_WINE_STACK_MANIFEST_CACHE="$PWD/.dart_tool/konyak/remote-linux-runtime-proof/konyak-linux-wine-runtime-stack-source.json" ./scripts/prepare_linux_dev_runtime_source.zsh --force --print-manifest-path && jq -r ".components[].archiveUrl" .dart_tool/konyak/remote-linux-runtime-proof/konyak-linux-wine-runtime-stack-source.json'`:
    passed and showed the default GitHub Release component URLs.
  - `nix develop -c zsh -lc 'unset KONYAK_DEV_LINUX_WINE_STACK_MANIFEST KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST KONYAK_LINUX_WINE_STACK_MANIFEST KONYAK_RUNTIME_STACK_SOURCE_MANIFEST KONYAK_LINUX_WINE_HOME; KONYAK_LINUX_RUNTIME_CLI_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/linux-runtime-cli-smoke-remote" ./scripts/run_linux_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'unset KONYAK_DEV_LINUX_WINE_STACK_MANIFEST KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST KONYAK_LINUX_WINE_STACK_MANIFEST KONYAK_RUNTIME_STACK_SOURCE_MANIFEST KONYAK_RUNTIME_STACK_SOURCE_SIGNATURE KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH KONYAK_LINUX_WINE_HOME; nix run .#linux-release'`:
    passed and produced
    `.dart_tool/konyak/release/linux/Konyak-1.0.0-linux-x86_64.AppImage`.
  - `nix develop -c zsh -lc './scripts/smoke_linux_release_metadata.zsh && ./scripts/smoke_linux_appimage_apprun_env.zsh && openssl dgst -sha256 -verify .dart_tool/konyak/release/linux/konyak-runtime-stack-public-key.pem -signature .dart_tool/konyak/release/linux/konyak-linux-wine-runtime-stack-source.json.sig .dart_tool/konyak/release/linux/konyak-linux-wine-runtime-stack-source.json'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - First GitHub Actions run
    `https://github.com/serika12345/Konyak/actions/runs/27958353880` reached
    the new Linux Runtime CLI Smoke job and failed because the dev-shell
    default `KONYAK_DEV_LINUX_WINE_STACK_MANIFEST` path was not materialized in
    the clean CI workspace.
  - `nix develop -c zsh -lc 'rm -rf .dart_tool/konyak/dev-runtime-source/linux-wine-stack .dart_tool/konyak/linux-runtime-cli-smoke-ci-proof; KONYAK_DEV_LINUX_WINE_STACK_MANIFEST="$PWD/.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json" KONYAK_LINUX_RUNTIME_CLI_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/linux-runtime-cli-smoke-ci-proof" ./scripts/run_linux_runtime_cli_smoke.zsh'`:
    passed after the smoke script fallback fix.
  - `nix develop -c zsh -lc 'zsh -n scripts/run_linux_runtime_cli_smoke.zsh && git diff --check'`:
    passed.

- Timestamp: 2026-06-22 20:46 JST
- State: `completed`
- Branch: `main`
- Related work: Linux runtime CLI smoke real-run proof
- Purpose: prove the Linux runtime installation and release packaging paths
  with a real complete source manifest instead of fake packaging fixtures.
- Completed:
  - Located the local complete Linux source manifest at
    `.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json`.
  - Confirmed the manifest includes `wine`, `winetricks`, `wine-mono`, `dxvk`,
    and `vkd3d-proton`; local component archive checksums match the manifest.
  - Ran `scripts/run_linux_runtime_cli_smoke.zsh` with install enabled through
    the public CLI path. The smoke installed the runtime, verified
    `list-runtimes`, `validate-runtime`, prefix creation, Winetricks verb
    listing, and `run-winetricks ci-prefix-smoke --verb win10 --json`.
  - Built the Linux AppImage through `nix run .#linux-release` using the same
    manifest as `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST`.
  - Confirmed the produced release metadata references
    `konyak-linux-wine-runtime-stack-source.json`, and the Linux release
    metadata/AppRun environment smokes pass.
- Remaining:
  - The repository default release locator in `runtime/linux-wine-release.json`
    still points at a GitHub release asset that has not been published yet, so
    default release builds without an explicit manifest still require the
    Linux runtime packaging owner to publish the default manifest/signature/key.
- Next: publish the complete Linux runtime source manifest and optional
  signature/public key to the default Linux runtime release, then rerun the
  same commands without `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST`.
- Verification:
  - `nix develop -c zsh -lc 'sha256sum .dart_tool/konyak/dev-runtime-source/linux-wine-stack/components/*.tar.xz'`:
    passed for the local `winetricks`, `wine-mono`, `dxvk`, and
    `vkd3d-proton` component archives referenced by the manifest.
  - `nix develop -c zsh -lc 'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST="$PWD/.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json" KONYAK_LINUX_RUNTIME_CLI_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/linux-runtime-cli-smoke-real" ./scripts/run_linux_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'KONYAK_RUNTIME_STACK_SOURCE_MANIFEST="$PWD/.dart_tool/konyak/dev-runtime-source/linux-wine-stack/konyak-linux-wine-runtime-stack-source.json" nix run .#linux-release'`:
    passed and produced
    `.dart_tool/konyak/release/linux/Konyak-1.0.0-linux-x86_64.AppImage`.
  - `nix develop -c zsh -lc './scripts/smoke_linux_release_metadata.zsh && ./scripts/smoke_linux_appimage_apprun_env.zsh'`:
    passed.

- Timestamp: 2026-06-22 20:38 JST
- State: `completed`
- Branch: `main`
- Related work: Linux runtime CLI smoke parity
- Purpose: add a maintained Linux public-CLI runtime smoke path that consumes a
  complete runtime-owner-produced source manifest, matching the macOS runtime
  CLI smoke boundary without building Linux runtime payloads in the parent
  repository.
- Completed:
  - Committed the Linux runtime manifest release path work as
    `d2cc7c4 Align Linux runtime manifest release path`.
  - Read the macOS runtime CLI smoke and existing Linux runtime CLI contracts.
  - Added `scripts/run_linux_runtime_cli_smoke.zsh` as the maintained Linux
    runtime CLI smoke entry point.
  - Added `.github/workflows/linux-runtime-cli-smoke.yml`, gated so it runs
    when a complete Linux runtime source manifest is supplied by workflow input
    or repository variable.
  - Added a `linux-runtime-cli-smoke` just target.
  - Extended runtime validation so `validate-runtime konyak-linux-wine --json`
    probes Linux Wine with Linux runtime environment instead of using the macOS
    loader assumptions.
  - Added CLI contract coverage for Linux runtime validation.
  - Updated AGENTS, governance, CLI distribution docs, and TODO state for the
    maintained Linux runtime smoke path.
- Remaining:
  - The full install path still needs a real complete Linux runtime stack
    source manifest. The local smoke script was dynamically checked with a fake
    installed runtime root and `KONYAK_LINUX_RUNTIME_CLI_SMOKE_INSTALL=false`.
- Next: supply or publish the complete Linux runtime stack source manifest and
  run `scripts/run_linux_runtime_cli_smoke.zsh` with install enabled.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "Linux runtime validator checks the Wine loader with Linux env"'`:
    failed before implementation because the validator did not accept Linux
    environment input, then passed.
  - `nix develop -c zsh -lc 'KONYAK_LINUX_RUNTIME_CLI_SMOKE_INSTALL=false KONYAK_LINUX_RUNTIME_CLI_SMOKE_WINETRICKS=false KONYAK_LINUX_WINE_HOME=<fake runtime> KONYAK_DEV_LINUX_WINE_STACK_MANIFEST=<fake manifest> ./scripts/run_linux_runtime_cli_smoke.zsh'`:
    first failed because the fake runtime omitted `bin/wineboot`, then passed
    after the fake runtime was completed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'zsh -n scripts/run_linux_runtime_cli_smoke.zsh && git diff --check'`:
    passed.

- Timestamp: 2026-06-22 19:55 JST
- State: `completed`
- Branch: `main`
- Related work: Linux runtime source-manifest SSOT and release smoke parity
- Purpose: align Linux development builds, AppImage release builds, runtime
  installation, and CI around one complete Linux runtime stack source manifest
  contract while keeping parent-repository runtime payload generation out of
  scope.
- Completed:
  - Stashed the previous Linux executable thumbnailer WIP as
    `stash@{0}: On main: linux-exe-thumbnailer-wip`.
  - Investigated the AppImage runtime install path and confirmed the Settings
    action reaches `install-linux-wine --json`, which fails when neither a
    Linux source manifest nor archive URL is configured.
  - Split the next work into source-manifest resolver, AppImage bundling/AppRun
    export, publish workflow artifact coverage, CI smoke planning, and audit
    workstreams.
  - Added `runtime/linux-wine-release.json` as the parent-repository Linux
    runtime release locator.
  - Added a shared Linux source-manifest resolver used by both development
    runtime preparation and AppImage release builds.
  - Changed Linux AppImage release builds to resolve, validate, publish, and
    bundle the Linux runtime stack source manifest before packaging.
  - Changed AppRun to export `KONYAK_LINUX_WINE_STACK_MANIFEST`,
    `KONYAK_LINUX_WINE_STACK_SIGNATURE_URL`,
    `KONYAK_RUNTIME_STACK_PUBLIC_KEY_PATH`, and
    `KONYAK_LINUX_WINE_STACK_PUBLIC_KEY_PATH` when the corresponding bundled
    resources exist.
  - Added Linux release metadata and AppRun environment smoke scripts, and
    wired both into the Linux release workflow.
  - Updated governance checks, release/runtime docs, VSCode Linux notes, and
    TODO state for the new Linux manifest contract.
- Remaining:
  - A real complete signed Linux runtime stack source manifest still needs to
    be published by the Linux runtime packaging owner. Until that exists, local
    release builds should pass `KONYAK_RUNTIME_STACK_SOURCE_MANIFEST` to an
    explicit complete manifest or the default release locator will fail early.
- Next: publish or supply the complete Linux runtime stack source manifest, then
  run the same release build without the fake manifest/tool overrides.
- Verification:
  - `nix develop -c zsh -lc 'zsh -n scripts/resolve_linux_runtime_source_manifest.zsh scripts/prepare_linux_dev_runtime_source.zsh scripts/build_linux_release.zsh scripts/smoke_linux_appimage_apprun_env.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'KONYAK_RUNTIME_STACK_SOURCE_MANIFEST=<fake complete manifest> KONYAK_APPIMAGETOOL_PATH=<fake appimagetool> ./scripts/build_linux_release.zsh'`:
    passed and generated Linux release metadata/AppDir/AppRun with the resolved
    source manifest bundled.
  - `nix develop -c zsh -lc './scripts/smoke_linux_release_metadata.zsh && ./scripts/smoke_linux_appimage_apprun_env.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'KONYAK_DEV_LINUX_WINE_STACK_SOURCE_MANIFEST=<fake complete manifest> KONYAK_DEV_LINUX_WINE_STACK_MANIFEST_CACHE=<temp cache> ./scripts/prepare_linux_dev_runtime_source.zsh --print-manifest-path'`:
    passed and cached the manifest.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - First `nix develop -c zsh -lc 'just verify-governance'`: failed because
    governance still expected the Linux development manifest env and
    no-parent-generation message in `scripts/prepare_linux_dev_runtime_source.zsh`;
    the script comments were updated to keep that contract visible.
  - Final `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-22 00:29 JST
- State: `completed`
- Branch: `main`
- Related work: Linux Mesa pci-id log suppression follow-up
- Purpose: suppress the remaining bare Mesa `pci id for fd ... driver (null)`
  diagnostics that still appeared after adding EGL-specific log suppression.
- Completed:
  - Confirmed the remaining `pci id for fd ...` lines are still Mesa-family
    diagnostics and are separate from Wine's `wineboot:process_run_key` output.
  - Added failing CLI contract expectations requiring Linux Wine requests and
    Linux Terminal-backed `cmd` launches to export `MESA_LOG_LEVEL=fatal`.
  - Added `MESA_LOG_LEVEL=fatal` to the shared Linux Wine log-suppression
    environment so normal app-owned Wine runs and generated terminal rcfiles
    receive the same setting.
  - Confirmed the public CLI `run-bottle-command dxvk-hud-probe --command cmd
    --json` path generates terminal argv with `export MESA_LOG_LEVEL='fatal'`.
- Remaining:
  - The `wineboot:process_run_key` line is Wine's own `wineboot` error-channel
    output, not Mesa/EGL output. It remains intentionally unsuppressed so Wine
    errors are not hidden by this graphics-log cleanup.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens Command Prompt in a Linux terminal"'`:
    failed before implementation on missing `MESA_LOG_LEVEL`, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "Linux planner uses a configured Konyak-managed runtime"'`:
    failed before implementation on missing `MESA_LOG_LEVEL`, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-program --json applies persisted program settings"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && TERMINAL=/bin/echo dart run bin/konyak.dart run-bottle-command dxvk-hud-probe --command cmd --json'`:
    returned JSON through the public CLI path and confirmed the generated
    terminal argv includes `export MESA_LOG_LEVEL='fatal'`.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.

- Timestamp: 2026-06-22 00:18 JST
- State: `completed`
- Branch: `main`
- Related work: Linux terminal Mesa/EGL log suppression
- Purpose: stop Mesa `libEGL warning` diagnostics from appearing in
  Terminal-backed Linux Wine commands, matching the earlier macOS MoltenVK log
  suppression approach.
- Completed:
  - Read the current progress/TODO state and compared Linux terminal setup
    generation with the macOS Terminal suppression path.
  - Identified that macOS suppresses graphics-runtime noise through Wine
    environment variables while Linux did not set Mesa/EGL log suppression.
  - Added failing CLI contract coverage for normal Linux Wine runs and Linux
    Terminal-backed bottle commands requiring `EGL_LOG_LEVEL=fatal` and
    `MESA_DEBUG=silent`.
  - Added Linux Command Prompt terminal coverage because the reported output
    came from `run-bottle-command --command cmd`.
  - Added the suppression environment to Linux app-owned Wine runs and Linux
    terminal rcfile generation.
  - Confirmed the real `dxvk-hud-probe` bottle exists through the public CLI
    route and confirmed the generated `cmd` terminal argv contains both
    suppression exports with terminal launching neutralized by `TERMINAL`.
- Remaining:
  - No code work remains for Mesa/EGL warning suppression. The separate
    `wineboot:process_run_key` line is Wine's own `err` channel and is not
    controlled by Mesa/EGL log levels.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens a Linux bottle terminal"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "Linux planner uses a configured Konyak-managed runtime"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens Command Prompt in a Linux terminal"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-bottles --json'`:
    passed and confirmed `dxvk-hud-probe` exists.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && TERMINAL=/bin/echo dart run bin/konyak.dart run-bottle-command dxvk-hud-probe --command cmd --json'`:
    returned JSON through the public CLI path and confirmed the generated
    terminal argv includes `export EGL_LOG_LEVEL='fatal'` and
    `export MESA_DEBUG='silent'`.
  - First `nix develop -c zsh -lc 'just cli-test'`: failed because the
    persisted Linux program-settings test asserted the exact pre-suppression
    environment map; the test expectation was updated to include the new Mesa
    log suppression variables.
  - First `nix develop -c zsh -lc 'just format-check'`: failed because Dart
    format adjusted `lib/src/io/wine_run_requests.dart` and
    `test/cli_contract_program_execution.part.dart`; the command passed on the
    final rerun.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-program --json applies persisted program settings"'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 23:57 JST
- State: `completed`
- Branch: `main`
- Related work: Linux GUI launch feedback / Wayland process fallback
- Purpose: reduce launch-feedback stalls for native Wayland Wine/Proton
  launches by falling back from window visibility to process observation.
- Completed:
  - Added failing Flutter widget coverage proving Linux launch progress hides
    when no new window is visible but a new Wine process survives multiple
    polls while `run-program --json` is still pending.
  - Added coverage proving preexisting Wine processes do not close launch
    progress.
  - Added Linux method-channel coverage for `runningWineProcessIds`.
  - Extended the Linux native runner to scan `/proc`, filter Wine/Proton/
    CrossOver-like executables, and return matching process IDs.
  - Updated the launch watcher to prefer window detection, then use new Wine
    process IDs as a fallback after they remain visible for two polls.
  - Updated the run-feedback TODO wording to include the process-based Wayland
    fallback.
- Remaining:
  - No code work remains. A real Wine/Proton GUI smoke on native Wayland would
    still be useful to confirm the process fallback timing against a live app.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/app/program_window_probe_test.dart'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux run program hides launch progress after a new Wine process survives"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux run program"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter build linux --debug'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: failed once after
    formatting two Dart files, then passed on rerun.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-linux-loader-check'`: passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && timeout 5s ./build/linux/x64/debug/bundle/konyak'`:
    reached normal GTK startup and VM service startup under the current
    Wayland session, then exited by timeout (`124`).
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 23:37 JST
- State: `completed`
- Branch: `main`
- Related work: Linux GUI launch feedback / XWayland Wine detection
- Purpose: detect XWayland Wine/Proton windows even when Konyak itself is
  running on the GTK Wayland backend in a GNOME Wayland session.
- Completed:
  - Confirmed the current session is Wayland with an XWayland `DISPLAY`.
  - Added failing Linux runner coverage requiring direct `XOpenDisplay` /
    `XCloseDisplay` probing of the XWayland display.
  - Changed the Linux native window probe to reuse GTK's X11 display when
    Konyak is running on X11, or open `$DISPLAY` directly when Konyak is
    running on GTK Wayland.
  - Preserved the fallback for sessions without an XWayland display: Flutter
    keeps the launch overlay until the CLI returns.
- Remaining:
  - No code work remains. A manual smoke with a real Wine/Proton GUI program
    on XWayland would still be useful to prove the end-to-end app path against
    an actual Wine-owned window.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart --plain-name "Linux runner probes visible Wine windows through X11 when available"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter build linux --debug'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-linux-loader-check'`: passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && timeout 5s ./build/linux/x64/debug/bundle/konyak'`:
    reached normal GTK startup and VM service startup under the current
    Wayland session, then exited by timeout (`124`).
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 23:19 JST
- State: `completed`
- Branch: `main`
- Related work: Linux GUI launch feedback
- Purpose: hide Flutter's launch progress overlay on Linux as soon as a newly
  visible Wine/Proton window appears, matching the macOS feedback behavior
  while keeping a documented Wayland fallback.
- Completed:
  - Read the current progress/TODO state and the existing macOS launch
    feedback path.
  - Added failing widget coverage proving Linux program launches hide
    `Launching program...` when a new Wine process window appears before
    `run-program --json` returns.
  - Added failing `NativeProgramWindowProbe` coverage proving Linux uses the
    `konyak/linux_window` method channel.
  - Added failing Linux runner coverage for an X11/XWayland-aware
    `visibleExternalWindowIds` native method.
  - Extended `NativeProgramWindowProbe` to call the Linux window channel for
    Linux targets.
  - Added X11 linkage to the Linux runner build.
  - Implemented Linux native visible-window probing with `_NET_CLIENT_LIST`,
    `_NET_WM_PID`, `/proc/<pid>/stat`, and `/proc/<pid>/exe`.
  - Matched windows when their owner process is descended from the launched
    CLI process or when the owner executable is Wine/Proton/CrossOver-like.
  - Kept native Wayland as the fallback path: GTK cannot inspect other Wayland
    clients, so the method returns an empty list and Flutter keeps the launch
    overlay until the CLI returns.
  - Marked the Linux launch feedback TODO complete.
- Remaining:
  - No code work remains. A manual smoke with a real GUI Wine/Proton program
    on X11/XWayland would still be useful because automated local tests cannot
    create a real external Wine window.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux run program hides launch progress for a new Wine process window"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/app/program_window_probe_test.dart'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart --plain-name "Linux runner probes visible Wine windows through X11 when available"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program hides launch progress"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter build linux --debug'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && timeout 5s ./build/linux/x64/debug/bundle/konyak'`:
    reached normal GTK startup and VM service startup, then exited by timeout
    (`124`).
  - `nix develop -c zsh -lc 'just flutter-format-check'`: failed once after
    formatting `test/linux_window_chrome_test.dart`, then passed on rerun.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-linux-loader-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 23:03 JST
- State: `completed`
- Branch: `main`
- Related work: Linux menu runtime reinstall parity
- Purpose: align the Linux screen-top Konyak menu with the macOS app menu by
  exposing managed runtime reinstall and making the Linux runtime reinstall
  path use the same explicit CLI contract.
- Completed:
  - Read the current progress/TODO state.
  - Compared the macOS native menu item and method-channel runtime reinstall
    path with the Linux Flutter menu bar.
  - Added failing Flutter client coverage for
    `install-linux-wine --reinstall`.
  - Added failing CLI contract coverage proving `install-linux-wine
    --reinstall` forces a full install.
  - Added failing Linux widget coverage for the `Reinstall Linux Runtime`
    menu item invoking the managed runtime reinstall path.
  - Added `--reinstall` support to the Linux runtime install CLI parser and
    Flutter CLI client.
  - Routed the Linux Konyak menu item through the shared runtime reinstall
    loader path, preserving the existing macOS native menu behavior.
- Remaining:
  - None.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux app menu command reinstalls the managed runtime"'`:
    failed before implementation because the Linux menu item was missing, then
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "reinstalls Konyak Linux Wine by passing reinstall to the CLI"'`:
    failed before implementation because `installLinuxWine` had no
    `reinstall` parameter, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "install-linux-wine --reinstall forces a full install"'`:
    failed before implementation with exit code `64`, then passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just cli-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 22:30 JST
- State: `completed`
- Branch: `main`
- Related work: Linux in-app window chrome
- Purpose: remove the Linux native white title/header bar by moving window
  controls into Konyak's dark Linux menu bar and making the empty menu-bar
  area draggable without paying a per-drag Flutter-to-native round trip.
- Completed:
  - Read the current progress/TODO state.
  - Traced Linux native window creation through
    `apps/konyak/linux/runner/my_application.cc`.
  - Traced the Flutter Linux menu bar through `KonyakHomeMenuBar` and
    `KonyakMenuBar`.
  - Added failing static coverage for undecorated Linux windows and native
    window-control channel handlers.
  - Added failing widget coverage proving the Linux menu bar hosts the window
    control buttons at the right edge, keeps a separate empty drag region, and
    calls the Linux window-control channel.
  - Changed the Linux GTK runner to disable native decorations with
    `gtk_window_set_decorated(window, FALSE)`.
  - Added the `konyak/linux_window` native method channel for drag-region
    registration and minimize, maximize/restore, and close commands.
  - Added a small Flutter Linux window-control client and moved minimize,
    maximize/restore, close, and drag handling into the existing dark Linux
    menu-bar row.
  - Superseded the initial `startWindowDrag` MethodChannel path and the later
    direct `FlView` button-press attempt; neither remains in the final code.
  - Implemented the final drag path as a transparent GTK `GtkEventBox` overlay
    whose bounds are updated from Flutter's empty menu-bar drag region.
  - Kept the drag-start hot path native: the event box receives
    `GdkEventButton` and calls `gtk_window_begin_move_drag` with
    `event->x_root`, `event->y_root`, and `event->time`.
  - Rebuilt and smoke-launched the Linux debug bundle. The app reached normal
    GTK startup and stayed alive until the smoke timeout.
- Remaining:
  - Interactive confirmation is still needed on the user's desktop because the
    exact Wayland drag gesture cannot be automated by the maintained local
    checks.
- Next: manually retest dragging the empty menu-bar area; if it works, commit
  the Linux chrome change.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart --plain-name "Linux runner starts window drags from a transparent native overlay"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux menu bar hosts window controls and draggable empty space"'`:
    failed before implementation, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter build linux --debug'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && timeout 5s ./build/linux/x64/debug/bundle/konyak'`:
    reached GTK startup and exited by timeout (`124`) without startup failure.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: failed once because
    it formatted `test/linux_window_chrome_test.dart`, then passed after the
    formatting change.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-21 21:12 JST
- State: `completed`
- Branch: `main`
- Related work: Linux Flutter debug loader libmount rpath
- Purpose: fix Linux debug launches failing at startup because the built
  Flutter bundle cannot resolve `libmount.so.1`.
- Completed:
  - Read the latest progress/TODO state and traced the existing Linux CMake
    dependency contract.
  - Reproduced the startup failure through the built Flutter bundle:
    `./build/linux/x64/debug/bundle/konyak` exited 127 with
    `libmount.so.1: cannot open shared object file`.
  - Confirmed `libmount` was intentionally linked for the previous Linux
    release link failure, so the fix should preserve the link and add the
    runtime search path.
  - Added failing regression coverage requiring the libmount pkg-config
    library directory in the Linux CMake rpath contract.
  - Appended `${LIBMOUNT_LIBRARY_DIRS}` to the Linux bundle install rpath
    before creating the runner target.
  - Added a `flutter-linux-loader-check` target to build the Linux debug bundle
    and fail on unresolved `ldd` entries; `just verify` now runs it, so the
    GitHub Verify workflow covers this path.
  - Initialized the `runtime/konyak-macos-runtime` submodule locally so
    governance verification could read its required workflow files.
- Remaining:
  - None for this loader fix.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && ./build/linux/x64/debug/bundle/konyak'`:
    failed before implementation with missing `libmount.so.1`.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart --plain-name "Linux release build links GTK transitive dependencies explicitly"'`:
    failed before implementation because the CMake contract did not include
    `${LIBMOUNT_LIBRARY_DIRS}`, then failed again until the CI loader target
    was added, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter build linux --debug'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && readelf -d build/linux/x64/debug/bundle/konyak | rg "RUNPATH|libmount"'`:
    confirmed the rebuilt bundle keeps `libmount.so.1` and includes the
    util-linux lib directory in `RUNPATH`.
  - `nix develop -c zsh -lc 'cd apps/konyak && ldd build/linux/x64/debug/bundle/konyak | rg "libmount|not found" || true'`:
    confirmed `libmount.so.1` resolves from the Nix store and no `not found`
    entries were reported.
  - `nix develop -c zsh -lc 'cd apps/konyak && timeout 5s ./build/linux/x64/debug/bundle/konyak'`:
    no longer failed with the `libmount.so.1` loader error; it reached normal
    GTK startup and was stopped by timeout.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: failed before
    submodule initialization because
    `runtime/konyak-macos-runtime/.github/workflows/build-runtime.yml` was not
    present locally, then passed after `git submodule update --init
    runtime/konyak-macos-runtime`.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-linux-loader-check'`: passed.
  - `nix develop -c zsh -lc 'just verify'`: passed.

- Timestamp: 2026-06-21 20:22 JST
- State: `completed`
- Branch: `main`
- Related work: Run program file chooser initial directory
- Purpose: make the Run dialog's file chooser open in the selected bottle's
  Konyak C drive by default.
- Completed:
  - Read the latest progress/TODO state and traced Run dialog file selection
    through `KonyakHomeLoader`, `RunProgramDialog`, and `ProgramFilePicker`.
  - Added widget coverage proving the Run file chooser receives the selected
    bottle's `drive_c` path as its initial directory.
  - Extended `ProgramFilePicker` with an optional initial directory and passed
    it through to `file_selector.openFile`.
  - Changed the Run dialog launch path to pass `bottle.path/drive_c` when
    opening the file chooser.
- Remaining:
  - None for this UI behavior change.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program dialog can choose a program file"'`:
    failed before implementation because the picker received `null`, then
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "pin program"'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-21 20:09 JST
- State: `completed`
- Branch: `main`
- Related work: Bottle Configuration sidebar context menu navigation
- Purpose: keep sidebar context-menu interaction independent from normal bottle
  selection so Bottle Configuration does not close when right-clicking any
  bottle.
- Completed:
  - Read the latest progress/TODO state and traced sidebar right-click handling
    through `SidebarBottleItem` and `KonyakHome`.
  - Added failing widget tests proving that right-clicking the selected sidebar
    bottle and another sidebar bottle while Bottle Configuration is open must
    keep the configuration detail visible.
  - Changed sidebar right-click handling so it never invokes normal bottle
    selection.
  - Removed the context-menu action handler's selection side effect; actions
    still target the right-clicked bottle directly.
- Remaining:
  - None for this UI bug fix.
- Next: none.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "right-clicking the selected bottle keeps Bottle Configuration open"'`:
    failed before implementation because the detail view returned to overview,
    then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "right-clicking another bottle keeps the current Bottle Configuration open"'`:
    failed before implementation because the detail view returned to overview,
    then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottle context menu"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottle configuration"'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-21 19:51 JST
- State: `completed`
- Branch: `main`
- Related work: Bottle Configuration graphics backend dropdown
- Purpose: make DXVK, DXMT, and GPTK/D3DMetal visibly mutually exclusive by
  selecting the graphics backend from one dropdown and showing only the
  options relevant to the selected backend.
- Completed:
  - Read the latest progress/TODO state and existing Bottle Configuration UI,
    runtime settings models, availability resolver, and widget tests.
  - Added widget coverage proving macOS Graphics Backend selection switches
    between DXMT, GPTK/D3DMetal, and DXVK-macOS while preserving the existing
    `dxvk`, `dxmt`, and `dxrEnabled` JSON fields.
  - Replaced the separate DXVK/Vulkan/Metal UI sections with one Graphics
    section that maps dropdown choices to the existing runtime settings.
  - Kept Linux `vkd3d-proton` independent because it is not mutually exclusive
    with DXVK.
  - Updated `docs/todo.md` and `docs/flutter-architecture-plan.md` to describe
    the Graphics Backend dropdown instead of separate DXVK/Metal sections.
- Remaining:
  - None for this UI change.
- Next: test against real macOS and Linux bottles if manual backend smoke is
  desired before release.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS bottle configuration selects graphics backend from one dropdown"'`:
    failed before implementation because `Graphics` was not shown, then
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottle configuration"'`:
    passed after updating the old switch-focused widget expectations.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-21 17:26 JST
- State: `completed`
- Branch: `main`
- Related work: High Resolution Mode internal naming
- Purpose: remove stale Retina-mode operation names from internal helpers while
  keeping the existing registry-backed `retinaMode` JSON/storage field
  compatible.
- Completed:
  - Read the latest progress state and searched the remaining stale internal
    names.
  - Renamed CLI/domain adjustment helpers from Retina Mode wording to High
    Resolution Mode / Windows DPI wording.
  - Renamed Flutter UI model and pending-control helpers to High Resolution
    Mode / Windows DPI wording while preserving the `retinaMode` and
    `dpiScaling` JSON values.
  - Kept `withRetinaMode` only on the CLI registry parser path where it maps
    the literal Wine `RetinaMode` registry value.
- Remaining:
  - None for this naming cleanup.
- Next: test against a real macOS bottle if manual CrossOver parity smoke is
  desired before release.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "set-runtime-settings --json applies registry-backed settings"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "set-runtime-settings --json restores DPI when disabling High Resolution Mode"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottle configuration enables High Resolution Mode with 192 DPI"'`:
    passed.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart packages/konyak_cli/lib/src/domain/program/program_registry_plans.dart packages/konyak_cli/lib/src/cli/cli_bottle_mutation_handlers.dart apps/konyak/lib/src/app/bottles/bottle_runtime_settings_controls.dart apps/konyak/lib/src/app/bottles/bottle_runtime_settings_sections.dart apps/konyak/lib/src/bottles/bottle_summary.dart packages/konyak_cli/test/cli_contract_app_bottle.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-21 17:15 JST
- State: `completed`
- Branch: `main`
- Related work: High Resolution Mode UI alignment
- Purpose: make the bottle configuration UI describe the CrossOver-style
  RetinaMode/DPI coupling as High Resolution Mode, with DPI shown as current
  Windows DPI rather than a separate-looking mode.
- Completed:
  - Read the latest progress/TODO state.
  - Confirmed the implementation already keeps CLI/registry contracts as
    `retinaMode` and `LogPixels`, while the UI still says `Retina Mode` and
    `DPI Scaling`.
  - Updated focused widget expectations before changing UI labels.
  - Renamed visible macOS controls to `High Resolution Mode` and `Windows DPI`,
    keeping internal `retinaMode` JSON and widget keys unchanged.
  - Moved the Windows DPI row next to High Resolution Mode in the Wine section
    so the coupled settings read as one group.
  - Updated `docs/todo.md` and `docs/flutter-architecture-plan.md` to record
    the user-facing names and registry backing.
- Remaining:
  - None for this UI alignment pass.
- Next: test against a real macOS bottle if manual CrossOver parity smoke is
  desired before release.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottle configuration opens a settings screen and runs utilities"'`:
    failed before implementation because `Windows DPI` was not shown, then
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottle configuration enables High Resolution Mode with 192 DPI"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux hides macOS runtime controls"'`:
    passed.
  - `nix develop -c zsh -lc 'dart format apps/konyak/lib/src/app/bottles/bottle_runtime_settings_sections.dart apps/konyak/test/widget_bottle_configuration.part.dart apps/konyak/test/widget_menus_winetricks.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-21 17:03 JST
- State: `completed`
- Branch: `main`
- Related work: Retina Mode DPI coupling
- Purpose: align Konyak's macOS Retina Mode behavior with CrossOver High
  Resolution Mode by coupling RetinaMode registry changes with DPI scaling.
- Completed:
  - Read the latest progress/TODO state.
  - Traced registry-backed runtime settings planning/parsing, CLI persistence,
    and Flutter optimistic runtime settings updates.
  - Added failing CLI coverage for enabling Retina Mode with LogPixels 192 and
    disabling it back to LogPixels 96.
  - Added failing Flutter widget coverage that the Retina Mode toggle updates
    visible DPI and the outgoing settings JSON to 192 DPI.
  - Implemented macOS-only runtime settings normalization so Retina Mode
    false-to-true doubles current DPI with a 480 cap, and true-to-false halves
    current DPI with a 96 floor and 24-DPI step alignment.
  - Kept inspect-bottle registry parsing independent for RetinaMode and
    LogPixels.
- Remaining:
  - None for this implementation pass.
- Next: test against a real macOS bottle if manual CrossOver parity smoke is
  desired before release.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "set-runtime-settings --json applies registry-backed settings"'`:
    failed before implementation with LogPixels 144, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "set-runtime-settings --json restores DPI when disabling Retina Mode"'`:
    failed before implementation because LogPixels was not written, then
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottle configuration enables Retina Mode with 192 DPI"'`:
    failed before implementation because 192 DPI was not shown, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "inspect-bottle --json reads registry-backed bottle settings"'`:
    passed.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/domain/bottle/bottle_runtime_settings_models.dart packages/konyak_cli/lib/src/domain/program/program_registry_plans.dart packages/konyak_cli/lib/src/cli/cli_bottle_mutation_handlers.dart packages/konyak_cli/test/cli_contract_app_bottle.part.dart apps/konyak/lib/src/bottles/bottle_summary.dart apps/konyak/test/widget_bottle_configuration.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-21 16:38 JST
- State: `completed`
- Branch: `main`
- Related work: Bottle Tools Simulate Reboot command
- Purpose: add a Tools launcher that simulates a Windows reboot inside the
  selected bottle by running Wine's `wineboot --restart` path.
- Completed:
  - Read the latest progress/TODO state.
  - Confirmed Konyak already has prefix initialization `wineboot --init`
    planners but no Tools or `run-bottle-command` route for simulated reboot.
  - Added failing CLI contract coverage for macOS and Linux simulated reboot
    run plans before implementation.
  - Added failing Flutter widget coverage for the Tools `Simulate Reboot`
    launcher before implementation.
  - Added the `simulate-reboot` bottle command and routed it to Wine
    `wineboot --restart` through the platform-specific run planner.
  - Added the `Simulate Reboot` Tools item for the selected bottle.
- Remaining:
  - None for this implementation pass.
- Next: use the Tools item against a real bottle if manual runtime smoke is
  needed before release.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json simulates a Windows reboot on macOS"'`:
    failed before implementation with unsupported command exit 65, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Bottle Tools groups bottle utility launchers"'`:
    failed before implementation because `Simulate Reboot` was not present,
    then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json simulates a Windows reboot on Linux"'`:
    passed after implementation.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-21 16:15 JST
- State: `completed`
- Branch: `main`
- Related work: DLSS powered by MetalFX design
- Purpose: define the TODO and design for a Konyak macOS bottle toggle that
  mirrors CrossOver's DLSS powered by MetalFX behavior without starting
  implementation.
- Completed:
  - Read the latest progress/TODO state.
  - Confirmed existing Konyak GPTK/D3DMetal and DXMT runtime handling already
    validates or packages `nvapi64` and `nvngx` shim files.
  - Confirmed CrossOver documents DLSS as MetalFX-backed and limited to
    D3DMetal/DXMT with in-game DLSS enabled.
  - Added `docs/dlss-metalfx-design.md` covering product behavior, data
    contracts, run-planning constraints, dynamic proof requirements, tests, and
    CI limits.
  - Added the implementation backlog item to `docs/todo.md`.
- Remaining:
  - None for this design/TODO pass.
- Next: start implementation only after choosing a DLSS-capable dynamic proof
  path and confirming the exact D3DMetal/DXMT enablement signal.
- Verification:
  - `nix develop -c zsh -lc 'git diff --check'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-21 15:22 JST
- State: `completed`
- Branch: `main`
- Related work: automatic pinning for newly installed programs
- Purpose: automatically pin newly discovered Installed Programs after a
  completed installer/program run, with an app setting that can disable the
  behavior.
- Completed:
  - Read the latest progress/TODO state.
  - Traced Installed Programs listing, manual pinning, program-run completion,
    and app settings persistence through the Flutter UI and CLI JSON contracts.
  - Added `automaticallyPinNewInstalledPrograms` to the CLI and Flutter app
    settings contracts, with missing legacy JSON defaulting to enabled.
  - Added a Programs switch in Konyak Settings to persist the behavior.
  - Added post-run Installed Programs diffing in the Flutter home loader and
    automatic pinning through the existing `pin-program` CLI contract.
  - Added CLI, Flutter client, settings widget, and program-run widget
    coverage for enabled, disabled, and legacy-setting behavior.
  - Updated `docs/todo.md` to include the completed app setting.
- Remaining:
  - None for this automatic pinning change.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "get-app-settings --json returns persisted application settings"'`:
    failed before implementation because the new app setting field did not
    exist, then passed after implementation.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "set-app-settings --json defaults automatic pinning for old payloads"'`:
    passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "loads app settings through the JSON CLI contract"'`:
    failed before implementation because the new Flutter setting field did not
    exist, then passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program auto-pins newly installed programs when enabled"'`:
    failed before implementation because no `list-bottle-programs` diff or
    `pin-program` call ran after completion, then passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "run program does not auto-pin installed programs when disabled"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "settings dialog loads and persists Konyak app settings"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "sets app settings through the JSON CLI contract"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "set-app-settings --json persists application settings"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/domain/app/app_settings_models.dart packages/konyak_cli/lib/src/io/app_settings_repositories.dart packages/konyak_cli/test/cli_contract_app_bottle.part.dart apps/konyak/lib/src/settings/app_settings_summary.dart apps/konyak/lib/src/cli/konyak_cli_settings_payload_parsers.dart apps/konyak/lib/src/app/dialogs/app_settings_dialog.dart apps/konyak/lib/src/home_loader_parts/home_loader_programs.part.dart apps/konyak/test/cli/konyak_cli_client_test.dart apps/konyak/test/widget_settings.part.dart apps/konyak/test/widget_programs.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test && just flutter-format-check && just flutter-analyze && just flutter-test'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance && just verify-safety && just format-check && just lint && git diff --check'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check && just flutter-analyze && just flutter-test && just verify-governance && just verify-safety && just format-check && just lint && git diff --check'`:
    passed after the final completed-run condition cleanup.

- Timestamp: 2026-06-21 14:57 JST
- State: `completed`
- Branch: `main`
- Related work: macOS cmd Terminal MoltenVK log suppression
- Purpose: stop MoltenVK info dumps from appearing inside Terminal-backed
  bottle commands such as Command Prompt when Vulkan initializes.
- Completed:
  - Read the latest progress/TODO state and inspected the user-provided
    Terminal capture.
  - Confirmed the long output is `[mvk-info]` MoltenVK capability logging,
    not a Konyak SnackBar or Flutter notification.
  - Confirmed the generated
    `logs/konyak-terminal-setup.zsh` for the affected bottle does not export
    `MVK_CONFIG_LOG_LEVEL`.
  - Added failing CLI contract expectations that macOS Wine execution and
    Terminal-backed bottle commands include `MVK_CONFIG_LOG_LEVEL=0`.
  - Added `MVK_CONFIG_LOG_LEVEL=0` to Konyak's macOS Wine environment so
    normal app-owned Wine runs and Terminal setup scripts suppress MoltenVK
    info logs.
  - Confirmed the public CLI route regenerated the affected bottle's
    `konyak-terminal-setup.zsh` with `export MVK_CONFIG_LOG_LEVEL='0'`.
- Remaining:
  - None for this log suppression cleanup.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-program --json uses the Konyak macOS Wine startup path on macOS"'`:
    failed before implementation because the macOS Wine environment did not
    contain `MVK_CONFIG_LOG_LEVEL`, then passed after the environment change.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens a macOS bottle terminal"'`:
    failed before implementation because the Terminal setup script did not
    contain `MVK_CONFIG_LOG_LEVEL`, then passed after the environment change.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens Command Prompt in a macOS terminal"'`:
    failed before implementation because the Command Prompt setup script did
    not contain `MVK_CONFIG_LOG_LEVEL`, then passed after the environment
    change.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart run-bottle-command bottle --command cmd --json'`:
    passed through the public CLI route and returned `runnerKind:
    macosTerminal`, `processExitCode: 0`, with `export
    MVK_CONFIG_LOG_LEVEL='0'` in the generated AppleScript setup text.
  - `nix develop -c zsh -lc 'nl -ba "/Users/masato/Library/Application Support/Konyak/Bottles/bottle/logs/konyak-terminal-setup.zsh" | sed -n "1,3p"'`:
    confirmed the generated setup script contains `export
    MVK_CONFIG_LOG_LEVEL='0'`.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart packages/konyak_cli/test/cli_contract_program_execution.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 14:50 JST
- State: `completed`
- Branch: `main`
- Related work: normal program-run completion feedback cleanup
- Purpose: stop showing bottom SnackBars for all normal program-run
  completions, including Terminal-backed bottle tools.
- Completed:
  - Confirmed the current bug is in Flutter feedback classification:
    `processExitCode == 0` is quiet only for Wine/Winetricks runner kinds.
  - Added failing Flutter coverage that successful Terminal runner completions
    should also be quiet.
  - Changed `programRunFeedback` so every `CompletedProgramRun` with
    `processExitCode == 0` returns no feedback regardless of runner kind.
  - Updated widget coverage so Terminal-backed bottle tools no longer show
    `macosTerminal exited with code 0`.
- Remaining:
  - None for this feedback cleanup.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/app/program_run_feedback_test.dart --plain-name "omits feedback for all successful runner completions"'`:
    failed before implementation because Terminal success still returned
    `terminal exited with code 0`, then passed after the feedback change.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottom bar opens a bottle terminal"'`:
    failed before implementation because the `macosTerminal exited with code 0`
    SnackBar was still shown, then passed after the feedback change.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/app/program_run_feedback_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "bottom bar launches a selected winetricks verb for a bottle"'`:
    passed.
  - `nix develop -c zsh -lc 'dart format apps/konyak/lib/src/app/utils/program_run_feedback.dart apps/konyak/test/app/program_run_feedback_test.dart apps/konyak/test/widget_menus_winetricks.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 14:27 JST
- State: `completed`
- Branch: `main`
- Related work: GPTK/D3DMetal import progress wording
- Purpose: replace the misleading `Adding GPTK Wine` progress label with
  wording that describes importing the D3DMetal backend, not replacing or
  adding a Wine runtime.
- Completed:
  - Read the current progress/TODO state and traced the label to
    `AppSettingsRuntimeSection._gptkInstallPanel`.
  - Confirmed the confirmation dialog and CLI behavior describe importing a
    D3DMetal backend while preserving the Wine executable.
  - Updated the in-progress button label to `Importing D3DMetal`.
  - Updated widget coverage so the GPTK/D3DMetal import flow holds the install
    future open and verifies the in-progress label while rejecting the old
    `Adding GPTK Wine` text.
- Remaining:
  - None for this wording cleanup.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog imports GPTK/D3DMetal"'`:
    failed before implementation because the in-progress button still showed
    the old wording, then passed after changing the label.
  - `nix develop -c zsh -lc 'dart format apps/konyak/lib/src/app/dialogs/app_settings_runtime_section.dart apps/konyak/test/widget_settings.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 13:53 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime partial status and repair gating
- Purpose: fix Repair so it is only offered for missing components that should
  be repaired by Konyak's runtime installer, while missing user-provided
  GPTK/D3DMetal is shown as `Partial` instead of `Incomplete`.
- Completed:
  - Read the current progress/TODO state and traced the Repair button to
    `RuntimeSectionState.shouldOfferInstall`.
  - Confirmed the previous GPTK/D3DMetal required-component change made Repair
    try to repair a user-provided component that the runtime installer cannot
    supply.
  - Added failing CLI and Flutter tests proving missing GPTK/D3DMetal remains
    the last macOS component, is optional, shows the stack as `Partial`, and
    does not expose Repair.
  - Restored GPTK/D3DMetal to `isRequired: false` while keeping it last in the
    macOS component and backend lists.
  - Added Flutter stack status labeling for `Complete`, `Partial`, and
    `Incomplete`, with Repair still gated only by missing required stack
    components or a not-installed runtime.
  - Kept missing component path details hidden in the settings component rows.
  - Removed GPTK/D3DMetal from the normal Konyak-managed macOS runtime test
    archives and complete-runtime fixtures, leaving GPTK/D3DMetal only in
    explicit user-provided import/preserve fixtures.
  - Confirmed the public `list-runtimes --json` CLI route reports the local
    missing GPTK/D3DMetal runtime as complete for required components, with
    GPTK/D3DMetal last, optional, and missing.
- Remaining:
  - None for Repair gating and partial GPTK/D3DMetal status.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "list-runtimes --json reports missing GPTK/D3DMetal as optional last"'`:
    failed before implementation because `stack.isComplete` was still `false`,
    then passed after GPTK/D3DMetal became optional again.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/app/app_settings_runtime_view_model_test.dart --plain-name "labels optional missing runtime components as partial without repair"'`:
    failed before implementation because `runtimeStackStatusLabel` did not
    exist, then passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog keeps missing GPTK last and partial"'`:
    failed before implementation because the settings dialog did not show
    `Partial`, then passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "install-macos-wine builds a stack from component archives"'`:
    failed after removing GPTK/D3DMetal from the normal component-stack
    fixture because one stale GPTK path assertion remained, then passed after
    updating the assertion.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-runtimes --json | jq -r '\''.runtimes[] | select(.id=="konyak-macos-wine") | {stackComplete: .stack.isComplete, lastComponent: (.stack.components[-1] | {id, isRequired, isInstalled})}'\'''`:
    passed and reported `stackComplete: true`, last component
    `gptk-d3dmetal`, `isRequired: false`, and `isInstalled: false`.
  - `nix develop -c zsh -lc 'dart format apps/konyak/lib/src/app/dialogs/app_settings_runtime_section.dart apps/konyak/lib/src/app/dialogs/app_settings_runtime_view_model.dart apps/konyak/test/app/app_settings_runtime_view_model_test.dart apps/konyak/test/widget_settings.part.dart apps/konyak/test/widget_test.dart apps/konyak/test/cli/runtime_list_contract_test.dart packages/konyak_cli/lib/src/domain/runtime/runtime_platform_support.dart packages/konyak_cli/test/cli_contract_runtime_install.part.dart packages/konyak_cli/test/cli_contract_runtime_process_update.part.dart packages/konyak_cli/test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 13:48 JST
- State: `completed`
- Branch: `main`
- Related work: GPTK/D3DMetal runtime completeness and ordering cleanup
- Purpose: make missing GPTK/D3DMetal keep the macOS runtime stack
  `Incomplete`, and keep the GPTK/D3DMetal component last in runtime component
  listings.
- Completed:
  - Read the current progress/TODO state and traced macOS runtime completeness
    from Flutter settings display to the CLI runtime stack contract.
  - Confirmed GPTK/D3DMetal is currently `isRequired: false`, so
    `RuntimeStack.isComplete` can be true while GPTK/D3DMetal is missing.
  - Added CLI contract coverage for a macOS runtime with every non-GPTK
    component present but GPTK/D3DMetal missing.
  - Made GPTK/D3DMetal a required macOS runtime stack component and moved it to
    the end of the macOS component and backend definitions.
  - Added Flutter widget coverage that a missing GPTK/D3DMetal runtime remains
    `Incomplete` and lists GPTK/D3DMetal after DXMT.
  - Updated runtime parsing and installer fixtures so complete macOS runtime
    fixtures include valid GPTK/D3DMetal payload files.
  - Confirmed the public CLI `list-runtimes --json` route now reports the local
    missing GPTK/D3DMetal runtime as incomplete with GPTK/D3DMetal last.
- Remaining:
  - None for this cleanup.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "list-runtimes --json requires GPTK/D3DMetal last on macOS"'`:
    failed before implementation because `stack.isComplete` was still `true`,
    then passed after GPTK/D3DMetal became required and last.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS settings dialog keeps missing GPTK last and incomplete"'`:
    passed.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/domain/runtime/runtime_platform_support.dart packages/konyak_cli/test/cli_contract_runtime_process_update.part.dart packages/konyak_cli/test/cli_contract_test.dart apps/konyak/test/widget_test.dart apps/konyak/test/widget_settings.part.dart apps/konyak/test/cli/runtime_list_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    failed once after implementation because complete runtime fixtures lacked
    GPTK/D3DMetal payloads, then passed after fixture updates.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-runtimes --json | jq -r '\''.runtimes[] | select(.id=="konyak-macos-wine") | {isInstalled, stackComplete: .stack.isComplete, lastComponent: (.stack.components[-1] | {id, isRequired, isInstalled}), gptk: (.stack.components[] | select(.id=="gptk-d3dmetal") | {id, isRequired, isInstalled})}'\'''`:
    passed and reported `stackComplete: false`, last component
    `gptk-d3dmetal`, `isRequired: true`, and `isInstalled: false`.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: failed once because two CLI
    test files needed formatting, then passed after formatting.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 13:31 JST
- State: `completed`
- Branch: `main`
- Related work: runtime settings component path display cleanup
- Purpose: remove raw missing runtime component paths from the app settings UI
  while keeping component installed/missing status visible.
- Completed:
  - Read the current roadmap/progress state and the Flutter runtime settings
    component rendering path.
  - Updated settings widget coverage so missing runtime component status remains
    visible while the raw missing path is absent from the UI.
  - Removed `missingPaths` detail rendering from runtime component rows.
- Remaining:
  - None for this UI cleanup.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Linux settings dialog shows runtime stack component statuses"'`:
    failed before implementation because the missing runtime path was still
    rendered, then passed after the display cleanup.
  - `nix develop -c zsh -lc 'dart format apps/konyak/lib/src/app/dialogs/app_settings_runtime_section.dart apps/konyak/test/widget_settings.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 13:10 JST
- State: `completed`
- Branch: `main`
- Related work: macOS packaged app execution-path CI hardening
- Purpose: close the remaining CI gap where Finder/LaunchServices smoke proved
  app launch and visible-window behavior, but did not prove that a Finder-opened
  `.exe` reached Flutter's bundled CLI `run-program` execution path with the
  packaged app resource environment.
- Completed:
  - Added widget coverage for a smoke-only executable-open auto-run path that
    skips the bottle chooser and sends the pending executable to
    `run-program <bottle-id> --program <path> --json`.
  - Added a smoke-only app hook driven by
    `KONYAK_ENABLE_SMOKE_HOOKS=1` plus
    `KONYAK_SMOKE_OPEN_EXECUTABLE_AUTO_RUN_BOTTLE_ID`.
  - Added `scripts/smoke_macos_packaged_app_cli_bridge.zsh`, which copies a
    finalized `Konyak.app`, replaces only `Contents/Resources/konyak-cli` with
    a CLI spy, opens an `.exe` through `/usr/bin/open`, and verifies the spy saw
    `run-program` plus `KONYAK_BUNDLE_RESOURCES` at the front of `PATH`.
  - Wired the smoke into `just smoke-macos-app-cli-bridge` and the macOS release
    workflow after the packaged Finder smoke.
  - Updated release documentation, TODO tracking, and governance checks so the
    new packaged app CLI bridge smoke remains part of CI coverage.
- Remaining:
  - None for this CI hardening step.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "macOS startup can auto-run pending executable files for smoke"'`:
    failed before implementation because `KonyakApp` did not expose the
    smoke-only auto-run parameter, then passed after the hook was added.
  - `nix develop -c zsh -lc 'dart format apps/konyak/lib/main.dart apps/konyak/lib/src/app/konyak_app.dart apps/konyak/lib/src/home_loader/home_loader.dart apps/konyak/lib/src/home_loader_parts/home_loader_executables.part.dart apps/konyak/test/widget_test.dart apps/konyak/test/widget_macos_startup.part.dart apps/konyak/test/macos_window_metrics_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'zsh -n scripts/smoke_macos_packaged_app_cli_bridge.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/main_entrypoint_test.dart'`:
    passed after moving the smoke hook back into inline entrypoint wiring so
    `main.dart` stayed within the thin-entrypoint line budget.
  - `nix run .#macos-release`: passed and refreshed the local release
    `Konyak.app` and zip artifacts.
  - `nix develop -c zsh -lc './scripts/smoke_macos_packaged_app_cli_bridge.zsh .dart_tool/konyak/release/macos/Konyak.app'`:
    passed against the refreshed release app.
  - `nix develop -c zsh -lc 'just smoke-macos-app-cli-bridge'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: failed once because the first
    smoke hook version made `main.dart` exceed the thin-entrypoint line budget,
    then passed after the hook was inlined.
  - `nix develop -c zsh -lc 'just verify'`: passed.
  - `git diff --check`: passed.

- Timestamp: 2026-06-21 12:30 JST
- State: `completed`
- Branch: `main`
- Related work: Bottle Tools GUI launch progress follow-up defect
- Purpose: make Bottle Tools GUI utility launches use the existing program
  launch progress overlay and window-detection completion path instead of
  waiting silently while `run-bottle-command` is pending.
- Completed:
  - Confirmed normal `Run` uses `_beginProgramLaunch()` plus
    `_finishProgramLaunchWhenMatchingWindowAppears()`, while
    `_runBottleCommand()` directly awaits `cliClient.runBottleCommand()` and
    never marks a launch active.
  - Confirmed `KonyakCliClient.runBottleCommand()` does not expose the
    `onStarted` callback already used by `runProgram`, so Tools launches cannot
    currently close progress when a Wine window appears.
  - Added widget coverage that selecting `Open Wine Configuration` from Bottle
    Tools shows the existing `program-launch-progress` overlay while
    `run-bottle-command` is pending.
  - Added CLI client coverage that `runBottleCommand` forwards the started
    process id through `onStarted`.
  - Changed `KonyakCliClient.runBottleCommand()` to accept and forward
    `onStarted`.
  - Routed `_runBottleCommand()` through the existing program launch tracking
    path: it starts a launch id, captures the baseline external windows,
    starts the window watcher when the process id is available, and clears the
    overlay when a matching window appears or the command completes.
- Remaining:
  - None for this follow-up defect.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Bottle Tools shows progress while launching a GUI utility"'`:
    failed before implementation because no widget with key
    `program-launch-progress` was shown, then passed after launch tracking was
    added.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "runs a bottle utility through the JSON run-bottle-command CLI contract"'`:
    failed before implementation because `runBottleCommand` had no `onStarted`
    parameter, then passed after the client change.
  - `nix develop -c zsh -lc 'dart format apps/konyak/lib/src/cli/konyak_cli_program_commands.dart apps/konyak/lib/src/home_loader_parts/home_loader_programs.part.dart apps/konyak/test/widget_shell_sidebar.part.dart apps/konyak/test/cli/konyak_cli_client_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.

- Timestamp: 2026-06-21 12:17 JST
- State: `completed`
- Branch: `main`
- Related work: Bottle Tools DirectX Diagnostic launcher follow-up defect
- Purpose: fix the `DirectX Diagnostic Tool` Bottle Tools action so it
  produces a visible, useful result instead of launching Wine's built-in
  `dxdiag` directly, which exits successfully without presenting a window.
- Completed:
  - Confirmed the user-provided Konyak Wine Run Log is for `dxdiag`, not
    `cmd`: it shows `Runner Kind: macosWine`, `Arguments: ["dxdiag"]`,
    `Process Exit Code: 0`, empty stdout, and MoltenVK/GStreamer diagnostics
    on stderr.
  - Reproduced the public CLI route with
    `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart run-bottle-command bottle --command dxdiag --json'`,
    which returned `runnerKind: macosWine`, `argv: [..., "dxdiag"]`, and
    `processExitCode: 0`.
  - Sampled the same run with `pgrep` and `CGWindowListCopyWindowInfo`; during
    execution `dxdiag.exe` and `explorer.exe /desktop` appeared as Wine
    processes, but no Wine/DirectX window appeared in CGWindowList.
  - Confirmed `explorer` itself can present a Wine `Desktop` window through the
    same public CLI route, so the failure is specific to launching Wine's
    built-in `dxdiag` as a GUI utility rather than a global window-observation
    failure.
  - Stopped the diagnostic `explorer` run with
    `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart terminate-wine-processes --bottle bottle --json'`.
  - Added CLI contract coverage that `dxdiag` runs through
    `cmd /c "dxdiag /t C:\konyak-dxdiag.txt && start "" notepad
    C:\konyak-dxdiag.txt"` instead of direct `dxdiag` execution.
  - Implemented explicit bottle-command argument mapping for `dxdiag` on both
    macOS and Linux Wine request builders.
  - Renamed the Bottle Tools label from `DirectX Diagnostic Tool` to
    `DirectX Diagnostic Report` to match the visible behavior.
  - Confirmed the fixed public CLI route starts `notepad.exe
    C:\konyak-dxdiag.txt`, exposes a CGWindowList window named
    `konyak-dxdiag.txt - Notepad`, and writes the report under the bottle's
    `drive_c`.
- Remaining:
  - None for this follow-up defect.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens the DirectX diagnostic report"'`:
    failed before implementation because `dxdiag` planned as `["dxdiag"]`,
    then passed after the fixed argument mapping.
  - `nix develop -c zsh -lc 'dart format apps/konyak/test/widget_shell_sidebar.part.dart apps/konyak/lib/src/app/dialogs/bottle_tools_dialog.dart packages/konyak_cli/test/cli_contract_program_execution.part.dart packages/konyak_cli/lib/src/domain/program/program_argument_support.dart packages/konyak_cli/lib/src/io/wine_run_requests.dart packages/konyak_cli/lib/src/platform/linux/linux_program_run_requests.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "run-bottle-command"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Bottle Tools groups bottle utility launchers"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart run-bottle-command bottle --command dxdiag --json'`:
    passed and returned argv `["wineloader", "cmd", "/c", "dxdiag /t
    C:\\konyak-dxdiag.txt && start \"\" notepad
    C:\\konyak-dxdiag.txt"]`.
  - `pgrep` and `CGWindowListCopyWindowInfo` during the fixed public CLI run:
    showed `notepad.exe C:\konyak-dxdiag.txt` and a visible Wine window
    `konyak-dxdiag.txt - Notepad`.
  - `nix develop -c zsh -lc 'ls -l "$HOME/Library/Application Support/Konyak/Bottles/bottle/drive_c/konyak-dxdiag.txt"'`:
    passed; the report file existed.
  - `nix develop -c zsh -lc 'sed -n "1,40p" "$HOME/Library/Application Support/Konyak/Bottles/bottle/drive_c/konyak-dxdiag.txt"'`:
    passed and showed a `System Information` DirectX diagnostic report.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart terminate-wine-processes --bottle bottle --json'`:
    passed after the public CLI verification.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.

- Timestamp: 2026-06-21 12:01 JST
- State: `completed`
- Branch: `main`
- Related work: Bottle Tools launcher surface follow-up defect
- Purpose: fix the new `Command Prompt` Bottle Tools action so it opens an
  interactive host Terminal-backed Wine command prompt instead of running
  `cmd` directly under `macosWine` where the prompt is captured in Konyak's
  stdout and no visible window appears.
- Completed:
  - Confirmed the user-provided Konyak Wine Run Log shows `Runner Kind:
    macosWine`, `Arguments: ["cmd"]`, `Process Exit Code: 0`, and stdout
    containing a Windows command prompt, proving direct Wine execution succeeds
    but does not present an interactive window.
  - Reproduced the same public CLI route locally with
    `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart run-bottle-command bottle --command cmd --json'`,
    which returned `runnerKind: macosWine`, `argv: [..., "cmd"]`, and
    `processExitCode: 0`.
  - Added CLI contract coverage requiring `cmd` to plan through
    `macosTerminal` and `/usr/bin/osascript` with the bottle `WINEPREFIX`,
    `wineloader`, and `cmd` present in the generated Terminal script.
  - Routed the `cmd` bottle command through the existing host terminal request
    builders on macOS and Linux while preserving direct `macosWine` execution
    for the other allowlisted Wine utilities.
  - Extended the terminal setup command builders so they can run an initial
    Wine command after exporting the managed runtime environment.
  - Updated the Bottle Tools widget mock to expect the `Command Prompt` action
    to return `runnerKind: macosTerminal`.
  - Confirmed the fixed public CLI route now returns `runnerKind:
    macosTerminal`, `programPath: cmd`, `executable: /usr/bin/osascript`, and
    a generated setup script ending in the managed `wineloader` invocation for
    `cmd`.
- Remaining:
  - None for this follow-up defect.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens Command Prompt in a macOS terminal"'`:
    failed before implementation because `cmd` still planned as `macosWine`,
    then passed after the terminal routing change.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/domain/program/program_runner.dart packages/konyak_cli/lib/src/io/wine_run_requests.dart packages/konyak_cli/lib/src/platform/platform_terminal_commands.dart packages/konyak_cli/test/cli_contract_program_execution.part.dart apps/konyak/test/widget_shell_sidebar.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "run-bottle-command"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Bottle Tools groups bottle utility launchers"'`:
    failed once because a snackbar covered the `Tools` button during the
    second dialog open, then passed after hiding the snackbar in the test.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart run-bottle-command bottle --command cmd --json'`:
    passed and returned `runnerKind: macosTerminal`,
    `executable: /usr/bin/osascript`, and a Terminal setup script that runs
    `wineloader cmd`.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.

- Timestamp: 2026-06-21 11:43 JST
- State: `completed`
- Branch: `main`
- Related work: `docs/todo.md` Bottle Tools launcher surface
- Purpose: implement a bottle-scoped Tools surface that keeps Winetricks in its
  current entry point, moves Wine utility/location launchers into one shared
  dialog, and expands `run-bottle-command` through explicit allowlist command
  ids.
- Completed:
  - Reviewed the existing `run-bottle-command` planner, current bottom bar
    utility buttons, Bottle Configuration utility buttons, and widget/CLI
    tests that cover the old direct button placement.
  - Added CLI contract coverage proving `uninstaller`, `taskmgr`, `cmd`,
    `explorer`, `dxdiag`, and `winver` are allowlisted Wine utility commands,
    while unsafe arbitrary command strings still fail.
  - Extended `run-bottle-command` through the existing explicit allowlist
    instead of accepting arbitrary shell strings.
  - Added a bottle-scoped Tools dialog that contains Wine Configuration,
    Registry Editor, Control Panel, Uninstall Programs, Task Manager, Command
    Prompt, File Explorer, DirectX Diagnostic Tool, Windows Version, Terminal,
    Open C: Drive, and Open Bottle Folder actions.
  - Moved the overview and Bottle Configuration bottom bars to a shared
    `Tools` entry point while keeping Winetricks as its existing separate
    bottom-bar action.
  - Updated widget coverage for the new Tools surface and old direct button
    placement.
  - Marked the Bottle Tools TODO complete.
- Remaining:
  - None for the Bottle Tools item.
- Next: continue with the next unfinished TODO item.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json launches allowlisted Wine utilities"'`:
    failed before implementation on `uninstaller` with exit code 65, then
    passed after the allowlist expansion.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart --plain-name "Bottle Tools groups bottle utility launchers"'`:
    failed before implementation because no `Tools` bottom-bar button existed,
    then passed after the Tools dialog implementation.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "run-bottle-command"'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/widget_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: failed once on import
    directive ordering in `bottom_bars.dart`, then passed after sorting the
    imports.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: failed once on the same Flutter
    import ordering issue, then passed after sorting the imports.

- Timestamp: 2026-06-21 11:27 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime automated smoke coverage; CrossOver-derived
  macOS runtime Phase 3 launch/smoke normalization
- Purpose: finish the remaining CI-side runtime smoke work by making the parent
  repository prove DXVK, DXMT, and vkd3d backend execution through Konyak's
  public CLI `run-program` path instead of relying only on runtime-submodule
  low-level diagnostics.
- Completed:
  - Added parent CLI smoke coverage that builds the runtime-submodule Windows
    backend probes, installs the published macOS runtime stack, creates
    backend-specific bottles, applies runtime settings, runs probes through
    `dart run bin/konyak.dart run-program ... --json`, and waits for
    bottle-local success sentinels.
  - Extended the runtime-submodule D3D11 and D3D12 probes so `start /unix`
    launches can prove child-process success via `C:\konyak-...-probe-ok.txt`
    sentinel files, since stdout from the detached child is not owned by the
    parent `run-program` process.
  - Confirmed the first parent app-route vkd3d smoke attempt failed because
    `LoadLibraryA(d3d12.dll)` could not find Wine's D3D12 DLLs when the probe
    lived outside the runtime DLL directory.
  - Fixed the macOS `run-program` environment so `WINEPATH` always includes the
    managed Wine `lib/wine/x86_64-windows` and `lib/wine/i386-windows` search
    directories, while backend-specific DXVK/DXMT/GPTK paths still prepend
    those core paths.
  - Updated `.github/workflows/macos-runtime-cli-smoke.yml` to checkout
    submodules recursively and trigger on backend probe source/builder changes.
  - Added the MinGW compiler to the parent Darwin dev shell so CI can build the
    Windows probe fixtures without treating it as a runtime component.
  - Marked the macOS runtime automated smoke coverage and Phase 3
    launch/smoke normalization TODOs complete.
  - Committed and pushed runtime submodule commit
    `5bfa6adf4da415662fe0acdeb654cb9ed0fbaa9d` and parent commit
    `4257277251911612b71ef9643f2b562d080834f3`.
  - Confirmed parent GitHub Actions and runtime submodule GitHub Actions
    completed successfully after the push.
- Remaining:
  - None for this CI smoke completion work.
- Next: no open action remains for this item.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS runtime CLI smoke runs backend probes through the CLI"'`:
    failed before implementation because the parent CLI smoke did not build or
    run backend probes; passed after the smoke/workflow updates.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-program --json uses the Konyak macOS Wine startup path on macOS"'`:
    failed before the macOS `WINEPATH` fix because the normal app route omitted
    Wine's core Windows DLL search paths.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/build-backend-probes.zsh .dart_tool/konyak/backend-probes-test >/tmp/konyak-backend-probes-test.out && /usr/bin/file .dart_tool/konyak/backend-probes-test/d3d11_device_probe.exe .dart_tool/konyak/backend-probes-test/d3d12_device_probe.exe'`:
    passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh .dart_tool/konyak/dev-runtime/macos-wine vkd3d-d3d12 .dart_tool/konyak/macos-runtime-cli-smoke/backend-probes'`:
    passed as a diagnostic, proving the runtime vkd3d contract itself worked
    before fixing the parent app route.
  - `nix develop -c zsh -lc './scripts/run_macos_runtime_cli_smoke.zsh'`:
    failed once at DXVK before sentinel files existed, failed once at vkd3d
    before the app-route `WINEPATH` fix, then passed after the probe sentinel
    and `WINEPATH` changes.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify'`: passed.
  - `git diff --check`: passed.
  - `git -C runtime/konyak-macos-runtime diff --check`: passed.
  - Parent remote GitHub Actions for
    `4257277251911612b71ef9643f2b562d080834f3`: `Konyak Pages`
    run `27890217321`, `Konyak Verify` run `27890217320`, and
    `macOS Runtime CLI Smoke` run `27890217314` all passed.
  - Runtime submodule remote GitHub Actions for
    `5bfa6adf4da415662fe0acdeb654cb9ed0fbaa9d`: `Build runtime`
    run `27890202909` passed, including Wine runtime build, binary component
    packaging, vkd3d and DXMT component builds, runtime stack assembly, GUI
    start smoke, GPTK/D3DMetal smoke, DXVK smoke, vkd3d smoke, DXMT smoke,
    Wine32-on-64 smoke, release metadata generation, and publish release.
    The run reported non-failing annotations for Node.js 20 deprecation and
    FlakeHub authentication on cache setup.

- Timestamp: 2026-06-20 23:32 JST
- State: `completed`
- Branch: `main`
- Related work: typed CLI/domain string map governance
- Purpose: consume the light CI/governance TODO by preventing raw
  `Map<String, String>` from re-entering CLI/domain code outside approved
  value-object implementations.
- Completed:
  - Added a governance check that rejects raw `Map<String, String>` type usage
    under `packages/konyak_cli/lib/src/domain` except for
    `ProgramEnvironmentOverrides`, `ProgramRunEnvironment`, `HostEnvironment`,
    and `RuntimeComponentVersions` implementation files.
  - Confirmed the new governance check failed before implementation on
    `bottle_runtime_settings_models.dart`.
  - Replaced the remaining domain-side raw environment map construction with
    `ProgramRunEnvironment` composition.
  - Replaced PE version-string map return values with a private typed record.
  - Changed the runtime install preserve callback to pass
    `RuntimeComponentVersions` instead of a mutable raw map through the domain
    request contract.
- Remaining:
  - None for this light CI/governance cleanup.
- Next: continue with the heavier CI TODOs, starting with macOS runtime backend
  probe smoke only after its headless runner path is non-flaky on GitHub-hosted
  arm64 macOS.
- Verification:
  - `nix develop -c zsh -lc 'just verify-governance'`: failed before
    implementation because `bottle_runtime_settings_models.dart` still exposed
    a raw `Map<String, String>` type; passed after the typed-map changes.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just verify'`: passed.

- Timestamp: 2026-06-20 23:09 JST
- State: `completed`
- Branch: `main`
- Related work: split packaged app, Finder smoke, and release CI fixes
- Purpose: finish the requested split commits, refresh local release artifacts,
  and prove the resulting macOS and Linux release paths in CI.
- Completed:
  - Split the work into natural commits covering packaged macOS runtime
    extraction, packaged Finder smoke coverage, progress recording, Linux
    release diagnostics, Linux GTK transitive link fixes, bubblewrap-free
    AppImage packaging, and Linux AppStream metadata cleanup.
  - Refreshed local macOS artifacts with `nix run .#macos-release`, producing
    the local release `Konyak.app`, zip, checksum, release metadata, and release
    notes under `.dart_tool/konyak/release/macos`.
  - Rebuilt the packaged debug app with `just macos-debug-app` and verified the
    packaged runtime extraction, synthetic Finder smoke, and PuTTY-backed Finder
    smoke locally.
  - Fixed the Linux release job issues surfaced by CI: hidden GTK/Pango/GIO
    transitive linker dependencies, AppImage bubblewrap uid-map failure on
    GitHub runners, and AppStream metadata validation warnings.
  - Pushed the commits through `c3248aa`.
  - Confirmed GitHub Actions `Konyak Release` run `27873459646` passed: Linux
    AppImage build and artifact upload succeeded, and the macOS app job passed
    release build, packaged runtime extraction smoke, PuTTY-backed Finder smoke,
    and artifact upload.
  - Confirmed GitHub Actions `Konyak Verify` run `27873454871` and `Konyak
    Pages` run `27873454880` passed for the same pushed code. The latest macOS
    runtime CLI smoke triggered by code changes, run `27873295529`, also passed;
    the final AppStream metadata-only push did not trigger that workflow.
- Remaining:
  - None for this requested split, artifact refresh, and CI completion work.
    Failed intermediate release runs are retained in Actions history and record
    the sequence of diagnosed CI failures.
- Next: use the passing release run artifacts from `27873459646` or rebuild
  locally with `nix run .#macos-release` / `nix run .#linux-release` on the
  appropriate host.
- Verification:
  - `nix develop -c zsh -lc 'just verify'`: passed after the Linux link fix,
    after the AppImage packaging fix, and after the AppStream metadata fix.
  - `nix develop -c zsh -lc 'git diff --check'`: passed for the final code
    changes before commit.
  - GitHub Actions `Konyak Release` run `27873459646`: passed.
  - GitHub Actions `Konyak Verify` run `27873454871`: passed.
  - GitHub Actions `Konyak Pages` run `27873454880`: passed.
  - GitHub Actions `macOS Runtime CLI Smoke` run `27873295529`: passed.

- Timestamp: 2026-06-20 23:01 JST
- State: `in_progress`
- Branch: `main`
- Related work: fix Linux AppStream metadata for AppImage packaging
- Purpose: finish Linux AppImage packaging after switching appimagetool away
  from bubblewrap by addressing metadata validation failures.
- Completed:
  - Reran `Konyak Release` at `953f419`; Linux AppImage reached
    `appimagetool`, proving Flutter Linux build and bubblewrap-free
    appimagetool execution both progressed.
  - Confirmed the remaining failure came from AppStream validation:
    `summary-has-dot-suffix`, unreachable homepage URL
    `https://github.com/masatokinugawa/Konyak`, and missing developer info.
  - Added a failing static regression test for the Linux AppStream metadata
    contract.
  - Updated Linux appdata metadata to remove the summary dot suffix, add
    developer metadata, and point the homepage at the actual
    `https://github.com/serika12345/Konyak` repository.
- Remaining:
  - Run local gates, push the AppStream metadata fix, rerun release CI, and
    confirm Linux AppImage artifact upload succeeds.
- Next: verify and push the AppStream metadata fix, then rerun
  `Konyak Release`.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart --plain-name "Linux AppStream metadata avoids release packaging warnings"'`:
    failed before implementation because the metadata still had the dot suffix,
    old URL, and no developer entry.
  - GitHub Actions `Konyak Release` run `27873299748`, Linux AppImage job
    `82488580073`: passed Flutter Linux build and reached appimagetool, then
    failed AppStream validation before this fix.

- Timestamp: 2026-06-20 22:55 JST
- State: `in_progress`
- Branch: `main`
- Related work: fix Linux AppImage packaging on GitHub-hosted runners
- Purpose: finish the release workflow after the Linux Flutter build fix by
  removing the AppImage packaging dependency on bubblewrap user namespaces.
- Completed:
  - Reran the failed Linux release job from `27873061451`; it passed Flutter
    Linux compilation and produced `build/linux/x64/release/bundle/konyak`.
  - Confirmed the remaining Linux failure was AppImage packaging:
    `appimage-run` invoked bubblewrap and failed with
    `bwrap: setting up uid map: Permission denied` on the GitHub Ubuntu runner.
  - Added a failing static regression test requiring the Linux release script to
    run `appimagetool` with `APPIMAGE_EXTRACT_AND_RUN=1` and not depend on
    `appimage-run`.
  - Updated the Linux release script to execute the downloaded `appimagetool`
    AppImage directly with `APPIMAGE_EXTRACT_AND_RUN=1`, avoiding the bubblewrap
    wrapper path, and removed `appimage-run` from Linux release Nix inputs.
- Remaining:
  - Run the local gates, push the AppImage packaging fix, rerun release CI, and
    confirm the Linux AppImage job now reaches artifact upload.
- Next: verify and push the AppImage packaging fix, then rerun `Konyak Release`.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart --plain-name "Linux release runs appimagetool without bubblewrap wrappers"'`:
    failed before implementation because the script still used `appimage-run`.
  - GitHub Actions `Konyak Release` run `27873061451`, rerun Linux AppImage job
    `82488215136`: passed Flutter Linux build, then failed at AppImage
    packaging with the bubblewrap uid-map error before this fix.

- Timestamp: 2026-06-20 22:45 JST
- State: `in_progress`
- Branch: `main`
- Related work: fix Linux AppImage release link failure after packaged macOS
  smoke split
- Purpose: complete the manually dispatched publish CI run by fixing the Linux
  release build failure exposed after the macOS packaged app jobs were added.
- Completed:
  - Used the failure-only diagnostics from release run `27872835781` to capture
    the actual Linux linker errors instead of relying on Flutter's hidden
    `clang++` summary.
  - Confirmed the failed link command omitted `libmount` and `fontconfig` while
    `libgio-2.0.so` required `mnt_monitor_veil_kernel@MOUNT_2_40` and
    `libpangocairo-1.0.so` required `FcConfigSetDefaultSubstitute`.
  - Added a failing static regression test covering the Linux CMake and flake
    dependency contract.
  - Updated Linux CMake to import and link `fontconfig` and `mount`
    explicitly, and added the corresponding Nix build inputs for Linux Flutter
    release builds.
- Remaining:
  - Run the local gates for the Linux link fix, push the fix, rerun the release
    workflow, and confirm the Linux AppImage and macOS packaged app jobs both
    pass.
- Next: verify and push the Linux link fix, then rerun `Konyak Release`.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/linux_window_chrome_test.dart --plain-name "Linux release build links GTK transitive dependencies explicitly"'`:
    failed before implementation and passed after implementation.
  - GitHub Actions `Konyak Release` run `27872835781`, Linux AppImage job
    `82487411820`: failed before this fix with the captured missing
    `libmount`/`fontconfig` link dependencies.

- Timestamp: 2026-06-20 22:36 JST
- State: `in_progress`
- Branch: `main`
- Related work: split packaged macOS release/Finder smoke changes and complete
  publish CI
- Purpose: keep the already verified macOS release/Finder/runtime smoke changes
  in natural commits, push them, and bring GitHub Actions publish coverage to a
  clean run.
- Completed:
  - Split and pushed the local changes into commits for packaged macOS runtime
    extraction support, packaged Finder smoke coverage, and progress
    documentation.
  - Manually dispatched the `Konyak Release` workflow after the push.
  - Confirmed pushed CI status:
    `Konyak Verify`, `Konyak Pages`, and `macOS Runtime CLI Smoke` all passed.
  - Confirmed the manually dispatched release workflow's macOS job passed its
    release build, packaged runtime extraction smoke, and PuTTY-backed Finder
    integration smoke.
  - Confirmed the release workflow is currently blocked only by the Linux
    AppImage job, where `flutter build linux` reports a hidden
    `clang++: error: linker command failed` failure.
  - Added failure-only Linux release diagnostics so CI prints CMake `link.txt`,
    CMake logs, and a verbose Flutter rebuild if the Linux linker failure
    persists.
- Remaining:
  - Push the Linux release diagnostic commit, rerun the release workflow, inspect
    the detailed Linux linker failure if it persists, and fix the Linux release
    build before final reporting.
- Next: rerun GitHub Actions `Konyak Release` and use the Linux job diagnostics
  to complete the CI pass.
- Verification:
  - GitHub Actions `Konyak Verify` run `27872555547`: passed.
  - GitHub Actions `Konyak Pages` run `27872555545`: passed.
  - GitHub Actions `macOS Runtime CLI Smoke` run `27872555556`: passed.
  - GitHub Actions `Konyak Release` run `27872560742`: macOS app job passed;
    Linux AppImage job failed before this diagnostic update.

- Timestamp: 2026-06-20 22:16 JST
- State: `completed`
- Branch: `main`
- Related work: discard stale LaunchServices OpenWith cleanup
- Purpose: remove the app-side migration cleanup for stale
  `com.apple.LaunchServices.OpenWith` attributes while keeping the actual
  Finder `.exe` open event path intact.
- Completed:
  - Re-reviewed `AppDelegate.swift`, the macOS packaging static test, and the
    Finder smoke script.
  - Confirmed the cleanup is separate from the required AppKit
    `openFiles`/`open urls` entrypoints that receive Finder-launched `.exe`
    paths.
  - Changed static coverage so the macOS app delegate must keep
    `openFiles`/`open urls` forwarding but must not contain
    `LaunchServices.OpenWith`, `getxattr`, or `removexattr` cleanup logic.
  - Removed the app-side `com.apple.LaunchServices.OpenWith` xattr reader and
    remover from `AppDelegate.swift`.
  - Removed the Finder smoke script's `xattr` command dependency and
    post-smoke OpenWith assertion.
  - Rebuilt the packaged debug app and confirmed both synthetic and
    PuTTY-backed Finder smoke paths still launch Konyak through the public
    `open` route after the cleanup removal.
- Remaining:
  - None for removing the OpenWith cleanup. Files with stale per-file
    LaunchServices overrides are no longer auto-repaired by Konyak; the
    packaged app/Finder smoke path is now the owned regression point.
- Next: keep Finder launch verification on the packaged app smoke path and do
  not reintroduce app-side xattr mutation unless a new migration requirement is
  explicitly accepted.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS app registers and forwards Windows executable files"'`:
    failed before implementation because OpenWith cleanup was still present;
    passed after removal.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS release bundles zstd extraction support for runtime stacks"'`:
    passed.
  - `nix develop -c zsh -lc 'zsh -n scripts/smoke_macos_finder_integration.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'just swift-lint'`: passed.
  - `nix develop -c zsh -lc 'just macos-debug-app'`: passed and rebuilt the
    packaged debug app without the OpenWith cleanup.
  - `nix develop -c zsh -lc 'just smoke-macos-finder-putty'`: passed.
  - `nix develop -c zsh -lc 'just smoke-macos-finder'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: failed once because Dart
    formatting was needed in `test/macos_window_metrics_test.dart`; passed
    after formatting.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 21:59 JST
- State: `completed`
- Branch: `main`
- Related work: pinned Windows executable fixture for packaged macOS Finder
  smoke coverage
- Purpose: remove the remaining manual `.app`/fixture placement assumption by
  making local and CI Finder smokes use a checksum-pinned OSS Windows
  executable fixture against the same finalized packaged app layout.
- Completed:
  - Reviewed the existing packaged debug/release finalizer, Finder smoke,
    release workflow, static macOS packaging test, and release documentation.
  - Confirmed sub-agent tooling exists but cannot be used for this task
    because the active tool contract only permits spawning when the user
    explicitly asks for sub-agents; investigation, implementation, and audit
    will be kept as separate written workstream notes in this snapshot instead.
  - Checked the official PuTTY release/checksum pages and selected the
    standalone 64-bit Windows `putty.exe` fixture without vendoring the binary
    into the repository.
  - Added failing static coverage requiring a checksum-pinned PuTTY fixture
    fetcher, Finder smoke app override/cleanup support, local Just target,
    release workflow wiring, and release documentation.
  - Added `scripts/fetch_windows_fixture_putty.zsh`, which downloads PuTTY
    0.84 standalone 64-bit `putty.exe` into
    `.dart_tool/konyak/fixtures/windows`, verifies the official SHA-256
    checksum, and prints the cached path for smoke scripts.
  - Updated `scripts/smoke_macos_finder_integration.zsh` so callers can select
    the packaged app through `KONYAK_MACOS_FINDER_SMOKE_APP`, relative app
    paths are normalized before macOS tooling reads them, and smoke-launched
    Konyak processes are killed on every exit path unless explicitly retained.
  - Added Just targets `fetch-windows-fixture-putty` and
    `smoke-macos-finder-putty`.
  - Updated the macOS release workflow to run the PuTTY-backed Finder smoke
    against `.dart_tool/konyak/release/macos/Konyak.app` after
    `nix run .#macos-release`.
  - Updated `docs/release.md`, `docs/todo.md`, and governance checks to record
    the pinned real-PE fixture and CI/local packaged app smoke path.
  - Downloaded and checksum-verified the fixture locally, then proved both the
    packaged debug app and refreshed release app can be launched through the
    Finder public `open` path with that fixture.
- Remaining:
  - None for the local pinned fixture and packaged app smoke path. The first
    GitHub-hosted macOS workflow run should still be watched for runner-specific
    WindowServer or LaunchServices differences now that the step is enabled.
- Next: inspect the first macOS release workflow run and keep the Finder smoke
  as the CI-owned regression point instead of relying on manual `.app`
  placement checks.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS release bundles zstd extraction support for runtime stacks"'`:
    failed before implementation because
    `scripts/fetch_windows_fixture_putty.zsh` did not exist; passed after
    implementation.
  - `nix develop -c zsh -lc 'zsh -n scripts/fetch_windows_fixture_putty.zsh scripts/smoke_macos_finder_integration.zsh scripts/finalize_macos_app.zsh scripts/build_macos_debug_app.zsh scripts/build_macos_release.zsh scripts/smoke_macos_release_runtime_extraction.zsh'`:
    passed.
  - `nix develop -c zsh -lc './scripts/fetch_windows_fixture_putty.zsh'`:
    passed and cached the PuTTY fixture under
    `.dart_tool/konyak/fixtures/windows`.
  - `nix develop -c zsh -lc 'just smoke-macos-finder-putty'`: passed against
    the packaged debug app.
  - `nix develop -c zsh -lc 'fixture="$(./scripts/fetch_windows_fixture_putty.zsh)" && ./scripts/smoke_macos_finder_integration.zsh .dart_tool/konyak/release/macos/Konyak.app "$fixture"'`:
    passed against the packaged release app, both before and after the release
    rebuild.
  - `nix run .#macos-release`: passed and refreshed the release app/zip
    artifacts.
  - `nix develop -c zsh -lc 'just smoke-macos-runtime-install'`: passed.
  - `nix develop -c zsh -lc 'just smoke-macos-finder'`: passed.
  - `nix develop -c zsh -lc 'pgrep -fl ".dart_tool/konyak/.*/Konyak.app/Contents/MacOS/Konyak|apps/konyak/build/macos/.*/Konyak.app/Contents/MacOS/Konyak" || true'`:
    returned no Konyak process after smoke runs.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just swift-lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 20:06 JST
- State: `completed`
- Branch: `main`
- Related work: packaged macOS debug/release parity and Finder/runtime smoke
  coverage
- Purpose: reduce development/release drift by finalizing debug and release
  macOS app bundles through the same packaging path, then make Finder,
  LaunchServices, Quick Look, and packaged runtime extraction checks target the
  local runnable packaged app artifacts rather than loose build products.
- Completed:
  - Reviewed the current release script, runtime extraction smoke, Justfile,
    and recent stale `.dart_tool` app-copy failure notes.
  - Confirmed sub-agent tooling exists but cannot be used for this task
    because the active tool contract only permits spawning when the user
    explicitly asks for sub-agents.
  - Added failing static coverage requiring a shared macOS app finalizer,
    packaged debug app builder, Finder smoke script, runtime smoke Just target,
    Finder smoke Just target, and release docs for those paths.
  - Added `scripts/finalize_macos_app.zsh`, shared by debug and release
    packaging, to install `Contents/Resources/konyak-cli`, bundled `zstd`,
    `libzstd.1.dylib`, notices, licenses, and ad-hoc signatures.
  - Updated `scripts/build_macos_release.zsh` to delegate app bundle
    finalization to the shared finalizer before refreshing
    `.dart_tool/konyak/release/macos/Konyak.app` and packaging the zip.
  - Added `scripts/build_macos_debug_app.zsh`, which builds a packaged debug
    app at `.dart_tool/konyak/app/macos/debug/Konyak.app` through the same
    finalizer path as release.
  - Added `scripts/smoke_macos_finder_integration.zsh`, a local smoke that
    registers the packaged debug app with LaunchServices, validates `.exe`
    content type/default app resolution, opens the fixture through
    `/usr/bin/open`, checks for a visible Konyak window with
    `CGWindowListCopyWindowInfo`, and optionally runs `qlmanage` for a
    provided PE fixture.
  - Added Just targets: `macos-debug-app`,
    `smoke-macos-runtime-install`, and `smoke-macos-finder`.
  - Updated `docs/release.md`, `docs/todo.md`, and governance checks to reflect
    the shared finalizer and packaged app smoke coverage.
  - Built the packaged debug app and release app, then verified runtime
    extraction against both packaged app layouts with the inherited environment
    reduced to `PATH=/usr/bin:/bin`.
  - Ran the Finder integration smoke against the packaged debug app and
    confirmed it did not leave a Konyak process behind.
- Remaining:
  - Quick Look thumbnail rendering is supported by the Finder smoke when a real
    PE fixture is supplied, but the default smoke only uses a synthetic `.exe`
    file for LaunchServices/Finder launch coverage because no stable PE icon
    fixture lives in the parent repository yet.
- Next: use `nix develop -c zsh -lc 'just macos-debug-app'` followed by
  `just smoke-macos-finder` for local Finder/LaunchServices verification, and
  keep `nix run .#macos-release` plus `just smoke-macos-runtime-install` for
  release runtime extraction checks.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS release bundles zstd extraction support for runtime stacks"'`:
    failed before implementation because `scripts/finalize_macos_app.zsh` did
    not exist; passed after implementation.
  - `nix develop -c zsh -lc 'zsh -n scripts/finalize_macos_app.zsh scripts/build_macos_debug_app.zsh scripts/build_macos_release.zsh scripts/smoke_macos_finder_integration.zsh scripts/smoke_macos_release_runtime_extraction.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'just macos-debug-app'`: passed and produced
    `.dart_tool/konyak/app/macos/debug/Konyak.app` with code signature
    verification.
  - `nix develop -c zsh -lc './scripts/smoke_macos_release_runtime_extraction.zsh .dart_tool/konyak/app/macos/debug/Konyak.app'`:
    passed.
  - `nix develop -c zsh -lc './scripts/smoke_macos_release_runtime_extraction.zsh'`:
    passed against the packaged release app.
  - `nix develop -c zsh -lc 'just smoke-macos-finder'`: passed.
  - `nix run .#macos-release`: passed with the shared finalizer path and
    produced the refreshed local release app plus zip/checksum/metadata
    artifacts.
  - `nix develop -c zsh -lc 'just smoke-macos-runtime-install'`: passed after
    the release rebuild.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just swift-lint'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: failed before updating
    governance ownership from `build_macos_release.zsh` to
    `finalize_macos_app.zsh`; passed after the governance update.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-20 15:52 JST
- State: `completed`
- Branch: `main`
- Related work: stale local macOS release app copy missing bundled `zstd`
- Purpose: fix the still-failing runtime install from
  `.dart_tool/konyak/release/macos/Konyak.app`, which remained an older app
  copy without `Contents/Resources/zstd` even after `nix run .#macos-release`
  refreshed the build product and zip artifact.
- Completed:
  - Confirmed the currently running Konyak process is
    `/Users/masato/Documents/Konyak/.dart_tool/konyak/release/macos/Konyak.app/Contents/MacOS/Konyak`.
  - Confirmed that app copy has `Contents/Resources/konyak-cli` but does not
    have `Contents/Resources/zstd` or `Contents/Resources/libzstd.1.dylib`.
  - Confirmed the fresh build product at
    `apps/konyak/build/macos/Build/Products/Release/Konyak.app` does include
    the bundled Zstandard helper and library.
  - Reproduced the failure directly with
    `nix develop -c zsh -lc './scripts/smoke_macos_release_runtime_extraction.zsh .dart_tool/konyak/release/macos/Konyak.app'`,
    which failed because the packaged zstd helper was missing.
  - Added static coverage requiring the macOS release script to replace
    `.dart_tool/konyak/release/macos/Konyak.app`, package the zip from that
    refreshed copy, and make the runtime extraction smoke default to that
    release app copy.
  - Updated `scripts/build_macos_release.zsh` to remove any stale
    `$release_root/Konyak.app`, copy the freshly signed build product there,
    verify its code signature, and package the zip from that refreshed local
    app.
  - Updated `scripts/smoke_macos_release_runtime_extraction.zsh` so its
    default target is `.dart_tool/konyak/release/macos/Konyak.app`.
  - Updated `docs/release.md` to list the local runnable `Konyak.app` output
    and document that it is refreshed on every release build.
  - Re-ran `nix run .#macos-release`; it refreshed
    `.dart_tool/konyak/release/macos/Konyak.app`, and that app now includes
    `Contents/Resources/zstd` and `Contents/Resources/libzstd.1.dylib`.
  - Re-ran the packaged runtime extraction smoke with no explicit app path, so
    it verified the local release app copy that had previously failed.
- Remaining:
  - None for the stale local release app copy. The already-running app process
    should be quit and relaunched so it uses the refreshed bundle and loaded
    Flutter code.
- Next: relaunch `.dart_tool/konyak/release/macos/Konyak.app` before retrying
  runtime install/reinstall from the UI.
- Verification:
  - `nix develop -c zsh -lc './scripts/smoke_macos_release_runtime_extraction.zsh .dart_tool/konyak/release/macos/Konyak.app'`:
    failed before implementation because `Contents/Resources/zstd` was
    missing.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS release bundles zstd extraction support for runtime stacks"'`:
    failed before implementation, passed after implementation.
  - `nix develop -c zsh -lc 'zsh -n scripts/build_macos_release.zsh scripts/smoke_macos_release_runtime_extraction.zsh'`:
    passed.
  - `nix run .#macos-release`: passed and refreshed the local release app
    copy, then produced the macOS zip/checksum/metadata artifacts.
  - `nix develop -c zsh -lc './scripts/smoke_macos_release_runtime_extraction.zsh'`:
    passed against `.dart_tool/konyak/release/macos/Konyak.app`.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just swift-lint'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 15:42 JST
- State: `completed`
- Branch: `main`
- Related work: packaged macOS app runtime stack extraction failure
- Purpose: fix built `Konyak.app` runtime install/reinstall failures where
  `/usr/bin/tar` cannot extract managed runtime `.tar.zst` archives because no
  `zstd` helper is available in the packaged app environment.
- Completed:
  - Confirmed the reported failure maps to the CLI runtime archive extraction
    path, which invokes `tar -xf` through `Process.runSync`.
  - Added failing regression coverage for the Flutter packaged CLI launch
    environment to expose `KONYAK_BUNDLE_RESOURCES` and prepend the bundle
    resources directory to `PATH`.
  - Added failing static release coverage requiring the macOS app artifact to
    bundle Zstandard extraction support and run a maintained runtime
    extraction smoke in CI.
  - Updated the Flutter packaged CLI launcher to resolve
    `Konyak.app/Contents/Resources`, pass it as `KONYAK_BUNDLE_RESOURCES`, and
    put it at the front of `PATH`.
  - Updated CLI runtime archive extraction so packaged `konyak-cli` processes
    also search `KONYAK_BUNDLE_RESOURCES` and the CLI executable directory for
    helper tools when spawning `tar`.
  - Updated the macOS release build to bundle `zstd` and
    `libzstd.1.dylib`, rewrite the helper's dylib reference to
    `@executable_path/libzstd.1.dylib`, sign both files, and include the
    Zstandard license notice.
  - Added `scripts/smoke_macos_release_runtime_extraction.zsh` and wired the
    publish workflow to run it after `nix run .#macos-release`.
  - Rebuilt the local macOS release app and proved packaged runtime extraction
    through the public `konyak-cli install-macos-wine --reinstall --archive
    ... --json` contract with `PATH=/usr/bin:/bin`, so the smoke cannot use a
    developer-shell `zstd`.
- Remaining:
  - None for the packaged `.tar.zst` extraction failure. The dynamic smoke
    uses a complete local runtime fixture to isolate the extraction contract;
    the published runtime install should follow the same post-download
    extraction path.
- Next: use the rebuilt local release artifact at
  `.dart_tool/konyak/release/macos/Konyak-1.0.0-macos-arm64.zip`, or the
  rebuilt app at
  `apps/konyak/build/macos/Build/Products/Release/Konyak.app`.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/konyak_cli_client_test.dart --plain-name "default CLI client exposes packaged bundle resources on PATH"'`:
    failed before implementation, passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS release bundles zstd extraction support for runtime stacks"'`:
    failed before implementation, passed after implementation.
  - `nix run .#macos-release`: passed after the final source changes and
    produced the local Release `Konyak.app` plus macOS zip/checksum/metadata
    artifacts.
  - Packaged app inspection confirmed `Contents/Resources/konyak-cli`,
    `Contents/Resources/zstd`,
    `Contents/Resources/libzstd.1.dylib`, and
    `Contents/Resources/Licenses/Zstandard-BSD-3-Clause.txt` exist; `otool`
    confirmed `zstd` loads `@executable_path/libzstd.1.dylib`; `codesign
    --verify --strict` passed for the helper, dylib, and app bundle.
  - `nix develop -c zsh -lc './scripts/smoke_macos_release_runtime_extraction.zsh'`:
    passed after proving packaged `.tar.zst` extraction from the built app.
  - `nix develop -c zsh -lc 'zsh -n scripts/build_macos_release.zsh scripts/smoke_macos_release_runtime_extraction.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just swift-lint'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 13:56 JST
- State: `superseded`
- Branch: `main`
- Related work: macOS `.exe` double-click/Open With stale LaunchServices
  override
- Purpose: fix Finder double-click and normal context-menu Open when a file has
  a stale `com.apple.LaunchServices.OpenWith` xattr pointing at an older
  Konyak.app path, while `Open With -> Other` works by explicitly choosing the
  current app bundle.
- Superseded by: 2026-06-20 22:16 JST decision to discard app-side OpenWith
  cleanup and keep Finder behavior fixed through the packaged app execution
  path and smoke coverage instead of mutating per-file LaunchServices xattrs.
- Completed:
  - Confirmed the current file
    `/Users/masato/Downloads/Ardour-9.5.0-w64-Setup.exe` has
    `com.apple.LaunchServices.OpenWith` set to bundle id `app.konyak.Konyak`
    and path `/Applications/Konyak.app`.
  - Confirmed a copy without that xattr resolves through LaunchServices to the
    currently registered debug Konyak app instead of `/Applications/Konyak.app`.
  - Confirmed deleting only `com.apple.LaunchServices.OpenWith` from a copy
    leaves icon xattrs untouched and changes the file default application URL
    away from the stale path.
  - Confirmed sub-agent spawning is available as a tool but still not allowed
    for this task because the current tool contract only permits spawning when
    the user explicitly asks for sub-agents.
  - Added failing static regression coverage for stale OpenWith cleanup in the
    macOS app delegate.
  - Implemented a scoped `AppDelegate` cleanup that removes only
    `com.apple.LaunchServices.OpenWith`, and only when the xattr references
    the current bundle identifier but a different Konyak.app path.
  - Confirmed the implementation leaves Finder icon metadata xattrs, including
    `com.apple.FinderInfo` and `com.apple.ResourceFork`, untouched.
  - Reproduced the fixed flow on a copied executable with the stale xattr:
    `open -a` against the current debug Konyak app removed the stale OpenWith
    xattr, LaunchServices then resolved the file to the debug app, and a
    normal `/usr/bin/open "$exe"` launched the debug app and left a visible
    Konyak window.
- Remaining:
  - None for the app-side fix. A file whose stale OpenWith xattr still points
    at an older app cannot be repaired by the newly built app until the current
    app is explicitly launched with that file once, because LaunchServices
    sends the initial double-click to the stale app path before current Konyak
    can run.
- Next: for affected local files, open once with the newly built/current
  Konyak through `Open With -> Other`, or remove only
  `com.apple.LaunchServices.OpenWith`; subsequent double-clicks should use the
  current LaunchServices default while Quick Look thumbnails continue to own
  icon rendering.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS app registers and forwards Windows executable files"'`:
    failed before implementation because the stale OpenWith cleanup was absent;
    passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter build macos --debug'`:
    passed.
  - `nix develop -c zsh -lc '... /usr/bin/open -a "$app" "$exe" ...'`:
    passed on a copied executable preserving the stale OpenWith xattr; after
    launch, `com.apple.LaunchServices.OpenWith` was absent while
    `com.apple.FinderInfo` and `com.apple.ResourceFork` remained.
  - `nix develop -c zsh -lc '... /usr/bin/open "$exe" ...'`: passed on the
    same copied executable after cleanup; LaunchServices opened the current
    debug Konyak app and `CGWindowListCopyWindowInfo` found its window.
  - `nix develop -c zsh -lc 'just swift-lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed after
    applying formatter changes to the touched Dart test.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 11:43 JST
- State: `completed`
- Branch: `main`
- Related work: macOS `.exe` Quick Look thumbnail extension
- Purpose: use a bundled Quick Look Thumbnail Extension so Finder can show
  PE-derived `.exe` thumbnails independently of Konyak's file association,
  matching image-file-style separation between opener and thumbnail provider.
- Completed:
  - Reviewed the existing `.exe` LaunchServices document type registration,
    macOS Runner project, and current CLI-driven Finder custom icon fallback.
  - Confirmed Apple documents Quick Look thumbnail extensions as the supported
    app-extension path for rich thumbnails of custom file types.
  - Confirmed sub-agent spawning is not available for this task because the
    current tool contract permits sub-agents only when the user explicitly
    asks for delegation; investigation, implementation, and audit are being
    kept as explicit local workstreams.
  - Added failing Flutter static coverage for the macOS Quick Look thumbnail
    extension target, Info.plist contract, PE icon extractor wiring, and the
    absence of a custom-icon CLI refresh path in the macOS open-file flow.
  - Added the `ExecutableThumbnail.appex` target, embedded it in
    `Konyak.app/Contents/PlugIns`, and declared
    `QLSupportedContentTypes = com.microsoft.windows-executable`.
  - Added a sandboxed Swift `QLThumbnailProvider` that reads the executable's
    PE resource directory directly, reconstructs an ICO payload from
    RT_GROUP_ICON/RT_ICON resources, and draws it into the Quick Look thumbnail
    reply without launching Konyak CLI or any external process.
  - Added `LSItemContentTypes = com.microsoft.windows-executable` to the
    Runner document type entry so the app's LaunchServices declaration is
    explicit about the UTI it handles.
  - Built the extension target and full Flutter macOS app; registered the
    built app/appex with LaunchServices/PluginKit and generated a 256x256 PNG
    thumbnail for `/Users/masato/Downloads/Ardour-9.5.0-w64-Setup.exe` via
    `qlmanage -t -x -s 256 -c com.microsoft.windows-executable`.
  - Superseded the earlier per-file custom Finder icon approach; the current
    app path no longer relies on `refresh-macos-executable-icon` or Finder
    custom icon xattrs to preserve `.exe` icons.
- Remaining: none for the Quick Look implementation.
- Next: if CI gains a reliable macOS user-session Quick Look environment, add
  a maintained smoke that registers the built app/appex and verifies
  `qlmanage` thumbnail output for a fixture PE. Current GitHub Actions were
  not updated because the dynamic proof depends on LaunchServices/PluginKit
  user-session registration and Quick Look daemon cache reload behavior.
- Verification:
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/macos_window_metrics_test.dart --plain-name "macOS app bundles a Quick Look thumbnail extension for EXE files"'`:
    failed before implementation because `macos/ExecutableThumbnail/Info.plist`
    did not exist; passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && xcodebuild -project macos/Runner.xcodeproj -target ExecutableThumbnail -configuration Debug build'`:
    passed.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter build macos --debug'`:
    passed and embedded `ExecutableThumbnail.appex` in the debug app bundle.
  - `nix develop -c zsh -lc '... qlmanage -t -x -s 256 -o "$out" -c com.microsoft.windows-executable "$exe" ...'`:
    passed after `qlmanage -r` and `qlmanage -r cache`, producing a 256x256
    alpha PNG thumbnail from the Ardour installer.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just swift-lint'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 10:51 JST
- State: `superseded`
- Branch: `main`
- Related work: macOS `.exe` file association icon preservation
- Purpose: confirm Konyak can remain the Finder opener for `.exe` files while
  preserving each executable's Windows PE icon as the Finder-visible file icon.
- Completed:
  - Superseded by the 2026-06-20 11:43 JST Quick Look Thumbnail Extension
    implementation. The custom-icon CLI refresh path described below is no
    longer the current product direction.
  - Rechecked the app bundle document type registration: `.exe` remains
    associated with Konyak without declaring a per-type document icon in
    `Info.plist`.
  - Confirmed the pending implementation adds the
    `refresh-macos-executable-icon --program <path> --json` CLI contract.
  - Confirmed the Flutter macOS open-executable path refreshes the Finder
    custom file icon before showing the run dialog, while keeping icon refresh
    best-effort so launch flow is not blocked by icon failures.
  - Re-ran dynamic verification through the public CLI path against
    `/Users/masato/Downloads/Ardour-9.5.0-w64-Setup.exe`; the command returned
    `status: updated` and the file retained Finder custom icon metadata
    (`kMDItemFSFinderFlags = 1024`, `com.apple.FinderInfo`, and
    `com.apple.ResourceFork`).
- Remaining: none; this approach was replaced by Quick Look thumbnails.
- Next: use the Quick Look Thumbnail Extension path recorded in the latest
  snapshot.
- Verification:
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart refresh-macos-executable-icon --program /Users/masato/Downloads/Ardour-9.5.0-w64-Setup.exe --json'`:
    passed and returned `status: updated`.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 10:22 JST
- State: `completed`
- Branch: `main`
- Related work: macOS release build failure in `release_unpack_macos`
- Purpose: make `nix run .#macos-release` use a writable Flutter macOS
  framework copy so Flutter's in-place `lipo` thinning can complete when the
  Flutter SDK comes from the read-only Nix store.
- Completed:
  - Reproduced the user-reported failure with `nix run .#macos-release`:
    Flutter failed in `release_unpack_macos` because `lipo` could not create
    `FlutterMacOS.lipo` inside `FlutterMacOS.framework/Versions/A`.
  - Confirmed the generated Release `FlutterMacOS.framework` and
    `Versions/A` directory are `dr-xr-xr-x`, and a direct `touch` inside
    `Versions/A` fails with `Permission denied`.
  - Confirmed Flutter's unpack target copies the framework with
    `rsync --chmod=Du=rwx,Dgo=rx,Fu=rw,Fgo=r` before running `lipo`.
  - Confirmed the current macOS release/dev environment resolves `rsync` to
    `/usr/bin/rsync` (`openrsync: protocol version 29`), and that copying the
    Nix-store Flutter framework with that command leaves the destination
    read-only.
  - Confirmed `pkgs.rsync` is available in nixpkgs but only Linux release
    packaging currently includes it.
  - Added `pkgs.rsync` to the Darwin Flutter build package set so both
    `nix run .#macos-release` and the dev shell resolve GNU rsync before
    `/usr/bin/rsync`.
  - Made `scripts/build_macos_release.zsh` require `rsync`.
  - Made the macOS release script remove any stale read-only Release
    `FlutterMacOS.framework` before invoking `flutter build macos`.
  - Re-ran `nix run .#macos-release`; it completed and produced the macOS zip,
    checksum, release metadata, and release notes.
- Remaining: none for this build failure.
- Next: use `.dart_tool/konyak/release/macos/Konyak-1.0.0-macos-arm64.zip`
  for the local macOS release artifact.
- Verification:
  - `nix run .#macos-release`: failed before implementation with the reported
    `FlutterMacOS.lipo (Permission denied)` error.
  - `nix develop -c zsh -lc 'nixfmt flake.nix'`: passed.
  - `nix develop -c zsh -lc 'zsh -n scripts/build_macos_release.zsh'`: passed.
  - `direnv allow`: passed after `flake.nix` changed.
  - `nix run .#macos-release`: passed after implementation and produced
    `.dart_tool/konyak/release/macos/Konyak-1.0.0-macos-arm64.zip`.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-20 00:13 JST
- State: `superseded`
- Branch: `main`
- Related work: macOS `.exe` file association icon preservation;
  `/Users/masato/Downloads/Ardour-9.5.0-w64-Setup.exe`
- Purpose: preserve the executable's PE icon in macOS Finder/Quick Look after
  Konyak is associated as the `.exe` opener, instead of leaving the file shown
  with a Konyak-badged generic executable icon.
- Completed:
  - Superseded by the 2026-06-20 11:43 JST Quick Look Thumbnail Extension
    implementation. The custom-icon CLI refresh path described below is
    historical and no longer the active solution.
  - Stashed the previous macOS pinned launcher runtime environment change as
    `stash@{0}: wip macOS pinned launcher runtime env`.
  - Confirmed the app bundle declares `.exe` as a macOS document type without a
    per-type icon, so LaunchServices uses Konyak as the opener and macOS shows
    a Konyak-badged document icon.
  - Confirmed the reported Ardour installer has UTI
    `com.microsoft.windows-executable`, no custom Finder icon flag, and Konyak
    is available as the opener.
  - Confirmed existing CLI PE metadata extraction already writes the Windows
    icon to bottle icon cache as `.ico`, and AppKit `NSImage` can read that
    `.ico` payload.
  - Confirmed sub-agent tooling cannot be used for this defect because the
    available tool contract only permits spawning sub-agents when the user
    explicitly asks for delegation; investigation, implementation, and audit
    are being kept as explicit local workstreams instead.
  - Added CLI contract coverage for
    `refresh-macos-executable-icon --program <path> --json`, including the
    macOS update path and non-macOS skip path.
  - Added the macOS executable icon updater that extracts the PE icon and uses
    AppKit through `/usr/bin/osascript` to set a Finder custom file icon.
  - Added Flutter CLI client support and call it before showing the macOS
    external executable dialog, while keeping the icon update best-effort so
    run flow is not blocked by icon failures.
  - Verified dynamically on the reported Ardour installer through the public
    CLI path: the command returned `status: updated`; Finder flags changed
    from `0` to `1024`; `com.apple.FinderInfo` and `com.apple.ResourceFork`
    xattrs appeared.
  - Did not update GitHub Actions for the AppKit/Finder custom icon write
    itself: the maintained CLI and Flutter tests cover the new contract, but
    the dynamic custom-icon proof depends on a macOS user-session filesystem
    metadata path that the current workflows do not mirror.
- Remaining: none for the user-visible fix.
- Next: optionally refresh other already-associated `.exe` files by opening
  them with Konyak, or by running the new CLI command for specific paths.
- Follow-up TODO: superseded by the Quick Look extension follow-up in the
  latest snapshot; no CI smoke remains for `refresh-macos-executable-icon`.
- Verification:
  - `nix develop -c zsh -lc 'git stash push -m "wip macOS pinned launcher runtime env" -- ...'`:
    passed and created `stash@{0}`.
  - `nix develop -c zsh -lc 'plutil -p apps/konyak/macos/Runner/Info.plist'`:
    passed and showed the `.exe` `CFBundleDocumentTypes` entry.
  - `nix develop -c zsh -lc 'mdls ... /Users/masato/Downloads/Ardour-9.5.0-w64-Setup.exe; xattr -l ...'`:
    passed and showed UTI `com.microsoft.windows-executable`,
    `kMDItemFSFinderFlags = 0`, and no custom icon resource.
  - `nix develop -c zsh -lc '/usr/bin/swift - <<EOF ... NSImage(contentsOfFile: cached.ico) ... EOF'`:
    passed and loaded the extracted `.ico` with 5 representations.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "refresh-macos-executable-icon --json sets a macOS custom file icon"'`:
    failed before implementation because the command/updater contract did not
    exist.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart refresh-macos-executable-icon --program /Users/masato/Downloads/Ardour-9.5.0-w64-Setup.exe --json'`:
    passed and returned `status: updated`.
  - `nix develop -c zsh -lc 'mdls -raw -name kMDItemFSFinderFlags ...; xattr -l ...'`:
    passed after the CLI run and showed `kMDItemFSFinderFlags = 1024` plus
    `com.apple.FinderInfo` and `com.apple.ResourceFork`.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-18 22:41 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime Winetricks verb catalog completeness;
  runtime GitHub Release update for `crossover-26.1.0-konyak.0`
- Purpose: promote the locally verified runtime-owner artifacts to the
  GitHub Release assets, using the runtime submodule candidate promotion flow
  so final Release publication is gated by CI smoke verification.
- Completed:
  - Confirmed the runtime README requires local artifacts to be staged as a
    candidate Release and then promoted by the `Promote runtime candidate`
    workflow, rather than uploading directly to the final Release.
  - Confirmed `scripts/stage-runtime-release-candidate.zsh --dry-run ... dist`
    accepts the generated local `dist` assets for
    `crossover-26.1.0-konyak.0`.
  - Confirmed GitHub CLI is authenticated as `serika12345` with access to
    `serika12345/konyak-macos-runtime`.
  - Confirmed sub-agent tooling cannot be used here because its tool contract
    only permits spawning agents when the user explicitly asks for sub-agent
    delegation; this Release update is being kept in explicit investigation,
    publication, and audit phases in this snapshot instead.
  - Committed and pushed runtime submodule commit
    `5b9dbe7cd135c07c247ba4f08fe094c1e15b5d23`
    (`Package Winetricks verb catalog`) so remote Release workflows include
    the Winetricks catalog check.
  - Staged candidate Release
    `candidate-20260618222002-winetricks-verbs` from the generated local
    `dist` assets.
  - Dispatched `Promote runtime candidate` on `main` with
    `delete_candidate=true`; workflow run
    `https://github.com/serika12345/konyak-macos-runtime/actions/runs/27762434147`
    completed successfully.
  - Confirmed the candidate Release was deleted after successful promotion.
  - Confirmed final Release
    `https://github.com/serika12345/konyak-macos-runtime/releases/tag/crossover-26.1.0-konyak.0`
    is public and contains:
    `konyak-macos-wine-runtime-stack.tar.zst`,
    `konyak-macos-wine-runtime-stack-source.json`, and
    `konyak-macos-runtime.release.json`.
  - Downloaded the final Release assets back from GitHub, verified the stack
    archive SHA-256 is
    `28cfc24a3f16c4e7101491c578357d294371d8db1a13963dd033cd0431fe0b15`,
    verified the final source manifest points all component `archiveUrl`
    values at the final Release URL with that SHA, and confirmed the stack
    archive contains executable `winetricks`, nonempty `verbs.txt`, and the
    `win10` verb.
  - Ran the maintained macOS runtime CLI smoke without any local manifest
    override; it installed from the public Release source manifest, listed
    Winetricks verbs, validated the runtime, created a smoke bottle, and ran
    `run-winetricks ci-prefix-smoke --verb win10 --json`.
- Remaining:
  - No Release update work remains for the Winetricks catalog artifact.
  - Parent repository changes remain uncommitted in the working tree; keep
    them staged or reviewed separately from the runtime Release publication.
- Next: prepare the parent repository change set for review/commit when ready.
- Verification:
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && scripts/stage-runtime-release-candidate.zsh --dry-run candidate-$(date +%Y%m%d%H%M%S) dist'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && git commit -m "Package Winetricks verb catalog" && git push origin main'`:
    passed and pushed commit `5b9dbe7`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && scripts/stage-runtime-release-candidate.zsh candidate-20260618222002-winetricks-verbs dist'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && gh workflow run "Promote runtime candidate" --ref main --field candidate_tag=candidate-20260618222002-winetricks-verbs --field delete_candidate=true'`:
    passed and created run `27762434147`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && gh run view 27762434147 --json status,conclusion,jobs,url'`:
    passed and reported `conclusion: success`; normalize, DXMT, Wine32-on-64,
    vkd3d, DXVK, GPTK/D3DMetal, GUI start, and publish jobs all succeeded.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && gh release view candidate-20260618222002-winetricks-verbs'`:
    failed as expected after promotion because `delete_candidate=true`
    removed the staging Release.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && gh release view crossover-26.1.0-konyak.0 --json tagName,name,isDraft,isPrerelease,publishedAt,targetCommitish,assets,url'`:
    passed and reported the final public Release assets.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && gh release download crossover-26.1.0-konyak.0 ... && shasum -a 256 konyak-macos-wine-runtime-stack.tar.zst && jq ... konyak-macos-wine-runtime-stack-source.json && tar -xaf konyak-macos-wine-runtime-stack.tar.zst ... && grep -E "^win10[[:space:]]+" stack-check/verbs.txt'`:
    passed.
  - `nix develop -c zsh -lc 'scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed using the public default Release source manifest.

- Timestamp: 2026-06-18 22:09 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime Winetricks verb catalog completeness;
  `docs/todo.md` Winetricks verb support
- Purpose: update the runtime-owner local artifacts after fixing the macOS
  Winetricks `verbs.txt` packaging contract, then prove the updated artifact
  through the public Konyak CLI path instead of parent-side runtime mutation.
- Completed:
  - Completed the parent/runtime contract fixes and verification recorded in
    the previous completed snapshot.
  - Generated runtime-owner component archives under
    `runtime/konyak-macos-runtime/dist`, including
    `konyak-macos-winetricks.tar.zst` with a generated nonempty
    `verbs.txt` catalog containing `win10`.
  - Built and packaged the Wine runtime, DXMT, vkd3d, DXVK for macOS,
    MoltenVK, GStreamer, FreeType, Wine Mono, Wine Gecko, and Winetricks
    component archives from the runtime submodule.
  - Assembled `dist/konyak-macos-wine-runtime-stack.tar.zst`; SHA-256 is
    `28cfc24a3f16c4e7101491c578357d294371d8db1a13963dd033cd0431fe0b15`.
  - Generated `dist/konyak-macos-wine-runtime-stack-source.json` and
    `dist/konyak-macos-runtime.release.json` for the local artifact set.
  - Inspected the assembled stack archive and confirmed it contains executable
    `winetricks`, `verbs.txt`, the `win10` verb, and stack metadata listing
    the `winetricks` component.
  - Installed the updated stack into the development runtime through
    `install-macos-wine --source-manifest ... --reinstall --json` using a
    temporary local manifest whose archive URL points at the generated stack
    archive.
  - Confirmed `list-runtimes --json` reports `stackComplete: true`, the
    `winetricks` component installed, and no missing Winetricks paths for
    `.dart_tool/konyak/dev-runtime/macos-wine`.
  - Confirmed `list-winetricks-verbs --json` returns five categories and the
    `win10` verb through the installed development runtime.
  - Ran `scripts/run_macos_runtime_cli_smoke.zsh` with the local source
    manifest override; it installed the runtime, listed Winetricks verbs,
    validated the runtime, created a smoke bottle, and ran
    `run-winetricks ci-prefix-smoke --verb win10 --json`.
- Remaining:
  - No local implementation or artifact-generation work remains for this
    update.
  - The default public runtime release still points at the older
    `crossover-26.1.0-konyak.0` artifact until the new local `dist` artifacts
    are promoted or uploaded; a smoke without the local manifest override
    still exercises that old artifact.
  - Direct local install from the release-style source manifest with relative
    `archiveUrl` is not supported by the parent CLI. The local verification
    used an absolute temporary manifest; release promotion should keep
    producing full asset URLs, or local-relative manifest support should be a
    separate follow-up.
- Next: promote or upload the generated runtime submodule `dist` artifacts
  through the runtime release flow when this build should become the default
  install/update source.
- Verification:
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/package-binary-components.zsh dist <gstreamer-root> <freetype-root> <gstreamer-root> <plugins-base-root> <plugins-good-root> <plugins-bad-root>'`:
    passed and produced the binary component archives.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --show-trace --out-link result-wine-runtime && ./scripts/check-wine32on64-runtime.zsh result-wine-runtime'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT=<runtime-root> KONYAK_METAL_TOOLCHAIN_BIN=<metal-bin> nix build --impure .#packages.x86_64-darwin.konyak-macos-dxmt -L --show-trace --out-link result-dxmt && ./scripts/check-dxmt-component.zsh result-dxmt'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT=<runtime-root> nix build --impure .#packages.x86_64-darwin.konyak-macos-vkd3d -L --show-trace --out-link result-vkd3d && ./scripts/check-vkd3d-component.zsh result-vkd3d'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/assemble-runtime-stack.zsh dist "$PWD/.artifact-work/runtime-stack" dist/konyak-macos-wine-runtime-stack.tar.zst'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-wine32on64-runtime.zsh .artifact-work/runtime-stack && ./scripts/check-dxmt-component.zsh .artifact-work/runtime-stack && ./scripts/check-vkd3d-component.zsh .artifact-work/runtime-stack && ./scripts/check-dxvk-component.zsh .artifact-work/runtime-stack && ./scripts/check-gstreamer-component.zsh .artifact-work/runtime-stack && ./scripts/check-wine-addons-component.zsh .artifact-work/runtime-stack && ./scripts/check-winetricks-component.zsh .artifact-work/runtime-stack && ./scripts/check-runtime-archive-excludes-gptk.zsh dist/konyak-macos-wine-runtime-stack.tar.zst'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_SINGLE_STACK_ARCHIVE=1 ./scripts/make-source-manifest.zsh ...'`:
    passed and generated local release/source metadata.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart install-macos-wine --source-manifest ../../runtime/konyak-macos-runtime/.artifact-work/local-install-source.json --reinstall --json'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart validate-runtime konyak-macos-wine --json'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-runtimes --json | jq ...'`:
    passed and reported complete Winetricks paths.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-winetricks-verbs --json | jq ...'`:
    passed and reported `win10`.
  - `nix develop -c zsh -lc 'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$PWD/runtime/konyak-macos-runtime/.artifact-work/local-install-source.json" scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/package-binary-components.zsh runtime/konyak-macos-runtime/scripts/check-winetricks-component.zsh scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check --no-build'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just test'`: passed.
  - `nix develop -c zsh -lc 'nix shell nixpkgs#actionlint -c actionlint runtime/konyak-macos-runtime/.github/workflows/build-runtime.yml runtime/konyak-macos-runtime/.github/workflows/promote-runtime-candidate.yml runtime/konyak-macos-runtime/.github/workflows/smoke-runtime-artifacts.yml'`:
    passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.

- Timestamp: 2026-06-18 21:30 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime Winetricks verb catalog completeness;
  `docs/todo.md` Winetricks verb support
- Purpose: fix the runtime/parent contract gaps that let a macOS runtime be
  reported as complete without the managed Winetricks `verbs.txt` catalog, and
  tighten adjacent fallback paths that can hide malformed runtime or bottle
  data.
- Completed:
  - Confirmed the defect and fallback history in the previous paused snapshot.
  - Confirmed sub-agent tooling is not available for this turn because the
    tool contract only permits spawning agents when the user explicitly asks
    for sub-agent work; investigation, implementation, and audit will therefore
    stay separated as explicit local workstreams.
  - Added failing tests first for the macOS Winetricks `verbs.txt`
    completeness contract, release metadata archive fallback narrowing, and
    malformed Flutter pinned-program payload handling.
  - Updated parent runtime completeness so macOS `winetricks` requires both
    `winetricks` and `verbs.txt`.
  - Updated macOS runtime submodule packaging so `package_winetricks()`
    generates `verbs.txt` from the pinned Winetricks script and validates that
    the catalog contains `win10`.
  - Added runtime submodule `scripts/check-winetricks-component.zsh` and wired
    it into build, promote, and artifact-smoke workflows.
  - Extended `scripts/run_macos_runtime_cli_smoke.zsh` so the public CLI smoke
    runs `list-winetricks-verbs --json` before `validate-runtime` and
    `run-winetricks`.
  - Tightened release metadata archive selection so non-archive assets are not
    selected as a fallback.
  - Tightened Flutter bottle parsing so malformed `pinnedPrograms` records
    fail parsing instead of being silently treated as an empty list.
  - Confirmed the current broken dev runtime now reports
    `stackComplete: false`, `winetricks.isInstalled: false`, and
    `verbs.txt` as a missing path through `list-runtimes --json`.
  - Confirmed `validate-runtime konyak-macos-wine --json` now exits 75 and
    reports the missing `verbs.txt` path instead of reporting the runtime as
    valid.
- Remaining:
  - A newly packaged runtime artifact still needs to be built and released
    through `runtime/konyak-macos-runtime`; the existing downloaded
    `.dart_tool` runtime was intentionally not mutated from the parent
    repository to avoid compensating for a runtime-owner artifact defect.
- Next: build/promote a new macOS runtime stack artifact from the runtime
  submodule when a runtime release is desired.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "requires the macOS Winetricks verb catalog|does not fall back to non-archive assets|reports the Konyak macOS Wine runtime"'`:
    failed before implementation, then passed after implementation.
  - `nix develop -c zsh -lc 'cd apps/konyak && flutter test test/cli/bottle_list_contract_test.dart'`:
    failed before implementation, then passed after implementation.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "Winetricks|winetricks|release metadata fetcher|install-macos-wine"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-runtimes --json | jq ".runtimes[] | select(.id == \"konyak-macos-wine\") | {isInstalled, stackComplete: .stack.isComplete, winetricks: (.stack.components[] | select(.id == \"winetricks\"))}"'`:
    passed and reported the current dev runtime as incomplete with missing
    `verbs.txt`.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart validate-runtime konyak-macos-wine --json'`:
    exited 75 and reported the missing `verbs.txt` path as expected.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/package-binary-components.zsh runtime/konyak-macos-runtime/scripts/check-winetricks-component.zsh scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc '<fixture check using scripts/check-winetricks-component.zsh>'`:
    passed for a fixture with `winetricks` plus `verbs.txt` and failed for a
    fixture missing `verbs.txt`.
  - `nix develop -c zsh -lc 'actionlint runtime/konyak-macos-runtime/.github/workflows/build-runtime.yml runtime/konyak-macos-runtime/.github/workflows/promote-runtime-candidate.yml runtime/konyak-macos-runtime/.github/workflows/smoke-runtime-artifacts.yml'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-architecture'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just flutter-format-check'`: passed.
  - `nix develop -c zsh -lc 'just flutter-analyze'`: passed.
  - `nix develop -c zsh -lc 'just flutter-test'`: passed.
  - `nix develop -c zsh -lc 'just test'`: passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check --no-build'`:
    passed.

- Timestamp: 2026-06-18 20:21 JST
- State: `paused`
- Branch: `main`
- Related work: macOS runtime Winetricks verb catalog completeness;
  `docs/todo.md` Winetricks verb support
- Purpose: investigate why the dev/runtime contract lets a macOS runtime
  contain the managed `winetricks` executable without the required `verbs.txt`
  catalog, causing Flutter's Winetricks picker to fail through
  `list-winetricks-verbs --json`.
- Completed:
  - Reproduced the screenshot failure through the public CLI route:
    `cd packages/konyak_cli && dart run bin/konyak.dart list-winetricks-verbs --json`
    returned exit 75 with `winetricksVerbsUnavailable`.
  - Confirmed the failing runtime root is
    `.dart_tool/konyak/dev-runtime/macos-wine`; it contains `winetricks` but no
    `verbs.txt`.
  - Confirmed the published
    `crossover-26.1.0-konyak.0/konyak-macos-wine-runtime-stack.tar.zst`
    artifact with SHA-256
    `a3939cef05b38a7ba33923ac8301b88c55de982a043f926bcf6f35b3f5f76844`
    contains `./winetricks` but no `verbs.txt`.
  - Confirmed `list-runtimes --json` currently reports that runtime as
    `stack.isComplete: true` and the `winetricks` component as having no
    missing paths, because parent runtime completeness only requires
    `winetricks`.
  - Confirmed the runtime submodule `package_winetricks()` copies only the
    pinned `winetricks` script into the component payload and does not generate
    a `verbs.txt` catalog.
- Remaining:
  - No code changes were made for the fix yet.
  - Add a failing contract/completeness test for the missing macOS
    `verbs.txt` catalog.
  - Update the runtime submodule winetricks component packaging so
    `verbs.txt` is produced by the runtime owner and included in the component
    archive.
  - Update parent runtime completeness fixtures/contracts to require
    `verbs.txt`.
  - Run focused CLI/runtime script checks, then the required repository gates.
- Next: wait for approval to implement; start by adding the failing test before
  changing runtime packaging or parent completeness contracts.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-winetricks-verbs --json; printf "exit=%s\n" "$?"'`:
    reproduced the failure; stdout contained
    `Managed Winetricks verb catalog is missing from runtime:
    /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine/verbs.txt`,
    and the command exited 75.
  - `nix develop -c zsh -lc 'find .dart_tool/konyak/dev-runtime/macos-wine -maxdepth 3 \( -name "verbs.txt" -o -name "winetricks" -o -name "*winetricks*" \) -print'`:
    found only `.dart_tool/konyak/dev-runtime/macos-wine/winetricks`.
  - `nix develop -c zsh -lc 'curl --fail --location --retry 3 --retry-delay 5 --output .dart_tool/winetricks-archive-inspect/konyak-macos-wine-runtime-stack.tar.zst https://github.com/serika12345/konyak-macos-runtime/releases/download/crossover-26.1.0-konyak.0/konyak-macos-wine-runtime-stack.tar.zst; shasum -a 256 .dart_tool/winetricks-archive-inspect/konyak-macos-wine-runtime-stack.tar.zst; tar -tf .dart_tool/winetricks-archive-inspect/konyak-macos-wine-runtime-stack.tar.zst | rg "(^|/)(winetricks|verbs\.txt)$" || true'`:
    passed; the archive hash was
    `a3939cef05b38a7ba33923ac8301b88c55de982a043f926bcf6f35b3f5f76844`, and
    only `./winetricks` was listed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart run bin/konyak.dart list-runtimes --json | jq ".runtimes[] | select(.id == \"konyak-macos-wine\") | {isInstalled, stack: {isComplete: .stack.isComplete, winetricks: (.stack.components[] | select(.id == \"winetricks\"))}}"'`:
    passed; it reported `stack.isComplete: true`, `winetricks.isInstalled:
    true`, and `missingPaths: []` despite the missing verb catalog.

- Timestamp: 2026-06-18 19:17 JST
- State: `completed`
- Branch: `main`
- Related work: macOS GPTK/D3DMetal local smoke;
  `runtime/konyak-macos-runtime/TODO.dxmt-runtime.md` GPTK smoke;
  `docs/todo.md` macOS runtime automated smoke coverage
- Purpose: add a `nix run` entry point that reproduces the GPTK/D3DMetal
  local smoke path without mutating the supplied runtime root or placing the
  Gcenx payload in Konyak release artifacts.
- Completed:
  - Added runtime submodule script
    `scripts/smoke-gptk-d3dmetal-local.zsh`.
  - Added flake app/package `gptk-d3dmetal-local-smoke`, runnable as
    `nix run .#gptk-d3dmetal-local-smoke -- <runtime-root-or-stack-archive>`.
  - The local app accepts either an assembled runtime root or
    `konyak-macos-wine-runtime-stack.tar.zst`, verifies stack archives exclude
    GPTK payloads, copies/extracts the runtime into a work directory, downloads
    the pinned Gcenx GPTK archive into that transient work directory, imports
    it only into the copied runtime, and runs both `gptk-d3d11-device` and
    `gptk-d3d12-device`.
  - Updated runtime README usage notes and runtime TODO state.
  - Created runtime submodule commit
    `d427bd9f30fe7c2dd7dfb83f8e8cf9c58337a412`.
- Remaining:
  - The app still depends on the pinned external Gcenx release asset remaining
    available and SHA-stable.
  - `--allow-unsupported-host` exists only for reproducing hosted-runner GPU
    behavior; normal local runs should leave it unset so D3DMetal device
    creation is actually proven.
- Next: no open action remains for this local smoke entry point.
- Verification:
  - `nix develop -c zsh -lc 'nix run .#gptk-d3dmetal-local-smoke -- --help'`:
    failed before implementation because the flake did not expose the app.
  - `nix develop -c zsh -lc 'nix run .#gptk-d3dmetal-local-smoke -- --help'`:
    passed after implementation.
  - `nix develop -c zsh -lc 'zsh -n scripts/smoke-gptk-d3dmetal-local.zsh && nixfmt --check flake.nix && nix eval .#apps.aarch64-darwin.gptk-d3dmetal-local-smoke.type'`:
    passed.
  - `nix develop -c zsh -lc 'zsh -n scripts/smoke-gptk-d3dmetal-local.zsh && nixfmt --check flake.nix && if nix run .#gptk-d3dmetal-local-smoke -- --work-root dist/gptk README.md; then exit 1; fi'`:
    passed by rejecting a `dist/` work-root for transient GPTK payload files.
  - `nix develop -c zsh -lc 'nix flake check -L --show-trace'`: passed in the
    runtime submodule.
  - `nix develop -c zsh -lc 'curl --fail --location --retry 3 --retry-delay 5 --output .dart_tool/local-smoke-input/konyak-macos-wine-runtime-stack.tar.zst https://github.com/serika12345/konyak-macos-runtime/releases/download/crossover-26.1.0-konyak.0/konyak-macos-wine-runtime-stack.tar.zst; shasum -a 256 .dart_tool/local-smoke-input/konyak-macos-wine-runtime-stack.tar.zst'`:
    passed; SHA-256 was
    `a3939cef05b38a7ba33923ac8301b88c55de982a043f926bcf6f35b3f5f76844`.
  - `nix develop -c zsh -lc 'nix run .#gptk-d3dmetal-local-smoke -- --work-root .dart_tool/gptk-d3dmetal-local-smoke .dart_tool/local-smoke-input/konyak-macos-wine-runtime-stack.tar.zst'`:
    passed; the app imported the CI-only Gcenx payload into the copied runtime
    and both `Backend smoke OK: gptk-d3d11-device` and
    `Backend smoke OK: gptk-d3d12-device` were observed.
  - `nix develop -c zsh -lc 'git diff --check && just verify-governance'`:
    passed in the parent repo.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-18 18:38 JST
- State: `completed`
- Branch: `main`
- Related work: macOS GPTK/D3DMetal CI smoke using Gcenx Game Porting Toolkit
  release; `runtime/konyak-macos-runtime/TODO.dxmt-runtime.md` GPTK smoke;
  `docs/todo.md` macOS runtime automated smoke coverage
- Purpose: publish refreshed macOS runtime artifacts with Konyak's
  GPTK/D3DMetal loader shim and add CI coverage for the GPTK/D3DMetal
  D3D11/D3D12 path using a pinned external Gcenx release asset while keeping
  Apple/Gcenx GPTK payloads out of Konyak runtime distribution artifacts.
- Completed:
  - Added runtime submodule CI helper
    `scripts/prepare-gptk-d3dmetal-ci-smoke.zsh` to download the pinned
    `Game-Porting-Toolkit-3.0-3` release asset, verify SHA-256
    `d377683937340f914823dbb2e1252b329cbf834ff58907d0293db8cebf0e392e`,
    locate `Game Porting Toolkit.app/Contents/Resources/wine/lib`, verify the
    D3DMetal license resource exists, and import it only into an unpacked smoke
    runtime.
  - Added `scripts/check-runtime-archive-excludes-gptk.zsh` and wired it into
    runtime stack assembly, candidate staging, candidate promotion, and
    artifact smoke paths so Konyak archives reject `components/gptk-d3dmetal`,
    legacy `lib/external/D3DMetal.framework` or `libd3dshared.dylib`, and common
    GPTK overlay files under base `lib/wine/x86_64-*`.
  - Added `smoke-gptk-d3dmetal` jobs to `build-runtime.yml` and
    `promote-runtime-candidate.yml`; both jobs download only the assembled
    Konyak runtime stack artifact, verify it excludes GPTK, import the pinned
    Gcenx payload into the temporary smoke runtime under runner-local storage,
    and run `gptk-d3d11-device` plus `gptk-d3d12-device`.
  - Split manual `smoke-runtime-artifacts.yml` GPTK verification into a
    separate rerunnable job rather than appending it to the existing combined
    smoke job.
  - Tightened candidate source-manifest validation so component IDs must match
    the approved macOS runtime component set exactly, preventing hidden
    `gptk-d3dmetal` manifest entries.
  - Updated runtime docs and TODOs to record that GPTK/D3DMetal is a CI-only
    transient external smoke input, not a shipped Konyak component. The docs now
    call out that maintainers running the CI path are responsible for complying
    with the Apple D3DMetal/GPTK license terms referenced by the Gcenx release.
  - Pushed runtime submodule commit
    `da5c97fae955c414de180fa42be570263bd1453c`, including CI fixes for hosted
    runner GPTK unsupported-GPU detection inside the runtime Nix shell.
  - GitHub Actions runtime run `27748147073` completed successfully and
    republished `crossover-26.1.0-konyak.0`.
  - The published release assets are:
    `konyak-macos-runtime.release.json`
    (`sha256:455a03c9a787686d334239d01ddd5568118c4c5091a728371fe096f9a4500516`),
    `konyak-macos-wine-runtime-stack-source.json`
    (`sha256:10b92bdcebe620fe3636cd1c4b84db5c292cb85111aec112e91aa6f765154698`),
    and `konyak-macos-wine-runtime-stack.tar.zst`
    (`sha256:a3939cef05b38a7ba33923ac8301b88c55de982a043f926bcf6f35b3f5f76844`).
  - Confirmed the release asset list contains only Konyak runtime stack and
    metadata assets. GPTK/D3DMetal files remain transient CI smoke inputs and
    are not attached to the runtime release.
- Remaining:
  - Hosted GitHub macOS runners expose an Apple Paravirtual GPU that D3DMetal
    rejects, so CI proves the loader/import path and expected hosted-runner
    unsupported-GPU signature for GPTK D3D11/D3D12, not actual D3DMetal device
    creation.
  - CI still depends on the pinned external Gcenx release asset remaining
    available and SHA-stable.
- Next: no open action remains for this artifact publication and CI run. Actual
  GPTK/D3DMetal device creation remains a local Apple Silicon smoke because the
  hosted runner GPU is unsupported.
- Verification:
  - `nix develop -c zsh -lc 'curl -sL https://api.github.com/repos/Gcenx/game-porting-toolkit/releases/latest | jq "{tag_name, name, html_url, published_at, assets: [.assets[] | {name, size, browser_download_url, content_type}] }"'`:
    passed; latest release was `Game-Porting-Toolkit-3.0-3` with asset
    `game-porting-toolkit-3.0-3.tar.xz`.
  - `nix develop -c zsh -lc 'archive=.dart_tool/gcenx-gptk-release-inspect/game-porting-toolkit-3.0-3.tar.xz; curl -fL --retry 3 --retry-delay 5 -o "$archive" https://github.com/Gcenx/game-porting-toolkit/releases/download/Game-Porting-Toolkit-3.0-3/game-porting-toolkit-3.0-3.tar.xz; shasum -a 256 "$archive"; tar -tf "$archive"'`:
    passed; SHA-256 was
    `d377683937340f914823dbb2e1252b329cbf834ff58907d0293db8cebf0e392e`, and
    the archive contained `Game Porting Toolkit.app/Contents/Resources/wine/lib`.
  - `nix develop -c zsh -lc './scripts/prepare-gptk-d3dmetal-ci-smoke.zsh <minimal-runtime-layout> <work-root>'`:
    passed; the helper imported the Gcenx payload into
    `components/gptk-d3dmetal` and preserved the D3DMetal symlinks.
  - `nix develop -c zsh -lc './scripts/check-runtime-archive-excludes-gptk.zsh <clean-fixture.tar.zst>'`:
    passed.
  - `nix develop -c zsh -lc 'if ./scripts/check-runtime-archive-excludes-gptk.zsh <fixture-with-components/gptk-d3dmetal.tar.zst>; then exit 1; fi'`:
    passed by rejecting the intentionally contaminated fixture.
  - CI-equivalent local dynamic smoke against a temporary stack assembled from
    rebuilt Wine output plus existing component archives:
    `check-runtime-archive-excludes-gptk`, `check-wine32on64-runtime`,
    `check-dxmt-component`, `check-vkd3d-component`, `check-dxvk-component`,
    `check-gstreamer-component`, `check-wine-addons-component`, Gcenx GPTK
    import, `smoke-backend-device.zsh gptk-d3d11-device`, and
    `smoke-backend-device.zsh gptk-d3d12-device`: passed.
  - `nix develop -c zsh -lc 'zsh -n scripts/prepare-gptk-d3dmetal-ci-smoke.zsh scripts/check-runtime-archive-excludes-gptk.zsh scripts/import-gptk-d3dmetal-redist.zsh scripts/stage-runtime-release-candidate.zsh scripts/smoke-backend-device.zsh scripts/check-wine32on64-runtime.zsh scripts/build-runtime.zsh scripts/assemble-runtime-stack.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml .github/workflows/promote-runtime-candidate.yml .github/workflows/smoke-runtime-artifacts.yml'`:
    passed.
  - `nix develop -c zsh -lc './scripts/stage-runtime-release-candidate.zsh --dry-run candidate-gptk-ci-smoke-test dist'`:
    passed.
  - Independent audit sub-agent for the Gcenx CI wiring: initially found the
    candidate promotion inline GPTK exclusion check weaker than the shared
    checker and manifest validation accepting scalar extra entries; both were
    fixed before completion.
  - `nix develop -c zsh -lc 'zsh -n scripts/stage-runtime-release-candidate.zsh scripts/check-runtime-archive-excludes-gptk.zsh scripts/prepare-gptk-d3dmetal-ci-smoke.zsh && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml .github/workflows/promote-runtime-candidate.yml .github/workflows/smoke-runtime-artifacts.yml'`:
    passed after the audit fixes.
  - `nix develop -c zsh -lc 'if ./scripts/check-runtime-archive-excludes-gptk.zsh <fixture-with-lib/wine/x86_64-unix/nvngx.so.tar.zst>; then exit 1; fi'`:
    passed by rejecting the intentionally contaminated root overlay fixture.
  - `nix develop -c zsh -lc 'if ./scripts/stage-runtime-release-candidate.zsh --dry-run candidate-gptk-negative <manifest-with-extra-scalar-component>; then exit 1; fi'`:
    passed by rejecting the invalid scalar component entry.
  - `nix develop -c zsh -lc 'git diff --check'`: passed in the parent repo.
  - `nix develop -c zsh -lc 'git diff --check && git diff --cached --check'`:
    passed in the runtime submodule.
  - `nix develop -c zsh -lc 'zsh -n scripts/smoke-backend-device.zsh scripts/prepare-gptk-d3dmetal-ci-smoke.zsh scripts/check-runtime-archive-excludes-gptk.zsh'`:
    passed after making backend smoke log checks independent of external
    `grep`.
  - `nix develop -c zsh -lc 'nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml .github/workflows/promote-runtime-candidate.yml .github/workflows/smoke-runtime-artifacts.yml'`:
    passed after the final CI smoke-script fix.
  - Runtime GitHub Actions run `27748147073`:
    passed; validate, binary component packaging, Wine runtime build, vkd3d,
    DXMT, runtime assembly, release metadata, GUI `/unix` smoke, vkd3d, DXVK,
    DXMT, GPTK/D3DMetal, Wine32-on-64, and publish-release jobs all succeeded.
  - GPTK/D3DMetal job `82096511842` log audit:
    passed; the job prepared the CI-only
    `Game-Porting-Toolkit-3.0-3` payload, then both `gptk-d3d11-device` and
    `gptk-d3d12-device` reached the expected hosted-runner unsupported-GPU
    signature.
  - `nix develop -c zsh -lc 'gh release view crossover-26.1.0-konyak.0 --repo serika12345/konyak-macos-runtime --json tagName,name,isDraft,isPrerelease,url,assets'`:
    passed; the release is published and contains only the runtime release
    metadata, source manifest, and runtime stack archive listed above.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-18 12:29 JST
- State: `completed`
- Branch: `main`
- Related work: macOS GPTK/D3DMetal loader shim;
  `runtime/konyak-macos-runtime/TODO.dxmt-runtime.md` GPTK local/manual smoke;
  `docs/todo.md` macOS runtime automated smoke coverage
- Purpose: make GPTK/D3DMetal D3D11 work without CrossOver's proprietary
  `cxcompatdb.so` by shipping a Konyak-owned minimal loader shim that uses only
  public CrossOver Wine `ntdll` exports.
- Completed:
  - Added `shims/cxcompatdb/cxcompatdb.c` in the runtime submodule. The shim is
    loaded as `lib/wine/x86_64-unix/cxcompatdb.so`, derives the user-imported
    GPTK Wine root from `CX_APPLEGPTK_LIBD3DSHARED_PATH`, applies the native
    D3DMetal load order, sets `CX_ACTIVE_GRAPHICS_BACKEND=d3dmetal`, and keeps
    the prepended path alive for process lifetime because Wine stores the
    pointer directly.
  - Integrated the shim into the x86_64 Darwin Wine runtime Nix build, linking
    it to `@rpath/ntdll.so` and verifying the expected Mach-O dependency during
    installation.
  - Strengthened the Wine32-on-64 runtime layout check to require the shim,
    x86_64 Mach-O identity, `@loader_path/` rpath, and `@rpath/ntdll.so`
    dependency.
  - Extended the backend smoke runner with local/manual
    `gptk-d3d11-device` and `gptk-d3d12`/`gptk-d3d12-device` targets that use
    the user-imported `components/gptk-d3dmetal` payload.
  - Copied only the rebuilt shim into
    `.dart_tool/konyak/dev-runtime/macos-wine` for dynamic verification so the
    existing user-imported GPTK component was preserved.
- Remaining:
  - GPTK/D3DMetal smoke remains local/manual because the GPTK payload is
    user-provided and not redistributed by this repository.
  - Release archives were not regenerated or promoted in this scope.
- Next: regenerate and promote macOS runtime release artifacts only when this
  shim should be published to the hosted runtime channel.
- Verification:
  - `nix develop -c zsh -lc './scripts/check-wine32on64-runtime.zsh /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine'`:
    failed before implementation because `lib/wine/x86_64-unix/cxcompatdb.so`
    was missing, proving the new layout check.
  - `nix develop -c zsh -lc './scripts/smoke-backend-device.zsh /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine gptk-d3d11-device .dart_tool/pre-shim-probes'`:
    failed before implementation because the GPTK smoke required the missing
    base-runtime shim.
  - `nix develop -c zsh -lc 'zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-backend-device.zsh scripts/build-runtime.zsh scripts/assemble-runtime-stack.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'nix eval .#packages.x86_64-darwin.konyak-macos-wine-runtime.name'`:
    passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.
  - `nix develop -c zsh -lc 'git diff --cached --check'`: passed.
  - `nix develop -c zsh -lc 'nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --show-trace --out-link result-cxcompatdb-shim'`:
    passed.
  - `nix develop -c zsh -lc '/usr/bin/file result-cxcompatdb-shim/lib/wine/x86_64-unix/cxcompatdb.so && otool -L result-cxcompatdb-shim/lib/wine/x86_64-unix/cxcompatdb.so && otool -l result-cxcompatdb-shim/lib/wine/x86_64-unix/cxcompatdb.so | awk "/LC_RPATH/ { getline; getline; print $2 }"'`:
    passed; the shim is x86_64 Mach-O, depends on `@rpath/ntdll.so`, and has
    `@loader_path/` in its rpath list.
  - `nix develop -c zsh -lc './scripts/check-wine32on64-runtime.zsh result-cxcompatdb-shim'`:
    passed.
  - `nix develop -c zsh -lc 'install -m 755 result-cxcompatdb-shim/lib/wine/x86_64-unix/cxcompatdb.so /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine/lib/wine/x86_64-unix/cxcompatdb.so'`:
    passed; this updated only the local dev runtime shim for smoke verification.
  - `nix develop -c zsh -lc './scripts/smoke-backend-device.zsh /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine gptk-d3d11-device .dart_tool/gptk-cxcompat-probes'`:
    passed with `Backend smoke OK: gptk-d3d11-device`.
  - `nix develop -c zsh -lc './scripts/smoke-backend-device.zsh /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine gptk-d3d12 .dart_tool/gptk-cxcompat-probes'`:
    passed with `Backend smoke OK: gptk-d3d12`.
  - Independent audit sub-agent: passed; no blocking findings. The audit
    confirmed the shim uses only public `ntdll` exports, does not copy or
    implement proprietary CrossOver `cxcompatdb.so` behavior, and matches the
    documented GPTK component layout.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-17 19:06 JST
- State: `completed`
- Branch: `main`
- Related work: macOS bottle prefix bootstrap; Wine Mono installer suppression
- Purpose: prevent user bottle creation from showing or leaving Wine Mono
  Installer by installing the bundled Wine Mono MSI silently before
  `wineboot --init`.
- Completed:
  - Added a macOS prefix bootstrap plan that runs
    `wineloader msiexec /i Z:\...\wine-mono-10.4.1-x86.msi /qn /norestart`
    before the existing `wineloader wineboot --init` request.
  - Kept the existing single `planPrefixInitialization` request contract while
    switching `DartIoBottlePrefixInitializer` to execute the new bootstrap
    request sequence.
  - Added CLI contract coverage for the Mono install request, the retained
    `wineboot` request, and sequential prefix initializer execution.
  - Dynamically verified the command ordering through the public CLI
    `create-bottle --json` path against
    `.dart_tool/konyak/dev-runtime/macos-wine`; the generated prefix contained
    `drive_c/windows/mono/mono-2.0/bin/libmono-2.0-x86.dll` and
    `libmono-2.0-x86_64.dll`, and `CGWindowList` reported no Wine Mono
    Installer windows.
- Remaining:
  - No known blocker for the Wine Mono installer popup path.
- Next: none.
- Verification:
  - Low-level diagnostic:
    `wineloader msiexec /i Z:\...\wine-mono-10.4.1-x86.msi /qn /norestart`
    followed by `wineloader wineboot --init` on a fresh temporary prefix:
    passed; both commands exited 0 and Mono files were installed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart -n "macOS prefix bootstrap silently installs Wine Mono before wineboot|bottle prefix initializer runs bootstrap requests in order"'`:
    passed.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/domain/program/program_runner.dart packages/konyak_cli/lib/src/platform/macos/macos_program_run_requests.dart packages/konyak_cli/lib/src/io/program_discovery.dart packages/konyak_cli/test/cli_contract_program_execution.part.dart && cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - Public CLI dynamic smoke:
    `KONYAK_RUNTIME_PROFILE=development KONYAK_MACOS_WINE_HOME=/Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine dart run packages/konyak_cli/bin/konyak.dart create-bottle --name "Mono Quiet Smoke" --json`:
    passed; `wine-mono-install.log` and `prefix-init.log` showed the expected
    argv, Mono DLLs existed in the prefix, and a Swift `CGWindowList` probe
    returned `mono_installer_windows=0`.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.

- Timestamp: 2026-06-17 18:07 JST
- State: `completed`
- Branch: `main`
- Related work: remote macOS runtime release artifact promotion
- Purpose: publish the locally verified hosted Wine launcher activation runtime
  refresh to the final GitHub release assets.
- Completed:
  - Staged local `dist/` as draft/prerelease candidate
    `candidate-20260617175149-hosted-launcher-identity`.
  - Dispatched `Promote runtime candidate` run `27677358486` with
    `delete_candidate=true`.
  - GitHub Actions normalized the source manifest, ran Wine32-on-64, GUI
    `start /unix`, DXVK D3D11, DXMT D3D11, and vkd3d D3D12 smoke gates, then
    published the verified final release assets.
  - Confirmed the candidate release was deleted after promotion.
  - Confirmed final release `crossover-26.1.0-konyak.0` now ships
    `konyak-macos-wine-runtime-stack.tar.zst`
    `sha256:cf4146de728cf152cbdd144d5c1bf7c21b6aa0428d05d1b8b52538cf423df825`,
    `konyak-macos-wine-runtime-stack-source.json`
    `sha256:79f27f7e1dd0c56baa667480739dbdbd02aaa6fc0bfb9558ac8d47c830beffe5`,
    and `konyak-macos-runtime.release.json`
    `sha256:455a03c9a787686d334239d01ddd5568118c4c5091a728371fe096f9a4500516`.
- Remaining:
  - None for remote artifact promotion.
- Next: none.
- Verification:
  - `scripts/stage-runtime-release-candidate.zsh --dry-run candidate-20260617175149-hosted-launcher-identity dist`:
    passed.
  - `gh run watch 27677358486 --repo serika12345/konyak-macos-runtime --exit-status --interval 30`:
    passed.
  - `gh release view crossover-26.1.0-konyak.0 --repo serika12345/konyak-macos-runtime --json tagName,name,isDraft,isPrerelease,url,assets`:
    passed and showed the final release is non-draft/non-prerelease with the
    expected updated asset digests.
  - `gh release view candidate-20260617175149-hosted-launcher-identity --repo serika12345/konyak-macos-runtime`:
    failed with `release not found`, confirming candidate cleanup.

- Timestamp: 2026-06-17 17:25 JST
- State: `completed`
- Branch: `main`
- Related work: hosted Wine launcher Info.plist binding; development runtime
  refresh; GUI frontmost smoke correction
- Purpose: fix the remaining macOS Wine activation regression in the runtime
  actually consumed by Konyak, and replace the local `.dart_tool` development
  runtime with the rebuilt stack.
- Completed:
  - Audited the previous runtime refresh and found that the real Konyak
    entrypoints, `bin/wine` and `bin/wineloader`, are copied from
    `tools/wine`, not only from `loader/wine`.
  - Updated the CrossOver Wine derivation so `tools/wine/Makefile.in` embeds the
    same Konyak-owned `loader/wine_info.plist` into those hosted launchers, keeps
    CrossOver's `LSUIElement=1` startup policy, and preserves the existing
    in-process `SetFrontProcessWithOptions` activation fallback.
  - Moved gettext to native build inputs and set `dontAddExtraLibs = true` so
    Darwin gettext/libiconv setup hooks do not leak `-lintl` into mingw PE DLL
    links.
  - Strengthened `check-wine32on64-runtime.zsh` to validate every host loader
    and ntdll candidate, including `bin/wine` and `bin/wineloader`, for bound
    Info.plist identity, `LSUIElement`, signing, entitlements, system-only
    loader dependencies, and absence of the CrossOver temp-loader rename.
  - Corrected `smoke-gui-launch.zsh` so the active-window poll does not stop
    when `wine start /unix` exits; that command can return while the Windows GUI
    child process is still alive.
  - Rebuilt the Wine runtime and regenerated local runtime artifacts:
    `konyak-macos-wine-runtime.tar.zst`
    `sha256:4727cabd30d0eb6e31af697f5e3d4c58e29568a345403a82debf0afa030085b5`,
    `konyak-macos-wine-runtime-stack.tar.zst`
    `sha256:cf4146de728cf152cbdd144d5c1bf7c21b6aa0428d05d1b8b52538cf423df825`,
    and `konyak-macos-wine-runtime-stack-source.json`
    `sha256:79f27f7e1dd0c56baa667480739dbdbd02aaa6fc0bfb9558ac8d47c830beffe5`.
  - Refreshed `.dart_tool/konyak/dev-runtime/macos-wine` from the rebuilt stack
    with `rsync --checksum --delete`; plain `rsync -a` was insufficient because
    reproducible mtimes and equal sizes allowed an old host loader to be skipped.
  - Re-copied the development source manifest to
    `.dart_tool/konyak/dev-runtime-source/macos-wine-stack/` and re-imported
    GPTK/D3DMetal from `/Users/masato/Documents/CrossOver.app`.
  - Committed runtime submodule commit `1f3f553` (`Bind hosted Wine launcher
    activation identity`).
- Remaining:
  - No blocker remains for this local runtime refresh. Public release promotion
    is still a separate release-management step.
- Next: promote the refreshed runtime artifacts through the release pipeline when
  this local fix is accepted.
- Verification:
  - `nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --show-trace --out-link result-wine-runtime-release-refresh`:
    passed; output `/nix/store/kmjd05m3wjy0f1gnpljbamxm0p1b3vsh-konyak-macos-wine-runtime-crossover-26.1.0-konyak.0`.
  - `scripts/check-wine32on64-runtime.zsh result-wine-runtime-release-refresh`:
    passed.
  - `scripts/check-wine32on64-runtime.zsh /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine`:
    passed.
  - `KONYAK_GUI_LAUNCH_SMOKE_TIMEOUT_SECONDS=90 KONYAK_GUI_LAUNCH_SMOKE_WINESERVER_WAIT_TIMEOUT_SECONDS=10 KONYAK_GUI_LAUNCH_PROBE_HOLD_MS=30000 scripts/smoke-gui-launch.zsh /Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine .dart_tool/backend-probes-activation`:
    passed; the smoke now requires the Wine GUI probe window to become
    frontmost.
  - `nix develop -c zsh -lc 'KONYAK_MACOS_WINE_HOME=/Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine dart run packages/konyak_cli/bin/konyak.dart validate-runtime konyak-macos-wine --json'`:
    passed; all required runtime checks were true.
  - `nix develop -c zsh -lc 'KONYAK_RUNTIME_PROFILE=development KONYAK_MACOS_WINE_HOME=/Users/masato/Documents/Konyak/.dart_tool/konyak/dev-runtime/macos-wine dart run packages/konyak_cli/bin/konyak.dart list-runtimes --json'`:
    passed; DXVK-macOS, DXMT, GPTK/D3DMetal, and vkd3d were all available with
    no missing paths.
  - `cmp -s runtime/konyak-macos-runtime/dist/konyak-macos-wine-runtime-stack-source.json .dart_tool/konyak/dev-runtime-source/macos-wine-stack/konyak-macos-wine-runtime-stack-source.json`:
    passed.
  - `nix eval .#packages.x86_64-darwin.konyak-macos-wine-runtime.name`,
    `zsh -n scripts/check-wine32on64-runtime.zsh scripts/smoke-gui-launch.zsh`,
    and `git diff --check` in the runtime submodule: passed.

- Timestamp: 2026-06-16 21:00 JST
- State: `completed`
- Branch: `main`
- Related work: refreshed macOS runtime release artifacts after activation
  identity fix; DXMT sidecar smoke regression
- Purpose: reflect the activation identity fix into release artifacts and keep
  DXVK, DXMT, and vkd3d smoke coverage passing before promotion.
- Completed:
  - Updated the user-facing investigation Markdown outputs with the final
    dynamic root cause: CrossOver's `WINEDLLPATH` temp loader rename, not the
    drawing backends themselves.
  - Rebuilt the x86_64 Wine runtime from submodule commit `95ded19` and
    recreated `dist/konyak-macos-wine-runtime.tar.zst`.
  - Reassembled `dist/konyak-macos-wine-runtime-stack.tar.zst` and regenerated
    `dist/konyak-macos-wine-runtime-stack-source.json` and
    `dist/konyak-macos-runtime.release.json`.
  - While verifying the refreshed stack, found a separate DXMT artifact defect:
    `winemetal.dll` loaded successfully but Wine searched for the Unix sidecar
    at `lib/dxmt/x86_64-windows/winemetal.so`; the artifact only shipped
    `lib/dxmt/x86_64-unix/winemetal.so`, causing `LoadLibraryA(d3d11.dll)` to
    fail with Win32 error `1114`.
  - Updated the DXMT derivation to mirror the rewritten `winemetal.so` closure
    into `x86_64-windows`, and strengthened `check-dxmt-component.zsh` plus
    `smoke-backend-device.zsh` to require and diagnose that sidecar path.
  - Rebuilt the DXMT component with the local Metal toolchain, recreated
    `dist/konyak-macos-dxmt.tar.zst`, reassembled the runtime stack, and
    regenerated release metadata.
  - Committed and pushed runtime submodule commit `c35feb5` and parent commit
    `bd0c41e`.
  - Staged `candidate-20260616-activation-identity`, promoted it through
    GitHub Actions run `27607837566`, and deleted the candidate release.
  - Confirmed the final public release `crossover-26.1.0-konyak.0` now ships
    `konyak-macos-wine-runtime-stack.tar.zst` with
    `sha256:086ab2438f9d9b53e9288e384c9bc04d6ca74ec32b27f81b8275723c064d6c9f`.
  - Refreshed the local development runtime from the public release source
    manifest, then imported GPTK/D3DMetal from
    `/Users/masato/Documents/CrossOver.app`.
  - Confirmed `list-runtimes --json` reports DXVK, DXMT, GPTK/D3DMetal, and
    vkd3d backends all available in the development runtime.
- Remaining:
  - No blocker remains for this scope. GPTK/D3DMetal is connected as the
    existing user-imported optional component, not redistributed in the public
    runtime stack.
- Next: if D3DMetal needs runtime execution coverage beyond availability, add
  or run a dedicated local/manual GPTK D3DMetal smoke workflow with a suitable
  probe executable.
- Verification:
  - `nix develop -c zsh -lc 'nix build ./runtime/konyak-macos-runtime#packages.x86_64-darwin.konyak-macos-wine-runtime --out-link result-wine-runtime-x86_64'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT=/Users/masato/Documents/Konyak/result-wine-runtime-x86_64 KONYAK_METAL_TOOLCHAIN_BIN="$(dirname "$(/usr/bin/xcrun -sdk macosx -find metal)")" nix build --impure .#packages.x86_64-darwin.konyak-macos-dxmt --out-link result-dxmt'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-dxmt-component.zsh result-dxmt'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-wine32on64-runtime.zsh result-runtime-stack && ./scripts/check-dxmt-component.zsh result-runtime-stack && ./scripts/check-vkd3d-component.zsh result-runtime-stack && ./scripts/check-dxvk-component.zsh result-runtime-stack && ./scripts/check-gstreamer-component.zsh result-runtime-stack && ./scripts/check-wine-addons-component.zsh result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/stage-runtime-release-candidate.zsh --dry-run candidate-20260616-activation-identity dist'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-wine32on64-launch.zsh result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-gui-launch.zsh result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-backend-device.zsh result-runtime-stack dxvk-d3d11 && ./scripts/smoke-backend-device.zsh result-runtime-stack dxmt-d3d11 && ./scripts/smoke-backend-device.zsh result-runtime-stack vkd3d-d3d12'`:
    passed.
  - GitHub Actions run `27607837566`: passed normalize, Wine32-on-64 launch
    smoke, GUI `/unix` smoke, DXVK D3D11 backend smoke, DXMT D3D11 backend
    smoke, vkd3d D3D12 backend smoke, and release publishing.
  - Final release assets:
    `konyak-macos-runtime.release.json`
    `sha256:455a03c9a787686d334239d01ddd5568118c4c5091a728371fe096f9a4500516`,
    `konyak-macos-wine-runtime-stack-source.json`
    `sha256:ac9d1671b1b50aed04568d8f2b2e12548c687cdf5babe1e550a87b386661b2a1`,
    and `konyak-macos-wine-runtime-stack.tar.zst`
    `sha256:086ab2438f9d9b53e9288e384c9bc04d6ca74ec32b27f81b8275723c064d6c9f`.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development KONYAK_MACOS_WINE_HOME="$runtime_path" KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$manifest_path" dart run bin/konyak.dart install-macos-wine --reinstall --source-manifest "$manifest_path" --json'`:
    passed; final JSON reported `isInstalled: true`, stack `isComplete: true`,
    and DXMT with no missing paths including `x86_64-windows/winemetal.so`.
  - `nix develop -c zsh -lc 'runtime_path="$(./scripts/prepare_macos_dev_runtime_stack.zsh --print-runtime-path)" && runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh "$runtime_path" && runtime/konyak-macos-runtime/scripts/check-dxmt-component.zsh "$runtime_path" && runtime/konyak-macos-runtime/scripts/check-vkd3d-component.zsh "$runtime_path" && runtime/konyak-macos-runtime/scripts/check-dxvk-component.zsh "$runtime_path" && runtime/konyak-macos-runtime/scripts/check-gstreamer-component.zsh "$runtime_path" && runtime/konyak-macos-runtime/scripts/check-wine-addons-component.zsh "$runtime_path"'`:
    passed.
  - `nix develop -c zsh -lc 'runtime_path="$(./scripts/prepare_macos_dev_runtime_stack.zsh --print-runtime-path)" && runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh "$runtime_path" && runtime/konyak-macos-runtime/scripts/smoke-gui-launch.zsh "$runtime_path" && runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh "$runtime_path" dxvk-d3d11 && runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh "$runtime_path" dxmt-d3d11 && runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh "$runtime_path" vkd3d-d3d12'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development KONYAK_MACOS_WINE_HOME="$runtime_path" dart run bin/konyak.dart install-gptk-wine --from /Users/masato/Documents/CrossOver.app --json'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development KONYAK_MACOS_WINE_HOME="$runtime_path" dart run bin/konyak.dart list-runtimes --json'`:
    passed; DXVK, DXMT, GPTK/D3DMetal, and vkd3d backends were all available
    with no missing paths.

- Timestamp: 2026-06-16 14:46 JST
- State: `completed`
- Branch: `main`
- Related work: macOS CrossOver Wine activation identity regression;
  `WINEDLLPATH` temp loader rewrite; runtime artifact audit
- Purpose: fix the Konyak-specific macOS Wine focus/input regression where
  Windows GUI processes launched with `WINEDLLPATH` were registered by macOS as
  temporary unbundled Windows-exe pseudo-apps instead of the Konyak Wine loader.
- Completed:
  - Dynamically reproduced the failure through the public Konyak CLI path with
    `WINEDLLPATH` set, using Ardour setup as the GUI probe. `CGWindowList` and
    `NSRunningApplication` showed the Wine window owned by
    `$TMPDIR/winetemp-.../Ardour-9.5.0-w64-Setup.exe`, and activation did not
    make that process frontmost.
  - Compared direct CrossOver hosted-app execution and confirmed that simply
    launching CrossOver's hosted `wineloader` from CLI is not the standalone
    launch contract Konyak can rely on.
  - Patched the runtime submodule CrossOver Wine derivation to disable only the
    `WINEDLLPATH`-triggered temp loader hard-link rewrite in
    `dlls/ntdll/unix/loader.c`, while preserving `WINEDLLPATH` for DXVK, DXMT,
    D3DMetal, vkd3d, and Wine DLL resolution.
  - Rewrote the embedded Wine loader identity to Konyak-owned bundle/name
    strings, moved runtime entrypoint signing to `postFixup`, and signed the
    hosted entrypoints plus Unix host loaders with hardened runtime
    entitlements.
  - Strengthened `check-wine32on64-runtime.zsh` to reject linker-signed
    entrypoints, require Konyak signing identifiers, require Wine entitlements,
    require the host loader's bound Info.plist identity, reject CrossOver
    application identity strings, and reject the `winetemp` temp-loader strings
    in host `ntdll.so`.
  - Updated the parent macOS runtime completeness contract and CLI fixtures so
    a Wine component must include the hosted entrypoints and Unix host loader,
    not just `bin/wineloader` and `bin/wineserver`.
  - Rebuilt and assembled the local x86_64 runtime stack. A follow-up dynamic
    Konyak CLI run with `WINEDLLPATH` still set showed the Ardour setup process
    registered as `wine`, with `bundleURL` and `executableURL` pointing at
    `work/runtime-stack-test/lib/wine/x86_64-unix/wine`; `lsof` showed no
    `winetemp` loader path.
  - Ran an isolated audit sub-agent for the produced code and artifacts. The
    audit found no blocking issues and confirmed that the patch is narrowly
    targeted, preserves DLL resolution, and adds checks for the known
    regression class.
- Remaining:
  - The automated GUI smoke still proves GUI launch under `WINEDLLPATH` with a
    sentinel; it does not encode the full manual `CGWindowList` /
    `NSRunningApplication` / `lsof` activation-identity proof.
  - `check-macos-setup` still follows existing `RuntimeRecord.isInstalled`
    semantics based on the primary executable, so it may report installed while
    a detailed stack component is incomplete.
- Next: publish the runtime submodule commit and parent submodule pointer after
  this local fix is accepted.
- Verification:
  - `nix develop -c zsh -lc 'nixfmt --check runtime/konyak-macos-runtime/nix/wine-crossover.nix runtime/konyak-macos-runtime/flake.nix'`:
    passed.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh runtime/konyak-macos-runtime/scripts/smoke-gui-launch.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh result-wine-runtime-x86_64'`:
    passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh work/runtime-stack-test'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh work/runtime-stack-test'`:
    passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/smoke-gui-launch.zsh work/runtime-stack-test'`:
    passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.

- Timestamp: 2026-06-16 10:17 JST
- State: `completed`
- Branch: `main`
- Related work: repository agent policy for runtime defect investigation,
  sub-agent workstream isolation, and artifact audit discipline
- Purpose: make future defect investigations require dynamic proof instead of
  static-analysis-only conclusions, and require separate investigation,
  implementation, and audit workstreams for substantial runtime and defect
  work.
- Completed:
  - Added AGENTS guidance that static analysis, binary metadata inspection,
    disassembly, source comparison, and Nix recipe review are only hypothesis
    inputs until confirmed by dynamic reproduction or counterexample.
  - Documented concrete macOS Wine dynamic-analysis probes, including public
    app/CLI reproduction, process inspection, targeted `WINEDEBUG`, Konyak
    logs, `CGWindowListCopyWindowInfo`, `NSRunningApplication`, `sample`,
    `spindump`, `lldb`, `log stream`, `fs_usage`, `dtruss`, and known-good
    runtime comparison.
  - Added AGENTS guidance to keep investigation, implementation, and
    artifact/result audit in separate sub-agent workstreams for substantial
    defect, runtime, packaging, and release artifact work.
- Remaining:
  - None for this repository policy update.
- Next: apply the new workflow to the next runtime defect fix before declaring
  the cause or produced artifact complete.
- Verification:
  - `nix develop -c zsh -lc 'just verify-governance && just verify-safety && just format-check && just lint'`:
    passed.

- Timestamp: 2026-06-16 09:39 JST
- State: `completed`
- Branch: `main`
- Related work: publish shallow hosted macOS runtime stack; update
  `crossover-26.1.0-konyak.0` runtime release assets; push runtime submodule
  and parent repository changes
- Purpose: publish the verified CrossOver-style `bin/wineloader` runtime
  contract and update the public macOS runtime stack artifacts consumed by
  Konyak.
- Completed:
  - Pushed runtime submodule commits
    `f29a800 Use hosted wineloader runtime layout` and
    `c58844a Handle draft runtime candidate cleanup` to
    `serika12345/konyak-macos-runtime`.
  - Generated a single-stack macOS runtime release payload from the locally
    verified x86_64 stack archive and staged it as draft/prerelease candidate
    `candidate-20260616092235-wineloader-rerun`.
  - Promoted that candidate through GitHub Actions run `27585433156`, which
    passed normalize, Wine32-on-64, GUI launch, DXVK D3D11, DXMT D3D11, vkd3d
    D3D12, and publish jobs.
  - Updated the final `crossover-26.1.0-konyak.0` release assets in
    `serika12345/konyak-macos-runtime`.
  - Confirmed the candidate release was deleted after successful promotion.
- Remaining:
  - None for publishing the shallow hosted macOS runtime stack artifacts.
- Next: none; the parent repository commit records the pushed runtime
  submodule pointer.
- Verification:
  - `nix develop -c zsh -lc 'nix shell nixpkgs#actionlint -c actionlint runtime/konyak-macos-runtime/.github/workflows/promote-runtime-candidate.yml'`:
    passed after fixing candidate cleanup.
  - `gh run watch 27585433156 --repo serika12345/konyak-macos-runtime --exit-status --interval 30`:
    passed.
  - `gh release view crossover-26.1.0-konyak.0 --repo serika12345/konyak-macos-runtime --json tagName,name,isDraft,isPrerelease,url,assets`:
    passed and showed `konyak-macos-wine-runtime-stack.tar.zst` with digest
    `sha256:8f84636cf920a28a8c0027a4c4ebd7ec79afebdbd944a684f98d445bdf78c020`.
  - `gh release view candidate-20260616092235-wineloader-rerun --repo serika12345/konyak-macos-runtime --json tagName`:
    failed as expected after successful candidate cleanup.

- Timestamp: 2026-06-16 01:21 JST
- State: `completed`
- Branch: `main`
- Related work: macOS CrossOver-style shallow hosted Wine runtime contract;
  public CLI `wineloader` launch path; runtime smoke entrypoint alignment
- Purpose: replace the incomplete app-bundle loader direction with a shallow
  CrossOver-style hosted runtime layout where `runtime/bin` points at
  `Konyak Wine Hosted Application`, Konyak launches the signed
  `runtime/bin/wineloader`, and parent CLI/runtime smoke paths set
  `WINELOADER`, `WINESERVER`, and base `WINEDLLPATH` explicitly.
- Completed:
  - Discarded the dirty parent and runtime-submodule workspace state before
    starting this implementation, per the handoff request.
  - Updated parent CLI runtime contracts to require and launch
    `bin/wineloader` on macOS instead of relying on a `bin/wine64` alias.
  - Added CLI contract coverage for macOS `WINELOADER`, `WINESERVER`,
    selected-backend `WINEPATH`, and base `WINEDLLPATH` propagation through
    program launch, winetricks, terminal, and runtime validation paths.
  - Updated the runtime submodule Wine derivation to produce the shallow hosted
    directory layout, point `bin` at that hosted directory, and sign the
    `wineloader`, `wineserver`, and host Unix loader entrypoints.
  - Updated runtime layout checks and raw runtime smoke diagnostics to use
    `bin/wineloader` and stop treating copied backend DLLs as proof of loader
    path correctness.
  - Changed backend device smoke to launch each probe from the selected runtime
    backend directory, using `WINEDLLPATH`, backend-only `WINEPATH`, and
    `WINEDLLOVERRIDES` instead of copying backend DLLs into the Wine prefix.
  - Verified the x86_64 macOS Wine runtime artifact and assembled runtime
    stack locally through the maintained runtime scripts that CI already calls.
- Remaining:
  - None for the shallow hosted `wineloader` runtime contract update.
- Next: publish these parent and runtime-submodule changes together so the
  parent CLI contract and runtime-produced artifact contract stay in sync.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed after the CLI contract update.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh runtime/konyak-macos-runtime/scripts/smoke-gui-launch.zsh runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh runtime/konyak-macos-runtime/scripts/assemble-runtime-stack.zsh scripts/run_macos_vulkan_wine_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'nix eval ./runtime/konyak-macos-runtime#packages.x86_64-darwin.konyak-macos-wine-runtime.drvPath'`:
    passed.
  - `nix develop -c zsh -lc 'nixfmt --check runtime/konyak-macos-runtime/nix/wine-crossover.nix runtime/konyak-macos-runtime/flake.nix'`:
    passed.
  - `nix develop -c zsh -lc 'nix build ./runtime/konyak-macos-runtime#packages.x86_64-darwin.konyak-macos-wine-runtime --out-link result-wine-runtime-x86_64'`:
    passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh result-wine-runtime-x86_64'`:
    passed.
  - `nix develop -c zsh -lc '<assemble x86_64 runtime stack with existing component archives, then run check-wine32on64-runtime.zsh, check-dxmt-component.zsh, check-vkd3d-component.zsh, check-dxvk-component.zsh, check-gstreamer-component.zsh, and check-wine-addons-component.zsh>'`:
    passed.
  - `nix develop -c zsh -lc '<run smoke-wine32on64-launch.zsh, smoke-gui-launch.zsh, and smoke-backend-device.zsh for dxvk-d3d11, dxmt-d3d11, and vkd3d-d3d12 on the assembled x86_64 stack>'`:
    passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-15 14:04 JST
- State: `completed`
- Branch: `main`
- Related work: macOS development runtime manifest cache refresh; runtime
  reinstall checksum mismatch
- Purpose: fix development runtime reinstall failures caused by stale cached
  source manifests after a verified runtime Release republishes assets under
  the same release tag.
- Completed:
  - Changed `scripts/prepare_macos_dev_runtime_stack.zsh` so URL source
    manifests are fetched and validated every time instead of trusting a
    `.source-url` marker when the URL matches.
  - Added macOS source manifest contract validation to the prepare script so
    malformed or incomplete manifests fail before runtime reinstall begins.
  - Applied the same no-stale-URL-cache rule to
    `scripts/prepare_linux_dev_runtime_source.zsh`.
  - Refreshed the local development macOS source manifest from the current
    `crossover-26.1.0-konyak.0` Release; the cached Wine component checksum now
    matches the published stack archive checksum
    `565a8167029956aca5f3ff310cb5b0dd5235d60576a44ad7ae5bb8a69511423d`.
  - Reinstalled the macOS development runtime through the public CLI
    `install-macos-wine --reinstall --source-manifest ... --json` route.
- Remaining:
  - None for this stale development manifest cache fix.
- Next: commit this parent-repository script fix if accepted; future runtime
  Release republish operations should not require deleting local
  `.dart_tool/konyak/dev-runtime-source` files.
- Verification:
  - `nix develop -c zsh -lc 'zsh -n scripts/prepare_macos_dev_runtime_stack.zsh scripts/prepare_linux_dev_runtime_source.zsh'`:
    passed.
  - `nix develop -c zsh -lc './scripts/prepare_macos_dev_runtime_stack.zsh --print-manifest-path; jq wine component sha256'`:
    passed and refreshed the local cache to the current published checksum.
  - `nix develop -c zsh -lc '<download current runtime Release source manifest; jq wine component sha256>'`:
    passed and matched the refreshed local cache.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && KONYAK_RUNTIME_PROFILE=development KONYAK_MACOS_WINE_HOME=... KONYAK_DEV_MACOS_WINE_STACK_MANIFEST=... dart run bin/konyak.dart install-macos-wine --reinstall --source-manifest ... --progress-json --json'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.

- Timestamp: 2026-06-15 12:42 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime release promotion; local artifact candidate flow
- Purpose: allow locally built macOS runtime stack artifacts to become final
  Release assets only after CI downloads, normalizes, verifies, smokes, and
  promotes them.
- Completed:
  - Added a runtime submodule staging script for local release candidates.
  - Added a runtime submodule candidate promotion workflow that normalizes
    candidate manifests, runs Wine32-on-64, GUI, DXVK, DXMT, and vkd3d smoke
    gates, and publishes the final Release only after every verification job
    succeeds.
  - Documented the candidate flow in runtime and parent release docs.
  - Added GitHub CLI to the runtime submodule dev shell so candidate staging
    stays inside the runtime submodule tooling boundary.
- Remaining:
  - None for the local-candidate release promotion path.
- Next: stage local runtime artifacts only as candidate releases, then promote
  them through `Promote runtime candidate`; keep direct final Release placement
  reserved for verification-passing CI jobs.
- Verification:
  - `nix develop -c zsh -lc 'direnv allow'`: passed after the runtime
    submodule `flake.nix` tooling change.
  - `nix develop ./runtime/konyak-macos-runtime -c zsh -lc 'cd runtime/konyak-macos-runtime && command -v jq && command -v gh && zsh -n scripts/stage-runtime-release-candidate.zsh'`:
    passed.
  - `nix develop ./runtime/konyak-macos-runtime -c zsh -lc '<download existing runtime release assets; run scripts/stage-runtime-release-candidate.zsh --dry-run candidate-local-test>'`:
    passed.
  - `nix develop -c zsh -lc 'nixfmt --check runtime/konyak-macos-runtime/flake.nix'`:
    passed.
  - `nix develop -c zsh -lc '<promote-runtime-candidate workflow shape check>'`:
    passed.
  - `nix develop -c zsh -lc 'nix shell nixpkgs#actionlint -c actionlint runtime/konyak-macos-runtime/.github/workflows/promote-runtime-candidate.yml'`:
    passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-15 11:46 JST
- State: `completed`
- Branch: `main`
- Related work: runtime SSOT hardening; parent runtime fallback removal;
  macOS runtime submodule completeness guards; parent commit `60711db`;
  runtime submodule commit `984d41e`
- Purpose: remove remaining parent-side runtime compensation paths so macOS
  runtime contents are complete in `runtime/konyak-macos-runtime` and consumed
  through source manifests instead of generated, downloaded, or overlaid by the
  parent repository.
- Completed:
  - Removed the parent CLI winetricks script installer and the unpinned
    `master/src/winetricks` runtime mutation path.
  - Changed winetricks verb listing to require the runtime-provided macOS
    `verbs.txt` or Linux managed `winetricks` executable.
  - Split Linux runtime-settings environment generation from macOS-only Metal,
    D3DMetal, and Rosetta variables.
  - Removed parent-side local macOS component generation from
    `scripts/prepare_macos_dev_runtime_stack.zsh`; it now resolves only complete
    source manifests from the macOS runtime submodule release metadata or an
    explicitly supplied complete manifest.
  - Added `runtime/konyak-macos-runtime/scripts/check-wine-addon-versions.zsh`
    and wired it into runtime Actions before binary component packaging.
  - Renamed parent raw Wine/Vulkan just targets to diagnostic names and added
    governance checks for the runtime SSOT rules.
  - Removed parent-side Linux development component generation from
    `scripts/prepare_linux_dev_runtime_source.zsh`; Linux development now
    requires an explicitly supplied complete runtime source manifest.
  - Removed macOS runtime source payload packages from the parent dev shell so
    parent Nix packages do not act as managed runtime payload sources.
  - Updated AGENTS, TODO, CLI distribution docs, VSCode docs, and the runtime
    integrity inventory.
  - Pushed runtime submodule commit `984d41e` and parent commit `60711db`.
  - Republished the `crossover-26.1.0-konyak.0` macOS runtime stack assets from
    runtime Actions run `27519923579`.
- Remaining:
  - None for this SSOT hardening pass.
- Next: keep macOS runtime fixes in `runtime/konyak-macos-runtime`; for Linux,
  add a runtime-owner packaging source before enabling a default development or
  release stack instead of regenerating components in the parent repository.
- Verification:
  - `nix develop -c zsh -lc 'zsh -n scripts/prepare_linux_dev_runtime_source.zsh scripts/prepare_macos_dev_runtime_stack.zsh scripts/run_macos_vulkan_wine_smoke.zsh scripts/run_linux_vulkan_wine_smoke.zsh runtime/konyak-macos-runtime/scripts/check-wine-addon-versions.zsh'`:
    passed.
  - `nix develop -c zsh -lc '<temporary complete Linux source manifest>; ./scripts/prepare_linux_dev_runtime_source.zsh --print-manifest-path'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-wine-addon-versions.zsh'`:
    passed.
  - `nix develop -c zsh -lc './scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.
  - Runtime Actions run `27519923579`: passed through `Publish runtime release`.
  - Release assets updated on 2026-06-15 02:43 UTC:
    `konyak-macos-runtime.release.json`,
    `konyak-macos-wine-runtime-stack-source.json`, and
    `konyak-macos-wine-runtime-stack.tar.zst`.
  - Parent Actions run `27520926939`
    (`macOS Runtime CLI Smoke`, manually dispatched after republish): passed.

- Timestamp: 2026-06-15 09:18 JST
- State: `completed`
- Branch: `main`
- Related work: macOS runtime Wine loader parity with CrossOver; winetricks CLI
  smoke; execution path SSOT
- Purpose: replace the earlier winetricks environment workaround with the root
  runtime fix discovered by comparing Konyak's packaged Wine layout with
  `/Users/masato/Downloads/CrossOver.app`.
- Completed:
  - Compared CrossOver's packaged Wine entrypoints and Unix loader with the
    Konyak dev runtime. CrossOver's copied Wine loader depends only on system
    libraries and carries an rpath back to CrossOver's `lib64`, while Konyak's
    `lib/wine/x86_64-unix/wine` still linked
    `@loader_path/../../libintl.8.dylib`.
  - Confirmed the `libintl` dependency is the real failure mode for Wine's
    temporary `winetemp-*` loader copy: after Wine copies the loader under
    `/private/var/...`, `@loader_path/../../libintl.8.dylib` no longer points
    at the runtime root.
  - Removed the earlier parent-side `WINETRICKS_FALLBACK_LIBRARY_PATH` CLI
    environment workaround and its contract expectations.
  - Added a runtime layout check that fails if the Wine Unix loader depends on
    packaged or third-party dylibs, so the temporary-copy hazard is caught by
    maintained runtime verification instead of papered over in CLI process
    environment.
  - Updated the CrossOver Wine derivation to link with
    `-Wl,-dead_strip_dylibs`, matching CrossOver's observable loader contract
    by dropping unused direct dylib dependencies from the copied loader.
  - Extended `scripts/run_macos_runtime_cli_smoke.zsh` so the maintained
    CLI-backed smoke path creates a bottle and runs
    `run-winetricks ci-prefix-smoke --verb win10 --json`.
  - Built the x86_64-darwin runtime, assembled it with the existing component
    archives, and ran the parent CLI smoke through `install-macos-wine`,
    `create-bottle`, and `run-winetricks` using the local stack source
    manifest.
  - Published the rebuilt runtime stack from runtime Actions run `27505571080`
    to the existing `crossover-26.1.0-konyak.0` release.
  - Pushed the parent repository commit `15c219c` and verified the published
    runtime through parent Actions run `27516631769`.
- Remaining:
  - None for this CrossOver loader parity repair.
- Next: if winetricks or prefix initialization regresses again, start from the
  published-runtime CLI smoke and the runtime loader dependency check; do not
  add parent-side dylib fallback environment as a workaround.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart -n "run-winetricks --json launches a selected verb|run-bottle-command --json launches winetricks with bottle env"'`:
    passed after removing the earlier fallback workaround.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc './runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh .dart_tool/konyak/dev-runtime/macos-wine'`:
    failed as expected before the runtime rebuild because
    `lib/wine/x86_64-unix/wine` depended on
    `@loader_path/../../libintl.8.dylib`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#konyak-macos-wine-runtime --print-build-logs'`:
    passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh runtime/konyak-macos-runtime/result'`:
    passed for the current-system aarch64 build.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime --print-build-logs'`:
    passed; the new `lib/wine/x86_64-unix/wine` depends only on
    `/usr/lib/libSystem.B.dylib`.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh runtime/konyak-macos-runtime/result'`:
    passed for the x86_64-darwin build.
  - `nix develop -c zsh -lc 'otool -L runtime/konyak-macos-runtime/result/lib/wine/x86_64-unix/wine runtime/konyak-macos-runtime/result/bin/wine runtime/konyak-macos-runtime/result/bin/wineserver'`:
    confirmed the copied Unix loader no longer links `libintl`.
  - `nix develop -c zsh -lc '<assemble local runtime stack from the rebuilt Wine archive and existing component archives; run check-wine-addons-component.zsh, check-wine32on64-runtime.zsh, check-dxmt-component.zsh, check-vkd3d-component.zsh, check-dxvk-component.zsh, and check-gstreamer-component.zsh>'`:
    passed for `.dart_tool/konyak/macos-runtime-root-fix-dist/result-runtime-stack`.
  - `nix develop -c zsh -lc 'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$PWD/.dart_tool/konyak/macos-runtime-root-fix-dist/konyak-macos-wine-runtime-stack-source.json" KONYAK_MACOS_RUNTIME_CLI_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/macos-runtime-cli-smoke-root-fix-crossover-parity" KONYAK_MACOS_RUNTIME_CLI_SMOKE_COMMAND_TIMEOUT=300s KONYAK_MACOS_RUNTIME_CLI_SMOKE_INSTALL_TIMEOUT=1200s ./scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/check-wine32on64-runtime.zsh scripts/run_macos_runtime_cli_smoke.zsh && git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.
  - Runtime GitHub Actions run `27505571080`: passed, including build,
    Wine32-on-64 runtime payload verification, stack assembly, launch/backend
    smoke, release metadata, and `publish-release`.
  - Parent GitHub Actions run `27516631769`: passed the published runtime CLI
    smoke.

- Timestamp: 2026-06-14 23:03 JST
- State: `completed`
- Branch: `main`
- Related work: runtime integrity debt repair; macOS Mono/Gecko addon payloads;
  execution path SSOT
- Purpose: remove prefix/runtime verification masking, align packaged Wine
  addon payloads with the built CrossOver/Wine expectation, and prove the
  repair through Konyak's public CLI route plus runtime CI smoke scripts.
- Completed:
  - Discarded the earlier standalone Wine loader-path experiment before this
    repair.
  - Removed `WINEDLLOVERRIDES=mscoree,mshtml=` from macOS prefix
    initialization and runtime smoke scripts.
  - Packaged `wine-mono-10.4.1-x86.msi` and
    `wine-gecko-2.47.4-{x86,x86_64}.msi` in the runtime submodule with checksum
    verification and CI checks.
  - Added `wine-gecko` to runtime stack assembly, source manifests, CLI
    completeness contracts, install fixtures, docs, and local CLI smoke.
  - Made macOS runtime archive install fail when required stack components are
    still incomplete after normalization.
  - Added `validate-runtime` stack completeness checks before loader execution.
  - Stopped release metadata from silently ignoring unreadable `.release.json`
    assets and made macOS runtime update checks require source manifests.
  - Kept backend smoke DLL placement as a component diagnostic that mirrors
    Konyak `set-runtime-settings`, while preventing it from masking Wine
    Mono/Gecko prefix initialization.
  - Updated AGENTS, TODO, release docs, CLI distribution docs, architecture docs,
    and the runtime integrity debt inventory to reflect the repaired contract.
- Remaining:
  - None for this repair.
- Next: future runtime changes should keep app behavior proof on
  `scripts/run_macos_runtime_cli_smoke.zsh` or another maintained CLI-backed
  route, and should update runtime submodule CI when changing stack contracts.
- Verification:
  - Targeted red tests failed before implementation for prefix override
    removal, incomplete archive rejection, incomplete runtime validation, bad
    release metadata fallback, and macOS update metadata without source
    manifests.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/package-binary-components.zsh runtime/konyak-macos-runtime/scripts/assemble-runtime-stack.zsh runtime/konyak-macos-runtime/scripts/make-source-manifest.zsh runtime/konyak-macos-runtime/scripts/check-wine-addons-component.zsh runtime/konyak-macos-runtime/scripts/smoke-gui-launch.zsh runtime/konyak-macos-runtime/scripts/smoke-wine32on64-launch.zsh runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#gnutar -c ./scripts/package-binary-components.zsh dist result-runtime-stack result-runtime-stack result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#gnutar nixpkgs#jq -c ./scripts/assemble-runtime-stack.zsh dist result-runtime-stack dist/konyak-macos-wine-runtime-stack.tar.zst && ./scripts/check-wine-addons-component.zsh result-runtime-stack && ./scripts/check-wine32on64-runtime.zsh result-runtime-stack && ./scripts/check-dxmt-component.zsh result-runtime-stack && ./scripts/check-vkd3d-component.zsh result-runtime-stack && ./scripts/check-dxvk-component.zsh result-runtime-stack && ./scripts/check-gstreamer-component.zsh result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'KONYAK_DEV_MACOS_WINE_STACK_MANIFEST="$PWD/runtime/konyak-macos-runtime/dist/konyak-macos-wine-runtime-stack-source.json" KONYAK_MACOS_RUNTIME_CLI_SMOKE_WORK_ROOT="$PWD/.dart_tool/konyak/macos-runtime-cli-smoke-root-fix" ./scripts/run_macos_runtime_cli_smoke.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-wine32on64-launch.zsh result-runtime-stack && ./scripts/smoke-gui-launch.zsh result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'zsh -n runtime/konyak-macos-runtime/scripts/smoke-backend-device.zsh && cd runtime/konyak-macos-runtime && ./scripts/smoke-backend-device.zsh result-runtime-stack dxvk-d3d11 && ./scripts/smoke-backend-device.zsh result-runtime-stack dxmt-d3d11 && ./scripts/smoke-backend-device.zsh result-runtime-stack vkd3d-d3d12'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: failed once because Dart
    formatting changed two touched files, then passed after formatting.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.

- Timestamp: 2026-06-14 22:26 JST
- State: `completed`
- Branch: `main`
- Related work: runtime integrity debt inventory; execution path SSOT policy
  correction
- Purpose: audit implementations and tests that make runtime verification pass
  by suppressing, bypassing, or shallowly checking the behavior that Konyak
  actually depends on.
- Completed:
  - Read the current progress and TODO state.
  - Audited macOS prefix initialization, runtime component packaging,
    runtime stack completeness checks, release metadata fallback behavior,
    validate-runtime checks, raw Wine smoke scripts, and backend smoke setup.
  - Recorded the debt inventory in
    `docs/runtime-integrity-debt-inventory.md`.
  - Corrected the AGENTS execution path policy so Mono/MSHTML addon probing must
    not be suppressed to make prefix initialization, bottle creation, runtime
    validation, winetricks, or CI smoke pass.
  - Added governance checks that require the corrected policy and the inventory
    document to remain present.
  - Added a TODO item for removing runtime verification masking and proving
    prefix/addon integrity through the normal application-owned path.
- Remaining:
  - Implement the repair items listed in
    `docs/runtime-integrity-debt-inventory.md` and `docs/todo.md`.
- Next: start with a failing CLI contract test that rejects
  `WINEDLLOVERRIDES=mscoree,mshtml=` during macOS prefix initialization, then
  align the runtime submodule's Mono/Gecko payload packaging with the built
  Wine expectation.
- Verification:
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.
  - `nix develop -c zsh -lc 'git -C runtime/konyak-macos-runtime diff --check'`:
    passed.

- Timestamp: 2026-06-14 22:06 JST
- State: `completed`
- Branch: `main`
- Related work: execution path SSOT policy hardening; macOS winetricks runtime
  verification discipline
- Purpose: prevent runtime verification from bypassing the application-owned
  Flutter/CLI execution path and accidentally exercising raw Wine prefix
  initialization behavior such as Wine Mono installer prompts.
- Completed:
  - Read the current progress and TODO state.
  - Identified the app-owned macOS winetricks path as the CLI
    `run-winetricks <bottle-id> --verb <verb> --json` contract, which plans a
    `macosWinetricks` runner request.
  - Confirmed the previous raw `result-wine-runtime/bin/wine64 ...` smoke was
    not the application path and triggered Wine Mono setup because it created a
    new ad hoc prefix outside Konyak's CLI runner flow.
  - Add AGENTS policy that makes the Flutter/CLI route and maintained smoke
    scripts the single source of truth for app/runtime execution verification.
  - Add governance checks so the policy cannot be removed silently.
  - Verified the governance check fails before the AGENTS policy is present and
    passes after the policy is added.
- Remaining:
  - None.
- Next: any future macOS winetricks validation should use `run-winetricks` or a
  maintained smoke script that wraps the same CLI contract.
- Verification:
  - Process cleanup confirmed no leftover `wineboot`, `wineserver`,
    `install_mono`, `winetemp`, or `result-wine-runtime` smoke processes.
  - `nix develop -c zsh -lc 'just verify-governance'`: failed before
    `AGENTS.md` contained the new SSOT policy, then passed after the policy was
    added.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.

- Timestamp: 2026-06-14 20:56 JST
- State: `superseded`
- Branch: `main`
- Related work: macOS runtime Phase 3 follow-up; winetricks Wine loader dylib
  resolution
- Purpose: fix macOS winetricks runs that fail when Wine creates temporary
  loader executables such as `winedevice.exe` and the copied loader can no
  longer resolve `libintl.8.dylib` from the packaged runtime.
- Completed:
  - Read the current progress and TODO state.
  - Inspected the reported winetricks run log for the `cjkfonts` verb.
  - Confirmed the failing process is a Wine temporary loader under
    `/private/var/.../winetemp-*`, not the top-level winetricks script.
  - Confirmed the packaged Wine loader at `lib/wine/x86_64-unix/wine`
    references `@loader_path/../../libintl.8.dylib`, which works in-place but
    breaks after Wine starts a temporary loader name outside the runtime tree.
  - Confirmed setting `WINE`, `WINE64`, `WINE_BIN`, and `WINESERVER_BIN` to
    absolute runtime paths is not sufficient because Wine still creates the
    temporary loader executable during winetricks prefix probing.
- Remaining:
  - Folded into the execution path SSOT policy hardening snapshot above. Any
    future winetricks smoke must use the app-owned CLI path, not a raw Wine
    command.
- Next: resume winetricks validation only through `run-winetricks` or a
  maintained smoke script that wraps the same CLI contract.
- Verification:
  - The runtime loader packaging fix and checker were implemented after this
    snapshot, but raw Wine smoke verification was intentionally stopped because
    it bypassed the app-owned execution path.

- Timestamp: 2026-06-14 19:25 JST
- State: `completed`
- Branch: `main`
- Related work: installed-program listing pinned shortcut deduplication
- Purpose: fix the Installed Programs dialog so pinning a discovered Start Menu
  shortcut does not make the same program appear twice on later listings.
- Completed:
  - Read the current progress and TODO state.
  - Identified `list-bottle-programs --json` program discovery as the shared
    source for the Installed Programs dialog.
  - Added CLI contract coverage for a pinned Start Menu shortcut with the same
    path as a discovered shortcut.
  - Confirmed the new CLI contract failed before implementation by returning
    both `globalStartMenu` and `pinned` entries for the same `.lnk`.
  - Updated bottle program discovery to skip pinned entries when the same
    normalized program path is already present in the discovered program list.
- Remaining:
  - None.
- Next: manually reopen Installed Programs after pinning a Start Menu shortcut
  if local UI smoke verification is desired.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "list-bottle-programs --json does not duplicate pinned Start Menu shortcuts"'`:
    failed before implementation on the duplicate `pinned` entry, then passed
    after implementation.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/lib/src/io/program_discovery.dart packages/konyak_cli/test/cli_contract_program_execution.part.dart'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-14 15:06 JST
- State: `completed`
- Branch: `main`
- Related work: macOS bottle Terminal launch repair
- Purpose: fix the macOS bottle Terminal command so Terminal no longer opens
  into zsh's unfinished quote prompt when the Wine environment contains the
  GStreamer registry path and other runtime variables.
- Completed:
  - Read the current progress and TODO state.
  - Identified the macOS Terminal command generator in the CLI.
  - Added CLI contract coverage requiring macOS Terminal launches to keep the
    full GStreamer registry setup in a generated setup script while passing
    only a short `source .../konyak-terminal-setup.zsh` command to Terminal.
  - Changed the macOS bottle Terminal AppleScript to write the generated shell
    setup into a bottle-local logs script with restrictive permissions before
    opening Terminal.
  - Kept the existing Wine environment and aliases in the sourced setup script,
    including `WINEPREFIX`, GStreamer variables, Wine DLL paths, and sync mode.
- Remaining:
  - None.
- Next: manually retry the Bottle Terminal action from the Flutter app if a
  local UI smoke is desired.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-bottle-command --json opens a macOS bottle terminal"'`:
    failed before implementation on the missing setup-script handoff assertion,
    then passed after implementation and formatting.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: failed once after formatting
    the updated CLI contract test, then passed on rerun.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'git diff --check'`: passed.

- Timestamp: 2026-06-14 03:02 JST
- State: `completed`
- Branch: `main`
- Related work: CrossOver-derived macOS Wine compatibility repair, Phase 3;
  CI completion
- Purpose: finish the remaining launch and smoke behavior around the repaired
  macOS runtime, keep the app launch environment aligned with CI, and prepare
  the commits for GitHub Actions completion.
- Completed:
  - Read the Phase 3 TODO and current runtime smoke scripts.
  - Confirmed the parent launch path still uses `wine64 start /unix <program>`
    and already carries the runtime `lib` path in `DYLD_LIBRARY_PATH`.
  - Added CLI contract coverage for macOS enhanced sync environment generation
    and made `msync` set only `WINEMSYNC=1`; `WINEESYNC=1` is now reserved for
    the explicit `esync` mode.
  - Added a Win32 GUI probe and `scripts/smoke-gui-launch.zsh` so the assembled
    runtime stack is tested through `wine64 start /unix <program>`, matching
    the normal Konyak `.exe` launch path.
  - Removed smoke-only `DYLD_FALLBACK_LIBRARY_PATH` usage from runtime smoke
    scripts so CI does not hide missing runtime-library placement.
  - Added runtime workflow coverage for the GUI launch smoke as a downstream
    job that consumes the uploaded assembled stack artifact instead of
    rebuilding CrossOver Wine.
  - Repaired the single stack archive assembly so component extraction cannot
    replace Wine's libiconv ABI split: standard `libiconv.2.dylib` stays
    Darwin-compatible for macOS system libraries, while GNU consumers use
    `libiconv-gnu.2.dylib`.
  - Verified `libgnutls.30.dylib` can be loaded from the assembled stack
    without host or fallback dylib paths.
  - Confirmed the CI GUI smoke timeout no longer reports the previous
    `libiconv` dyld override warnings after the Darwin/GNU iconv ABI split.
  - Stabilized GUI smoke prefix initialization by disabling Wine Mono/MSHTML
    probing with the same `WINEDLLOVERRIDES=mscoree,mshtml=` policy used by the
    other runtime smoke scripts.
  - Pushed runtime commit `43ce18f` and parent commit `c38f88b`.
  - Confirmed runtime CI run `27472434310` completed successfully, including the
    GUI `/unix`, Wine32-on-64, DXVK, DXMT, and vkd3d smoke jobs.
  - Confirmed parent CI runs `27472442049`, `27472442066`, and `27472442044`
    completed successfully.
- Remaining:
  - None for this phase.
- Next: use the rebuilt published runtime stack for manual real-application
  validation such as the reported Ardour path if further launch issues are
  reported.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "run-program --json preserves macOS bottle environment on macOS"'`:
    failed before the sync-mode environment change and passed after
    implementation.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "(preserves macOS bottle environment|applies DXVK settings on Linux|applies vkd3d-proton settings on Linux)"'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/assemble-runtime-stack.zsh scripts/smoke-gui-launch.zsh scripts/check-wine32on64-runtime.zsh scripts/build-backend-probes.zsh scripts/smoke-wine32on64-launch.zsh scripts/smoke-backend-device.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/assemble-runtime-stack.zsh dist "$PWD/result-runtime-stack" dist/konyak-macos-wine-runtime-stack.tar.zst && ./scripts/check-wine32on64-runtime.zsh result-runtime-stack && ./scripts/check-dxmt-component.zsh result-runtime-stack && ./scripts/check-vkd3d-component.zsh result-runtime-stack && ./scripts/check-dxvk-component.zsh result-runtime-stack && ./scripts/check-gstreamer-component.zsh result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --show-trace --out-link result-wine-runtime'`:
    passed after the Darwin/GNU iconv ABI split.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-wine32on64-runtime.zsh result-wine-runtime'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && <x86_64 dlopen probe> "$PWD/result-wine-runtime/lib/libgnutls.30.dylib"'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && <x86_64 dlopen probe> "$PWD/result-runtime-stack/lib/libgnutls.30.dylib"'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-gui-launch.zsh result-runtime-stack .dart_tool/backend-probes-phase3'`:
    passed after adding `WINEDLLOVERRIDES=mscoree,mshtml=` to the smoke
    environment; before that, it timed out during prefix initialization without
    the previous `libiconv` dyld warnings.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-wine32on64-launch.zsh result-runtime-stack && ./scripts/smoke-backend-device.zsh result-runtime-stack dxvk-d3d11 .dart_tool/backend-probes-phase3 && ./scripts/smoke-backend-device.zsh result-runtime-stack dxmt-d3d11 .dart_tool/backend-probes-phase3 && ./scripts/smoke-backend-device.zsh result-runtime-stack vkd3d-d3d12 .dart_tool/backend-probes-phase3'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_SINGLE_STACK_ARCHIVE=1 KONYAK_RELEASE_ASSET_BASE_URL="https://example.invalid/runtime" nix shell nixpkgs#jq -c ./scripts/make-source-manifest.zsh ...'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && for f in scripts/build-backend-probes.zsh scripts/smoke-gui-launch.zsh scripts/smoke-wine32on64-launch.zsh scripts/smoke-backend-device.zsh scripts/assemble-runtime-stack.zsh scripts/check-wine32on64-runtime.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh scripts/check-wine-configure-flags.zsh; do zsh -n "$f"; done && nix shell nixpkgs#actionlint -c actionlint .github/workflows/build-runtime.yml .github/workflows/smoke-runtime-artifacts.yml && ./scripts/check-wine-configure-flags.zsh && nix flake check path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime -L --show-trace'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance && just verify-safety && just format-check && just lint && git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.
  - GitHub Actions `serika12345/konyak-macos-runtime` run `27472434310`:
    passed.
  - GitHub Actions `serika12345/Konyak` runs `27472442049`, `27472442066`, and
    `27472442044`: passed.

- Timestamp: 2026-06-13 14:01 JST
- State: `completed`
- Branch: `main`
- Related work: CrossOver-derived macOS Wine compatibility repair, Phase 2;
  macOS runtime Actions artifact rebuild
- Purpose: make the CrossOver-derived macOS runtime resolve normal Wine
  dlopen-facing dependencies from the packaged runtime itself, then publish the
  verified macOS runtime as one assembled public stack archive while preserving
  narrow internal CI rerun units.
- Completed:
  - Packaged dlopen-facing runtime dylibs such as GnuTLS, GSSAPI/Kerberos,
    OpenCL, and libusb into the Wine runtime shared library root.
  - Normalized Wine runtime Mach-O install names and `LC_RPATH` entries so Wine
    binaries, Unix modules, and copied dylib closures do not retain Nix store
    dylib or RPATH references.
  - Extended Wine runtime checks to validate dlopen-facing dylib presence,
    install names, module RPATHs, and Nix store `LC_RPATH` absence.
  - Extended DXMT and GStreamer component packaging/checks so copied Mach-O
    payloads remove Nix store `LC_RPATH` entries and keep local
    `@loader_path` resolution.
  - Added single stack archive assembly for the verified Wine, DXMT, vkd3d,
    DXVK-macOS, MoltenVK, GStreamer, FreeType, wine-mono, and winetricks
    payloads.
  - Updated runtime Actions so public release metadata and smoke jobs consume
    the assembled stack archive, while Wine, DXMT, vkd3d, and binary component
    artifacts remain separate internal build/rerun units.
  - Updated the parent CLI runtime installer to dedupe identical archive URLs
    in a single-archive source manifest while preserving per-component versions.
  - Fixed incomplete-runtime repair so preserved existing runtime files also
    preserve their existing component versions, including user-provided GPTK
    Wine versions, while newly repaired components keep source-manifest
    versions.
  - Rebuilt the local Actions-equivalent artifacts: Wine runtime archive, DXMT
    archive, vkd3d archive, binary component archives, assembled runtime stack
    archive, source manifest, and release metadata.
- Remaining:
  - Phase 3: verify normal GUI `.exe` launch behavior against the repaired
    runtime, align smoke launch environment with the app launch environment,
    and settle `WINEMSYNC` / `WINEESYNC` defaults.
  - Manual smoke of the reported Ardour launch is still needed to prove the
    Phase 2 runtime layout fixes that specific application path.
- Next: start Phase 3 from the normal `.exe` launch path, using the repaired
  single stack runtime artifact and the Ardour path as the first real-world
  smoke target.
- Verification:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "downloads a single-archive"'`:
    failed before the planner change and passed after implementation.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --name "source manifest"'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "install-macos-wine repairs required components without removing GPTK"'`:
    passed after preserving existing component versions during repair installs.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `nix develop -c zsh -lc 'zsh -n scripts/package-binary-components.zsh scripts/check-gstreamer-component.zsh scripts/check-dxmt-component.zsh scripts/check-wine32on64-runtime.zsh scripts/assemble-runtime-stack.zsh scripts/make-source-manifest.zsh'`:
    passed in `runtime/konyak-macos-runtime`.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --show-trace --out-link result-wine-runtime'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-wine32on64-runtime.zsh result-wine-runtime'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && <package binary runtime components and verify DXVK/GStreamer>'`:
    passed.
  - `KONYAK_METAL_TOOLCHAIN_BIN="$(dirname "$(/usr/bin/xcrun -sdk macosx -find metal)")" nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT="$PWD/result-wine-runtime" nix build --impure .#packages.x86_64-darwin.konyak-macos-dxmt -L --show-trace --out-link result-dxmt && ./scripts/check-dxmt-component.zsh result-dxmt'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_WINE_RUNTIME_ROOT="$PWD/result-wine-runtime" nix build --impure .#packages.x86_64-darwin.konyak-macos-vkd3d -L --show-trace --out-link result-vkd3d && ./scripts/check-vkd3d-component.zsh result-vkd3d'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/assemble-runtime-stack.zsh dist "$PWD/result-runtime-stack" dist/konyak-macos-wine-runtime-stack.tar.zst && ./scripts/check-wine32on64-runtime.zsh result-runtime-stack && ./scripts/check-dxmt-component.zsh result-runtime-stack && ./scripts/check-vkd3d-component.zsh result-runtime-stack && ./scripts/check-dxvk-component.zsh result-runtime-stack && ./scripts/check-gstreamer-component.zsh result-runtime-stack'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_SINGLE_STACK_ARCHIVE=1 KONYAK_RELEASE_ASSET_BASE_URL="https://example.invalid/runtime" nix shell nixpkgs#jq -c ./scripts/make-source-manifest.zsh ...'`:
    passed; every component record pointed at
    `konyak-macos-wine-runtime-stack.tar.zst` with the same stack SHA-256 while
    preserving individual component versions.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/check-wine-configure-flags.zsh'`:
    passed.
  - `nix develop -c zsh -lc 'nix flake check path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime -L --show-trace'`:
    passed for the current host system; x86_64-darwin is omitted by this command
    on the current host, but the x86_64-darwin Wine, DXMT, and vkd3d packages
    were built directly above.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.

- Timestamp: 2026-06-13 01:13 JST
- State: `completed`
- Branch: `main`
- Related work: CrossOver-derived macOS Wine compatibility repair, Phase 1
- Purpose: restore the CrossOver-derived macOS Wine configure surface to a
  normal Wine-compatible baseline while keeping Wine32-on-64, D3DMetal/GPTK,
  DXVK, DXMT, vkd3d, MoltenVK, and GStreamer support available at Konyak
  runtime quality.
- Completed:
  - Compared Konyak's current CrossOver Wine derivation with nixpkgs Darwin
    `wineWow64Packages.stable` and `stableFull`, CrossOver 26.1 source, and
    the installed CrossOver.app runtime layout.
  - Identified that Konyak keeps the core Wine32-on-64 and Vulkan flags but
    over-prunes normal Wine feature probes with several hard `--without-*`
    flags.
  - Identified that `--with-gnutls` is directionally correct, but the packaged
    runtime currently places `libgnutls.30.dylib` where Wine's dlopen users do
    not reliably find it.
  - Recorded the intended repair order in `docs/todo.md`: remove unnecessary
    `--without-*` flags, fix missing dependencies and dylib placement, then
    normalize `.exe` launch, smoke coverage, CI search paths, and sync-mode
    defaults.
  - Decided to move public macOS runtime distribution to a single assembled
    runtime stack archive, while keeping component archives as internal CI
    build, verification, and rerun units.
  - Added
    `runtime/konyak-macos-runtime/docs/crossover-runtime-compatibility.md` as
    the technical handoff for the runtime compatibility investigation,
    GnuTLS/dlopen diagnosis, adopted and rejected runtime packaging patterns,
    single-archive distribution direction, and phased repair plan.
  - Added a runtime-submodule configure flag check that requires the adopted
    `--with-*` set, rejects unapproved `--without-*` flags, and rejects
    compatibility-reducing `--disable-*` flags other than `--disable-tests`.
  - Updated `runtime/konyak-macos-runtime/nix/wine-crossover.nix` to remove the
    current hard-pruned `--without-*` flags other than `--without-x`, remove
    `--disable-win16`, and add the adopted `--with-*` flags and matching Nix
    build inputs.
  - Verified that forcing `--with-opengl` is not part of the Darwin baseline:
    Wine 11 configure requires EGL development files when that flag is explicit,
    and nixpkgs Darwin Wine does not add OpenGL support dependencies on Darwin.
  - Fixed the concrete build issue exposed by the expanded configure surface:
    `libinotify-kqueue` must be added to the compiler and linker search paths,
    otherwise Unix-side modules such as `winebus.sys` can detect inotify at
    configure time but fail to compile.
  - Verified the updated CrossOver Wine derivation with a full x86_64-darwin
    build.
- Remaining:
  - Phase 2 implementation: add the missing dependencies, package dlopen-facing
    dylibs such as `libgnutls.30.dylib` in a loader-visible location, and
    validate Mach-O `LC_RPATH` and closure placement. The verified payloads
    should then be assembled into one public runtime archive.
  - Phase 3 implementation: verify the normal `.exe` launch path, align CI
    smoke environment with app launch environment, and settle `WINEMSYNC` /
    `WINEESYNC` defaults.
- Next: begin Phase 2 by moving dlopen-facing runtime dylibs such as
  `libgnutls.30.dylib` into a loader-visible runtime library area, adding
  closure checks for those libraries, and preparing the single assembled public
  macOS runtime archive path.
- Verification:
  - `git diff --check`: passed.
  - `runtime/konyak-macos-runtime/scripts/check-wine-configure-flags.zsh`:
    passed.
  - `nix develop -c zsh -lc 'nix flake check path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime -L --show-trace'`:
    passed for the current host system; x86_64-darwin is omitted by this command
    on the current host.
  - `nix develop -c zsh -lc 'nix build path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime#checks.x86_64-darwin.wine-configure-flags -L --show-trace --no-link'`:
    passed.
  - `nix develop -c zsh -lc 'nix eval path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime#packages.x86_64-darwin.konyak-macos-wine-runtime.drvPath && nix eval path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime#packages.aarch64-darwin.konyak-macos-wine-runtime.drvPath'`:
    passed.
  - `nix develop path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime#packages.x86_64-darwin.konyak-macos-wine-runtime -c zsh -lc 'echo wine-dev-env-ok'`:
    passed.
  - `nix develop -c zsh -lc 'just verify-governance'`: passed.
  - `nix develop -c zsh -lc 'just verify-safety'`: passed.
  - `nix develop -c zsh -lc 'just format-check'`: passed.
  - `nix develop -c zsh -lc 'just lint'`: passed.
  - `nix develop -c zsh -lc 'runtime/konyak-macos-runtime/scripts/check-wine-configure-flags.zsh && nix build path:/Users/masato/Documents/Konyak/runtime/konyak-macos-runtime#packages.x86_64-darwin.konyak-macos-wine-runtime -L --show-trace --no-link'`:
    passed.

- Timestamp: 2026-06-12 22:07 JST
- State: `completed`
- Branch: `main`
- Related work: Process Manager executable icons
- Purpose: fix missing Process Manager icons for Wine processes launched from
  Start Menu `.lnk` shortcuts.
- Completed:
  - Added regression coverage for `list-wine-processes --json` when the
    latest run log records a shortcut path but `winedbg info proc` reports the
    target executable name.
  - Added regression coverage for recorded external launch entries that point
    at shortcuts.
  - Changed Wine process metadata resolution to resolve shortcut targets before
    matching a recorded launch/log path against the reported process
    executable.
- Remaining:
  - Manual smoke against a real shortcut-launched Windows app is still useful to
    confirm the extracted `.ico` renders correctly in the Flutter engine.
- Next: manually smoke a real shortcut-launched Windows app if icon rendering
  still needs confirmation outside the synthetic CLI tests.
- Verification:
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart -n
    "runCliStreaming list-wine-processes resolves shortcut targets for process
    icons"`: failed before implementation because no metadata extraction was
    attempted; passed after implementation.
  - `cd packages/konyak_cli && dart test test/cli_contract_test.dart -n
    "list-wine-processes --json resolves recorded shortcut launches to target
    metadata"`: passed.
  - `just cli-test`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

- Timestamp: 2026-06-12 21:56 JST
- State: `completed`
- Branch: `main`
- Related work: Linux program launch window detection TODO
- Purpose: keep the Linux equivalent of macOS launch overlay dismissal visible
  in the roadmap.
- Completed:
  - Added an incomplete TODO under Flutter run feedback for Linux Wine/Proton
    window detection, scoped to X11/XWayland first with a documented Wayland
    fallback.
- Remaining:
  - Implement and verify Linux launch window detection.
- Next: design the Linux window-detection contract and decide how to handle
  Wayland environments where global window enumeration is unavailable.
- Verification:
  - `just verify-governance`: passed.
  - `git diff --check`: passed.

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
