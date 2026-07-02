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

- Timestamp: 2026-07-02 15:06 JST
- State: `completed`
- Branch: `task/interface-i1-cli-parser-wrappers`
- Active work: I1-P1 CLI Parser Compatibility Wrappers.
- Related TODO: `docs/todo.md` `I1: Compatibility Interface Cleanup`,
  `I1-P1 CLI Parser Compatibility Wrappers`.
- Pull request: https://github.com/serika12345/Konyak/pull/8
- Latest commit: branch commit (`Remove CLI parser compatibility wrappers`).
- Purpose: remove nullable parser compatibility wrappers from the runtime and
  location CLI parser families while preserving public CLI behavior.
- Completed work: added governance coverage that rejects the converted
  runtime/location nullable parser wrappers; removed those wrappers from
  `cli_runtime_parsers.dart` and `cli_location_parsers.dart`; updated runtime,
  streaming runtime, and location command-selection call sites to use the
  existing `Option` parser APIs directly; and marked I1-P1 as completed in
  `docs/todo.md`.
- Remaining work: review the draft PR. Do not advance into I1-P2 until I1-P1
  has been reviewed and merged.
- Next action: review https://github.com/serika12345/Konyak/pull/8.
- Verification: `just verify-governance` was first run after the new governance
  check and failed on the old `GptkWineInstallRequest?` wrapper as expected.
  Final verification passed with `just cli-test`, `just verify-governance`,
  `just verify-safety`, `just format-check`, and `just lint` through the Nix dev
  shell.
