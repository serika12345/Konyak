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

- Timestamp: 2026-07-03 10:57 JST
- State: `completed`
- Branch: `task/interface-i2-command-selection-planner-audit`
- Active work: I2-P5 Command Selection Planner Reassessment.
- Related TODO: `docs/todo.md` `I2: Boundary Hardening and Test Contract
  Cleanup`, `I2-S4` nullable command-selection bridge reassessment, and
  `I2-P5 Command Selection Planner Reassessment`.
- Pull request: not opened yet.
- Latest commit: pending branch commit for I2-P5.
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
- Remaining work: commit, push, open the draft PR, and stop before I2-S5
  governance cleanup or any broader planner-policy split.
- Next action: commit the verified I2-P5 branch, push it, and open the draft
  PR for review.
- Verification: focused domain test passed:
  `cd packages/konyak_cli && dart test --reporter compact
  test/domain_immutability_test.dart`; `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` passed through the Nix dev shell.
