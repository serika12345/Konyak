# Progress

This file records Konyak's current active work and completed state so the
project can be resumed without relying on chat history.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot, completed milestone summaries, and
handoff notes.

## Current Work Snapshot

- Timestamp: 2026-06-08 13:30 JST
- State: `in_progress`
- Branch: `main`
- Latest known parent commit:
  `ff4c464 docs: require Actions parity for local runtime smoke`
- Latest known macOS runtime submodule commit:
  `d6b64f3 ci: preserve Wine runtime result for launch smoke`
- Related work: macOS 32-bit Windows executable support
- Purpose: restore macOS 32-bit Windows executable support while keeping the
  `runtime/konyak-macos-runtime` submodule as the runtime artifact SSOT. The
  parent repository must validate and consume the submodule-produced Wine32-on-64
  payload instead of adding runtime dependencies to the parent Nix flake.
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
- Remaining:
  - Wait for GitHub Actions run `27116103755` to finish.
  - If the run succeeds, confirm the generated release assets and update the
    development runtime if needed.
  - If the run fails, inspect the failed step logs before changing code.
- Next action: monitor GitHub Actions run `27116103755`.
- Verification performed:
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

## Completed Milestones

- 2026-06-07: Bara-style progress handoff discipline was added through
  `docs/progress.md` and `AGENTS.md`, so active work and continuation state can
  be recovered without chat history.
- 2026-06-07: FreeType was added to the macOS runtime stack contract in the
  parent repository and packaged as a separate component in the
  `runtime/konyak-macos-runtime` submodule. The parent repository consumes the
  submodule-produced runtime stack as the source of truth instead of adding
  runtime dependencies to the parent Nix flake.
