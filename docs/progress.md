# Progress

This file records Konyak's current active work and completed state so the
project can be resumed without relying on chat history.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot, completed milestone summaries, and
handoff notes.

## Current Work Snapshot

- Timestamp: 2026-06-07 23:35 JST
- State: `ready_to_commit`
- Branch: `main`
- Latest known parent commit:
  `0351013 docs: plan macOS 32-bit runtime support`
- Latest known macOS runtime submodule commit:
  `ad73f93 feat: enable macOS Wine32-on-64 runtime`
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
  - Kept D3DMetal/GPTK x86_64-only unless a 32-bit-capable payload is produced.
  - Removed the external release archive dependency from the macOS source
    manifest failure contract test; the release manifest URL remains covered by
    the repository SSOT test.
- Remaining:
  - Commit the parent repository changes that consume submodule commit
    `ad73f93`.
  - Add a real 32-bit PE smoke test later, once there is a reliable dedicated
    runtime verification target. Current coverage validates the built payload
    and launch environment, not actual 32-bit process startup.
- Next action: commit the parent CLI/runtime-contract update and submodule
  pointer.
- Verification performed:
  - `zsh -n scripts/check-wine32on64-runtime.zsh scripts/package-binary-components.zsh scripts/make-source-manifest.zsh`
    in `runtime/konyak-macos-runtime`: passed.
  - `git -C runtime/konyak-macos-runtime diff --check`: passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix flake check -L --show-trace'`:
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix build .#packages.x86_64-darwin.konyak-macos-wine-runtime -L --no-link'`:
    passed; verified output
    `/nix/store/25r6j7wk964g1fzx8n14w9yfqha5iafz-konyak-macos-wine-runtime-crossover-26.1.0-konyak.0`.
  - `./scripts/check-wine32on64-runtime.zsh /nix/store/25r6j7wk964g1fzx8n14w9yfqha5iafz-konyak-macos-wine-runtime-crossover-26.1.0-konyak.0`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart'`:
    passed.
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_test.dart --plain-name "install-macos-wine reports macOS runtime source manifest failures"'`:
    passed.
  - `nix develop -c zsh -lc 'just cli-test'`: passed.
  - `just verify-governance`: passed.
  - `just verify-safety`: passed.
  - `just format-check`: passed.
  - `just lint`: passed.

## Completed Milestones

- 2026-06-07: Bara-style progress handoff discipline was added through
  `docs/progress.md` and `AGENTS.md`, so active work and continuation state can
  be recovered without chat history.
- 2026-06-07: FreeType was added to the macOS runtime stack contract in the
  parent repository and packaged as a separate component in the
  `runtime/konyak-macos-runtime` submodule. The parent repository consumes the
  submodule-produced runtime stack as the source of truth instead of adding
  runtime dependencies to the parent Nix flake.
