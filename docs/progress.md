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

- Timestamp: 2026-07-05 23:53 JST
- State: `completed`
- Branch: `task/gptk3-d3d10-parent-import`
- Active work: G1-P1 GPTK3 D3D10 Parent Import Contract.
- Related TODO: `docs/todo.md` `Next Tasks` now points at
  `docs/gptk-d3dmetal-import-progress.md`; the first planned gate is
  `G1-P1 GPTK3 D3D10 Parent Import Contract`.
- Pull request: https://github.com/serika12345/Konyak/pull/32
- Latest implementation commit: `aa88bd6`.
- Purpose: make the parent repository import contract preserve GPTK3
  `d3d10.dll` and `d3d10.so` before any GPTK4 variant support is added.
- Completed work: added `docs/gptk-d3dmetal-import-progress.md` with current
  evidence, operating rules, large milestones G1-G4, PR gates G1-P1 through
  G4-P1, verification requirements, and deferred follow-ups; added a top-level
  TODO pointer to that file; incorporated the PR #31 reporting format requiring
  change intent and what is now possible in GPTK review packages and final
  reports; created `task/gptk3-d3d10-parent-import`; added parent tests and
  implementation so GPTK3 imports require, install, preserve, and report
  `d3d10.dll` and `d3d10.so`; captured public CLI proof with the Apple GPTK 3.0
  DMG; committed and pushed `aa88bd6`; opened draft PR #32.
- Remaining work: review draft PR #32, then start G1-P2 only after the review
  gate is accepted.
- Next action: review https://github.com/serika12345/Konyak/pull/32; do not
  start G1-P2 until the G1-P1 review gate is cleared.
- Verification: G1-P1 implementation verification passed through the Nix dev
  shell with `just cli-test`, `just verify-governance`, `just verify-safety`,
  `just format-check`, and `just lint`. Focused red/green coverage used
  `dart test test/cli_contract_runtime_install_test.dart
  test/runtime_platform_definition_type_fronts_test.dart`. Public CLI proof
  used `install-gptk-wine --from
  /Users/masato/Downloads/Game_Porting_Toolkit_3.0.dmg --json` with a temporary
  runtime root and confirmed installed `d3d10.dll` plus `d3d10.so ->
  ../../external/libd3dshared.dylib`. The post-PR documentation record is
  verified with `just verify-governance`.
