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

- Timestamp: 2026-07-02 15:56 JST
- State: `completed`
- Branch: `task/interface-i1-cli-command-dispatch`
- Active work: I1-P2 CLI Command Dispatch.
- Related TODO: `docs/todo.md` `I1: Compatibility Interface Cleanup`,
  `I1-P2 CLI Command Dispatch`.
- Pull request: https://github.com/serika12345/Konyak/pull/9
- Latest commit: branch commit (`Replace CLI command nullable dispatch`).
- Purpose: replace nullable command dispatch for the runtime and location
  command groups with explicit matched/not-matched variants while preserving the
  public CLI contract.
- Completed work: introduced `CliCommandMatch`, `CliCommandMatched`, and
  `CliCommandNotMatched`; replaced `firstCliResult` with explicit
  `firstCliCommandMatch`; converted runtime and location command handlers to
  return explicit dispatch variants; kept a legacy wrapper only around
  command groups not yet converted; added matched/unmatched command dispatch
  contract tests; added governance coverage for the converted dispatch
  boundary; and marked I1-P2 as completed in `docs/todo.md`.
- Remaining work: review the draft PR. Do not advance into I1-P3 until I1-P2
  has been reviewed and merged.
- Next action: review https://github.com/serika12345/Konyak/pull/9.
- Verification: final verification passed with `just cli-test`,
  `just verify-governance`, `just verify-safety`, `just format-check`, and
  `just lint` through the Nix dev shell.
