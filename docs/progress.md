# Progress

This file records Konyak's current active work and completed state so the
project can be resumed without relying on chat history.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot, completed milestone summaries, and
handoff notes.

## Current Work Snapshot

- Timestamp: 2026-06-08 19:54 JST
- State: `in_progress`
- Branch: `main`
- Latest known parent commit:
  `36fc487 docs: track component dylib closure fix`
- Latest known macOS runtime submodule commit:
  `b7a3e8b fix: bundle component dylib closures`
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
- Remaining:
  - Review and commit the runtime workflow split before pushing.
  - Run the new split workflow and confirm failed-job reruns no longer require
    a successful Wine runtime build to run again.
  - If the run succeeds, confirm the generated release assets and update the
    development runtime if needed.
  - If the run fails, inspect the failed step logs before changing code.
- Next action: review and commit the split runtime workflow; do not push until
  the rerun structure is accepted.
- Verification performed:
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
