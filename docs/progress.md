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

- Timestamp: 2026-07-06 10:43 JST
- State: `blocked`
- Branch: `task/gptk-d3d10-smoke`
- Active work: `G1-P4 GPTK D3D10 Render/Readback Proof`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G1-P4 GPTK D3D10 Render/Readback Proof`.
- Pull request: https://github.com/serika12345/Konyak/pull/33
- Runtime submodule pull request:
  https://github.com/serika12345/konyak-macos-runtime/pull/2
- Latest implementation commit: runtime submodule `5ca9454`; parent branch
  update is on `task/gptk-d3d10-smoke`. Runtime PR #1 was merged into runtime
  `main` as `2fd0578`.
- Purpose: prove actual D3D10 render/readback through GPTK/D3DMetal
  specifically. DXVK and WineD3D/Vulkan render success must not be reported as
  GPTK/D3DMetal proof.
- Completed work: kept runtime PR #2's DXVK D3D10 render/readback proof intact;
  dynamically tested GPTK D3D10 device creation/readback candidates against the
  assembled Konyak runtime, Apple GPTK 3.0, Apple GPTK 4.0 beta 1, and
  `/Users/masato/Documents/CrossOver.app`.
- Dynamic result: native GPTK/D3DMetal `dxgi`/`d3d11` paths do not expose a
  usable `ID3D10Device`. `D3D10CreateDevice` and `D3D10CreateDevice1` return
  `0x80004005`; a diagnostic `D3D11CreateDevice` plus
  `QueryInterface(ID3D10Device)` returns `0x80004002`. CrossOver.app can pass
  the D3D10 render/readback probe, but `WINEDEBUG=+loaddll` shows that success
  uses builtin WineD3D's Vulkan renderer, not native GPTK/D3DMetal DLLs.
- Remaining work: decide the product contract for D3D10 on macOS. Current
  dynamic evidence supports DXVK or WineD3D/Vulkan for real D3D10 rendering,
  while GPTK/D3DMetal remains only a bridge reachability check for D3D10.
- Next action: do not add a passing `gptk-d3d10-render` CI target unless a new
  runtime/payload combination actually returns `ID3D10Device` and passes
  readback through native GPTK/D3DMetal. Either keep G1-P3 as the honest D3D10
  smoke PR or open a new investigation with a different upstream payload.
- Verification: runtime and parent worktrees were restored clean after the
  blocked GPTK experiments. The latest passing verification remains the G1-P3
  DXVK D3D10 render/readback verification recorded in
  `docs/gptk-d3dmetal-import-progress.md`.
