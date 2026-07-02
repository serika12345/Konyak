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

- Timestamp: 2026-07-02 22:12 JST
- State: `completed`
- Branch: `task/interface-i2-cli-contract-family-tests`
- Active work: I2-P3 CLI Contract Family Test Part Split.
- Related TODO: `docs/todo.md` `I2: Boundary Hardening and Test Contract
  Cleanup`, completed `I2-P3 CLI Contract Family Test Part Split`, and next
  `I2-P4 Semantic Constructor Primitive Fronts`.
- Pull request: draft PR #16
  <https://github.com/serika12345/Konyak/pull/16>.
- Latest commit: branch head for the I2-P3 draft PR.
- Purpose: remove the remaining CLI contract hand-written test `part` files so
  app/bottle, pinned program, program execution, runtime process/update, and
  runtime install contract coverage run from standalone test entry points.
- Completed work: converted the remaining CLI contract part files into
  standalone tests backed by `test/support/cli_contract_full_helpers.dart`;
  reduced `cli_contract_test.dart` to the macOS runtime release SSOT check;
  added governance coverage so `packages/konyak_cli/test` cannot reintroduce
  CLI contract `*.part.dart` files.
- Remaining work: review draft PR #16, then stop before implementing I2-P4.
- Next action: review the I2-P3 draft PR and then run `/advance-pr` for
  `I2-P4 Semantic Constructor Primitive Fronts`.
- Verification: focused CLI contract family test command passed:
  `cd packages/konyak_cli && dart test --reporter compact
  test/cli_contract_app_bottle_test.dart
  test/cli_contract_pinned_program_test.dart
  test/cli_contract_program_execution_test.dart
  test/cli_contract_runtime_process_update_test.dart
  test/cli_contract_runtime_install_test.dart`; `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed through the Nix dev shell.
