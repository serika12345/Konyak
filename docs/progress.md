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

- Timestamp: 2026-07-06 17:41 JST
- State: `in_progress`
- Branch: `task/gptk4-parent-import-variant`
- Active work: `G3-P1 GPTK4 Parent Import Variant`.
- Related TODO: `docs/todo.md` `Next Tasks` points at
  `docs/gptk-d3dmetal-import-progress.md`; the active gate is
  `G3-P1 GPTK4 Parent Import Variant`.
- Pull request: not opened yet for the current gate. Previous parent PR
  https://github.com/serika12345/Konyak/pull/36 merged as `4e56d49`.
- Latest known completed work: runtime PR
  https://github.com/serika12345/konyak-macos-runtime/pull/3 merged as
  `eedc190`; parent PR https://github.com/serika12345/Konyak/pull/34 merged
  as `ab048d8`; parent PR https://github.com/serika12345/Konyak/pull/35
  merged as `0afa99f`; parent PR https://github.com/serika12345/Konyak/pull/36
  merged as `4e56d49`.
- Purpose: accept the GPTK4 parent import payload variant that lacks
  `atidxx64.*`, while keeping GPTK3 validation strict and recording the
  detected GPTK version in the public import result.
- Completed work: created branch `task/gptk4-parent-import-variant`; added
  GPTK4-without-`atidxx64.*` CLI import coverage; kept GPTK3 validation strict;
  split GPTK validation and component copy requirements by detected GPTK
  version; removed `atidxx64.*` from the active runtime completeness contract;
  preserved `nvngx-on-metalfx.*` source normalization into canonical
  `nvngx.*` installed names; added detected GPTK version to public import JSON.
- Remaining work: commit, push, open a draft PR, and stop at the G3-P1 review
  gate. Apple GPTK 4.0 beta 1 DMG proof remains pending outside this parent
  fixture gate.
- Next action: stage the G3-P1 files, commit, push
  `task/gptk4-parent-import-variant`, and open a draft PR.
- Verification so far:
  - `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test test/cli_contract_runtime_install_test.dart test/cli_contract_runtime_process_update_test.dart test/cli_app_runtime_json_test.dart test/runtime_platform_definition_type_fronts_test.dart'`
    passed.
  - `nix develop -c zsh -lc 'dart format packages/konyak_cli/test/cli_contract_runtime_install_test.dart && cd packages/konyak_cli && dart test test/cli_contract_runtime_install_test.dart --plain-name "install-gptk-wine imports GPTK4 payloads without atidxx64"'`
    passed.
  - `nix develop -c zsh -lc 'just cli-test && just verify-governance && just verify-safety && just format-check && just lint'`
    passed.
