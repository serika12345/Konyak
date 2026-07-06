# Progress

This file records Konyak's current active work and handoff state so the project
can be resumed without relying on chat history. Fully completed work is removed
from this file after verification; commits, releases, tests, and generated
artifacts are the durable record for finished work.

Use `docs/todo.md` for the actionable backlog and long-running milestones. Use
this file for the current work snapshot and any handoff notes needed to resume
unfinished work.

## Current Work Snapshot

### Latest Update

- Timestamp: 2026-07-06 20:09 JST
- State: `completed`
- Branch: `task/gptk-import-public-proof-docs`
- Active work: `G4-P1 GPTK Import Public Proof and Docs`.
- Related TODO: GPTK/D3DMetal import compatibility work is completed in
  `docs/gptk-d3dmetal-import-progress.md`; `docs/todo.md` now points at the
  next DLSS/MetalFX rendering-proof task.
- Pull request: runtime draft PR
  https://github.com/serika12345/konyak-macos-runtime/pull/5 opened from
  `task/gptk-import-public-proof-docs`; parent draft PR
  https://github.com/serika12345/Konyak/pull/39 opened from the same branch.
  Previous runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/4 merged as
  `472091f`; parent PR https://github.com/serika12345/Konyak/pull/38 merged
  as `3e1d5f`.
- Latest known completed work: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 merged as
  `eedc190`; parent PR https://github.com/serika12345/Konyak/pull/34 merged
  as `ab048d8`; parent PR https://github.com/serika12345/Konyak/pull/35
  merged as `0afa99f`; parent PR https://github.com/serika12345/Konyak/pull/36
  merged as `4e56d49`; parent PR https://github.com/serika12345/Konyak/pull/37
  merged as `2445a0d`; runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/4 merged as
  `472091f`; parent PR https://github.com/serika12345/Konyak/pull/38 merged
  as `3e1d5f`.
- Runtime branch: `runtime/konyak-macos-runtime` branch
  `task/gptk-import-public-proof-docs`, based on runtime `main` merge commit
  `472091f`, documentation commit `61624ad`.
- Purpose: prove GPTK3 and GPTK4 import through Konyak's public
  `install-gptk-wine --json` CLI path, rerun maintained GPTK backend smoke
  against those installed runtimes, and document the resulting support matrix.
- Workstream separation: the multi-agent tool is available, but its tool-level
  instructions allow spawning only when the user explicitly requests
  sub-agents. Investigation, implementation, and audit evidence will therefore
  be kept separate in this snapshot and in
  `docs/gptk-d3dmetal-import-progress.md`.
- Completed work: runtime PR #4 and parent PR #38 merged GPTK4 payload import
  support; this gate added the maintained parent public CLI smoke
  `scripts/run_macos_gptk_import_cli_smoke.zsh` and `just
  smoke-macos-gptk-import-cli`; proved Apple GPTK 3.0 and Apple GPTK 4.0 beta 1
  imports through `install-gptk-wine --json`; proved `list-runtimes --json`
  reports the `gptk-d3dmetal` component/backend after each import; reran the
  maintained runtime `gptk-d3d10-unsupported`, `gptk-d3d11-device`, and
  `gptk-d3d12-device` smokes against both installed runtimes; updated
  user-facing, release, GPTK workstream, and runtime contract docs with the
  GPTK3/GPTK4 support matrix.
- Remaining work: review runtime PR #5 and parent PR #39 before merging.
- Next action: review G4-P1 PRs; after merge, continue with the DLSS/MetalFX
  rendering-proof task in `docs/todo.md`.
- Verification so far:
  - `nix develop -c zsh -lc 'just smoke-macos-gptk-import-cli'` passed:
    Apple GPTK 3.0 and Apple GPTK 4.0 beta 1 were installed through the public
    CLI path, `list-runtimes --json` reported `gptk-d3dmetal`, GPTK3 retained
    `atidxx64.*`, GPTK4 omitted `atidxx64.*`, neither installed active
    `d3d10.*`, and all maintained GPTK backend smokes passed. Logs:
    `.dart_tool/konyak/gptk-import-cli-smoke/logs`.
  - `nix develop -c zsh -lc 'zsh -n scripts/run_macos_gptk_import_cli_smoke.zsh && git diff --check && git -C runtime/konyak-macos-runtime diff --check && just cli-test && just verify-governance && just verify-safety && just format-check && just lint'`
    passed; `just cli-test` reported 382 tests passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && zsh -n scripts/import-gptk-d3dmetal-redist.zsh scripts/prepare-gptk-d3dmetal-ci-smoke.zsh scripts/smoke-backend-device.zsh scripts/smoke-gptk-d3dmetal-local.zsh scripts/check-runtime-archive-excludes-gptk.zsh'`
    passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && KONYAK_GPTK_D3DMETAL_CI_SOURCE_PATH=/Users/masato/Downloads/Game_Porting_Toolkit_4.0_beta_1.dmg ./scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-gptk4-local-smoke dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed: GPTK4 was detected, `gptk-d3d10-unsupported`,
    `gptk-d3d11-device`, and `gptk-d3d12-device` passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && ./scripts/smoke-gptk-d3dmetal-local.zsh --allow-unsupported-host --work-root /tmp/konyak-gptk3-local-smoke dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed: GPTK3 was detected and the same GPTK smoke targets passed.
  - `nix develop -c zsh -lc 'cd runtime/konyak-macos-runtime && nix shell nixpkgs#gnutar -c ./scripts/check-runtime-archive-excludes-gptk.zsh dist/konyak-macos-wine-runtime-stack.tar.zst'`
    passed.
  - `nix develop -c zsh -lc 'git diff --check && git -C runtime/konyak-macos-runtime diff --check && just verify-governance && just verify-safety && just format-check && just lint'`
    passed.
  - Runtime PR #4 full Build runtime CI passed, including Wine runtime,
    MoltenVK, DXMT, vkd3d, binary components, runtime stack assembly, release
    metadata, Wine32-on-64, GUI start, DXVK D3D10/D3D11, WineD3D D3D10,
    DXMT D3D11, vkd3d D3D12, and GPTK/D3DMetal backend smoke.
  - Parent PR #38 CI passed: Konyak Verify and macOS Runtime CLI Smoke.
