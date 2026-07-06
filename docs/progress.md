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

- Timestamp: 2026-07-06 11:43 JST
- State: `planned`
- Branch: `task/gptk-d3d10-smoke`
- Active work: `G1-P4 GPTK D3D10 Unsupported and WineD3D Fallback Contract`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G1-P4 GPTK D3D10 Unsupported and WineD3D Fallback Contract`.
- Pull request: https://github.com/serika12345/Konyak/pull/33
- Runtime submodule pull request:
  https://github.com/serika12345/konyak-macos-runtime/pull/2, merged into
  runtime `main` as `9c5bdf1`.
- Latest implementation commit: runtime submodule `9c5bdf1`; parent branch
  update is on `task/gptk-d3d10-smoke`. Runtime PR #1 was merged into runtime
  `main` as `2fd0578`.
- Purpose: implement CrossOver-equivalent D3D10 handling for Konyak: GPTK/D3DMetal
  is expected to be unsupported for direct D3D10 render/readback, while actual
  macOS D3D10 rendering is handled through DXVK first and WineD3D/Vulkan
  fallback second.
- Completed work: kept runtime PR #2's DXVK D3D10 render/readback proof intact;
  dynamically tested GPTK D3D10 device creation/readback candidates against the
  assembled Konyak runtime, Apple GPTK 3.0, Apple GPTK 4.0 beta 1, and
  `/Users/masato/Documents/CrossOver.app`; decided that CrossOver.app's passing
  D3D10 route is the fallback model to implement, not GPTK/D3DMetal proof.
- Dynamic result: native GPTK/D3DMetal `dxgi`/`d3d11` paths do not expose a
  usable `ID3D10Device`. `D3D10CreateDevice` and `D3D10CreateDevice1` return
  `0x80004005`; a diagnostic `D3D11CreateDevice` plus
  `QueryInterface(ID3D10Device)` returns `0x80004002`. CrossOver.app can pass
  the D3D10 render/readback probe, but `WINEDEBUG=+loaddll` shows that success
  uses builtin WineD3D's Vulkan renderer, not native GPTK/D3DMetal DLLs.
- Remaining work: add runtime smoke coverage for expected GPTK D3D10
  unsupported behavior and CrossOver-equivalent WineD3D/Vulkan D3D10
  render/readback; align parent backend hints and launch fallback diagnostics.
- Next action: merge parent PR #33, then implement G1-P4 before GPTK4 import.
  The runtime side needs `gptk-d3d10-unsupported` and `wined3d-d3d10-render`
  smoke coverage, and the parent side needs an explicit D3D10 fallback
  contract.
- Verification: this plan update passed runtime submodule
  `nix develop -c zsh -lc 'git diff --check'`; parent
  `nix develop -c zsh -lc 'just verify-governance'`,
  `nix develop -c zsh -lc 'just verify-safety'`,
  `nix develop -c zsh -lc 'just format-check'`, and
  `nix develop -c zsh -lc 'just lint'`. Runtime PR #2 CI passed through
  GitHub Actions before merge, including `Verify DXVK D3D10/D3D11 backend
  smoke`, `Verify GPTK/D3DMetal backend smoke`, runtime stack assembly, metadata,
  GUI, Wine32-on-64, DXMT, and vkd3d smoke jobs.
