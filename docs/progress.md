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

- Timestamp: 2026-07-03 10:58 JST
- State: `completed`
- Branch: `task/interface-i2-command-selection-planner-audit`
- Active work: I2-P5 Command Selection Planner Reassessment.
- Related TODO: `docs/todo.md` `I2: Boundary Hardening and Test Contract
  Cleanup`, `I2-S4` nullable command-selection bridge reassessment, and
  `I2-P5 Command Selection Planner Reassessment`.
- Pull request: draft PR #18
  <https://github.com/serika12345/Konyak/pull/18>.
- Latest commit: branch head for the I2-P5 draft PR.
- Purpose: make bottle-command selection carry the selected execution shape
  before `ProgramRunPlanner` maps it to host-specific run requests, removing
  ad hoc string comparisons from the planner without changing public CLI JSON,
  argv, exit-code, app, or runtime behavior.
- Completed work: PR #17 for I2-P4 was merged; `main` was fast-forwarded; the
  I2-P5 PR Gate was added to `docs/todo.md`; `supportedBottleCommand` now
  returns a `SupportedBottleCommand` record with the normalized command and
  `BottleCommandPlanKind`; `ProgramRunPlanner.planBottleCommand` now switches
  on the selected plan kind instead of comparing command strings; focused
  domain tests and governance were updated for the completed boundary.
- Remaining work: review draft PR #18, then stop before I2-S5 governance
  cleanup or any broader planner-policy split.
- Next action: review the I2-P5 draft PR and then decide whether the next
  gate should finish remaining I2-S4 planner-policy reassessment or move to
  I2-S5 governance tightening.
- Verification: focused domain test passed:
  `cd packages/konyak_cli && dart test --reporter compact
  test/domain_immutability_test.dart`; `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed through the Nix dev shell.
