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

- Timestamp: 2026-07-06 09:32 JST
- State: `completed`
- Branch: `task/gptk-d3d10-smoke`
- Active work: `G1-P3 D3D10 DXVK Render Smoke and Backend Hint Contract`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G1-P3 D3D10 DXVK Render Smoke and Backend Hint Contract`.
- Pull request: https://github.com/serika12345/Konyak/pull/33
- Runtime submodule pull request:
  https://github.com/serika12345/konyak-macos-runtime/pull/2
- Latest implementation commit: runtime submodule `5ca9454`; parent branch
  update is on `task/gptk-d3d10-smoke`. Runtime PR #1 was merged into runtime
  `main` as `2fd0578`.
- Purpose: add actual D3D10 render/readback proof for the supported bundled
  runtime route and align parent backend suggestions with the dynamic evidence:
  D3D10 uses DXVK, while D3D11 keeps DXMT first.
- Completed work: merged runtime PR #1; confirmed DXVK D3D10 render/readback
  succeeds against `dist/konyak-macos-wine-runtime-stack.tar.zst`; confirmed
  diagnostic DXMT D3D10 attempts fail before rendering with `0x80004005`;
  added runtime PR #2 with `dxvk-d3d10-render` probe, smoke target, workflow
  coverage, and documentation; split parent graphics backend hints so macOS
  D3D10 recommends DXVK and macOS D3D11 keeps DXMT first with DXVK fallback.
- Remaining work: review the parent PR and runtime submodule PR #2 before GPTK4
  import work.
- Next action: review https://github.com/serika12345/Konyak/pull/33 and
  https://github.com/serika12345/konyak-macos-runtime/pull/2. After merge,
  continue with G2-P1 version-specified GPTK import.
- Verification: passed runtime DXVK D3D10 render/readback, DXVK D3D11, and
  DXMT D3D11 smoke through `scripts/smoke-backend-device.zsh`; passed runtime
  `git diff --check` and `nix flake check -L --show-trace`; passed focused Dart
  `suggest-graphics-backend` tests; passed parent `just cli-test`,
  `just verify-governance`, `just verify-safety`, rerun `just format-check`,
  and `just lint`.
