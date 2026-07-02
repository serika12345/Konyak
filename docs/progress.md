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

- Timestamp: 2026-07-02 20:33 JST
- State: `completed`
- Branch: `task/interface-i1-governance-allowances`
- Active work: I1-P5 Refactoring Governance Allowance Cleanup.
- Related TODO: `docs/todo.md` `I1: Compatibility Interface Cleanup`, `I1-S5`,
  and `I1-P5 Refactoring Governance Allowance Cleanup`.
- Pull request: https://github.com/serika12345/Konyak/pull/13
- Latest commit: branch commit (`Tighten I1 nullable governance allowance`).
- Purpose: remove the remaining stale governance allowance left after the I1
  compatibility wrapper cleanup and make the current Flutter update DTO
  boundary enforceable by custom lint.
- Completed work: removed the broad `apps/konyak/lib/src/updates/` nullable
  boundary allowlist from `konyak_lints`, added a Flutter custom-lint fixture
  proving app-facing update summaries cannot reintroduce nullable fields,
  added governance coverage for the tightened boundary, and marked I1-P5 as
  completed in `docs/todo.md`.
- Remaining work: review the draft PR. Do not add or start a post-I1
  milestone until I1-P5 has been reviewed and merged.
- Next action: review the I1-P5 draft PR after it is opened.
- Verification: `just konyak-lints-test` intentionally failed before the lint
  allowlist was tightened; `just verify-governance` intentionally failed before
  the docs update because I1-P5 was not yet marked complete. Final
  verification passed with `just konyak-lints-test`, `just verify-governance`,
  `just verify-safety`, `just format-check`, and `just lint` through the Nix
  dev shell.
