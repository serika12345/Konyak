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

- Timestamp: 2026-07-03 09:13 JST
- State: `completed`
- Branch: `task/interface-i2-semantic-constructor-fronts`
- Active work: I2-P4 Semantic Constructor Primitive Fronts.
- Related TODO: `docs/todo.md` `I2: Boundary Hardening and Test Contract
  Cleanup`, completed `I2-P4 Semantic Constructor Primitive Fronts`, and next
  `I2-S4` nullable command-selection bridge reassessment.
- Pull request: draft PR #17
  <https://github.com/serika12345/Konyak/pull/17>.
- Latest commit: branch head for the I2-P4 draft PR.
- Purpose: remove selected primitive constructor compatibility fronts from
  stable settings/runtime domain APIs while preserving primitive JSON, argv,
  registry, and persisted-data adapter boundaries.
- Completed work: typed `AppSettingsRecord`, `BottleRuntimeSettings`,
  `ProgramSettingsRecord`, `ProgramLoggingSettingsRecord`, and
  `RuntimeValidationRecord` public constructors with existing value objects;
  moved primitive conversion to app settings JSON, repository storage,
  registry parsing, and runtime validation adapters; added governance checks
  for the converted signatures.
- Remaining work: review draft PR #17, then stop before nullable
  command-selection or planner policy changes.
- Next action: review the I2-P4 draft PR and then plan the I2-S4 command
  selection bridge reassessment before implementation.
- Verification: focused domain test command passed:
  `cd packages/konyak_cli && dart test --reporter compact
  test/domain_immutability_test.dart`; `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed through the Nix dev shell.
