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

- Timestamp: 2026-07-03 13:58 JST
- State: `completed`
- Branch: `task/interface-i2-registry-platform-policy`
- Active work: I2-P7 Registry Planner Platform Policy.
- Related TODO: `docs/todo.md` `I2: Boundary Hardening and Test Contract
  Cleanup`, completed `I2-S4`, completed `I2-P7 Registry Planner Platform
  Policy`, and next `I2-S5` governance tightening.
- Pull request: draft PR #21
  <https://github.com/serika12345/Konyak/pull/21>.
- Latest commit: `8c980cb` (`Model registry planner platform policy`).
- Purpose: replace the raw `includeMacDriverSettings` boolean bridge between
  `ProgramRunPlanner` and registry plan helpers with an explicit
  `RegistryPlanningPolicy` while preserving generated registry updates,
  queries, argv, CLI JSON, exit codes, app behavior, runtime behavior, and Wine
  execution paths.
- Completed work: PR #20 for I2-P6 was merged; `main` was fast-forwarded;
  registry plan helpers now accept `RegistryPlanningPolicy`; the planner maps
  `KonyakHostPlatform` to `RegistryPlanningPolicy`; focused domain tests cover
  macOS inclusion and Linux exclusion of Wine Mac Driver registry values;
  governance was updated for the completed registry policy boundary; I2-S4 and
  I2-P7 are marked complete in `docs/todo.md`.
- Remaining work: review draft PR #21, then stop before I2-S5 governance
  cleanup.
- Next action: review the I2-P7 draft PR; after approval, merge it before
  starting I2-S5.
- Verification: focused domain test passed:
  `nix develop -c zsh -lc 'cd packages/konyak_cli && dart test --reporter
  compact test/domain_immutability_test.dart'`; required gate verification
  passed through the Nix dev shell with `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint`.
