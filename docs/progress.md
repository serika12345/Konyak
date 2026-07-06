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

- Timestamp: 2026-07-06 17:18 JST
- State: `in_progress`
- Branch: `task/gptk-version-detection`
- Active work: `G2-P2 GPTK Version Detection and Mismatch Diagnostics`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G2-P2 GPTK Version Detection and Mismatch Diagnostics`.
- Pull request: not opened yet for the current gate. Previous parent PR
  https://github.com/serika12345/Konyak/pull/35 merged as `0afa99f`.
- Latest known completed work: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 merged as
  `eedc190`; parent PR https://github.com/serika12345/Konyak/pull/34 merged
  as `ab048d8`; parent PR https://github.com/serika12345/Konyak/pull/35
  merged as `0afa99f`.
- Purpose: detect GPTK3/GPTK4 payload versions from `D3DMetal.framework`
  metadata and return stable JSON diagnostics when an explicit requested
  version does not match the detected payload.
- Completed work: created branch `task/gptk-version-detection`; confirmed real
  GPTK metadata uses `CFBundleShortVersionString=3.0` for GPTK3/CrossOver and
  `4.0b1` for GPTK4 beta 1; added failing CLI contract tests for GPTK3 request
  receiving GPTK4, GPTK4 request receiving GPTK3, and `auto` accepting detected
  GPTK4; implemented framework version detection and `gptkWineVersionMismatch`
  JSON error fields.
- Remaining work: commit, push, open a draft PR, then stop before G3-P1.
- Next action: commit the verified G2-P2 implementation and open a draft PR.
- Verification so far: `nix develop -c zsh -lc 'cd packages/konyak_cli && dart
  test test/cli_contract_runtime_install_test.dart --plain-name
  "install-gptk-wine"'` passed; `nix develop -c zsh -lc 'just cli-test &&
  just verify-governance && just verify-safety && just format-check && just
  lint'` passed.
