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

- Timestamp: 2026-06-25 17:28 JST
- State: `completed`
- Branch: `main`
- Active work: removing inventoried implementation-debt compatibility paths.
- Related TODO: removal of remaining archive/Wine-only compatibility fallback
  after source-manifest runtime acquisition became the supported contract.
- Purpose: retire tests and implementation paths that only preserve older
  runtime acquisition, metadata, or layout debt instead of proving current
  Konyak behavior.
- Completed work: removed public runtime archive install options, removed
  runtime update archive fallback, removed the Linux development manifest legacy
  fallback, required backend records for runtime-backed Flutter controls,
  limited GPTK/D3DMetal preservation to the canonical component layout, updated
  macOS release extraction smoke to use a source manifest, and updated the
  affected tests, VS Code/Nix wiring, governance checks, and documentation.
- Remaining work: none for this cleanup.
- Next action: choose the next open item from `docs/todo.md`.
- Verification: passed `just verify-governance`, `just verify-safety`,
  `just format-check`, `just lint`, `just flutter-format-check`,
  `just flutter-analyze`, `just flutter-test`, and `just cli-test`.
