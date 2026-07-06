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

- Timestamp: 2026-07-06 14:53 JST
- State: `in_progress`
- Branch: `task/gptk-d3d10-fallback-contract`
- Active work: `G1-P4 GPTK D3D10 Unsupported and WineD3D Fallback Contract`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G1-P4 GPTK D3D10 Unsupported and WineD3D Fallback Contract`.
- Pull request: not opened yet for the current gate. Previous parent PR
  https://github.com/serika12345/Konyak/pull/33 was merged into parent `main`
  as `bb8fefc`.
- Runtime submodule branch: `task/d3d10-fallback-smoke`; pull request not
  opened yet. Previous runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/2 was merged into
  runtime `main` as `9c5bdf1`.
- Latest implementation commit: parent `d7915aa`, runtime submodule `9f8f43a`.
  Runtime PR #1 was merged into runtime `main` as `2fd0578`.
- Purpose: implement CrossOver-equivalent D3D10 handling for Konyak: GPTK/D3DMetal
  is expected to be unsupported for direct D3D10 render/readback, while actual
  macOS D3D10 rendering is handled through DXVK first and WineD3D/Vulkan
  fallback second.
- Completed work: kept runtime PR #2's DXVK D3D10 render/readback proof intact;
  dynamically tested GPTK D3D10 device creation/readback candidates against the
  assembled Konyak runtime, Apple GPTK 3.0, Apple GPTK 4.0 beta 1, and
  `/Users/masato/Documents/CrossOver.app`; implemented parent launch fallback
  diagnostics so macOS D3D10 programs run through WineD3D/Vulkan when
  GPTK/D3DMetal is selected; confirmed CrossOver's WineD3D/Vulkan D3D10 route
  needs CrossOver MoltenVK behavior rather than a Konyak WineD3D feature-gate
  patch; removed the temporary non-Wine-library patch from the CrossOver Wine
  derivation; added a dedicated CrossOver-source MoltenVK Nix recipe and local
  component package path; added runtime smoke targets and CI jobs for expected
  GPTK D3D10 unsupported behavior and WineD3D/Vulkan D3D10 fallback; addressed
  audit findings by allowing the hosted-runner GPTK unsupported GPU signature
  only under `KONYAK_ALLOW_GPTK_UNSUPPORTED_HOST=1`, keeping D3DMetal selected
  for `D3D12CreateDevice` string signals, and adding pinned-launcher fallback
  coverage.
- Dynamic result: native GPTK/D3DMetal `dxgi`/`d3d11` paths do not expose a
  usable `ID3D10Device`. `D3D10CreateDevice` and `D3D10CreateDevice1` return
  `0x80004005`; a diagnostic `D3D11CreateDevice` plus
  `QueryInterface(ID3D10Device)` returns `0x80004002`. CrossOver.app can pass
  the D3D10 render/readback probe, but `WINEDEBUG=+loaddll` shows that success
  uses builtin WineD3D's Vulkan renderer, not native GPTK/D3DMetal DLLs.
- Remaining work: commit and push the runtime and parent branches, open PRs,
  run the new `build-moltenvk-component` GitHub Actions path through runtime
  stack assembly and smoke, then address any CI-only findings.
- Next action: rerun final local static checks, commit the source-built
  CrossOver MoltenVK component work, push the branches, and watch runtime CI
  until `wined3d-d3d10-render` plus `gptk-d3d10-unsupported` pass from uploaded
  artifacts.
- Verification: parent `nix develop -c zsh -lc 'cd packages/konyak_cli && dart
  test test/cli_contract_program_execution_test.dart
  test/cli_contract_pinned_program_test.dart'` passed; parent `nix develop -c
  zsh -lc 'cd packages/konyak_cli && dart test
  test/runtime_platform_definition_type_fronts_test.dart
  test/cli_contract_runtime_process_update_test.dart'` passed; parent `nix
  develop -c zsh -lc 'dart format --output=none --set-exit-if-changed ...'`
  passed for the touched Dart files; runtime `nix develop -c zsh -lc 'zsh -n
  scripts/smoke-backend-device.zsh scripts/smoke-gptk-d3dmetal-local.zsh &&
  git diff --check'` passed; runtime `nix develop -c zsh -lc 'nix build
  .#packages.x86_64-darwin.konyak-macos-moltenvk -L --show-trace --out-link
  result-moltenvk-crossover'` passed; `./scripts/check-moltenvk-component.zsh
  result-moltenvk-crossover`, `./scripts/package-moltenvk-component.zsh
  result-moltenvk-crossover dist`, and archive recheck passed; local stack
  assembly with `crossover-26.1.0-moltenvk-konyak.0` passed
  `check-moltenvk-component.zsh`, `check-dxvk-component.zsh`, and
  `check-wine32on64-runtime.zsh`; local dynamic smoke passed
  `wined3d-d3d10-render`; GPTK local smoke passed
  `gptk-d3d10-unsupported`, `gptk-d3d11-device`, and `gptk-d3d12-device`.
  Runtime GitHub Actions are still pending.
