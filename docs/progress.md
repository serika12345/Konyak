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

- Timestamp: 2026-07-06 01:10 JST
- State: `completed`
- Branch: `task/gptk-d3d10-smoke`
- Active work: `G1-P2 D3D10 GPTK Bridge Smoke Contract`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G1-P2 D3D10 GPTK Bridge Smoke Contract`.
- Pull request: not opened yet.
- Latest implementation commit: runtime submodule `a1cf1d0`; parent commit is
  pending on `task/gptk-d3d10-smoke`. PR #32 merged as
  `f30d0cf677060d100a9f0d8e92fae745a8966632`, but its active GPTK `d3d10.*`
  import direction is corrected by this follow-up.
- Purpose: keep D3D10 on the base Wine builtin frontend, remove active GPTK
  `d3d10.*` component expectations, and add runtime smoke/CI proof that D3D10
  reaches GPTK/D3DMetal through D3D11/DXGI.
- Completed work: added and maintained the dedicated GPTK progress file;
  incorporated the PR #31 reporting format into project instructions;
  investigated Apple GPTK 3.0, Apple GPTK 4.0 beta 1, CrossOver.app, and
  CrossOver FOSS sources; concluded that active GPTK `d3d10.*` should not be
  installed or overridden; created `task/gptk-d3d10-smoke`; removed active GPTK
  `d3d10.*` from parent component/import contracts and fixtures; added the
  runtime D3D10 bridge probe and `gptk-d3d10-bridge` smoke target; wired the
  D3D10 bridge smoke into build, artifact-smoke, and candidate-promotion
  workflows; confirmed local maintained GPTK smoke passes with D3D10 bridge
  signature, D3D11 device success, and D3D12 device success.
- Remaining work: commit and push the runtime submodule plus parent pointer,
  open a draft PR, then stop before GPTK4 import work.
- Next action: review the D3D10 bridge smoke PR; after merge, continue with
  G2-P1 version-specified GPTK import.
- Verification: passed `zsh -n` for edited runtime scripts; passed runtime
  backend probe build; passed `smoke-gptk-d3dmetal-local.zsh
  --allow-unsupported-host --work-root
  /tmp/konyak-gptk-d3d10-bridge-smoke-check
  dist/konyak-macos-wine-runtime-stack.tar.zst`; passed focused Dart tests
  `runtime_platform_definition_type_fronts_test.dart` and
  `cli_contract_runtime_install_test.dart`; passed `just cli-test`; passed
  `just verify-governance`; passed `just verify-safety`; passed
  `just format-check`; passed `just lint`.
